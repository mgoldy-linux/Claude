# Deployment Guide — Remove `ds_view_open_rma_value`

> Status: **DONE in P21Training and Prod (2026-08-06). P21Play deliberately left mid-progress** — will resolve on its next refresh-from-Prod, not a gap. Independent legacy/non-P21 view cleanup task — **not part of SA-51376.** It was noticed while working nearby on that ticket, but this is its own initiative (removing custom views that add nothing over the native P21 view underneath). See `Deploy-Guides\SA-51376-rma-transaction-history-reason-code.md` only for background on how the `fc_dataobject`/`custom_objects` schema was mapped — the two tasks are otherwise unrelated and track separately.

## Goal
Remove the custom (non-P21) view `ds_view_open_rma_value` from the database, as part of a broader push to eliminate non-P21 views. It's a thin wrapper with no logic of its own:
```sql
CREATE VIEW ds_view_open_rma_value AS
SELECT DISTINCT order_no, open_total_value FROM p21_view_open_rma_report
```
`p21_view_open_rma_report` is the genuine P21-native (Epicor-shipped) reporting view underneath it — created 2017 (`dsievertsen`), no logic added by the wrapper itself.

## Findings so far (measured against P21Play)
- **No other SQL object references it.** Checked `sys.sql_modules` text search and `sys.sql_expression_dependencies` — zero hits. Same definition confirmed in Prod.
- **Blind spot:** DynaChange/Field Chooser layouts are stored as data, not SQL text, so a plain SQL dependency search can't see screen-level usage — that's exactly what the schema mapping below closes.
- **Proven equivalent** to inlining directly against the native view: `EXCEPT` both directions between the wrapper and `(SELECT DISTINCT order_no, open_total_value FROM p21_view_open_rma_report)` = 0 rows.
- **Only known consumer:** the "Transaction Master Inquiry Orders" screen (`w_transaction_master_inquiry.d_dw_transaction_inquiry_order`), via P21's Field Chooser mechanism:
  - `fc_dataobject` uid **30** = `d_dw_transaction_inquiry_order` (the screen's underlying DataWindow — one shared row, not per-role)
  - `fc_dataobject_table` uid **80** = the join: `LEFT JOIN ds_view_open_rma_value on ds_view_open_rma_value.order_no = oe_hdr.order_no`
  - `fc_dataobject_column` uid **222** = the field `ufc_ds_view_open_rma_value_open_total_value` sourced from table_uid 80

**`row_status_flag` note (checked, not a red flag):** `fc_dataobject_table` row 80 shows `row_status_flag = 705`, which in P21's shared code table (`p21_view_code_p21`) means "Inactive." Verified this is **not meaningful for this table** — all 171 rows in `fc_dataobject_table` are uniformly 705, no exceptions, so it isn't functioning as an active/inactive toggle here (unlike `fc_dataobject_column`, where it's a genuine mix — 423 rows at 704/Active, 28 at 705/Inactive, and our field, row 222, is correctly 704/Active). The join is confirmed live regardless (it was already returning real data in the base retrieval SQL before any edits this session).

## Per-role placement — only 6 of 21 role versions actually use the field
The Field Chooser SQL/join definition above is defined **once** (shared), but each role's *placement* of the field on its grid lives separately in `custom_objects_detail`. Checked all 21 `custom_objects` rows for `w_transaction_master_inquiry.d_dw_transaction_inquiry_order` — only **6** actually have `ufc_ds_view_open_rma_value_open_total_value` (or its header-label sibling `..._t`) placed:

| `custom_objects_uid` | `version_id` |
|---|---|
| 158 | `screen_transaction_master_inquiry_orders_all` |
| 922 | `screen_transaction_master_inquiry_orders_management` |
| 923 | `screen_transaction_master_inquiry_orders_customer service manager` |
| 929 | `screen_transaction_master_inquiry_orders_accounts receivable manager` |
| 930 | `screen_transaction_master_inquiry_orders_accounts receivable` |
| 2990 | `screen_transaction_master_inquiry_orders_vendor maintenance` |

The other 15 role versions never placed it — nothing to clean up there.

## Decision: Path B (retarget, keep the column) — via delete + rebuild
Went with retargeting rather than pure removal — the 6 roles keep seeing Open Total Value, sourced natively. Executed as **delete old placement → retarget the shared join/column → rebuild the placement**, rather than an in-place join_syntax edit only, so the field's internal name (`ufc_ds_view_open_rma_value_open_total_value` → `ufc_p21_view_open_rma_report_open_total_value`) no longer references the retired view.

## Environment ID check
`fc_dataobject_table` uid 80 / `fc_dataobject_column` uid 222 / the 6 `custom_objects_uid` values (158, 922, 923, 929, 930, 2990) are identical across **Play, Training, and Prod**. **P21Dev differs** — same core IDs plus 4 extra leftover placements (`custom_objects_uid` 3485/3487/3488/3489, oddly named `..._orders_158`/`_922`/`_923`/`_930`) Play/Training/Prod don't have. Chose **P21Training** as the test environment (clean match to Play) instead of P21Dev for this reason.

## P21Training — DONE
1. **Removed** old placements: `Sql-Scripts\Remove-ds_view_open_rma_value-Column-Training.sql` — deleted `ufc_ds_view_open_rma_value_open_total_value`(`_t`) from all 6 `custom_objects_detail`. Verified no errors across all DynaChange versions afterward.
2. **Retargeted**: `Sql-Scripts\Retarget-ds_view_open_rma_value-to-P21-Native-Training.sql` — repointed `fc_dataobject_table` 80 to `LEFT JOIN (SELECT DISTINCT order_no, open_total_value FROM p21_view_open_rma_report) p21_view_open_rma_report on ...`, renamed `fc_dataobject_column` 222's `user_column_name` to `ufc_p21_view_open_rma_report_open_total_value`. `description` ("Open Total Value" display label) left untouched — field re-added via Field Chooser in the client picked it up from the existing list (no "New Field" needed) with the correct label.
3. **Re-added via Field Chooser** in the P21 client, one role at a time (all 6 done: 158, 922, 923, 929, 930, 2990).
4. **Decimal format fix**: field inherited a 9-decimal mask (`editmask.mask="##,###,###,###,###.000000000"`) instead of P21's standard 2-decimal currency mask (confirmed convention via `ufc_opportunity_ud_labor_amount` elsewhere: `"##,###,###,###,###.00"`). Fixed via `Sql-Scripts\Fix-Open-Total-Value-Decimal-Format-Training.sql` (`REPLACE` on the `create` blob's `editmask.mask`, scoped to all 6, safe to re-run).
5. **Header alignment — attempted, DID NOT WORK, dropped from deployment.** Tried matching Carrier/Class 1's header-centering (they have an explicit `alignment=2` override row layered on their base `alignment=1`/`0`; ours only had the base `alignment=1`, no override). Inserted a matching `alignment=2` override row for `_all`/158 (`Sql-Scripts\Fix-Open-Total-Value-Header-Alignment-Training.sql`) via the counter-safe path (`p21_set_counter` resync — `seq_custom_objects_detail` was drifted, 319020 vs. real max 319025) — **did not visibly fix it**, so the inserted row (uid 319041) was deleted again. **Not part of this rollout.** Headers stay as the client's own default rendering.
6. **Comments logged**: `Sql-Scripts\Update-Open-Total-Value-Version-Comments-Training.sql` appended `| 20260805 - restored open_total_value sourced from p21_view_open_rma_report (native), 2-decimal format fixed` to all 6 `custom_objects.version_desc`, matching the existing dated-history convention.

## P21Play — INTENTIONALLY LEFT MID-PROGRESS (2026-08-06 decision)
Same sequence as Training, minus the alignment attempt. SQL-level steps (remove + retarget) done for all 6 roles; Field Chooser rebuild done on only 2 of 6 (`_all`, `customer service manager`). **User's call 2026-08-06: don't finish the remaining 4** — Play gets refreshed from Prod periodically, and Prod is now done (see below), so the next refresh resolves Play automatically without manual rework. Not a gap to chase unless Play is needed for something sooner than the next refresh.
- **Side finding before starting:** Play's *current* (pre-change) state isn't uniform — 4 of the 6 roles (922, 929, 930, 2990) already carry a 2-decimal format override on the *old* `ds_view_open_rma_value`-sourced field (someone fixed this previously), but 2 (158/`_all`, 923/customer service manager) still show the raw 9-decimal mask. End state is the same either way (all 6 clean at 2 decimals, natively sourced).
1. `Sql-Scripts\Remove-ds_view_open_rma_value-Column-Play.sql` — run, confirmed.
2. `Sql-Scripts\Retarget-ds_view_open_rma_value-to-P21-Native-Play.sql` — run, confirmed.
3. Re-add via Field Chooser in the client for each of the 6 roles — **done on 2 of 6** (`_all`, `customer service manager`). 4 roles remain unfinished by design: management (922), AR manager (929), AR (930), vendor maintenance (2990).
4. Decimal-format-fix and version-comment scripts for Play — not run for the remaining 4 (moot, see above).

## Prod — DONE (2026-08-06)
Prioritized ahead of finishing the remaining 4 Play roles, per the reasoning above. Verified Prod's pre-change state matched Training/Play (all 6 roles still on the old field, `fc_dataobject_table` 80/`fc_dataobject_column` 222 still on `ds_view_open_rma_value`) before running anything.
1. `Sql-Scripts\Remove-ds_view_open_rma_value-Column-Prod.sql` — run; confirmed 0 rows remain across all 6 roles afterward.
2. `Sql-Scripts\Retarget-ds_view_open_rma_value-to-P21-Native-Prod.sql` — run; confirmed `fc_dataobject_table` 80 → `p21_view_open_rma_report`, `fc_dataobject_column` 222 → `ufc_p21_view_open_rma_report_open_total_value`.
3. Re-added via Field Chooser in the P21 client on all 6 Prod roles (158, 922, 923, 929, 930, 2990) — verified via SQL afterward that exactly these 6 (no extras, no misses) have `ufc_p21_view_open_rma_report_open_total_value` placed.
4. `Sql-Scripts\Fix-Open-Total-Value-Decimal-Format-Prod.sql` — same inherited 9-decimal mask bug confirmed present on all 6, fixed; confirmed `.00` mask on all 6 after.
5. `Sql-Scripts\Update-Open-Total-Value-Version-Comments-Prod.sql` — changelog appended to all 6 (role 158 already had a manual note from the user dated 2026-08-06 — script appended after it, nothing overwritten).
6. Header-alignment fix **not attempted** in Prod either — already proven not to work in Training.

`DROP VIEW ds_view_open_rma_value` **not yet done anywhere** — held until Play/Training are also clean (Play via its next refresh), so the view isn't dropped out from under an environment still referencing it.

## Verification
- Transaction Master Inquiry Orders (all 21 role versions, but especially the 6 above) opens without error.
- Open Total Value column still populates correctly on the 6 affected roles, formatted to 2 decimals. **Confirmed via SQL in Prod** (all 6 roles: field present, `.00` mask, changelog updated) — not yet visually confirmed in the P21 client by a user.
- Eventually (after view drop): `SELECT * FROM sys.views WHERE name = 'ds_view_open_rma_value'` returns 0 rows. Not done yet — view is still in place, just no longer referenced by any of the 6 Prod roles.

## Rollback
- Training: pre-change `custom_objects_detail` rows for the old field were captured in this session's query output before deletion (not saved to a file) — if needed, the PowerBuilder `create column(...)`/`create text(...)` blobs can be reconstructed from the conversation history, or simply re-run Field Chooser "New Field" against `ds_view_open_rma_value` again (view itself hasn't been dropped yet).
- Play: 2 of 6 roles changed (see above); 4 unchanged (never touched).
- Prod: all 6 roles changed. Same recovery path as Training — view hasn't been dropped, so `ds_view_open_rma_value` can still be rejoined manually via Field Chooser "New Field" if a rollback is ever needed. `Remove-ds_view_open_rma_value-Column-Prod.sql`'s BEFORE query output (this session) has the exact pre-change `custom_objects_detail` rows if a byte-for-byte restore is needed instead.

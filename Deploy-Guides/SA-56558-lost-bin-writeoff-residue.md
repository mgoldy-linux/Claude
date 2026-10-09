# Deployment Guide — SA 56558 LOST-bin write-offs (loc 342): lot fix + sub-penny residue cleanup

> **Status 2026-10-07: APPLIED IN PROD** (3:45 pm, by Mark). Awaiting Teresa Doerr's confirmation that her write-offs work.

## Artifact(s)
- `Sql-Scripts\Inventory\SA-56558-Zero-LOST-Residue-PROD.sql` — Prod cleanup (preview-by-default, single transaction, logged)
- `Sql-Scripts\Inventory\SA-56558-Zero-LOST-Residue-Play.sql` — same logic, Play-only (dry run + commit tested 10/7)
- `Sql-Scripts\Inventory\SA-56558-Item-Issues-Status.sql` — re-runnable status for the 30 PDF items
- `Sql-Scripts\Inventory\SA-56558-Rebuild-Check.sql` — what a rebuild touched / cleared since `@since`
- `Sql-Scripts\Inventory\SA-56558-LOST-Bin-Settings-All-Locations.sql`, `SA-56558-Lots-In-LOST-Bins-Play.sql` — investigation queries
- `Sql-Scripts\Extended-Events\Create-XE-SA56558-Lot-Qty-Error-Trace-Play.sql` — Play trace that located message #5649's validation
- **New Prod object:** `dbo.asi_sa56558_lost_cleanup_log` (122 before/after rows from the 10/7 run)
- Ticket: SA 56558 (source list: `sa-56558 -item issues.pdf`, Inventory Card Report By Bin, loc 342 / bin LOST)

## Target environments
Play (`P21Play` @ `P21Dev.allsurfaces.com`) first -> Prod (`P21` @ `P21.allsurfaces.com`). Done in that order on 2026-10-07.

## What was wrong (two independent data problems)
1. **Lot header drift (KARSCB76, lot V025G31):** `lot.qty_on_hand` 23.639999998 vs `lot_bin_xref`/`inv_bin` 23.64. Writing off 23.64 exceeded the lot by 2e-9 -> client message #5649 "There is not enough quantity available in lot ...". **Fix: extended Rebuild Inventory Quantities** (single item + location 342, BOTH boxes ticked), not SQL.
2. **Sub-penny residues (29 items):** e.g. 0.003 in the LOST bin. Show 0.00, round to a zero-quantity adjustment line (dropped by P21), and the rebuild keeps them because lot/bin/location already agree. **Fix: the cleanup script.**

## Dependencies & deploy order
1. Play: dry run (`@Commit = 0`), review, commit (`@Commit = 1`).
2. Rebuild Inventory Quantities on ONE cleaned Play item (CON72050121) — confirm the residue does not return.
3. Prod: run the Prod script as a **preview** (`@Commit = 0`, no writes), compare to the plan, then `@Commit = 1`.
- The first Prod commit creates `dbo.asi_sa56558_lost_cleanup_log`; the script grants INSERT/SELECT to `p21_application_role, PxxiUser` and **refuses to start** if the runner still cannot insert (a new table has no grants — the first attempt was denied *after* the updates ran and rolled back clean).

## What the cleanup changes (and does not)
- Residue = each LOST `lot_bin_xref` row with 0 < |qty| < 0.02 and nothing allocated. Subtracts only that residue from `lot_bin_xref` (-> 0), `lot.qty_on_hand`, the LOST `inv_bin` row, and `inv_loc.qty_on_hand`; results within 0.00001 of a 3-decimal value are snapped. Rows stamped `last_maintained_by = 'SA56558_zero_lost_residue'`.
- Skips (and lists) an item if location total vs bin total differ by >= 0.02, if LOST rows have allocations, or if the bin would go negative.
- **No `inv_tran` / GL posting** (sub-penny value). Tables have triggers (lot audit trail, bin stock status, ECC sync on `inv_loc`). Run when order entry is quiet.
- **Scope: loc 342 only.** KARSCB76 (fixed by rebuild) and JOHFM18205 (764.80 location-vs-bin gap) are excluded.

## Deploy steps
1. Play: open the Play script, run as-is (dry run, rolls back), check the 4 result sets, set `@Commit = 1`, run.
2. Prod: `SA-56558-Zero-LOST-Residue-PROD.sql` against `P21.allsurfaces.com` / `USE [P21]` — preview first (expected plan 2026-10-07: 34 / 34 / 27 / 27 rows, nothing skipped), then `@Commit = 1`.

## Verification
- `SA-56558-Item-Issues-Status.sql` (Prod) -> expect `lost_bin_qty` = 0 for the PDF items. Result 10/7: 29 of 30 at 0; JOHFM18205 (held back) still 0.00004.
- `SELECT step, tbl, COUNT(*) FROM dbo.asi_sa56558_lost_cleanup_log GROUP BY step, tbl` -> 34 / 34 / 27 / 27.
- Teresa writes off the 3 real items (CONUP160121 941.96, CONAP412121 83.34, CON88015121 1.40) and confirms in SysAid.

## Rollback
- Every change is in `dbo.asi_sa56558_lost_cleanup_log` (`before_qty` / `after_qty` per row, keyed by item + `row_key`). To revert, `UPDATE` the four tables back from `before_qty` for `inv_mast_uid` + `row_key` (steps: 1 `lot_bin_xref`, 2 `lot`, 3 `inv_bin`, 4 `inv_loc`). Sub-penny quantities, so rollback is rarely worth it.
- A later **Rebuild Inventory Quantities** (rebuilds from `inv_tran`) *could* bring a residue back — a Play test on CON72050121 showed it did not. Re-run `SA-56558-Item-Issues-Status.sql` after any rebuild on these items.
- **Do not** trust "LOST is locked so nothing can be written off": Teresa wrote off ~145 lines from LOST 9/14–10/6. Check the lot header vs bin/xref at 12 decimals first.

## Addendum 2026-10-08 - third cause: leading-space lot values (no deploy)
- CONUP160121 in the 342 LOST bin: lots 16174073 / 16176029 / 16174077 / 16174080 are stored with a **leading space** (hex `20...`), each with a 0.00 no-space twin. Typing the roll # without the space hits the empty twin -> "lot/Bin combination does not exist". Reproduced in Prod (Inventory Adjustments, Lost) 10/8.
- **Workaround (no data change):** type a leading space for those four lots; 16210009, 16210095, 13061046 (and CONAP412121 lot 15142005, CON88015121 lot 16079028) have no space.
- CON88015121 LOST qty is 1.403 - write off 1.403, not 1.40, or a 0.003 residue remains.
- Read-only query: `Sql-Scripts/Inventory/SA-56558-Leading-Space-Lots-LOST-READONLY.sql`. Data fix (merge/rename the lot values) NOT written - Play first if the workaround fails or the pattern is widespread. Prod: nothing changed.

## Addendum 2026-10-09 - round 2 residue cleanup + phantom allocation (APPLIED IN PROD)
- `Sql-Scripts/Inventory/SA-56558-Zero-LOST-Residue-PROD-Round2.sql` - same logic as the 10/7 script, scoped to CON88015121 and CONUP160121 (0.008 / 0.006 left in LOST), `@Commit` defaults to 0. Previewed, then applied 10/9: 8 rows (2/2/2/2), logged in `dbo.asi_sa56558_lost_cleanup_log`. Rollback = same log table, `before_qty` per `row_key`.
- **WARNING:** the 10/7 `-PROD.sql` has `@Commit = 1` in the file (its header says 0). Set it to 0 before any reuse.
- CONAP412121 83.34: `inv_loc.qty_allocated` = 83.34 from **Inventory Return Entry #3070** (3/20/2026, tdoerr, nothing picked). Not changed by us - Teresa cancels/updates it in P21, then writes off. Find such allocations with `p21_view_find_transaction_allocations` (inv_mast_uid + location_id).

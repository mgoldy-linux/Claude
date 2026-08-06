# Deployment Guide — SA-46321 PO Required Date (Line + Header)

> Status: **Built and fully tested in P21Play, awaiting user acceptance testing.** UAT request sent 2026-08-06 via SysAid to Mike Learned (coordinating), Chad (EDI-driven POs), Pamela (manual PO creation), plus PORG testing. Jere signs off once the team's satisfied — Prod not yet started.

## Artifact(s)
- `dbo.asi_fn_po_next_business_day` — scalar SQL function, slides a date past weekends/holidays
- `dbo.asi_table_po_header_required_date_frozen` / `dbo.asi_table_po_line_required_date_frozen` — marker tables, track "already computed" state
- `dbo.asi_proc_po_required_date` — stored procedure, all the compute/freeze logic, keyed by `@PONo`
- `asi_po_required_date` — P21 business rule (C#), thin wrapper: pulls `po_no` off the event and calls the proc
- `asi_po_required_date_diag` — throwaway diagnostic rule used to determine `pohdrpostupdate`'s field shape. Not required for production, but keeping it committed as a record of how the design was derived (repo precedent: `asi_oe_email_close_diag`). Not meant to be registered in Prod.
- Ticket: SA-46321 (Jerome Butler)

## Target environments
- ✅ **P21Play** @ `P21Dev.allsurfaces.com` — built, fully tested here (see Verification)
- ⬜ **P21 (Prod)** @ `P21.allsurfaces.com` — not yet deployed

## Dependencies & deploy order
Order matters — later objects reference earlier ones:
1. `CREATE-OR-ALTER-FUNCTION-asi_fn_po_next_business_day.sql` (no dependencies)
2. `CREATE-TABLES-asi_table_po_required_date_frozen.sql` (no dependencies — idempotent, guarded with `IF NOT EXISTS`)
3. `CREATE-OR-ALTER-PROC-asi_proc_po_required_date.sql` (depends on 1 and 2)
4. **Grant `EXECUTE` on the proc** (see below) — do this before registering the rule, not after
5. Register/compile `asi_po_required_date.cs` as a business rule on `pohdrpostupdate` (business_rule_event_uid = 9)

## Backward-compatibility notes
- New objects, nothing depends on them yet. No existing behavior changes except what the rule itself does going forward.
- **No backfill** — this only computes dates for lines/headers going forward. Existing open POs keep whatever Required Date they already have (confirmed with Jerome, no email needed — this was already the agreed scope).

## Design notes (why it's built this way)
- P21 **auto-populates both `po_hdr.date_due` and `po_line.required_date` to `order_date`** the instant a PO/line is created (confirmed empirically 2026-08-06) — neither column is ever `NULL`. This means a `WHERE ... IS NULL` guard (the original plan) **cannot** signal "not yet computed." The two marker tables exist entirely to work around this — they track "already frozen" state ourselves, independent of what's currently sitting in the native columns.
- `pohdrpostupdate` exposes only an envelope via `Data.Set` — `POHeader` table with `key_value` (= `po_no`, string), `action` (`ADD`/`UPDATE`), `context` (what triggered this particular save — not reliable as a gate). **No `order_date`/`vendor_id`/`location_id`/line data at all.** `Data.Fields` throws outright ("cannot be accessed in a multi-row rule"). This is why the rule does everything via SQL keyed by `po_no`, not by reading the event's row content.
- "Published Lead Time" = `inventory_supplier_x_loc.manual_lead_time`; falls back to `average_lead_time` if 0/NULL (confirmed with Jerome). Holiday source = `service_calendar WHERE day_type_cd = 1788` (P21 has no dedicated holiday table — this one was repurposed, see `feedback_p21_service_calendar_holidays`).

## Deploy steps
1. Run `SQL-Schema\CREATE-OR-ALTER-FUNCTION-asi_fn_po_next_business_day.sql` against target `USE [<db>]`.
2. Run `SQL-Schema\CREATE-TABLES-asi_table_po_required_date_frozen.sql`.
3. Run `SQL-Schema\CREATE-OR-ALTER-PROC-asi_proc_po_required_date.sql`.
4. **Grant execute permission** — the proc is created under an admin login, but P21's rule engine connects as `p21_application_role`/`PxxiUser`, which does **not** get execute rights automatically:
   ```sql
   GRANT EXECUTE ON dbo.asi_proc_po_required_date TO p21_application_role, PxxiUser
   ```
   ⚠️ **Skipping this step doesn't throw a visible error.** The rule's error handling swallows the failure and returns `Success` so the PO save isn't blocked — the only symptom is Required Date silently never changing. Confirmed this exact failure in Play (`EXECUTE permission was denied on the object 'asi_proc_po_required_date'`) before granting it. Check `business_rule_log WHERE rule_name = 'asi_po_required_date' AND log_action = 'Error'` if dates aren't updating after deploy.
5. Compile/register `asi_po_required_date` as a business rule:
   - Event: **Purchase Order Update** (`pohdrpostupdate`)
   - Run Type: **Synchronous**
   - Multi-Row: **Yes**
   - Apply During Save / Apply Globally / Apply To All Rows: **No**
   - Run For All: **Yes**
   - Row Status: **Active** (704) once ready to go live — deploy Inactive first if following the usual Prod caution ([[feedback_deploy_inactive_survive_refresh]])
   - Enabled For Version: **Both**
   - Field Selector: check `key_value`, `action`, `context` under `Purchase Order Update → POHeader`; leave "Pass to Rule As" blank
   - (These settings mirror the 5 existing production rules on the sibling event `onoehdrpostupdate` — no precedent existed on `pohdrpostupdate` itself before this.)

## Verification
All of the following were run live in P21Play on 2026-08-06 — not just direct SQL, but through real PO saves in the P21 client:

| Test | PO(s) | Result |
|---|---|---|
| Line + header set on first save | 4319393, 4319394, 4319396 | ✅ order_date + lead time, both levels |
| Idempotent re-fire (no-op) | 4319393 | ✅ no change on re-run |
| Header frozen against downstream edits (simulated EDI/manual date_due change) | 4319393 | ✅ header untouched by our rule after the marker exists |
| New line added to an already-frozen PO | 4319393 | ✅ new line gets its own date; header stays frozen |
| Fallback to Average Lead Time (Published = 0) | 4319397 | ✅ 8/6 + 26d avg lead time = 9/1, correct |
| Weekend slide | 4319398 | ✅ 8/6 + 10d = Sun 8/16 → slid to Mon 8/17 |
| Holiday slide (incl. a double-holiday edge case) | function-level, Thanksgiving 11/26–11/27/2026 | ✅ slid to Mon 11/30, proves the loop (not single-step) was necessary |
| Multiple lines, different lead times, on one PO | 4319399 (3 lines: 6d/9d/49d) | ✅ each line got its own distinct date (8/12, 8/17-slid, 9/24); header froze to MAX = 9/24, not first/last line |
| Live edit-and-resave (Expected Date change) | 4319397 | ✅ required_date/date_due unchanged after re-save |
| Permission fire | 4319396 | Found & fixed missing EXECUTE grant (see step 4) — confirmed clean firing after grant |

To spot-check any of the above yourself:
```sql
SELECT po_no, order_date, date_due FROM po_hdr WHERE po_no = <PONo>
SELECT po_line_uid, required_date FROM po_line WHERE po_no = <PONo>
SELECT * FROM asi_table_po_header_required_date_frozen WHERE po_no = <PONo>
SELECT * FROM business_rule_log WHERE rule_name = 'asi_po_required_date' ORDER BY date_created DESC
```

## Rollback
- Set the rule's Row Status to **Inactive** (705) in the Business Rule Organizer — stops new computation immediately, no data cleanup needed.
- To fully remove: `DROP PROCEDURE dbo.asi_proc_po_required_date`, `DROP FUNCTION dbo.asi_fn_po_next_business_day`, `DROP TABLE` the two marker tables. Dates already written to `po_hdr.date_due`/`po_line.required_date` are **not** reverted automatically — they'd need a manual SQL fix if a rollback must also undo already-computed dates.

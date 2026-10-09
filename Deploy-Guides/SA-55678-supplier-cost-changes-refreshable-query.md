# Deployment Guide — SA 55678 Supplier Cost Changes in Last 7 Days (refreshable Excel)

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `Supplier Cost Changes in Last 7 Days - Refreshable.xlsx` (copy of Jere's workbook, in `Documents\Excel`; attached to the SysAid ticket) — two Power Query tables: `HeaderChanges` (sheet Header, A–F) and `LocationChanges` (sheet Location, A–H incl. `Concat`). Direct SQL to the **data warehouse** `asdwdb01.ahi.local` / db `P21` (switched from Prod 10/9), rolling 7 days.
- `Sql-Scripts\Supplier\SA-55678-Supplier-Cost-Changes-Discovery.sql` — audit_trail discovery (3 steps).
- `Sql-Scripts\Supplier\SA-55678-Supplier-Cost-Changes-Last-7-Days.sql` — the two queries (same SQL as the workbook).
- `SQL-Schema\CREATE-OR-ALTER-VIEWS-asi_view_supplier_cost_changes.sql` — **optional** views, NOT deployed.
- Ticket: SA-55678

## Target environments
- Reads the reporting data warehouse (`asdwdb01.ahi.local`, db `P21`) - a copy of Prod restored nightly ~2:05 AM, so the 7-day window ends at the last restore (data through yesterday). Nothing is deployed to any database; the workbook is the deliverable.

## Dependencies & deploy order
1. Nothing in SQL to deploy. (If the optional views are ever wanted: Play first, then Prod, with `GRANT SELECT ... TO p21_application_role`; then repoint the two queries at the views.)
- Notes: user needs read access to `audit_trail`, `inv_mast`, `supplier` (Windows auth). First refresh may prompt to confirm the data source.

## Backward-compatibility notes
- Header columns stay A–F in the original order, so the `Cost File Data` tabs' `XLOOKUP(...Header!B:B...)` formulas keep working.
- Hand-typed `Comments` column was dropped (belonged to 2024 rows). The three `Cost File Data` tabs are still the old pasted data, not refreshed.

## Deploy steps
1. Attach the workbook to the ticket; user opens it and uses Data > Refresh All.

## Verification
- Refresh → on 10/1 against Prod: 118 header / 7 location rows (matched SSMS). On 10/9 against the DW: 73 header / 1 location row, newest 10/8 9:19 AM. Counts differ from Prod because of the nightly-restore lag and a different window. Compare to the SQL file run in SSMS.

## Rollback
- Original workbook was left untouched (`Supplier Cost Changes in Last 7 Days .xlsx`). Nothing else to revert.

## Open
- Include/exclude `AHI\sqlsvc` nightly rows (add `AND a.created_by <> 'AHI\sqlsvc'`); rolling vs calendar week; logical reads on `audit_trail` not yet measured.

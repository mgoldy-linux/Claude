# SA 57028 - Lost and Quarantine Bin report (all locations)

**Ticket:** SA 57028 (Jerome Butler) | **Status:** 🟡 delivered 10/13, awaiting Jere/Jami confirmation | **Env:** none - Excel workbook only, reads DW (`asdwdb01.ahi.local` / `P21`), nothing created in any P21 DB

## Artifacts
- `Documents\Excel\Lost and Quarantine Bin - SA 57028.xlsx` (new copy; original `Lost and Quarantine Bin.xlsx` unchanged)
- `Sql-Scripts/Inventory/SA-57028-Quarantine-Flag-Bins-All-Locations.sql` (the query inside the workbook, named `Lost_Quarantine_Bin_Stock`)
- `Sql-Scripts/Inventory/SA-57028-Quarantined-Qty-By-Item-Location-Bin.sql` (diagnostic: `qty_quarantined > 0` -> bins)

## Deploy
Attach the workbook to the ticket (done). Refreshes on open; data current through last night's ~2:05 AM DW restore.

## Verify
Loc 100: EDS-LOST 157, QUARANTINE 102, LOST ~1,598 match the old report. Total 1,971 rows; locations 100/142/342/380.

## Rollback
Nothing to roll back; original workbook untouched.

## Notes
Rule = `bin_type.quarantine_flag='Y'` OR bin in (LOST, EDS-LOST, QUARANTINED, QUARANTINE). EDS-LOST is a pickable WOOD DALE-type bin. If renaming the query again via COM, also update the connection `Location=` and `CommandText`.

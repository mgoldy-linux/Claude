# Deployment Guide — SA 57068 Purchasing Open BO Age portal performance

> Produced during development. NOT deployed as of 2026-10-14.

## Artifact(s)
- `Sql-Scripts/Portals Queries/SA-57068-BO-Age-REWRITTEN.sql` — replacement `retrieve=` SQL for DataWindow `purchasing_open_BO_age` (`\\asp21fs1.ahi.local\Prod\Portals\purchasing_open_BO_age.srd`; portals PURCH OPEN BO AGE / PURCH_OPEN_BO_AGE)
- Ticket: SA-57068 (Cindy Polak, ~4 min P21 open). Same output columns and order; `<user_id>` token unchanged.

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com) first, then Prod (P21 @ P21.allsurfaces.com). No DB objects created; the change is the .srd retrieve text.

## Dependencies & deploy order
1. Play test: confirm the portal builder accepts multi-statement SQL with `SELECT ... INTO #bo_audit` and `DROP TABLE` in `retrieve=` (existing portals use DECLARE/WITH; temp tables are UNPROVEN). If rejected, move the logic to an `asi_` view/TVF and keep the .srd trivial.
2. Then edit the .srd in Prod (backup first).
- Needs index `KBJS_audit_trail_Cover01` for the speed-up (hint). If it is ever dropped, remove the `INDEX(...)` hint; results stay correct, just slower.

## Backward-compatibility notes
- DataWindow column list/order unchanged (buyer, order_no, line_no, loc_id, item_id, order_qty_bo, total_bo, bo_date, on_hand, po, xfer, net_avail, uom). Portal PURCH OPEN BO AGE (30-60) uses a separate `_old` DataWindow, not touched.

## Deploy steps
1. Copy `purchasing_open_BO_age.srd` to a dated backup in the Portals folder.
2. Replace the `retrieve=` string (escape double quotes as `~"`) with the file contents.
3. Reopen the portal as a buyer user and compare with the old output.

## Verification
- `EXCEPT` both ways old vs new for CPOLAK = 0 rows, 46 = 46 (done 10/14, Prod, read-only). Repeat for 1-2 other buyers and an admin (the `'%'` buyer path).
- Reads: before 2,665,000, after 213,284 (IO stats). Re-measure from the plan-cache DMV after deploy.

## Rollback
- Restore the backed-up `.srd`.

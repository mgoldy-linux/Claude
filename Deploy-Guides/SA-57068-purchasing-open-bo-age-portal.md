# Deployment Guide — SA 57068 Purchasing Open BO Age portal performance

> LIVE in Prod + Play since 2026-10-15 (function v2 + new elements V1/V4). Old elements/files retired 2026-10-18. See "Status 10/18" at the bottom.

## Artifact(s)
- `Sql-Scripts/Portals Queries/SA-57068-asi_fn_purchasing_open_bo_age.sql` — multi-statement TVF `dbo.asi_fn_purchasing_open_bo_age(@user_id)`. Holds all the logic.
- `Sql-Scripts/Portals Queries/SA-57068-BO-Age-REWRITTEN.sql` — same logic as a standalone script (temp table); reference/diagnostic only.
- DataWindow `purchasing_open_BO_age` (`\\asp21fs1.ahi.local\<Env>\Portals\purchasing_open_BO_age.srd`; portals PURCH OPEN BO AGE / PURCH_OPEN_BO_AGE) — `retrieve=` becomes one line (below).
- Ticket: SA-57068 (Cindy Polak, ~4 min P21 open).

## Why a function and not SQL in the .srd
SA-55014 lesson: multi-statement SQL pasted into a `.srd` can crash the DataWindow painter with no SQL error. The function must be multi-statement (not inline) so the 30-day audit_trail rows are materialized once in `@a`; inline, the optimizer probed audit_trail once per backorder line (1.6M reads). `#temp` and `OPTION (RECOMPILE)` are not allowed in functions (RECOMPILE also gave no gain).

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com): function created 10/15. Then Prod (P21 @ P21.allsurfaces.com).

## Dependencies & deploy order
1. Create the function in the target env (the script is `CREATE OR ALTER`).
2. Grants are at the end of the same script (`SELECT` to `p21_application_role` and `PxxiUser`, matching the other Prod `asi_fn_` table functions); new objects do not inherit P21 grants. Re-running is harmless.
3. THEN update the `.srd` (InfoMaker) — never the other way round.
- **KBJS dependency (being retired):** v1 of the function forced index `KBJS_audit_trail_Cover01` with `INDEX(...)`; a hint on a missing index makes the query FAIL, so v1 blocks dropping that index. **v2 (script in repo, 10/15) has no hint**: a ~28-step binary search on the clustered key (source_area_cd, audit_trail_uid) finds the start of the 30-day window (starting 1 day early because uid is only approximately monotonic with date_created). Tested on Prod ad hoc 10/15: v2 body = live v1 function for CPOLAK 46, RBONATO 72, ZMORIN 36, ADIERKS 1, JTIEHEN 0, ADMIN 0 (EXCEPT both ways empty each); audit_trail ~99K reads, ~0.9-1.0 s. **v2 deployed to Prod and Play 10/15 (Mark): same row counts before/after, no errors.** After v2 is in every env that has the function: check nothing else uses KBJS_ (sys.dm_db_index_usage_stats + plan cache), then retire the index. Do NOT build a replacement index on this 171M-row table (Standard edition: no online build).

## Backward-compatibility notes
- Output columns/order unchanged: buyer, order_no, line_no, loc_id, item_id, order_qty_bo, total_bo, bo_date, on_hand, po, xfer, net_avail, uom. The old query sorted by bo_date; keep that in the DataWindow. PURCH OPEN BO AGE (30-60) uses a separate `_old` DataWindow, not touched.

## Deploy steps
1. Back up `purchasing_open_BO_age.srd` to a dated copy in the Portals folder.
2. In InfoMaker open the `.srd`, change the SQL to: `SELECT * FROM dbo.asi_fn_purchasing_open_bo_age('<user_id>') ORDER BY bo_date`. Check the column list/order matches the 13 columns above; fix any column datatype prompts. Save to the env's portal share.
3. Reopen the portal as Cindy (CPOLAK) and compare with the old output.

## Verification (Prod, read-only, 10/15, user CPOLAK)
- Function body run as an ad hoc batch: 45 rows = 45 rows vs the original portal query; `EXCEPT` both ways = 0 rows.
- Logical reads: original ~2,665,000 -> function body ~268,700 (IO stats). The standalone temp-table script was ~213,000. Re-measure from the plan-cache DMV after deploy.
- Play: function compiles and runs; Play returns 0 rows for ADMIN and CPOLAK (no qualifying backorder data), so Play proves syntax only.
- Not yet tested: other buyers / the `'%'` buyer path in Prod; the .srd opening in the P21 client.

## Rollback
- Restore the backed-up `.srd`. The function can stay (harmless) or be dropped: `DROP FUNCTION dbo.asi_fn_purchasing_open_bo_age`.

## KBJS_audit_trail_Cover01 retirement review (Prod, 10/15)
- Last index seek 9:59:58 AM, 7 s before v2 was created (10:00:05); no reads since. 359 seeks since the 9/20 SQL restart (cannot attribute; includes this session's testing). 35 cached plans list the index but all are P21 audit write procs/triggers (maintenance); 0 plans read it. 282M updates since 9/20; index is 12.33 GB.
- No SQL module, SQL Agent step or SSRS .rdl names it. Daily 281 item-change job plan uses other indexes; the archive job filters date_created only so cannot use it.
- Caveat: ad hoc readers (Excel, Workbench, ad hoc SSMS) would just fall back to another index, not break. Script with DROP + rollback CREATE: `Sql-Scripts/Portals Queries/SA-57068-KBJS_audit_trail_Cover01-retire-and-rollback.sql` (NOT run). Rollback rebuild is slow and blocks audit_trail writes (Standard edition) - maintenance window.

## Status 10/18 (what is actually live)
- **Functions:** `dbo.asi_fn_purchasing_open_bo_age` v2 + grants in Prod, Play, Dev, BusinessRules, Training. Deploy order unchanged: function first, element/.srd second.
- **New elements (Prod + Play; Dev/BRR/Training also added by Mark):** `PURCHASING OPEN BO AGE V1` (`purchasing_open_bo_age_v1`, portal PURCH OPEN BO AGE, "PURCH Open BO Age (4-30)") and `PURCHASING OPEN BACKORDERS NONSAMPLES MINE V4` (`purchasing_open_backorders_nonsamples_mine_v4`, portal PURCH OPEN BACKORDERS MINE NONSAMPLES). V4 script: `Sql-Scripts/Portals Queries/SA-57068-NonSamples-no-kb-retrieve.sql` (replaces `kb_view_oe_line_po` and `kb_view_carrier`; EXCEPT-proven for 5 buyers; ~same CPU).
- **Retired in Prod 10/18:** elements `PURCH OPEN BACKORDERS`, `PURCHASING BOP SUPPLIER MANAGER V2`, `PURCHASING BOP SUPPLIER SUMMARY V2`, `PURCHASING OPEN BACKORDERS MINE NONSAMPLES`, `..._V2`, `PURCHASING OPEN BO AGE` deleted by Mark in Portal Maintenance; five .srd moved to `\asp21fs1.ahi.local\Prod\Portals\Previous-Portals`. Order followed: elements first (verified in DB), files after. Inactive portals `PURCH_OPEN_BO_AGE` and `PURCH OPEN BO MINE NONSAMPLES` still exist (0 assignments, 0 elements).
- **Keep:** `..._MINE NONSAMPLES V3` (PURCH OPEN LOT BACKORDERS), `PURCHASING OPEN BO AGE OLD` (PURCH OPEN BO AGE (30-60), `purchasing_open_BO_age_old`), BOP Order Detail V2, BOP Manager V3, BOP Summary V3.
- **User impact:** a dashboard widget on a deleted element shows an empty box with no error. Daniel McVeigh, Jenny Tiehen, Rob Bonato (and departed Graham Adkins) still hold the old NonSamples widget; remove and re-add via V4. Cindy has V4, no BO Age widget yet.
- **Rollback of the cleanup:** move the five .srd back from `Previous-Portals` and re-add the elements in Portal Maintenance (library `\asp21fs1\Prod\Portals`).
- **Still pending:** rename `Previous-Portals` to `Prod Portal Cleanup`; drop `KBJS_audit_trail_Cover01` after the 10/22 recheck (script not run).

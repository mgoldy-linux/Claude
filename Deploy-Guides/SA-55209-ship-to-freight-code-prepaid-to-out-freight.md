# Deployment Guide — SA 55209 Ship-To Freight Code: Prepaid → Out Freight

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `Sql-Scripts\Customers\SA-55209-Backup-ShipTo-FreightCode.sql` — script, run FIRST. Copies the rows the UPDATE will touch into `dbo.asi_bak_SA55209_ship_to_freight`
- `Sql-Scripts\Customers\SA-55209-Update-FreightCode-To-OutFreight.sql` — script, the change itself (`ship_to.freight_code_uid` 6 → 2). Refuses to run if the backup table is missing or out of sync
- `Sql-Scripts\Customers\SA-55209-Restore-ShipTo-FreightCode.sql` — script, backout only
- Ticket: SA 55209 (SysAid Change request submitted 9/30, status **In Approval**)

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com): **done 9/30** — tested end to end, left UPDATED
- Prod (P21 @ P21.allsurfaces.com): **pending change approval.** Planned 7:00 PM EDT
- Scope is `ship_to` rows only. Existing open orders/quotes are NOT touched (decision 9/30) — they keep Prepaid; new orders pick up the new default

## Dependencies & deploy order
1. Backup script → 2. UPDATE script → 3. (only if backing out) Restore script
- Each script's first line is a hardcoded `use [P21]` (Prod). Swap to `P21Play` for Play. Confirm with `SELECT DB_NAME(), @@SERVERNAME;` before running
- Backup script's `@ExpectedRows` must equal the step 1 verify SELECT count. Prod was 173 on 9/28 but **172 on 9/30** (Crew2 Inc. already fixed by tthousand) — set it to the live count
- The earlier 9/29 session's untracked `SA-55209-Batch-UPDATE-FreightCode.sql` (hardcoded ID list) and `SA-55209-Play-*.sql` are NOT part of this flow — don't run both

## Backward-compatibility notes
- Only changes `ship_to.freight_code_uid`. Nothing else is written. `oe_hdr.freight_code_uid` is a per-order snapshot and is independently set at entry, so existing orders are unaffected

## Deploy steps
1. SSMS, `USE [P21]`: run the step 1 verify SELECT (first query in the UPDATE script). Expect the count agreed above (172 on 9/30), all Prepaid. If it differs, stop and re-diff against `Reports\SA-55209-ShipTo-Terms-vs-FreightCode-2026-09-23.xlsx`
2. Set `@ExpectedRows` in the Backup script, run the WHOLE script (F5). Expect backup_rows = that count, min/max old uid 6
3. Export the backup grid to `Prod-before-Freight-Update.xlsx`; attach to the ticket
4. Run the UPDATE script in full. Expect (N rows affected) in Messages and an empty final re-verify grid
5. Email Michelle DeBartolo + Lynette Glenn; update ticket

## Verification
- `SELECT s.freight_code_uid, COUNT(*) FROM ship_to s JOIN dbo.asi_bak_SA55209_ship_to_freight b ON b.ship_to_id=s.ship_to_id AND b.customer_id=s.customer_id GROUP BY s.freight_code_uid;` → expect one row, uid 2, N
- Spot-check 3–5 accounts in the Prod client (Eckard, a Sherwin Williams account, 3000889, 3023115): Ship To tab shows Out Freight, edit/save clean, new order defaults to Out Freight
- Play result 9/30: backup 179 → UPDATE 179 → restore 179 → re-UPDATE 179; UI checks clean, no errors

## Rollback
- Run the Restore script (BEGIN TRAN; review preview + step 3 grid; then COMMIT or ROLLBACK by hand — an uncommitted restore blocks other sessions). Only restores rows still on Out Freight; rows changed since are skipped and listed
- Keep the backup table and Excel until the ticket closes
- Traps: two flagged accounts (3023115 "Transfer To Blakely", 3000889 NE Dept of Correctional Services) are in scope under "all confirmed"; Crew2 Inc. (1126566) is already Out Freight and drops out of the filter automatically

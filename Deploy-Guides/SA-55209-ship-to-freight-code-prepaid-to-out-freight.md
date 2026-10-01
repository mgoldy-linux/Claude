# Deployment Guide — SA 55209 Ship-To Freight Code: Prepaid → Out Freight

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `Sql-Scripts\Customers\SA-55209-Backup-ShipTo-FreightCode.sql` — script, run FIRST. Copies the rows the UPDATE will touch into `dbo.asi_bak_SA55209_ship_to_freight`
- `Sql-Scripts\Customers\SA-55209-Update-FreightCode-To-OutFreight.sql` — script, the change itself (`ship_to.freight_code_uid` 6 → 2). Refuses to run if the backup table is missing or out of sync
- `Sql-Scripts\Customers\SA-55209-Restore-ShipTo-FreightCode.sql` — script, backout only
- Ticket: SA 55209 (SysAid Change request submitted 9/30; executed 10/1)

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com): **done 9/30** — tested end to end, left UPDATED
- Prod (P21 @ P21.allsurfaces.com): **DONE 10/1.** Backup 172 rows (min/max old uid = 6) → UPDATE, no errors, re-verify empty → spot-checked in the Prod client (both flagged accounts, Eckard, Sherwin Williams, confirmed Crew2 Inc. untouched) — all correct
- Scope is `ship_to` rows only. Existing open orders/quotes are NOT touched (decision 9/30) — they keep Prepaid; new orders pick up the new default

## Dependencies & deploy order
1. Backup script → 2. UPDATE script → 3. (only if backing out) Restore script
- Each script's first line is a hardcoded `use [P21]` (Prod). Swap to `P21Play` for Play. Confirm with `SELECT DB_NAME(), @@SERVERNAME;` before running
- Backup script's `@ExpectedRows` must equal the step 1 verify SELECT count. Prod was 173 on 9/28 but **172 on 9/30** (Crew2 Inc. already fixed by tthousand) — set it to the live count
- The earlier 9/29 session's untracked `SA-55209-Batch-UPDATE-FreightCode.sql` (hardcoded ID list) and `SA-55209-Play-*.sql` are NOT part of this flow — don't run both

## Backward-compatibility notes
- Only changes `ship_to.freight_code_uid`. Nothing else is written. `oe_hdr.freight_code_uid` is a per-order snapshot and is independently set at entry, so existing orders are unaffected

## Deploy steps — executed 10/1
1. SSMS, `USE [P21]`: ran the step 1 verify SELECT. **172 rows**, all Prepaid — matched the 9/30 drift note exactly
2. `@ExpectedRows = 172` in the Backup script (already set), ran in full. `backup_rows = 172, min_old_uid = 6, max_old_uid = 6`
3. Backup grid exported for the ticket (per plan — not independently verified by me that the file landed in `Reports\`)
4. Ran the UPDATE script in full. No errors; final re-verify grid came back empty (header only)
5. Spot-checked in the Prod client: both flagged accounts, an Eckard Distributors location, a Sherwin Williams account, and confirmed Crew2 Inc. (1126566) wasn't re-touched — all correct
6. SysAid ticket updated (clipboard). Reply-All drafted to Michelle DeBartolo + Lynette Glenn on the original SysAid notification thread — **sitting in Drafts, not yet sent** as of this guide's last update

## Verification
- `SELECT s.freight_code_uid, COUNT(*) FROM ship_to s JOIN dbo.asi_bak_SA55209_ship_to_freight b ON b.ship_to_id=s.ship_to_id AND b.customer_id=s.customer_id GROUP BY s.freight_code_uid;` → expect one row, uid 2, 172 — not independently re-run after the UPDATE; the re-verify empty-grid result is the confirmation on hand
- Play result 9/30: backup 179 → UPDATE 179 → restore 179 → re-UPDATE 179; UI checks clean, no errors
- Prod result 10/1: backup 172 → UPDATE clean, empty re-verify → client spot-check clean

## Rollback
- Run the Restore script (BEGIN TRAN; review preview + step 3 grid; then COMMIT or ROLLBACK by hand — an uncommitted restore blocks other sessions). Only restores rows still on Out Freight; rows changed since are skipped and listed
- **Backup table and Excel being held a few hours (10/1) as a rollback window before cleanup** — not yet dropped. Keep until the ticket fully closes (Michelle/Lynette confirmation still pending)
- Traps: two flagged accounts (3023115 "Transfer To Blakely", 3000889 NE Dept of Correctional Services) are in scope under "all confirmed," now live; Crew2 Inc. (1126566) is already Out Freight and drops out of the filter automatically

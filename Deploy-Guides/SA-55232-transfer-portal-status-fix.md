# Deployment Guide — SA 55232 Transfer Portal "Shipped Partial" Stuck Status Fix

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `v_transfer_portal_status` — view, backs the "Open Transfers" portal's Ship side (`br_shp_open_xfer_ship_retrieval_v10a.srd`)
- `ds_view_transfers` — view, legacy near-duplicate, backs the "Open Transfers" portal's Rec side (`br_shp_open_xfer_rec_retrieval_v7.srd`) plus 8 more confirmed-live portals (see `project_ds_view_transfers_retirement.md`)
- Ticket: SA-55232

## Target environments
- Play (P21Play) → Prod (P21) — built/tested Play first, per usual
- Also deployed to Training, Dev, BusinessRules (full environment parity, same day)

## Dependencies & deploy order
1. No ordering dependency between the two views — they're independent objects, deploy either first.
2. Both are pure `CREATE OR ALTER VIEW` — no downstream `.srd`/report changes needed. The portals that consume them (`br_shp_open_xfer_ship_retrieval_v10a.srd`, `br_shp_open_xfer_rec_retrieval_v7.srd`, plus `my_open_xfers.srd`, `open_xfer_search.srd`, etc. for `ds_view_transfers`) reference the views by name and pick up the fix automatically on next query — no portal re-registration required.

## Backward-compatibility notes
- The new CASE branch is additive and tolerance-gated (`ABS(diff) < 0.0001`) — only fires for the specific rounding-residue pattern (UOM-conversion transfers where shipped/received are numerically ~equal to the target qty but not exactly, due to a P21-native floating-point artifact). Genuine partial shipments (real shortages, `qty_not_shipped >= ~0.01`) fall through untouched to the original branches — verified via regression test (transfer 8365784, short 1 of 4 units, unchanged).
- Reused existing `status_no 9` ("Shipped Complete / Received Partial") rather than adding a new lookup row — no `transfer_status_lookup` changes needed.

## Deploy steps
1. Run `CREATE-OR-ALTER-VIEW -dbo.v_transfer_portal_status-v2.sql` against target `USE [<db>]` (toggle the `USE` line at top of the script)
2. Run `CREATE-OR-ALTER-VIEW -dbo.ds_view_transfers.sql` against the same target
3. Both scripts live in the user's own SSMS `Views\` folder: `C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents\SQL Server Management Studio\Views\`

## Verification
Run against each target after deploy:
```sql
SELECT transfer_no, item_id, qty_to_transfer, qty_shipped, qty_recvd, status_no, status
FROM v_transfer_portal_status   -- and again against ds_view_transfers
WHERE transfer_no IN (8358948, 8359328, 8363346, 8363347, 8365520, 8369253, 8371670, 8389996)
ORDER BY transfer_no;
```
Expected: all rows show `status_no = 9` / "Shipped Complete / Received Partial" (previously stuck at `status_no = 5` / "Shipped Partial / Received").

Regression check (must stay unchanged):
```sql
SELECT transfer_no, item_id, qty_to_transfer, qty_shipped, qty_not_shipped, status_no, status
FROM v_transfer_portal_status WHERE transfer_no = 8365784;
```
Expected: `status_no = 5` (genuine partial, 1 of 4 units short) — unaffected by the fix.

**Confirmed 2026-09-22:** Play (both views), Prod (both views), Training, Dev, BusinessRules (view files run, not independently re-verified with the query above in each of the last three — user confirmed "ran both, confirmed").

## Rollback
- Prior definitions are the same script minus the new CASE branch (4 lines) — remove the branch block marked `-- SA 55232 2026-09-22` in each view (two locations per view: the main CASE and its duplicate in the lookup join) and re-run `CREATE OR ALTER VIEW`.
- No data was modified — both views are read-only reporting objects, so rollback is purely a view-definition revert, no data cleanup needed.

## Follow-on (separate, not part of this guide)
`ds_view_transfers` is slated for full retirement in favor of `v_transfer_portal_status` — see `project_ds_view_transfers_retirement.md`. Not started; today's fix on `ds_view_transfers` is a stopgap for the active bug, not the retirement itself.

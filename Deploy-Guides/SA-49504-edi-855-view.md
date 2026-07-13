# Deployment Guide — SA-49504 asi_view_edi_855_po_ack (EDI PO-Ack Exceptions portal)

> Status: DEPLOYED to Prod 2026-07-13 (view + v4 .srd). Awaiting user feedback.

## Artifact(s)
- `SQL-Schema/CREATE-OR-ALTER-VIEW-asi_view_edi_855_po_ack.sql` — view (source of truth also in OneDrive SSMS Views folder)
- `purch_open_po_edi_ack_exceptions_v4.srd` — portal datawindow (v4)
- Tickets: SA-49504 (this fix), 47715 (original buyer_id → requested_by change)

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com) → Prod (P21 @ P21.allsurfaces.com)

## Dependencies & deploy order
1. Deploy the **view** to the target env FIRST (the .srd selects `requested_by`, which the old view lacked → 207).
2. Then deploy the **v4 .srd**.
- Views are per-environment: updating Play does NOT update Prod. Deploy to each env separately.

## Backward-compatibility notes
- The view exposes **BOTH** `supplier.buyer_id` (used by V3 .srd) **and** `po_hdr.requested_by` (used by V4 .srd) so both portal versions resolve. Do not drop `buyer_id`.
- `buyer` contact_name joins on `po_hdr.requested_by` (per ticket 47715 intent).

## Deploy steps
1. Run `CREATE-OR-ALTER-VIEW-asi_view_edi_855_po_ack.sql` — **change `USE [P21Play]` to `USE [P21]`** — against **P21.allsurfaces.com** (Prod).
2. Re-run same script with `USE [P21Play]` against **P21Dev.allsurfaces.com** so Play also has both columns.
3. Deploy `purch_open_po_edi_ack_exceptions_v4.srd` to the target env's Portals share.

## Verification
- Open the `purch_open_po_edi_ack_exceptions` portal in the target env → loads without the `207 / 42S22 Invalid column name 'requested_by'` error.
- Confirm view columns: `SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.asi_view_edi_855_po_ack'))` contains both `requested_by` and `buyer_id`. (Prod verified 2026-07-13: both present.)

## Rollback
- Prior Prod view definition (old version used `supplier.buyer_id` only, no `requested_by`). Re-apply that CREATE OR ALTER to revert — but note this re-breaks V4.

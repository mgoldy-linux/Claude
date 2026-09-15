# Deployment Guide — SA 52078 Vendor Invoice Receiving Report Redesign

> Produced retroactively at deploy time (2026-09-15) — UAT/dev work happened in Play across 8/12–9/14, deploy guide was deliberately deferred until Chad's sign-off per project convention (no guide for pre-approval work).

## Artifact(s)
- `P21VendorInvoiceReport.rpt` — main Crystal report, redesigned to show 810 EDI data instead of PO-comparison data
- `sub_AdditionalCharges` — subreport (from SA-48124), consolidated to also carry Freight as one of its charge rows
- `asi_view_vendor_invoice_edi_charges` — SQL view (SA-48124's, shared), modified to UNION in a synthetic Freight row
- Ticket: SA-52078

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com) → Training (P21Training @ P21Dev.allsurfaces.com) → Prod (P21 @ P21.allsurfaces.com)
- All three confirmed live as of 2026-09-15 (verified directly via `sys.sql_modules`, not just user-reported — see Verification)

## Dependencies & deploy order
1. **View first** — `asi_view_vendor_invoice_edi_charges` must carry the Freight UNION before the report/subreport are pointed at it, or the subreport's Freight row will silently come up empty.
2. Then the report + subreport files themselves, copied to each environment's live report path.
- Notes: this view is **shared with SA-48124** (EDI vendor invoice charges), already live in Play/Prod independently of this ticket. Changing it needed sign-off beyond just this report's own UAT — flagged explicitly before deploying; confirm that sign-off happened if this guide is ever revisited for a rollback decision, since reverting the view affects SA-48124 too, not just this report.

## Backward-compatibility notes
- The view's original shape (no Freight row, `WHERE e.amt <> 0` only) is what SA-48124 was built against. The UNION is additive — existing SAC-charge rows are untouched, only a new synthetic `charge_description = 'Freight'` row was added per invoice. SA-48124 consumers that don't expect a "Freight" `charge_description` value should be checked if anything downstream filters/groups on that column by value.
- The Freight UNION branch is **unconditional** (no `WHERE freight_amount <> 0`) — every invoice now returns at least one row from this view, including `Freight: 0.00` on plain invoices. This was a deliberate fix for a Crystal "zero rows = static content won't print" quirk (see memory), not an oversight — don't "clean it up" by re-adding a non-zero filter without re-testing the zero-row Crystal behavior it was working around.

## Deploy steps
1. Run against each environment (`USE [<db>]` + `GO` batch separator required before `CREATE OR ALTER VIEW` — it must be the only statement in its batch):
   ```sql
   USE [<P21Play|P21Training|P21>]
   GO

   CREATE OR ALTER VIEW [dbo].[asi_view_vendor_invoice_edi_charges]
   AS
   SELECT
       e.vendor_invoice_hdr_uid, e.sac_id,
       charge_description = ISNULL(NULLIF(LTRIM(RTRIM(c.sac_desc)), ''), 'Other Charge'),
       charge_amount      = e.amt,
       invoice_amount     = h.invoice_amount
   FROM dbo.vendor_invoice_edi e
   JOIN dbo.vendor_invoice_hdr h ON h.vendor_invoice_hdr_uid = e.vendor_invoice_hdr_uid
   LEFT JOIN dbo.chart_of_accts_edi c ON c.sac_id = e.sac_id
   WHERE e.amt <> 0

   UNION ALL

   SELECT
       h.vendor_invoice_hdr_uid, sac_id = NULL,
       charge_description = 'Freight',
       charge_amount      = h.freight_amount,
       invoice_amount     = h.invoice_amount
   FROM dbo.vendor_invoice_hdr h;
   GO
   ```
2. Copy `P21VendorInvoiceReport.rpt` and the `sub_AdditionalCharges` subreport to the target environment's live report path (manual, done directly by the user — not a SQL step, not independently verified by Claude for any environment).
3. In each copy, confirm **Set Datasource Location** points at that environment's own connection (matching Prod's OLE DB/ADO provider type — not the legacy ODBC/RDO type that caused the live-print crash in Play; see [[feedback_crystal_rdo_vs_oledb_connection]]).

## Verification
- SQL: `sys.sql_modules.definition LIKE '%UNION ALL%' AND LIKE '%''Freight''%'` for `asi_view_vendor_invoice_edi_charges` → confirmed **present** on P21 (Prod), P21Training, and P21Play, all modified 2026-09-15 ~07:00–07:10 AM (checked directly this session, not just taken on report).
- Report-side verification (freight-only, freight+SAC, plain, multi-page invoices; header/grouping across a 26-page multi-vendor run; Subtotal-truncation fix through the desktop client's own Print Preview) was done in **Play only**, prior to this Prod push — not independently re-verified against Prod's live report path in this session. Recommend a quick spot-check against a real Prod invoice once convenient.

## Rollback
- View: re-run `CREATE OR ALTER VIEW` with the original pre-9/9 definition (drop the `UNION ALL` branch entirely, keep just the `SELECT ... WHERE e.amt <> 0` half) — this returns the view to exactly what SA-48124 was originally built against.
- Report: restore the prior `.rpt`/subreport files from whatever backup/version-control copy exists in each environment's report path (Crystal files aren't tracked in this git repo — restoring depends on whatever manual backup convention is in use for that path).

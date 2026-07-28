# Deployment Guide — SA-48124 Vendor Invoice Report: Additional EDI Charges

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `SQL-Schema/CREATE-OR-ALTER-VIEW-asi_view_vendor_invoice_edi_charges.sql` — custom view: itemized EDI 810 SAC charges per invoice header.
- `P21VendorInvoiceReport.rpt` — Crystal report; gets a **new subreport** ("Additional Charges") in the invoice footer. Baseline P21 objects untouched.
- Ticket: SA-48124

## Current status (2026-07-28)
- **View `asi_view_vendor_invoice_edi_charges`: deployed to BOTH Play and Prod** (with grants). Includes `invoice_amount`.
- **Subreport in `P21VendorInvoiceReport.rpt`: built and working in Play ONLY.** Not yet in Prod.
- 🟡 Awaiting A/P validation in Play. Then: deploy the `.rpt` to Prod (the view is already there).

## Target environments
- Build/test: **Play** (P21Play @ P21Dev.allsurfaces.com) → then **Prod** (P21 @ P21.allsurfaces.com)

## Dependencies & deploy order
1. Deploy the **VIEW** (`asi_view_vendor_invoice_edi_charges`) to the target DB **FIRST** — the subreport selects from it. *(Done in Play + Prod.)*
2. Then deploy the updated **`.rpt`** to the Crystal report folder for that env. *(Done in Play; Prod pending.)*
- The view reads baseline `vendor_invoice_edi` + `chart_of_accts_edi` + `vendor_invoice_hdr` (for the total). No baseline object is modified. No `kb_`/`js_` dependencies.

## The custom view (deployed Play + Prod)
Grain: **one row per SAC charge per `vendor_invoice_hdr_uid`**. Columns:
| column | meaning |
|---|---|
| `vendor_invoice_hdr_uid` | link key to the main report (invoice header) |
| `sac_id` | raw SAC code (e.g. H400184) — for reference/diagnostics |
| `charge_description` | human label from `chart_of_accts_edi.sac_desc`; `'Other Charge'` if blank/unmapped |
| `charge_amount` | the charge `amt` |
| `invoice_amount` | **authoritative payable total** (lines+freight+charges) from `vendor_invoice_hdr`. The baseline report view `p21_view_vendor_invoice_report` does NOT expose it, so we carry it here for the corrected-total line. Repeats identically per charge row. |

Filter is `amt <> 0` (not on `sac_id`), so a real charge is never hidden even if a future one arrives with a blank/unmapped SAC. `sac_id` is unique in `chart_of_accts_edi` (0 dupes, Play + Prod) so the label join can't fan out.

## ⚠️ Server-side gotchas (both solved — critical for the Prod `.rpt` deploy)
1. **A brand-new view has NO grants.** The report service (AHI-API1, connects as SQL login `crystal`) 500'd with `Failed to open the connection` (from `rptcontrollers.dll`) — **not** "permission denied", because ODBC (RDO) reports a SELECT gap on *open* as a generic connection failure. Fix = grant SELECT to `p21_application_role` + `PxxiUser` (crystal ∈ PxxiUser). Already in the `.sql`.
2. **The subreport must use the SAME connection as the main report.** Main report is on connection **`P21.Allsurfaces.com`**, which **P21 redirects to the running environment at runtime and injects the `crystal` credentials into**. A separate `P21Play` connection on the subreport is never credentialed → same "Failed to open the connection." In Designer: Set Datasource Location → point the subreport's view at the main report's `P21.Allsurfaces.com` connection. (This is why the view had to be in Prod — so that connection resolves it at design time.)
3. The `UserId:"ahi\MGOLDYN"` in the P21 error JSON is the **requester**, not the DB connection user — ignore it; the connection is `crystal`.

## Crystal subreport build steps (do in Play copy of the .rpt)
1. Open `P21VendorInvoiceReport.rpt` in Crystal Reports Designer.
2. **Insert → Subreport.** Name it `sub_AdditionalCharges`. Choose "Create a subreport with the Report Wizard" (or blank, then add the command/table).
3. Point the subreport at the same P21 datasource; add the table/view **`asi_view_vendor_invoice_edi_charges`** (or a Command: `SELECT charge_description, charge_amount, sac_id FROM dbo.asi_view_vendor_invoice_edi_charges WHERE vendor_invoice_hdr_uid = {?hdr_uid}`).
4. **Link** the subreport: on the "Subreport Links" tab, link the main report's invoice-header UID field to the subreport's `vendor_invoice_hdr_uid` (this both passes the parameter and applies the record filter). Confirm the main report actually carries `vendor_invoice_hdr_uid`; if it exposes only `invoice_no`, add the UID to the main query or link on `invoice_no` instead (the header UID is preferred — unique and indexed via PK on the header).
5. In the subreport Details section, place `charge_description` (left) and `charge_amount` (right, 2-decimal format to match the report's totals). Add a bold "Additional Charges" header.
6. **Corrected total:** in the subreport's Report Footer, add a label **"Invoice Total (incl. charges):"** and the **`invoice_amount`** field (2 decimals). Because every charge row carries the same `invoice_amount`, placing the field in the footer shows the one correct value — no summing. This drives the payable total off `vendor_invoice_hdr.invoice_amount` (avoids double-counting the ~0.1% legacy "freight in both" invoices). Only shows on charge invoices — correct, since no-charge invoices already total right.
7. **Suppress when empty:** subreport → Format Subreport → **Suppress Blank Subreport**. To also remove the empty *gap*, put the subreport **alone in its own section** (e.g. Group Footer #2b) and check **Suppress Blank Section** on that section — Suppress Blank Subreport hides content but the section keeps its height otherwise.
8. Place the subreport in the **invoice group footer** — Group #2 (`vendor_invoice_hdr_uid`), NOT Group #1 (`vendor_id` = supplier) and NOT Details.

### Crystal gotchas hit during the build
- **Link field must be placed on the main report to appear in Subreport Links.** `vendor_invoice_hdr_uid` is only a *group* field on the main report, so it wasn't in the subreport-links "Available Fields" list. Fix: drag `vendor_invoice_hdr_uid` from Field Explorer onto the main report (any invoice-group band), **Format Field → Suppress** so it doesn't print, then it appears for linking.
- **New view column needs Database → Verify Database** in the subreport before `invoice_amount` shows in Field Explorer.
- Main report exposes `vendor_invoice_hdr_uid` (confirmed) — link on it, not `invoice_no` (which can repeat across suppliers).

## Verification (Play)
Run the report for these known Play invoices (deployed view already returns them):
| invoice_no | hdr_uid | expected charge line | amount |
|---|---|---|---|
| 26170770 | 109507 | Drop Charge | 7.88 |
| 26170887 | 109511 | Drop Charge | 250.44 |
| 26172056 | 109543 | Drop Charge | 41.56 |

- Each invoice's footer shows the "Additional Charges" line with the right label + amount, then "Invoice Total (incl. charges)".
- **26172056** verified: Drop Charge **41.56**, corrected total **597.16** (was 555.60). Reconciles: lines 415.60 + freight 140.00 + charge 41.56 = 597.16 = `invoice_amount`.
- **Freight-only 26171989** verified: **no** charges section (suppressed), no gap, total unchanged.
- (Original ticket sample **26190433** is Prod-only — not in Play's 05/28/26 refresh — verify it after Prod deploy: expect Drop Charge 1.05, total 76.53.)

## Optional performance improvement (recommend to user)
The subreport filters `vendor_invoice_edi` on `vendor_invoice_hdr_uid`, but that table's only index is the PK on `vendor_invoice_edi_uid` — so each subreport call scans all ~24k rows. **Honest read:** at 24k rows a scan is only a few dozen logical reads, so today the win is small; but a covering index makes the per-invoice lookup a seek and keeps it cheap as the table grows. Optional, and it's on a baseline table (name it `asi_` so it's clearly a custom index; custom indexes normally survive P21 upgrades):
```sql
CREATE NONCLUSTERED INDEX asi_ix_vendor_invoice_edi_hdr_uid
    ON dbo.vendor_invoice_edi (vendor_invoice_hdr_uid)
    INCLUDE (sac_id, amt);
```

## Deploy to Prod (after Play sign-off)
1. ~~Deploy the view~~ — **already done** (view + grants live in Prod as of 2026-07-28, `invoice_amount` included).
2. Copy the updated `.rpt` to the Prod Crystal report folder. In Designer, confirm the subreport resolves via the `P21.Allsurfaces.com` connection (it does at runtime — P21 injects `crystal`).
3. Re-run verification, including sample invoice **26190433** → Drop Charge 1.05, total 76.53.
- **Note:** `P21VendorInvoiceReport.rpt` is a **standard P21 report** — a P21 upgrade can overwrite it. Keep the customized `.rpt` backed up / in source control so it can be re-applied.

## Rollback
- View: harmless standalone object — `DROP VIEW dbo.asi_view_vendor_invoice_edi_charges;` (nothing baseline references it).
- Report: restore the previous `.rpt` from the report folder backup / prior committed version. The subreport is additive; removing it returns the original behavior.

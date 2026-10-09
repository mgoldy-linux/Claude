# Deployment Guide — SA-56113 Invoice Detail: multi-select Manufacturer

> **DEPLOYED to Prod SSRS 2026-10-09 (Mark).** Tested in `/Test-Mark` first (all 5 test cases passed). Old report archived at `/Company Reports/Sales/Archive Sales/Invoice Detail - Cannot select MFG`; new one is `/Company Reports/Sales/Invoice Detail` (new item ID `90359525-2bb4-4196-8cfb-b949d0daa204`). **Ticket closed 2026-10-09 (Jere confirmed).**

## Artifact(s)
- **Upload this file:** `C:\SSRS-Local\Invoice Detail - SA56113 multi-mfg only.rdl` (multi-select only; existing queries/`kb_` views unchanged). SSRS report `/Company Reports/Sales/Invoice Detail` (Id 07e52b1f-6ecb-4bef-af83-05894ea98973)
- Ticket: SA-56113 (requested by Jere, Purchasing)

## What changed
- `mfg` parameter: Allow multiple values, default = all manufacturers, no "(Null)" entry (SSRS multi-value params can't be null).
- Dropdown now uses existing shared dataset `/Datasets/Manufacturers` (no null row) instead of `ManufacturersNULL`. Report dataset renamed `Manufacturers`. Shared datasets are NOT changed.
- Filter: `@mfg IS NULL OR item_class1 IN (@mfg)` -> `@mfg_cnt >= (count of active class-1 manufacturers) OR item_class1 IN (@mfg)`. New query parameter `@mfg_cnt = Parameters!mfg.Count`. "All selected" = no filter, so invoice lines with a retired/blank class still appear (old "(Null)" behavior). Last-year check on the DW: 0 null, 7 of 1.38M lines have a class not in the active list.
- Header text: lists the chosen manufacturers, and is omitted when all are selected.
- **Deferred to the kb_ cleanup project (NOT in the SA 56113 upload):** three `kb_` swaps built and proven, saved as `C:\SSRS-Local\Invoice Detail - multi-mfg + 3 kb swaps (for kb cleanup project).rdl`. Decision 2026-10-06 (Mark): keep the existing queries for this ticket.
  - `kb_view_users` -> `users` (only `name` is used). DW check: 905 vs 905 rows, 0 differences either way, 0 duplicate ids.
  - `kb_view_carrier` -> `p21_view_address` with `carrier_flag = 'Y'` in the join. 127 vs 127, 0 differences, 0 duplicate ids.
  - `kb_view_customer_x_dealer_type` (also hid `kb_view_customer`) -> `customer_x_dealer_type` + `dealer_type` (`row_status_flag = 704`) + `customer` (`delete_flag = 'N'`). All dealer types: 11,353 vs 11,353 id/customer pairs, 0 differences either way.
  - **Still open:** `kb_sales_history_report_view_roii_costs` (pulls in `kb_view_invoice_line_rewards`, `js_view_open_invoice_costs`, `kb_fn_get_*`, `kb_view_direct_invoices_incl_rebills`). Separate session/ticket. Also used by 7 `kb_` commission report objects and 8 SSRS reports that ran in the last 90 days; no `.srd` or Crystal files reference it (437 `.srd` + 3 `.rpt` on `\\AHI-FILESRVR.AHI.LOCAL\Shared\Portals`).

## Dependencies & deploy order
1. Nothing else to deploy; `/Datasets/Manufacturers` already exists on the server.
- **Live drift:** on 2026-09-30 `AHI\jvadakkel` modified the live report (filter changed `= @mfg` to `IN (@mfg)`). The edited RDL is built on that live version. Re-fetch and diff again before uploading if the live report changes.

## Backward-compatibility notes
- No subscriptions on this report (checked 2026-09-29). Saved links with `mfg` set to one value still work.
- Query still reads `kb_sales_history_report_view_roii_costs`, `kb_view_carrier`, `kb_view_customer_x_dealer_type`, `kb_view_users` (flagged, not in scope).

## Deploy steps
1. Test locally in Report Builder / Visual Studio: pick one, several, and all manufacturers; confirm row counts and the header text.
2. Upload `Invoice Detail - SA56113 multi-mfg only.rdl` over `/Company Reports/Sales/Invoice Detail` (portal Upload, or REST `PUT Reports(<id>)/Content`).
3. Open the report in the portal and confirm the Manufacturer box shows checkboxes with Select All.

## Verification
- All selected row count = pre-change "(Null)" row count for the same dates.
- One manufacturer = old single-select result.

## Rollback
- Re-upload `C:\SSRS-Local\Invoice Detail - PRE-SA56113 (live 2026-10-02, modified 9-30 by jvadakkel).rdl`.

## Open items before upload
- **Order vs. `asi_fnt_invoice_detail`:** a separate drafted TVF would replace `kb_sales_history_report_view_roii_costs` with a one-line `FROM` change in this RDL. Decide whether SA 56113 uploads first with the kb_ view still in place (the other session's plan) or waits.
- **Product Manager dropdown:** still the shared dataset `/Datasets/ProductManagersNULL`, which calls `kb_fn_get_product_manager` and `kb_view_item_classifications_loc100` (the latter has 46 dependent DB objects and ~20 reports - separate retirement). Drafted replacement over `inv_mast` + `product_group` returns the same 9 managers (0 diffs). Not applied: embed in this report or edit the shared dataset (1,028 report runs in 90 days)? Embedding leaves other reports untouched.
- **Stale manager list:** 4 of 9 dropdown managers are marked LEFT (TBASIC, GTHOMAS, KBENISH, BSPARKS); SUPPLIESMGR/PADMGR are delete-flagged accounts. Business decision for Purchasing, not part of this change. See `Reports\Departed-User-References-2026-10-02.xlsx`.

## Test settings (DW, 9/21/2026 - 9/25/2026 11:59:59 PM, other parameters default)
- Toli = 33 lines; Toli + Taylor Tools = 71; Toli + Taylor Tools + Lotte = 104; all manufacturers = 25,554; dealer type `MFT-CONDUALDAR` = 9,460 (query-level checks; the report may differ slightly through its own joins).

## Deployed 2026-10-09
- Order used: upload to `/Test-Mark` -> test -> move old report to `Archive Sales` (renamed "Invoice Detail - Cannot select MFG") -> place tested report as `/Company Reports/Sales/Invoice Detail`. The new item has a new ID, so ID-based bookmarks/favorites break; folder/name links work. No subscriptions.
- Live file is identical to `Invoice Detail - SA56113 multi-mfg only.rdl`. Rollback: upload the PRE-SA56113 backup over the live report (or move the archived one back).
- The `kb_` swaps and the Product Manager dropdown were NOT part of this deploy (kb cleanup project / separate issue).
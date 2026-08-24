# Deployment Guide — SA-53334 Order Ack ASAP Banner (Last-Page Footer Image)

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `ACKNOWLEDGEMENTS_user.rpt` — Crystal Reports Order Acknowledgement form
- Ticket: SA-53334

## Target environments
- **Play** (`\\asp21fs1.ahi.local\Play\CrystalReports\ACKNOWLEDGEMENTS_user.rpt`) — built and tested here, ready for Matt's review
- Not yet touched: BusinessRules, Prod (both also carry their own copy at `\\asp21fs1.ahi.local\{BusinessRules,Prod}\CrystalReports\`)

## Dependencies & deploy order
1. Copy `ASAP_InvoiceAd_2.png` into the target env's own `Logos` folder first (`\\asp21fs1.ahi.local\<env>\Logos\`) — Prod's copy already exists there; Play's copy was added 2026-08-24. **BusinessRules has no separate `Logos` folder today** — confirm/create it before deploying there.
2. Deploy the updated `.rpt` to the target env's `CrystalReports` folder.
- Note: the image is embedded into the `.rpt` at design time in Crystal Reports Designer (Insert → Picture), not read live at runtime — the Logos-folder copy is only a design-time source for whoever opens the report next, not a runtime dependency of the deployed file.

## Backward-compatibility notes
- Additive only — no existing fields/formulas changed, no new section added. The image lives inside the existing `Group Footer #1i` band (the customer-notice-text section), so no other section heights or suppress logic were touched.

## Deploy steps
1. Back up the target env's current `ACKNOWLEDGEMENTS_user.rpt` first (naming convention used here: `PlayCrystalBackup\ACKNOWLEDGEMENTS_user - YYYYMMDD.rpt`)
2. Copy the built `.rpt` (or redo the same edit in Designer) into the target env's `CrystalReports` folder
3. Confirm `ASAP_InvoiceAd_2.png` is present in that env's `Logos` folder

## Verification
- Print/export a 1-line, 1-page order → banner renders once, directly below the customer notice text, above the barcode/Document ID footer row, correctly sized/centered
- Print/export a multi-page order (tested with order 6062152, 9 lines / 2 pages) → banner renders **only** on the true last page, not repeated on earlier pages, and no extra blank page
- Trigger (or wait for) a scheduled `GenerateAndSendFormJob` email send → confirm no `Page Header plus Page Footer is too large for the page` error

## Rollback
- Restore from the pre-edit backup: `\\asp21fs1.ahi.local\Play\CrystalReports\PlayCrystalBackup\ACKNOWLEDGEMENTS_user - 20260824.rpt` (Play). Take an equivalent backup before ever editing the BusinessRules/Prod copies.

## Traps hit during build (Crystal Reports) — see [[feedback_crystal_page_footer_suppress_no_reclaim]]
- **Page Footer + Suppress formula does NOT reclaim space.** Crystal reserves the FULL height of every Page Header/Footer section on every page regardless of any Suppress formula on an object or the section itself (unlike Group/Detail sections, which do collapse when suppressed). Adding the banner to Page Footer with a `PageNumber <> TotalPageCount` suppress formula grew the reserved footer height past the page's available space and broke the live `GenerateAndSendFormJob` scheduled email (`Page Header plus Page Footer is too large for the page`, 40 retries then abort).
- **Report Footer avoids that budget but can orphan onto its own page.** Report Footer prints once at the true end of the report and isn't part of the fixed per-page Header+Footer reservation — but a leftover oversized band (from earlier edits) still forces the whole section onto a fresh page (repeating Page Header + Group Header, no Detail rows, banner floating alone) even with visible white space left on the true last page.
- **Fix that worked:** place the image directly inside the last Group Footer subsection (`Group Footer #1i`, which already holds the customer notice text) instead of Page Footer or Report Footer. Renders exactly once, on the true last page, right after the existing content — no reserved-space or orphan-page issues.

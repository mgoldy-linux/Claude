# SA-48124 — Vendor Invoice Report: Add Additional Charges — Research Complete / Implementation Plan

## Summary of findings
The "EDI Vendor Invoice Receiving Report" currently shows only **freight**. Other charges that come in on an EDI invoice — drop charge, pallet, restocking, broken-package, etc. — are received and stored by P21 but are **not displayed on the report**, so the printed total comes up short (our sample invoice showed 75.48 instead of the true 76.53, missing a 1.05 drop charge).

**Root cause:** The report's data view (`p21_view_vendor_invoice_report`) only reads freight. The other charges are stored separately in a P21 table called **`vendor_invoice_edi`** that the report never looks at. The plain-English name of each charge (e.g., "Drop Charge") lives in a companion lookup table, **`chart_of_accts_edi`**. The report just needs to be taught to read these two tables.

**Important freight note:** We confirmed that for the large majority of invoices where freight arrives as one of these charge entries, the report currently shows **no freight at all**. So this change doesn't only add the extras — it also fixes missing freight on those invoices. The fix should therefore display **all** charge entries (freight included), not a filtered subset.

## How the fix will be built (no impact to standard P21)
1. **Leave the standard P21 view and report logic untouched.** P21 baseline objects get overwritten on upgrades, so we will not modify them. Instead we add a small, self-contained custom piece.
2. **Add a small "charges" lookup** (a custom view) that lists, for each invoice, every additional charge with its description and amount — by joining `vendor_invoice_edi` to `chart_of_accts_edi`.
3. **Add a sub-section to the Crystal report** (a subreport) in the invoice footer that prints those charges itemized — one line each, e.g. "Drop Charge … 1.05", "Pallet Charge … X.XX".
4. **Show the correct combined total.** The report footer will display the invoice's authoritative total (P21's stored `invoice_amount`), so the previously-missing charges are now accounted for and the grand total matches the supplier's invoice.
5. Deploy the updated `.rpt` to the Crystal Reports folder and the custom view to the database.

**Estimated effort: ~4 hours** to build, deploy to Play, and complete the retest below.

## How to retest and verify
Do the testing in the test/play environment first (P21Play), then confirm in Production.

1. **Run the report for the known sample first:** Supplier **3012610**, Invoice **26190433**, Location **162**.
   - **Expected:** The report now shows the line item (10.48) **and** a "Drop Charge" of **1.05**, with a combined invoice total of **76.53** (previously it showed 75.48 and no drop charge).
2. **Pick 3–4 additional recent EDI invoices** that have extra charges (drop, pallet, restocking, freight-as-charge) and run the report for each.
   - **Expected:** Each extra charge appears with the right description and amount, and the report's grand total matches P21's stored invoice amount for that invoice.
3. **Check an invoice with no extra charges** (freight only / none).
   - **Expected:** Report looks the same as before — no blank/empty charge section, totals unchanged. (Confirms we didn't break the normal case.)
4. **Spot-check against the supplier's actual invoice** for one or two cases to confirm the printed total now equals what the supplier billed — which is the whole point: A/P can approve payment from the report without emailing the supplier for a copy.
5. **Known edge case to note, not a defect:** A very small number of older invoices (~0.1%) may list freight twice in the itemization. The grand total stays correct because it's taken from P21's stored invoice amount, not by re-adding the printed lines.

## Status
Research complete; data source confirmed and validated against a live sample. Ready to build the custom view + Crystal subreport. Estimated ~4 hours of work. **Out of office until 07/13/26** — next step on return is to draft the custom view and the subreport spec, then deploy to Play for the retest above.

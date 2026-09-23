# Accomplishments — Running List

*(Manual running log of completed work, kept because `New-WeeklyStatusReport.ps1`'s
auto-seed from `Work-Log.md` isn't working yet — see `Todo-Private.md` #2. Add to
this as work closes out; clear/archive a week's entries once they've been pulled
into the actual status report.)*

## Week of 2026-09-16 – 2026-09-22

- **SA 55014** — Sales Invoiced Yesterday portal: retired `kb_sales_history_report_view` and 3 related `kb_` objects, replaced with a native TVF. Deployed to Prod, confirmed live by John (9/17).
- **SA 54321** — Order Ack subject line: quantified the case against using Job Name (216K-order data pull) ahead of the Tina meeting; talking-points doc delivered.
- **SA 55277** — Crystal Reports out-of-memory error; root-caused to the WWMS document-generation path, transferred to Technical Services (9/18).
- **Low Margin Alert** — Play parity restored, found and fixed a durable alert-grid sync trap; added contract/job pricing fallback to the Price Page Description (Play); Prod deployment documented; three real-alert follow-ons closed out (9/18, 9/21).
- **SA 55248** — Teresa Doerr's PO line permissions: confirmed no native fix exists (audit trail shows 7 changes/yr); findings sent to Pamela, BR request submitted via SysAid (9/21).
- **SR 55318** — KMOORE user deletion: cash-drawer block cleared (9/21).
- **Order Deletion Criteria test cases** — full 10-case matrix run against P21Dev; two real traps found (NULL-expiration quotes not protected from deletion; Complete State has no reject-with-reason path); summary sent to Matt, his follow-up question answered (9/22).
- **SA 55232** — Transfer Portal stuck on "Shipped Partial" forever on decimal-qty transfers: root-caused to a UOM rounding residue in `v_transfer_portal_status` (and the same bug in `ds_view_transfers`), fixed and confirmed in Prod across 5 environments (9/22).

---

## Archive

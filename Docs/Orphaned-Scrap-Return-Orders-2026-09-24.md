# Orphaned Scrap/Return Orders — Found via Open-Order Age Audit

**Found:** 2026-09-24, while building an open-order aging query (`Sql-Scripts/Orders/Open-Order-Age*.sql`)
as a follow-up to the `customer_tab_open_order_lines.srd` portal review. The "5+ years" age bucket
(query in `Open-Order-Age-Summary.sql`) returned exactly 6 orders — these.

## The 6 orders

All negative-quantity scrap/return/stock-adjustment lines, `approved = 'Y'`, `validation_status = 'OK'`,
`complete = 'N'`, and **never invoiced**. Pattern: cleared validation/approval, then the
credit/return was never run through to invoice or closed out.

| Order # | Order Date | Age (days, as of 2026-09-24) | Customer | Taker | PO # / Job | Line Item(s) |
|---|---|---|---|---|---|---|
| 2203320 | 2020-07-10 | 2267 | Kerman Rug & Carpet Co / Scrap (1110308) | KSHORES | scrap | SCRAPPAD ×1 (qty -340) |
| 2470883 | 2021-01-14 | 2079 | Stugotz Flooring (1220263) | NBARBEE | Scrap Total | SCRAPPAD ×5 lines (qty -153, -79, -200, -134, -172) |
| 2798212 | 2021-08-11 | 1870 | Kinseys Floor Covering Inc Whse (1201966) | ABLANKENSHIP | stock | CCSMILLENIA28OZ-6FT (qty -40) |
| 2811804 | 2021-08-20 | 1861 | Best Buy Carpet (1153069) | RTROST | Never Given | TRASMT-8693BT60 (qty -10) |
| 2827389 | 2021-08-31 | 1850 | Richmond Carpet Outlet Inc. (1102667) | CCARTER | return | MAP4JA500533 (qty -1), PSN610217 (qty -10) |
| 2839073 | 2021-09-09 | 1841 | TSI Commercial (1045910) | KHYATT | 023658 / orizon Health Jaspet st | ROP40C71P100 (qty -480) |

11 lines total across 6 orders. Different takers, so this isn't one person's habit — it's a workflow
step (finishing/invoicing a scrap or return order) that routinely gets dropped for this order type.

## Assessment

Genuine orphaned data, not real backlog — these aren't orders waiting on product, they're
credit/scrap write-offs someone started and never finished. They inflate the open-order count for
no operational reason and are strong candidates for cleanup.

## Not actioned

No cancel/complete/invoice action taken on these — they're negative-qty credit-type transactions
on live Prod data. Per [[project-2026-09-09-cancel-order-procs]], the cancel-order SPs for this kind
of cleanup are deployed to Play only and **never run**, pending Matt. Whoever owns the scrap/return
process (or Matt, per that thread) needs to confirm per-order whether each should be invoiced-out
or cancelled before anything touches them.

**Next step:** fold this list into the cancel-order procs thread when that work resumes.

# Invoice Tab Price Cost Detail (`invoice_tab_price_cost_detail.srd`) - kb_ retirement

Status 2026-10-19: **built and verified in P21Play only. NOT in Prod/other envs. No .srd written yet (Mark builds it in InfoMaker).**

Tab: INVOICE TAB PRICE COST DETAIL (element 120 in Prod), 576 opens / 57 users (XE 2026-06-22..10-16). Live file: `\\ASP21FS1\Prod\Portals\invoice_tab_price_cost_detail.srd` (2024-10-24), 15 columns, one argument `invoice_number` (string).

## kb_ objects replaced
| Object | Replacement |
|---|---|
| `kb_sales_history_report_view` (2 uses) | `dbo.asi_fnt_invoice_price_cost(:invoice_number)` - only the ~19 columns the tab reads, copied logic, 17 joins instead of 43 |
| `kb_view_invoice_line_rewards` | `dbo.asi_fnt_invoice_line_rewards(:invoice_number)` - same logic, `inv_counter` scoped to this invoice's order |

Objects: `..\..\SQL-Schema\CREATE-OR-ALTER-FUNCTION-asi_fnt_invoice_price_cost.sql` (both functions, grants to p21_application_role + PxxiUser). Not in the new objects: no kb_ view, no kb_ UDF, no kb_ data table.
Hidden dependency gone too: the giant view's `kb_view_direct_invoices_incl_rebills` and `kb_fn_get_sales_manager`.

## Files
- `original.retrieve.sql` live retrieve | `v2.retrieve.sql` candidate | `v2.retrieve.paste.sql` clipboard version (header comment, CRLF)

## Verification (P21Play)
- Old vs v2 retrieve, EXCEPT both ways + row counts: 40 random invoices since 2026-07-01 = 0 bad; edge sets (8 invoices each): assembly/parent lines (506 rows), manual price override, order lines billed on several invoices, OE-line rewards, automatic rewards, rebates, returns = 0 bad.
- NOT covered (no rows found in Play): order_type 1706 service orders, advance-bill orders. Re-check in Prod before deploy.
- Dropped from the view without effect on this tab (still to prove on Prod): joins that could multiply rows (progress billing, prod order link, dealer commission, lot billing).

## Performance (plan cache, logical reads / CPU ms)
Old query is already cheap: Play 12.6K-17.4K reads / 46-56 ms; new 12.6K-17.9K / 46-56 ms (flat). Prod old: 13.2K-13.9K reads / 34-81 ms. **No performance win** - the optimizer already pushed invoice_no into the view. Value is retiring two kb_ objects and the 58K-char dependency, not speed.

## Open items
1. Mark: rebuild in InfoMaker as `asi_invoice_tab_price_cost_detail` (paste `v2.retrieve.paste.sql`). Close the preview without saving rows - saved retrieved data in the .srd breaks P21 ("Error serializing DW definition").
2. Prod: create both functions + grants, rerun EXCEPT on Prod invoices (incl. 1706/advance bill), deploy .srd, point element 120.
3. PowerBuilder must accept a function in FROM with :invoice_number - verify when pasting in InfoMaker.

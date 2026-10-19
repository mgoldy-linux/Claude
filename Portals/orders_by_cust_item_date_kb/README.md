# Order Search tab (`orders_by_cust_item_date_kb.srd`) - kb_ retirement

Status 2026-10-19: **LIVE IN PROD** (Play, Dev, BRR, Training too). View created in Prod 4:20 PM 10/19; Prod EXCEPT check 8 searches 0/0 (cust 1036638, item ROP154VXP675, order date, taker MBLONIGAN, PO SF0826, mgr 1008, rep 1077, mgr+rep); asi_orders_by_cust_item_date.srd (135,262 bytes, no embedded data) on Prod Portals; element 329 ORDERS SEARCH on ORDER SEARCH portal, old element 25 renamed ORDER SEARCH KB and off portal (rollback = swap back). Mark tested OK. Lesson: InfoMaker saves preview rows into the .srd and P21 then throws "Error serializing DW definition" - strip the data( line.

Tab: ORDER SEARCH (portal ORDER SEARCH). 808 opens / 45 users from 2026-06-22 to 2026-10-16 (XE capture), the most-used tab that touches kb_ objects. It does NOT use `kb_sales_history_report_view` (only an old copy in `SRD Backup 181015\` does).

## kb_ objects in the live .srd
| Object | Use | Replacement |
|---|---|---|
| `kb_view_salesrep` | `salesrep_name` only | `asi_view_salesrep_division_manager.salesrep_name` (nickname rule from `kb_fn_get_contact_name`) |
| `kb_fn_get_sales_manager` | `:sales_manager_id` filter | same view, join on rep + division (`COALESCE(item_commission_class_ud.division,'')`) |

Still inside the new view as DATA only: `kb_table_sales_manager_values_all` (no logic).

## Files
- `original.retrieve.sql` - live retrieve SQL (2024-10-24 file)
- `v2.retrieve.sql` - **the candidate**: kb_view_salesrep join and the UDF replaced by joins to `item_commission_class_ud` and the new view (aliases `rep`, `sm`)
- `v3.retrieve.sql` - v2 plus a customer/date-scoped invoice aggregate. **Dropped: no benefit** (more reads on item search).
- `..\..\SQL-Schema\CREATE-OR-ALTER-VIEW-asi_view_salesrep_division_manager.sql` - the view (create first, grants to p21_application_role and PxxiUser)

## Verification (Play)
- View vs `kb_fn_get_sales_manager`: 2,068 rep x commission-class combinations, EXCEPT 0/0. Names vs `kb_view_salesrep`: 188 reps, 0 mismatches.
- Old vs v2 retrieve, EXCEPT 0/0 on 8 searches: customer (761 rows), item+90d (55), order date (5), taker+7d (12), PO like (10), sales manager 1047 (18,926), sales rep 7913 (11,161), manager+rep (24,363). Play's `oe_line_ud.updated_salesrep_id` is only populated to 2026-08-02, so manager/rep cases used a July window. Prod is populated through today.

## Performance (plan cache, logical reads / CPU ms / elapsed ms)
| Search | Old | v2 |
|---|---|---|
| customer | 396,065 / 638 / 641 | 402,934 / 720 / 293 |
| item + 90d | 1,664,886 / 1,697 / 1,705 | 1,672,420 / 1,917 / 777 |
| PO like | 374,754 / 684 / 686 | 375,237 / 720 / 205 |
| taker + 7d | 374,859 / 694 / 696 | 375,288 / 723 / 332 |
Reads are flat (+1-2%), CPU 5-13% higher, elapsed 2-3x lower (the scalar UDF forced a serial plan; v2 can go parallel). Not a read/CPU win. The ~375K read floor is the unfiltered invoice-line aggregate (`invo_line`), not yet fixed.
First attempt of the view cost 589K reads per evaluation (CASE inside the predicate = scan); rewritten to compute the value first and seek (2,948 reads).

## Open items
1. v2 .srd WRITTEN 2026-10-16: `orders_by_cust_item_date_kb_v2.srd` (same UTF-16 encoding; bytes outside `retrieve=` identical to the live file). Still needs the PB painter/portal to open it (cannot be tested from here).
2. Reduce the `invo_line` floor (needs another approach than v3).
3. Latent bug: `:salesrep_id` filters `updated_salesrep_id` only, not the `COALESCE` with `oe_salesrep_id` the grid displays. Kept identical.
4. Prod: create the view, rerun the EXCEPT checks against Prod, then deploy.

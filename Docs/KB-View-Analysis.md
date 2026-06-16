# kb_ View Usage Analysis
**Date:** 2026-06-03  
**Server:** P21.allsurfaces.com / P21  
**Data window:** 2026-05-17 (last restart) → 2026-06-03 — 17 days  
**Source:** sys.objects modify_date only — no DMV tracking for views

---

## Why There Are No Execution Stats for Views

SQL Server does not track view reads in any DMV. When a query hits a view, SQL Server expands it into the underlying table access — stats land on the tables, not the view. The only data available without Query Store is `modify_date` (when the view was last altered).

---

## Query Store — The Right Solution for View Usage

Query Store captures every query plan that runs, including the query text. Querying it for a view name will show whether any query referencing that view has run, when, and how often. **Query Store data survives restarts**, unlike the DMVs used for tables, procs, and functions.

### How to check a specific view

```sql
SELECT
    qt.query_sql_text,
    rs.last_execution_time,
    rs.count_executions,
    CAST(rs.avg_duration / 1000.0 AS decimal(10,2)) AS avg_ms
FROM sys.query_store_query_text  qt
JOIN sys.query_store_query        q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan         qp ON qp.query_id     = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id     = qp.plan_id
WHERE qt.query_sql_text LIKE '%kb_view_your_view_name%'
ORDER BY rs.last_execution_time DESC;
```

### How to scan all kb_ views at once

```sql
SELECT
    v.name                                      AS view_name,
    MAX(rs.last_execution_time)                 AS last_seen,
    SUM(rs.count_executions)                    AS total_executions
FROM sys.views v
CROSS JOIN sys.query_store_query_text qt
JOIN sys.query_store_query        q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan         qp ON qp.query_id     = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id     = qp.plan_id
WHERE v.name LIKE 'kb_%'
  AND qt.query_sql_text LIKE '%' + v.name + '%'
GROUP BY v.name
ORDER BY last_seen DESC;
```

**Caveat:** Query Store has a retention window (default 30 days) and a size cap. Views queried infrequently may have fallen out of the store. Check retention settings with:
```sql
SELECT actual_state_desc, query_capture_mode_desc,
       size_based_cleanup_mode_desc, max_storage_size_mb,
       stale_query_threshold_days
FROM sys.database_query_store_options;
```

---

## Summary
| Category | Count |
|---|---|
| Likely active — modified recently (2024–2026) | 27 |
| Possibly active — modified 2020–2023 | 47 |
| Retire candidates — old + clearly obsolete | 7 |
| **Total** | **81** |

---

## LIKELY ACTIVE — Modified 2024 or Later

| View | Last Modified |
|---|---|
| kb_view_item_classifications_loc100 | 2025-06-10 |
| kb_view_sale_day_monitor | 2025-05-02 |
| kb_view_salesrep_territory_exceptions_summary | 2024-12-03 |
| kb_view_edi_832_dates | 2024-11-07 |
| kb_view_ship_to_shipping_defaults | 2024-08-29 |
| kb_view_customer | 2024-08-12 |
| kb_view_salesrep | 2024-06-12 |
| kb_view_salesrep_territory_exceptions | 2024-06-12 |
| kb_view_customer_contract_pricing_active | 2024-06-20 |
| kb_view_valid_carrier_location_combinations | 2024-07-17 |
| kb_view_user_log_in_history | 2023-12-21 |
| kb_view_buying_group_summary | 2023-12-20 |
| kb_view_inventory_wayfair | 2023-12-14 |
| kb_view_customer_x_territory | 2024-05-15 |
| kb_view_p21_window_permissions | 2024-05-16 |
| kb_view_salesrep_type | 2024-01-10 |
| kb_view_customer_matches_with_cartesian | 2024-01-19 |
| kb_view_edi_855_po_ack | 2020-01-30 |
| kb_view_edi_manufacturers | 2023-06-05 |
| kb_view_website_dsr_forms_rep_customer_list | 2023-06-22 |
| kb_view_commission_report | 2024-08-05 |
| kb_view_commission_report_adds | 2020-10-30 |
| kb_view_salesrep_assignments | 2020-11-09 |
| kb_sales_history_report_view | 2023-01-01 |
| kb_sales_history_report_view_roii_costs | 2023-01-01 |
| kb_view_users | 2024-04-15 |
| kb_view_customer_pricing_bulktable | 2023-07-10 |

---

## RETIRE — Strong Candidates

| View | Last Modified | Reason |
|---|---|---|
| kb_view_2022_q4_objective_items | 2022-10-12 | Year in name — one-time project view |
| kb_view_display_update_primary_child | 2017-01-23 | 9 years old — display program likely inactive |
| kb_view_display_update_primary_components | 2017-01-23 | Same |
| kb_view_inventory_order_totals | 2016-12-21 | 10 years old |
| kb_view_item_inch_unit_size | 2016-11-10 | 10 years old |
| kb_view_item_sf_unit_size | 2016-10-21 | 10 years old |
| kb_view_oe_line_auto_rewards | 2016-07-19 | 10 years old — rewards program may have changed |

---

## Flags Worth Investigating with Query Store

| View | Last Modified | Question |
|---|---|---|
| kb_view_invoice_line_commission | 2018-03-08 | 923k-row table never touched — is this view queried? |
| kb_view_aging_corporate | 2018-04-03 | Old but kb_table_credit_analysts is a config table read daily |
| kb_view_braun_pick_tickets_mi | 2019-01-08 | Braun-specific — is this vendor relationship still active? |
| kb_view_braun_pick_tickets_mnwi | 2019-01-08 | Same |
| kb_view_dancik_to_p21_acct_crossover | 2020-05-13 | Dančík crossover — migration artifact? |
| kb_view_sale_day_monitor | 2025-05-02 | Recently updated — confirms sale day program still maintained |
| kb_view_error_log | 2019-10-14 | Different from kb_view_br_error_log — what does this point to? |
| kb_dqc_view_commission_duplicates | 2016-07-19 | "dqc" prefix = data quality check? 10 years old |

---

## Recommended Next Step

Run the Query Store bulk scan query above on P21 Prod to get `last_seen` for every kb_ view in one pass. That will immediately separate active views from dead ones without having to check each individually.

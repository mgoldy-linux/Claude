# kb_ Trigger Usage Analysis
**Date:** 2026-06-03  
**Server:** P21.allsurfaces.com / P21  
**Data window:** 2026-05-17 (last restart) → 2026-06-03 — 17 days  
**Source:** sys.dm_exec_trigger_stats (resets on restart)

---

## Important: Plan Cache Eviction

`sys.dm_exec_trigger_stats` only tracks triggers whose execution plans are currently in the plan cache. A trigger that fired recently but whose plan was evicted will show NULL — **not proof it didn't run.** Cross-reference with the table write timestamps from the table analysis.

Example: `kb_trigger_customer_salesrep_log_customer_salesrep_changes_i` and `_u` show NULL here, but `kb_table_customer_salesrep_audit_trail` was written yesterday. The triggers likely fired but their plans were evicted.

---

## Summary
| Category | Count |
|---|---|
| Confirmed active (in cache, ran in window) | 2 |
| Likely active (table written, plan evicted) | 2 |
| Investigate | 1 |
| Not executed in window | 2 |
| **Total** | **7** |

---

## KEEP — Confirmed Active

| Trigger | Exec Count | Last Run | Table | Notes |
|---|---|---|---|---|
| kb_trigger_oe_line_rebate_rate_from_manual_update | 2,300 | Today | oe_line | High-frequency — fires on every manual price change |
| kb_trigger_invoice_hdr_add_printedby_to_invoice_hdr_ud | 1,515 (3 plans) | Today | invoice_hdr | Fires on invoice print — appears 3× due to multiple cached plans |
| kb_trigger_customer_ud_log_buying_group_changes | 1 | Yesterday | customer_ud → kb_table_buying_group_audit_trail | Audit trail trigger |

---

## KEEP — Likely Active (Plan Evicted from Cache)

| Trigger | Last Modified | Evidence | Table Written |
|---|---|---|---|
| kb_trigger_customer_salesrep_log_customer_salesrep_changes_i | 2021-11-11 | kb_table_customer_salesrep_audit_trail written yesterday | customer_salesrep |
| kb_trigger_customer_salesrep_log_customer_salesrep_changes_u | 2021-11-11 | Same | customer_salesrep |

---

## INVESTIGATE

| Trigger | Last Modified | Notes |
|---|---|---|
| kb_trigger_customer_br_sale_day_onlyhouse | 2020-08-17 | Sale day cluster — not run if no sale day active. Fires on customer table. Tied to kb_table_sale_day_customers. |

---

## NOT EXECUTED IN WINDOW

| Trigger | Last Modified | Notes |
|---|---|---|
| kb_trigger_oe_line_oe_salesrep_id | 2021-11-19 | Fires on oe_line changes. Not in cache — likely evicted. Cross-check: kb_table_customer_comclass_salesrep is very active (361k rows, written today). May still be active. |

---

## Flags

- **kb_trigger_invoice_hdr_add_printedby_to_invoice_hdr_ud** — appears 3 times with exec counts 657, 856, and 2. Multiple cached plans for the same trigger is unusual. Could indicate the trigger was recompiled or the table has multiple contexts (INSERT vs UPDATE). Total ~1,515 executions.
- **Trigger count is low** — only 7 kb_ triggers total. Most audit trail and business logic is handled via stored procs, not triggers. This is good — triggers are harder to trace and debug.

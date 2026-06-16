# kb_ Function Usage Analysis
**Date:** 2026-06-03  
**Server:** P21.allsurfaces.com / P21  
**Data window:** 2026-05-17 (last restart) → 2026-06-03 — 17 days  
**Source:** sys.dm_exec_function_stats (resets on restart)

---

## Important: Duplicate Rows in Results

`kb_fn_pricing_convert` and `kb_fn_date_rng_calc` appear multiple times with different exec counts. This is normal — SQL Server caches multiple execution plans for the same function (different parameter sniffs or contexts). **The exec counts are per-plan, not total.** True totals:

| Function | Total Executions (sum of plans) |
|---|---|
| kb_fn_pricing_convert | ~16,163,248 |
| kb_fn_date_rng_calc | ~279,837 |

---

## Important: TVF Tracking Limitation

All TVFs (table-valued functions) show NULL since restart — even ones that are referenced by active business rules like `kb_fnt_br_order_validator_v2`. This is a **DMV gap, not proof of inactivity.** `sys.dm_exec_function_stats` does not reliably track inline TVFs, and multi-statement TVF plans are evicted from cache quickly. **Do not use NULL TVF stats as a retirement signal.** Use Query Store (see Views Analysis doc) to verify actual usage.

---

## Scalar Functions — Summary
| Category | Count |
|---|---|
| Active — executed in window | 11 |
| Investigate — not executed | 14 |
| **Total Scalar** | **25** |

## TVFs — Summary
| Category | Count |
|---|---|
| Investigate (DMV unreliable) | 21 |
| **Total TVF** | **21** |

---

## SCALAR FUNCTIONS — KEEP (Executed in Window)

| Function | Exec Count | Last Run | Notes |
|---|---|---|---|
| kb_fn_pricing_convert | ~16.2M | Today | Most-called function in the system — pricing engine core |
| kb_fn_credit_analyst_expand | 952,896 | Today | Credit analyst lookup — called in AR views |
| kb_fn_date_rng_calc | ~279,837 | Today | Date range utility — called widely |
| kb_fn_get_sales_manager | 204,864 | Today | Sales manager lookup |
| kb_fn_proper_case | 6,535 | Today | String formatting |
| kb_fn_removeNonAlphaNumericCharacters | 1,611 | Today | String cleansing |
| kb_fn_packaging_convert | 773 | Today | Packaging unit conversion |
| kb_fn_number_shorten | 660 | Today | Display formatting |
| kb_fn_business_day_count | 20 | Today | Business day calculator |
| kb_fn_business_days_ahead | 10 | Today | Business day calculator |

---

## SCALAR FUNCTIONS — INVESTIGATE (Not Executed in Window)

Most are used by commission, salesrep, or portal-specific flows that haven't run in the 17-day window.

| Function | Last Modified | Likely Use |
|---|---|---|
| kb_fn_get_salesrep | 2025-01-06 | Recently updated — recently active |
| kb_fn_get_salesrep_from_table | 2025-01-06 | Recently updated — recently active |
| kb_fn_get_salesreps_by_division | 2024-12-02 | Division lookup — infrequent |
| kb_fn_get_sales_manager_names | 2024-10-27 | Portal-specific variant of get_sales_manager |
| kb_fn_get_sales_manager_names_portals | 2024-10-27 | Portal-specific |
| kb_fn_get_product_manager | 2024-10-27 | Product manager lookup |
| kb_fn_get_comm_rule_payout_rate_calculation | 2024-10-27 | Commission rules — runs when reports run |
| kb_fn_get_comm_rule_payout_rate_description | 2024-10-27 | Commission rules |
| kb_fn_get_sales_manager_value | 2024-10-27 | Sales manager config |
| kb_fn_get_contact_name | 2024-10-27 | Contact lookup |
| kb_fn_get_cust_ccs_loc | 2024-10-27 | CCS location for customer |
| kb_fn_comclass_convert | 2024-10-27 | Comm class conversion — table read daily |
| kb_fn_removeNonEDICharacters | 2024-10-27 | EDI string cleansing — EDI-specific |
| kb_fn_was_order_returned_recosted | 2024-10-27 | Order analysis — infrequent |
| kb_fn_convert_to_ftin | 2024-10-27 | Unit conversion (feet/inches) |

**Note on kb_fn_comclass_convert:** The `kb_comclass_convert` table is read daily, but this scalar function shows NULL. The table may be read via the `kb_view_cust_comclass_rep_rule` view rather than direct function calls — consistent with the TVF tracking gap.

---

## SCALAR FUNCTIONS — RETIRE

No strong retire candidates in scalar functions — most have recent `last_modified` dates (all showing 2024-10-27, suggesting a mass recompile). None are clearly obsolete by name or age.

---

## TABLE-VALUED FUNCTIONS — Full List

**Reminder: NULL stats are not reliable for TVFs. Use modify_date as the only signal.**

| TVF | Last Modified | Assessment |
|---|---|---|
| kb_fnt_get_user_loc | 2026-04-14 | Recently updated — active |
| kb_fnt_sales_manager_expand_table | 2026-01-19 | Recently updated — active |
| kb_fnt_br_notepad_class_defaults | 2025-01-30 | Recently updated — active BR |
| kb_fnt_br_validate_oo_block | 2024-05-28 | Recently updated — active BR |
| kb_fnt_user_settings | 2024-07-26 | Recently updated |
| kb_fnt_br_oe_rm_paysibfs | 2023-12-08 | Updated 2023 |
| kb_fnt_br_order_validator_v2 | 2023-12-08 | Active — used by order entry BR |
| kb_fnt_commission_schedule_details | 2024-03-22 | Commission support |
| kb_fnt_br_oe_required_date | 2023-02-02 | Required date BR |
| kb_fnt_customer_pricing_loc | 2019-03-28 | Pricing support |
| kb_fnt_aging_corporate | 2018-08-02 | AR aging — used by kb_view_aging_corporate |
| kb_fnt_br_credit_status | 2019-06-12 | Credit BR |
| kb_fnt_br_frontcounter_cotf | 2019-10-31 | Front counter BR |
| kb_fnt_br_shipto_info | 2019-08-27 | Ship-to BR |
| kb_fnt_related_orders | 2019-06-06 | Related order lookup |
| kb_fnt_user_login_details | 2019-10-14 | User login tracking |
| kb_fnt_br_order_validator | 2021-06-03 | Older order validator — superseded by _v2? |
| kb_fnt_credit_analyst_expand_table | 2018-10-29 | Credit analyst table version |
| kb_fnt_get_req_dates | 2018-07-12 | Required dates utility |
| kb_fnt_carrier_cutoff_color | 2018-09-13 | Carrier cutoff display |
| kb_fnt_split_string | 2018-06-14 | String split utility |
| kb_fnt_br_order_saleday_pricetype | 2020-06-03 | Sale day cluster |

### TVF Flags

- **kb_fnt_br_order_validator vs kb_fnt_br_order_validator_v2** — both exist. v2 was updated in 2023; the original was last modified 2021. Verify whether the original is still deployed in any active business rule or only v2 is.
- **kb_fnt_split_string (2018)** — SQL Server has `STRING_SPLIT()` built-in since 2016. This custom TVF may be replaceable with a standard function — reduces customization.
- **kb_fnt_carrier_cutoff_color (2018)** — related to the carrier cutoff TVF fix project (SA noted in memory). Verify this one is still needed vs. the updated version.

# 2026 Accomplishments Summary

*Prepared for performance review. Work spans March–June 2026.*

---

## Goal Area 1 — Technical Lead: Zilliant / Strategic Pricing

Owned the P21 side of the Zilliant strategic-pricing integration — the pricing data model, screen customizations, and quote-to-order workflow.

- **Special Pricing Indicator (Reqs v1.1, with Chad Skelton)** — Drove the requirements for new user-defined fields on **Sales Price Book Maintenance** and **Sales Price Page Maintenance** so the Pricing team can flag special pricing and price levels (e.g. "Strategic Price Type" / "Special Price" on both Price Book and Price Page screens).
- **P21 Interactive API transaction definitions** — Built/maintained the pricing transaction definitions: `SalesPricePage.json`, `SalesPriceBook.json`, `StrategicPricingLibrary.json` (price_page business object, key fields, valid-value lists for price page types, etc.).
- **QTO (Quote-to-Order) Order Taker business rule** — Built `asi_oe_qto_taker` to auto-set the order taker to the converting user on quote→order conversion.
  - **Wizard path (T4, `qtowindowopening` event): COMPLETE and passing** — ready for Prod deployment.
  - **RMB "Convert to Order" path: exhausted T1–T14 + a session-context table approach; placed on hold** after confirming a hard P21 framework limitation (the only reliable RMB trigger, message box 7770, carries no order context). Emailed Chad & Tyler directing users to the Wizard path.
  - Deep framework findings documented (ExecuteAsync vs Execute, `.FieldValue` field access, security-transparency/reflection workarounds).
- **`price_page_description` alert token** — Added to the KOW Low-Margin alert (`p21_view_alert_oe_OrderEntry`) so pricing context shows on the line item; done in P21Training (Prod run still pending).
- **SA-48237 `asi_view_inv_mast`** — New item-master view extending `p21_view_inv_mast` with division, manufacturer, and primary supplier_name to feed Zilliant pricing; row-count/column parity verified; in P21Dev awaiting Prod acceptance.
- **P21 Interactive API reference** established (auth, endpoints, dropdown-values endpoint) — foundational for further pricing automation.

---

## Goal Area 2 — Dynachange & Portal Cleanup  *(Goal deadline 2026-06-30)*

Major progress toward retiring KB customizations and decommissioning dead portal artifacts.

- **KB → ASI function/view migration** for the Open Orders portal (SA 43045): replaced `kb_fnt_get_user_loc`→`asi_fnt_get_user_loc`, `kb_view_open_orders`, `kb_view_item_classifications_loc100`, and `kb_view_users` with standard P21 objects; **validated zero row differences** across all 11 ops_region users (and 41 DEFAULT price-family users) on Prod. Grants deployed across all 5 instances.
- **BOP Purchasing portals (SA 45138)** — Added `bo_orders` and `critical_orders` (open SO numbers for backordered/critical items) to Supplier Summary & Supplier Manager portals; built a new **Order Detail drill-through portal**; excluded projected orders (V3); **deployed to Prod, approved by Pamela Dundas.**
- **Portal file decommissioning** — Cross-referenced live usage (24,524 usage rows) against the Play Portals share; **staged 156 unused `.srd` files + 32 loose asset files (188 total) to "Test Cleanup"**, reducing the share to active files only.
- **Portal usage telemetry** — Built and deployed Extended Events sessions:
  - `Portal_Usage_Tracking` + harvest scripts (incremental Excel output).
  - **Discovered how P21 logs custom-tab selection** (the `d_ds_portal_element` batch marker) — solved a long-standing blind spot — and built/deployed a new **`Portal_Tab_Tracking` XE on both Play and Prod**, with per-tab harvest scripts resolving `portal_element_uid` → tab name.
- Established the authoritative portal-cleanup method (`portal_user_defined.datawindow_name`) and a 9-step cleanup plan.

---

## Goal Area 3 — Business Rules Cleanup *(Goal deadline 2026-10-30)*

Established the standards and tooling for converting legacy KB/JS rules to owned `asi_` rules, and executed several conversions.

- **kb_Order_Validator_v2 modernization** — Retired `kb_SQLHelper` from the entire assembly (both rules → `P21SqlConnection` + native `business_rule_log`); fixed C# 7.3 compatibility; bumped to ver 1.0.1.0. **P21 accepted the rebuilt DLL (deploy-mechanics test PASSED, 2026-06-24.)** Built a full equivalence test plan + OLD-vs-NEW compare harness; drafted kb-free `asi_proc_br_oe_hdr_note`.
- **`asi_ribbon_rm_default_products`** — Rewrote `kb_RepRM_getDefaultProducts` to current standard (no kb_SQLHelper, direct field access, error logging to `business_rule_log`); fixed a real defect (new reps with no commission schedule now show actionable text instead of "n/a"); added a fallback data source so 18 of 21 no-schedule reps get real data; parity-verified 109/109 reps. Built a field-name **resolver pattern** now adopted as the standing standard.
- **WWMS Scanner-Only rule (`c_rf_item_id`)** — Built a DataChanged rule enforcing scanner-only entry (strip `&` prefix, reject manual/blank entry) on the picking floor; T4 passed initial testing.
- **WWMS Pick Item Description (SA 47981)** — Built a Pre-SQL injection rule; confirmed the SQL injection fires live (parked on the screen-only mapping; next approach scoped).
- **jsTextValidator analysis** — Fully traced the JS PO-text-validation chain and the "B2B limits" popup; documented 6+ code defects; agreed rename to `asi_po_entry_text_validator` (rewrite gated on a team answer about the B2B limit's validity).
- **Tooling & analysis** — Built `BusinessRuleExporter` (extracts rule metadata from DLLs); produced 5 KB usage-analysis documents (47 tables / 84 procs / 25 functions / 21 TVFs / 7 triggers / 81 views) identifying retirement candidates via DMVs + Query Store; built the `ValidState` and message-suppression rules.

---

## Everything Else (not tied to the three goals)

**Production fixes & support tickets**
- **`_asi Daily Sales Order Repair` job** — Diagnosed and fixed a recurring nightly failure (Error 245). Found the true root cause: a missing `fault_tolerance_problem_code` entry causing a COALESCE int-conversion error; applied the fix to Prod.
- **SA-45865** — Fixed OE note-save truncation by widening `apc_business_rule_extensions_xml` to `varchar(MAX)`, rebuilt 8 dependent procs, restored grants; rolled out across environments.
- **SA-48124 Vendor Invoice Report** — Researched and located the missing "additional charges" source (`vendor_invoice_edi` ⋈ `chart_of_accts_edi`); proved totals to the penny; designed an upgrade-safe view + Crystal subreport (build pending after 07/13).
- **WC Carrier ID consolidation**, **SA-46487 UOM report**, **SA-46684 oe_hdr bulk updates**, and several ad-hoc data/report requests for Jere and Matt.

**Database-refresh automation** (BRR/Play/Dev/Training)
- Substantially overhauled the Before/After refresh scripts for P21Play, P21Dev, and P21BusinessRules — added settings/user/role/scheduled-import capture-and-restore phases, dev-only user re-creation, PK-conflict handling, and run-counter fixes.

**Permissions tooling & governance**
- Built comparison scripts for `kb_table_br_error_log`, APC extensions, and `AHI-API1$` across all environments; found and fixed missing grants in Training/Dev/Play.

**PowerShell environment & utilities**
- Fixed the dbatools "assembly already loaded" failure (purged 10 stale library versions, rewrote the auto-update logic); fixed multiple `.Count` scalar bugs in Compare-Folders and harvest scripts; improved `Check-Job-History` (single-query rewrite + day-of-week scoping); standardized the script template; session-log cleanup.

**Apparently personal (non-work) side project — flag for exclusion from review**
- A large body of commits (May 2026) for an **EIA Jet Fuel / Athens-travel / aviation dashboard** (Chart.js dashboards, OpenSky/FlightAware/BestTime/Eurostat/BTS Postman collections, GitHub Pages). This is unrelated to All Surfaces work and should likely be left out of the performance review.

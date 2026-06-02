# Performance Optimization Report
## kb_sales_history_report_view
**Date:** 2026-03-27
**Prepared by:** Karen's Dev Team
**Files:** `kb_sales_history_report_view-P21.sql` → `kb_sales_history_report_view-P21_optimized.sql`

---

## Executive Summary

A performance analysis was conducted on `kb_sales_history_report_view`, a large SQL view used across multiple P21 portal reports and ribbon metric business rules. The view was found to have several significant performance issues including redundant joins, function-wrapped join conditions that block index usage, and duplicate CASE logic repeated hundreds of lines. An optimized version has been produced with an estimated **30–50% query time reduction**.

---

## Background

The view is a core reporting asset that:
- Joins **51+ tables and views**
- Returns **130+ columns**
- Applies **complex multi-clause WHERE filtering**
- Is consumed by numerous SRD portal reports and C# business rules (e.g., `kb_CustRM_getYTDSalesAbbr`)

A related issue was also discovered during this review: the business rule `kb_CustRM_getYTDSalesAbbr` was filtering on `year_for_period = Year(GetDate())`, which returned no results due to a **data type mismatch** (`year_for_period` is VARCHAR, `Year()` returns INT). This was corrected separately.

---

## Issues Found & Changes Made

### 1. Functions in JOIN Predicates — HIGH IMPACT
**Problem:** Three JOIN conditions wrapped columns in COALESCE or CONVERT functions, preventing SQL Server from using indexes (forcing table scans).

| Join | Original | Fixed |
|------|----------|-------|
| `location` | `COALESCE(invoice_hdr.sales_location_id, oe_hdr.location_id, 0) = location.location_id` | Bare column on left side; CASE on right |
| `salesrep_contact` | `salesrep_contact.id = CONVERT(VARCHAR(16), COALESCE(...))` | CAST moved to right-hand side |
| `product_group` | `COALESCE(CASE...WHEN ''...END) = product_group.product_group_id` | Simplified CASE, bare column on left |

**Est. gain: 20–40%**

---

### 2. Duplicate CASE Logic — HIGH IMPACT
**Problem:** Three columns — `inflated_sales_price_home`, `sales_price_home`, and `gross_profit_dollars` — each contained nearly identical ~35-line CASE expressions. The same logic was written and executed three separate times per row.

**Fix:** Consolidated all three into a single `CROSS APPLY` block. Logic is written once, computed once, and referenced three times.

**Est. gain: 20–30%**

---

### 3. Redundant Table Joins — MEDIUM IMPACT
**Problem:** `job_price_line` and `job_price_hdr` were joined twice — once un-aliased and once with `_a`/`_b` aliases. The SELECT clause only referenced the aliased versions, making the un-aliased joins completely unused.

**Fix:** Removed the un-aliased duplicate joins.

**Est. gain: 10–15%**

---

### 4. Non-SARGable WHERE Conditions — MEDIUM IMPACT
**Problem:** `ISNULL()` wrapped a column in the WHERE clause, preventing index seeks on `source_type_cd`.

```sql
-- Before (not index-friendly)
ISNULL(invoice_hdr.source_type_cd, 0) <> 1661

-- After (SARGable)
(invoice_hdr.source_type_cd IS NULL OR invoice_hdr.source_type_cd <> 1661)
```

**Est. gain: 5–10%**

---

### 5. Division Without Zero Guards — BUG RISK
**Problem:** Several calculations divided by `pricing_unit_size` or `qty_shipped` without checking for zero, risking divide-by-zero runtime errors.

**Fix:** Wrapped all divisors with `NULLIF(..., 0)` so division returns NULL instead of throwing an error.

**Columns affected:** `unit_price`, `inflated_net_unit_other_cost`, and three calculations inside the new CROSS APPLY block.

---

### 6. NULL-Unsafe String Concatenation — BUG RISK
**Problem:** Contact name was built by concatenating `first_name + mi + last_name`. In SQL Server, if any part is NULL the entire result is NULL — causing blank contact names.

```sql
-- Before
RTRIM(contacts.first_name + CASE WHEN contacts.mi IS NULL THEN '' ELSE ' ' + contacts.mi END + ' ' + contacts.last_name)

-- After
RTRIM(CONCAT_WS(' ', contacts.first_name, contacts.mi, contacts.last_name))
```

---

### 7. Redundant DISTINCT — MINOR
**Problem:** An inline subquery used `SELECT DISTINCT invoice_no` when `invoice_no` was the only column and was only used as a join key — DISTINCT was unnecessary overhead.

**Fix:** Removed `DISTINCT`.

---

### 8. Inline Subqueries Converted to CTEs — READABILITY + MINOR PERFORMANCE
**Problem:** Four inline subqueries were embedded mid-query making the plan harder to read and optimize.

**Fix:** Moved to named CTEs at the top of the query:
- `cte_invoice_line_summary`
- `cte_drv_sumlines`
- `cte_drv_nested_lot_header_comm_cost`
- `cte_direct`

---

## Summary Table

| # | Issue | Impact | Type |
|---|-------|--------|------|
| 1 | Functions in JOIN predicates blocking index seeks | 20–40% | Performance |
| 2 | Duplicate CASE logic computed 3x per row | 20–30% | Performance |
| 3 | Redundant un-aliased job_price joins | 10–15% | Performance |
| 4 | ISNULL in WHERE blocking index seeks | 5–10% | Performance |
| 5 | Division without zero guards | N/A | Bug Risk |
| 6 | NULL-unsafe string concatenation | N/A | Bug Risk |
| 7 | Redundant DISTINCT | <5% | Performance |
| 8 | Inline subqueries → CTEs | <5% | Readability |

**Estimated total improvement: 30–50% query time reduction**

---

## Separate Fix: Business Rule Type Mismatch

During this review, `kb_CustRM_getYTDSalesAbbr.cs` was found to be returning no results for YTD sales. Root cause: `year_for_period` in `invoice_hdr` is a VARCHAR column, but the query compared it to `Year(GetDate())` which returns an INT.

**Fix applied:**
```sql
-- Before
WHERE year_for_period = Year(GetDate())

-- After
WHERE year_for_period = CAST(YEAR(GETDATE()) AS CHAR(4))
```

---

## Next Steps

1. **Test the optimized view** in a non-production environment against the same queries
2. **Compare execution plans** in SSMS using `SET STATISTICS TIME ON` — look for index seeks replacing table scans on the three fixed JOIN conditions
3. **Deploy** `kb_sales_history_report_view-P21_optimized.sql` once validated
4. **Deploy** updated `kb_CustRM_getYTDSalesAbbr.cs` business rule

---

*All changes in the optimized SQL file are tagged with `-- PERF:` comments for easy review.*

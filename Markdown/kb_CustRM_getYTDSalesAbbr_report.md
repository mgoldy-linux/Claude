# Code Review Report
## kb_CustRM_getYTDSalesAbbr.cs
**Date:** 2026-03-27
**Prepared by:** Karen's Dev Team
**Namespace:** `kb_RibbonMetrics_r1`
**Base Class:** `P21.Extensions.BusinessRule.Rule`

---

## Purpose

P21 ribbon metric business rule that returns a customer's year-to-date sales as an abbreviated string (e.g., `$1.3mln`) for display on the customer ribbon in Prophet 21. Calls `kb_fn_number_shorten` to format the result.

---

## What Changed vs. Original

This report covers the **original file** as submitted. Six issues were identified and corrected in the current file on disk. Each is documented below with before/after.

---

## Issues Found & Changes Made

### 1. `GetFieldByAlias` → Direct Field Access — CONVENTION

**Problem:** The original code used `GetFieldByAlias("field_name")` to retrieve field values. Per project convention, direct field access should be used instead.

```csharp
// Before
this.Data.Fields.GetFieldByAlias("cust_id").FieldValue
this.Data.Fields.GetFieldByAlias("cust_type").FieldValue

// After
this.Data.Fields["cust_id"].FieldValue
this.Data.Fields["cust_type"].FieldValue
```

**Affected locations:** 7 occurrences throughout `Execute()`.

---

### 2. Repeated Class Name LINQ Expression → `nameof` — MEDIUM IMPACT

**Problem:** The class name was derived at runtime using a verbose LINQ expression repeated 5 times:

```csharp
// Before — repeated 5 times, hard to read, fragile in async contexts
new string(MethodBase.GetCurrentMethod().DeclaringType.Name
    .Where<char>(new System.Func<char, bool>(char.IsLetterOrDigit))
    .ToArray<char>())
```

Issues with this approach:
- `MethodBase.GetCurrentMethod()` can return incorrect results inside lambdas or async methods
- Allocates a new char array on every call
- Requires `using System.Reflection` and `using System.Linq`

```csharp
// After — declared once at the top of Execute(), compile-time safe
string ruleName = nameof(kb_CustRM_getYTDSalesAbbr);
```

Also allowed removal of `using System.Reflection` and `using System.Linq` from the file.

---

### 3. `outputNumber` as Instance Field → Local Variable — CODE QUALITY

**Problem:** `outputNumber` was declared as a private instance field on the class:

```csharp
// Before — instance field (class level)
private string outputNumber = string.Empty;
```

It was only ever read and written within a single `Execute()` call with no need to persist between calls. Instance fields on business rule classes can cause subtle state issues if the runtime ever reuses an instance.

```csharp
// After — local variable scoped to the else block
string outputNumber = string.Empty;
```

---

### 4. SQL Year Filter Type Mismatch → Correct Cast — BUG FIX

**Problem:** The WHERE clause compared `year_for_period` (a `VARCHAR`/`CHAR` column in `invoice_hdr`) to `Year(GetDate())` which returns an `INT`. SQL Server's implicit conversion is unreliable here and caused the query to return **no results**.

```sql
-- Before (broken — type mismatch, returns 0 rows)
WHERE year_for_period = Year(GetDate())

-- After (correct — explicit cast matches column type)
WHERE year_for_period = CAST(YEAR(GETDATE()) AS CHAR(4))
```

**Impact:** This was the root cause of YTD sales showing blank on the customer ribbon.

---

### 5. Redundant `connection.Close()` Inside `using` — CLEANUP

**Problem:** The original code explicitly closed the connection inside a `using` block that already handles disposal:

```csharp
// Before — redundant, the using block already closes on dispose
if (connection.State != 0)
    connection.Close();
```

```csharp
// After — removed; using handles this
```

---

### 6. `GetName()` Returning LINQ Expression → `nameof` — CONVENTION

**Problem:** `GetName()` used the same verbose LINQ expression as issue #2:

```csharp
// Before
public override string GetName()
{
    return new string(MethodBase.GetCurrentMethod().DeclaringType.Name
        .Where<char>(new System.Func<char, bool>(char.IsLetterOrDigit))
        .ToArray<char>());
}

// After
public override string GetName()
{
    return nameof(kb_CustRM_getYTDSalesAbbr);
}
```

---

## Summary Table

| # | Issue | Severity | Type |
|---|-------|----------|------|
| 1 | `GetFieldByAlias` used instead of direct field access | Medium | Convention |
| 2 | Class name derived via LINQ at runtime — repeated 5x | Medium | Performance / Code Quality |
| 3 | `outputNumber` declared as instance field instead of local variable | Low | Code Quality |
| 4 | SQL year filter type mismatch — query returned no results | Critical | Bug Fix |
| 5 | Redundant `connection.Close()` inside `using` block | Low | Cleanup |
| 6 | `GetName()` using same verbose LINQ expression | Low | Convention |

---

## Final State of File

The current file on disk (`kb_CustRM_getYTDSalesAbbr.cs`) reflects all six fixes above. Key characteristics of the corrected file:

- Uses `this.Data.Fields["field_name"].FieldValue` for all field access
- `ruleName` declared once via `nameof()` and reused in all logging calls
- `outputNumber` is a local variable inside the `else` block
- SQL query uses `CAST(YEAR(GETDATE()) AS CHAR(4))` for correct year filtering
- `using System.Reflection` and `using System.Linq` removed (no longer needed)
- `GetName()` returns `nameof(kb_CustRM_getYTDSalesAbbr)`

---

## Related Assets

| Asset | Relationship |
|-------|-------------|
| `kb_sales_history_report_view` | View queried by this rule — separate performance report issued |
| `kb_fn_number_shorten` | SQL function called to format the output number — separate review report issued |
| `kb_SQLHelper` | Helper class used for connection string retrieval and error logging |

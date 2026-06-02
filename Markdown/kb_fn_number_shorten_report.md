# Code Review Report
## kb_fn_number_shorten
**Date:** 2026-03-27
**Prepared by:** Karen's Dev Team
**Object:** `[dbo].[kb_fn_number_shorten]` — User Defined Function

---

## Purpose

Converts a large number into a human-readable abbreviated string (e.g., `1,250,000` → `$1.3mln`). Used in ribbon metric business rules such as `kb_CustRM_getYTDSalesAbbr` to display YTD sales on the P21 customer ribbon.

---

## Issues Found

### 1. `FORMAT()` Performance — HIGH IMPACT

**Problem:** SQL Server's `FORMAT()` function uses .NET CLR internally and is **10–50x slower** than equivalent `CONVERT`/`CAST` string operations. This function calls `FORMAT()` up to 3 times per invocation. Since this runs once per customer ribbon load (and potentially across many rows in reports), it adds up quickly.

**Recommendation:** Replace `FORMAT()` with `CONVERT(VARCHAR, ...)` + string concatenation where possible. For the magnitude suffixes (`k`, `mln`, `bln`), manual string building is straightforward and far faster.

**Example:**
```sql
-- Before (slow)
Format(Round(@conversion_number / 1000, 1), '0.0k;-0.0k')

-- After (fast)
CONVERT(VARCHAR(10), CAST(Round(@conversion_number / 1000, 1) AS DECIMAL(10,1))) + 'k'
```

---

### 2. `FLOAT` Input Type — MEDIUM IMPACT / BUG RISK

**Problem:** The parameter `@conversion_number` is typed as `FLOAT`. FLOAT uses binary floating-point representation which introduces precision errors for financial data — for example, `1000.50` may be stored as `1000.4999999998`. This can cause:
- Incorrect threshold comparisons (e.g., a value of exactly `1000` may trigger the wrong format tier)
- Rounding artifacts in the output

**Recommendation:** Change input type to `DECIMAL(19, 4)` which is exact for financial values.

```sql
-- Before
@conversion_number AS FLOAT

-- After
@conversion_number AS DECIMAL(19, 4)
```

---

### 3. Broken Integer Detection — BUG

**Problem:** The check `CONVERT(INT, @conversion_number) = @conversion_number` is used to detect whether the value is a whole number. However:
- `INT` has a max value of ~2.1 billion — any larger value causes an **overflow error**
- The code itself has a comment acknowledging this: *"doesn't work right for long decimals, though; it's a SQL quirk"*

**Recommendation:** Use the modulo operator instead, which works for any size:

```sql
-- Before (buggy for values > 2.1 billion)
CASE WHEN CONVERT(INT, @conversion_number) = @conversion_number THEN ...

-- After (safe)
CASE WHEN @conversion_number % 1 = 0 THEN ...
```

---

### 4. `@dollars` Should Be `BIT` — MINOR

**Problem:** The `@dollars` parameter is typed as `TINYINT` but is only ever checked `WHEN 1` — it functions as a boolean flag. Using `TINYINT` allows values like `2`, `3`, etc. that silently do nothing, which could confuse callers.

**Recommendation:** Change to `BIT` to make the intent explicit and prevent invalid values.

```sql
-- Before
@dollars AS TINYINT = NULL

-- After
@dollars AS BIT = 0
```

Changing the default from `NULL` to `0` also removes a subtle ambiguity — currently passing no value and passing `0` behave the same, but the signature implies they might not.

---

### 5. No NULL Handling — MINOR

**Problem:** If `@conversion_number` is NULL, the function returns NULL silently. Callers may not expect this and display a blank ribbon metric rather than `$0` or `--`.

**Recommendation:** Add an explicit NULL guard at the top:

```sql
IF @conversion_number IS NULL
    RETURN CASE WHEN @dollars = 1 THEN '$0' ELSE '0' END
```

---

### 6. Dead Commented-Out Code — CLEANUP

**Problem:** The ELSE branch contains a commented-out line that duplicates the active code below it:

```sql
ELSE --Format(@conversion_number,'0')   ← dead code, remove
    CASE WHEN CONVERT(INT, @conversion_number) = @conversion_number THEN
        Format(@conversion_number,'0')
    ...
```

**Recommendation:** Remove the commented line.

---

## Summary Table

| # | Issue | Severity | Type |
|---|-------|----------|------|
| 1 | `FORMAT()` used — 10–50x slower than alternatives | High | Performance |
| 2 | `FLOAT` type causes precision errors for financial data | Medium | Bug Risk |
| 3 | `CONVERT(INT,...)` overflows for values > 2.1 billion | Medium | Bug |
| 4 | `@dollars` should be `BIT` not `TINYINT` | Low | Code Quality |
| 5 | No NULL input handling | Low | Robustness |
| 6 | Dead commented-out code | Low | Cleanup |

---

## Recommended Revised Function

```sql
CREATE OR ALTER FUNCTION [dbo].[kb_fn_number_shorten]
(
    @conversion_number AS DECIMAL(19, 4),
    @dollars           AS BIT = 0
)
RETURNS VARCHAR(25)
AS
BEGIN
    DECLARE @return_value AS VARCHAR(25)

    -- NULL guard
    IF @conversion_number IS NULL
        RETURN CASE WHEN @dollars = 1 THEN '$0' ELSE '0' END

    SET @return_value = CASE
        WHEN @conversion_number > 10000000000 OR @conversion_number < -10000000000
            THEN CONVERT(VARCHAR(20), CAST(ROUND(@conversion_number / 1000000000, 0) AS BIGINT)) + 'bln'
        WHEN @conversion_number > 1000000000 OR @conversion_number < -1000000000
            THEN CONVERT(VARCHAR(20), CAST(ROUND(@conversion_number / 1000000000, 1) AS DECIMAL(10,1))) + 'bln'
        WHEN @conversion_number > 10000000 OR @conversion_number < -10000000
            THEN CONVERT(VARCHAR(20), CAST(ROUND(@conversion_number / 1000000, 0) AS BIGINT)) + 'mln'
        WHEN @conversion_number > 1000000 OR @conversion_number < -1000000
            THEN CONVERT(VARCHAR(20), CAST(ROUND(@conversion_number / 1000000, 1) AS DECIMAL(10,1))) + 'mln'
        WHEN @conversion_number > 10000 OR @conversion_number < -10000
            THEN CONVERT(VARCHAR(20), CAST(ROUND(@conversion_number / 1000, 0) AS BIGINT)) + 'k'
        WHEN @conversion_number > 1000 OR @conversion_number < -1000
            THEN CONVERT(VARCHAR(20), CAST(ROUND(@conversion_number / 1000, 1) AS DECIMAL(10,1))) + 'k'
        WHEN @conversion_number > 100 OR @conversion_number < -100
            THEN CONVERT(VARCHAR(20), CAST(@conversion_number AS INT))
        ELSE
            CASE WHEN @conversion_number % 1 = 0
                THEN CONVERT(VARCHAR(20), CAST(@conversion_number AS INT))
                ELSE CONVERT(VARCHAR(20), CAST(@conversion_number AS DECIMAL(10,2)))
            END
    END

    -- Apply dollar sign
    IF @dollars = 1
        SET @return_value = CASE
            WHEN @conversion_number < 0 THEN STUFF(@return_value, 2, 0, '$')
            ELSE '$' + @return_value
        END

    RETURN @return_value
END
```

> **Note:** The revised function removes `FORMAT()` entirely and replaces it with `CONVERT` + string concatenation. The comma formatting (e.g., `#,##0`) in the original `bln` tier has been simplified — if comma-separated thousands are required in the billion tier, add `FORMAT()` only for that one case.

---

## Notes

- The `@dollars` parameter change from `TINYINT` to `BIT` is a **breaking change** only if any callers pass values other than `0` or `1`. Review call sites before deploying.
- The `DECIMAL(19,4)` type change is **backward compatible** — SQL Server will implicitly convert FLOAT or INT arguments passed by callers.
- All output string formats are preserved — results should be identical for valid inputs.

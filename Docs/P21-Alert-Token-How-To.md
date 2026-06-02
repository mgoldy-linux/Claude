# P21 Alert Token — How To Add a New Token

*Last updated: 2026-05-27*

---

## Overview

This guide covers adding a new token to an existing P21 alert. A token is a data field that can be used in alert email templates and filter conditions. The process involves three artifacts:

| Object | Change |
|---|---|
| `dbo.p21_view_alert_<name>` | Add the new column (and join if needed) |
| `dbo.token` | Register the token via `p21_apply_alert_token` |
| `dbo.alert_type_x_token` | Linked automatically by the proc above |

**Always test on P21Training first, then apply to Prod.**

---

## Step 1 — Identify the alert_type_uid

Find the correct `alert_type_uid` for the alert you are targeting:

```sql
SELECT at.alert_type_uid, at.view_name, sc.code_description
FROM alert_type at
INNER JOIN code_p21 sc ON sc.code_no = at.type_cd
WHERE at.view_name = 'oe_OrderEntry'   -- change as needed
```

Common alert views:

| view_name | Description |
|---|---|
| `oe_OrderEntry` | Order Entry / RMA Entry (uid 12 and 15) |
| `oe_Shipping` | Shipping |
| `ap_VoucherEntry` | AP Voucher |

---

## Step 2 — Check whether the source table is already joined

Before adding a new join, verify whether the source table is already in the view:

```sql
DECLARE @def NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'))
PRINT CASE WHEN CHARINDEX('price_page', @def) > 0 THEN 'Already joined' ELSE 'Join needed' END
```

If the join already exists, skip the join insertion in Step 3.

---

## Step 3 — Modify the alert view

Use `OBJECT_DEFINITION` + `sp_executesql` so you modify the live definition without reconstructing it.

> **Important:** Use `CHARINDEX` + `STUFF` for all insertions. Do NOT use `REPLACE` — `OBJECT_DEFINITION` prepends 3 leading newlines and column/join whitespace varies, causing `REPLACE` to silently fail.

```sql
USE P21Training;
GO

DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'))

-- 1. Switch CREATE to ALTER
SET @sql = STUFF(@sql, CHARINDEX('CREATE', @sql), 6, 'ALTER')

-- 2. Add column after the last column in the SELECT list
--    Anchor on the alias of the currently-last column (e.g., 'reward_program_id')
DECLARE @colPos INT = CHARINDEX('''reward_program_id''', @sql)
IF @colPos = 0 PRINT 'ERROR: column anchor not found'
ELSE
    SET @sql = STUFF(@sql, @colPos + LEN('''reward_program_id'''), 0,
        CHAR(10) + '   ,COALESCE(price_page.description, '''') ''price_page_description''')

-- 3. Add LEFT JOIN after the last existing join (anchor on its ON clause, not on WHERE)
DECLARE @joinPos INT = CHARINDEX(
    'LEFT JOIN oe_line_ud ON oe_line_ud.order_no = oe_line.order_no AND oe_line_ud.line_no = oe_line.line_no',
    @sql)
IF @joinPos = 0 PRINT 'ERROR: join anchor not found'
ELSE
    SET @sql = STUFF(@sql,
        @joinPos + LEN('LEFT JOIN oe_line_ud ON oe_line_ud.order_no = oe_line.order_no AND oe_line_ud.line_no = oe_line.line_no'),
        0, CHAR(10) + 'LEFT JOIN price_page ON price_page.price_page_uid = oe_line.price_page_uid')

PRINT 'SQL length: ' + CAST(LEN(@sql) AS VARCHAR)
EXEC sp_executesql @sql
GO

-- Verify the column is now in the view
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'p21_view_alert_oe_OrderEntry'
  AND COLUMN_NAME = 'price_page_description'
GO
```

**Finding the right column anchor:** If you don't know the last SELECT column, print the end of the view:

```sql
DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'))
PRINT SUBSTRING(@sql, LEN(@sql) - 600, 600)
```

---

## Step 4 — Register the token

```sql
USE P21Training;
GO

DECLARE @return_value INT

EXEC @return_value = [dbo].[p21_apply_alert_token]
    @alert_type_uid        = 12,           -- from Step 1
    @token_name            = N'price_page_description',
    @token_available_areas = 4,            -- see available_areas reference below
    @token_description     = N'Price Page Description',
    @token_data_type_cd    = 850,          -- 850 = string, 851 = decimal
    @token_code_group_no   = null

SELECT 'Return Value' = @return_value
GO
```

---

## Step 5 — Fix the token description

`p21_apply_alert_token` overwrites `@token_description` with the raw view column formula. Always correct it immediately after registration:

```sql
USE P21Training;
GO

UPDATE token
SET description = 'Price Page Description'
WHERE name = 'price_page_description'
GO
```

---

## Step 6 — Verify

```sql
USE P21Training;
GO

SELECT t.token_uid, t.name, t.description, t.data_type_cd, t.available_areas
FROM token t
INNER JOIN alert_type_x_token atx ON atx.token_uid = t.token_uid
WHERE atx.alert_type_uid = 12
  AND t.name = 'price_page_description'
GO
```

Expected: one row with correct `available_areas` and a human-readable `description`.

---

## available_areas Reference (alert_type_uid = 12)

`available_areas` is a bitmask that controls where a token appears in the P21 alert editor.

| Value | Meaning | Example tokens |
|---|---|---|
| `4` | Line item body (per-line data in email) | item_description, unit_price, order_quantity |
| `11` | Order header | customer_name, order_number, ship_to_name |
| `32` | Event / order-level | new_order, company_id, will_call |
| `36` | Both event and line item (32+4) | item_id, price_edit, line_item_profit_percentage |
| `43` | Event + header combo | approved, total_amount, customer_id |
| `80` | Email routing | user_email, buyer_email, taker_email |
| `256` | User lookup | All Salesrep's User ID(s) |

**To confirm the right value**, query existing tokens on the same alert type:

```sql
SELECT t.token_uid, t.name, t.available_areas, t.description
FROM token t
INNER JOIN alert_type_x_token atx ON atx.token_uid = t.token_uid
WHERE atx.alert_type_uid = 12
ORDER BY t.available_areas, t.name
```

---

## data_type_cd Reference

| Value | Meaning |
|---|---|
| `850` | String / varchar |
| `851` | Decimal / numeric |

Confirm by querying an existing token of the same type.

---

## Cleanup — Removing Duplicate Tokens

If the registration proc was run multiple times with incorrect parameters, clean up duplicates by deleting from child tables first:

```sql
-- Replace 734, 735 with the actual token_uid values to remove
DELETE FROM Alert_implementation_query WHERE column_id IN (734, 735)
DELETE FROM alert_type_x_token WHERE token_uid IN (734, 735)
DELETE FROM token WHERE token_uid IN (734, 735)
```

---

## Decimal Formatting Note

`p21_fn_MaskDecimal` is hardcoded to return `DECIMAL(19,6)` regardless of system settings, which causes raw 6-decimal values in alert emails. Use `CAST(... AS DECIMAL(19,2))` directly in the view column instead.

---

## Key Notes

- `p21_apply_alert_token` always overwrites the description — fix it manually after every registration (Step 5).
- `OBJECT_DEFINITION` prepends 3 leading newlines before `CREATE` — never assume the text starts at position 1.
- Anchor the STUFF insertion on the ON clause of a join, not on what follows it (newline/WHERE spacing varies).
- Always apply to P21Training first; verify the column appears in `INFORMATION_SCHEMA.COLUMNS` and the token appears in the verify query before running on Prod.

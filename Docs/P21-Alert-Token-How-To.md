# P21 Alert Token — How To Add a New Token

*Last updated: 2026-07-14 — data_type_cd table corrected; available_areas rewritten as a bitmask; whole-alert creation added.*

---

## Overview

This guide covers adding a new token to an existing P21 alert. A token is a data field that can be used in alert email templates and filter conditions. The process involves three artifacts:

| Object | Change |
|---|---|
| `dbo.p21_view_alert_<name>` | Add the new column (and join if needed) |
| `dbo.token` | Register the token via `p21_apply_alert_token` |
| `dbo.alert_type_x_token` | Linked automatically by the proc above |

**Test in P21Play, not P21Training.** Play is refreshed from Prod, so it *is* the Prod baseline — the script proven there is the script that runs in Prod. (Training carries one-off tokens that exist nowhere else.)

---

## Creating a WHOLE alert (not just a token)

An entire alert is scriptable — **no Dynachange UI required**. Four tables:

| Table | Holds |
|---|---|
| `alert_implementation` | the definition: name, `alert_type_uid`, **`where_clause`** (the SQL that actually runs), activation/expiration, `row_status_flag` (705 = active) |
| `Alert_implementation_query` | one row per filter: `column_id` = **token_uid**, `operator_cd`, `column_value` |
| `alert_message` | `subject`, `header`, `line_item`, `footer` — the email body, with `<token>` placeholders |
| `alert_recipient` | recipients — hangs off **`alert_message_uid`**, not the implementation |

**Traps, all learned the hard way (2026-07-14):**

- 🚨 **`alert_message.sender_email_address` MUST be `NULL`, never `''`.** P21 falls back to `system_setting.alert_default_smtp_sender_email` **only when it IS NULL**. An empty string is not NULL, so it tries to send *from* an empty address and parks the mail in `alert_queued_mail` with `reason_cd 1060` — whose description is **"Email system down."** That reads like an infrastructure outage. It is not.
- `alert_recipient.record_type_cd` = **1059** ("Email Recipient") and is **NOT NULL**. Omitting it fails the INSERT.
- `recipient_type_cd`: `1281` = To, `1282` = CC, `1283` = BCC.
- **Recipients can be tokens.** `<taker_email>`, `<primary_salesrep_email>` (any `available_areas = 80` token) resolve per order. That is how "Order Taker" and "Sales Rep" get on an alert.
- **A missing recipient does NOT kill the alert.** `p21_fn_validate_email_address` returns `<email_not_found/>`, and `p21_sp_alert_generation` strips it and still sends to everyone else — but it *also* fires a bogus `<email_not_found/>` message into `alert_queued_mail` each time. Beware of designs that rely on a deliberately-blank recipient: they work, but they permanently pollute the queue.
- **None of these tables have identity columns.** Supply `MAX(uid) + 1` yourself. **uids do NOT align across environments — match on name, never uid.**
- **Filters are ANDed.** The grid cannot express an OR. To trigger on `A < 5 OR B < 5`, precompute a flag column in the view (`CASE WHEN ... THEN 'Y' ELSE 'N' END`) and filter on that.

**Verify without sending mail** — two checks that catch nearly everything:

```sql
-- 1. does the where_clause actually run?  (proves every token resolves to a column)
EXEC sp_executesql N'SELECT COUNT(*) FROM dbo.p21_view_alert_oe_OrderEntry WHERE <where_clause>'

-- 2. does every <token> in subject/header/line_item/footer exist as a view column?
--    an unresolved token renders as LITERAL TEXT in the email, silently.
```

`pending_alerts` is empty except in the instant an order is saved, so the view normally returns 0 rows. That is expected — you are testing that it *parses*, not that it returns data.

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

`available_areas` is a **bitmask**. It controls where a token may be used — and, critically, **whether it will actually render** in a given section of the email. A token used in a section whose bit it does not carry comes out as **literal text** (`<sales_location_id>`) in the sent email, with no error anywhere.

**Treat it as bits, not as a menu of magic numbers:**

| Bit | Meaning |
|---|---|
| `4` | Line item body (per-line data) |
| `11` (= 8+2+1) | **Order header** |
| `32` | Event / order level — **this is what alert FILTERS read** |
| `80` | Email routing (a token that resolves to an *address*) |
| `256` | User lookup |

Common combinations:

| Value | = | Meaning | Example tokens |
|---|---|---|---|
| `4` | 4 | line item body only | item_description, unit_price, order_quantity |
| `11` | 8+2+1 | header only | customer_name, total_line_items |
| `32` | 32 | event only (filterable, **NOT renderable in the header**) | new_order, will_call |
| `36` | 32+4 | event + line item body | item_id, line_item_profit_percentage |
| `43` | 32+11 | event + header | total_amount, customer_id, sales_location_id |
| `139` | 128+11 | header (+128) | primary_salesrep_name |
| `171` | 128+32+11 | event + header (+128) | taker |

**Rules of thumb**
- To **render in the header**, the token MUST carry bit `11`. Verified live 2026-07-14: `customer_name` (11), `customer_id` (43), `primary_salesrep_name` (139) and `taker` (171) all rendered; `sales_location_id` (32) and `source_location_id` (32) rendered as **literal text** until repointed to `43`.
- To be usable as an alert **filter**, the token must carry bit `32`.
- To be a **recipient**, use `80` (see `taker_email`, `primary_salesrep_email`).

⚠ **Token names are NOT unique.** `source_location_id` exists twice — uid `236` (Order Entry) and uid `103` (inv_TransferEntry / inv_OrderBasedTransferUpdate). **Never** `UPDATE token ... WHERE name = '...'`; always scope through `alert_type_x_token` to the alert type you mean, or target `token_uid`.

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

> **CORRECTED 2026-07-14.** This table previously said `851 = decimal`. **It does not.** The wrong value is how `extended_standard_cost` came to be registered as a `char` in March (SA 37384) — it holds a `DECIMAL(19,2)`. Values below are read from `code_p21`, not from memory.

| Value | Meaning |
|---|---|
| `850` | varchar |
| `851` | **char** |
| `852` | int |
| `853` | **decimal** |
| `854` | datetime |

```sql
SELECT code_no, code_description FROM code_p21 WHERE code_no BETWEEN 850 AND 854
```

*Footnote on `extended_standard_cost`:* the mistyping generates `... AND extended_standard_cost > '500'` (quoted) in the alert's `where_clause`. It still compares **numerically** — SQL Server's data-type precedence converts the varchar literal to decimal — so the live filter is **not** broken. It is fragile, not wrong. Do not "fix" it without testing.

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

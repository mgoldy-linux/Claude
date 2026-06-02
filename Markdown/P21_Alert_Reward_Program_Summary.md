# P21 Alert Customization
## New Order Alert: Extended Reward / Missing Reward Program ID
March 24, 2026

---

# Overview

This document summarizes the customization work performed on the Prophet 21 (P21) ERP system to add a new Order Entry alert that fires when an order line has an Extended Reward value but is missing a Reward Program ID. The goal was to catch lines where a reward was calculated but no reward program was assigned.

**Alert Condition:**
- Extended Reward > 0
- Reward Program ID = *(blank)*

---

# Step 1: Identify the Alert Type UID

Queried the `alert_type` table joined to `code_p21` to confirm the correct `alert_type_uid`:

```sql
SELECT at.alert_type_uid, at.view_name, sc.code_description
FROM alert_type at
INNER JOIN code_p21 sc ON sc.code_no = at.type_cd
WHERE at.view_name = 'oe_OrderEntry'
```

| alert_type_uid | view_name | code_description |
|---|---|---|
| 12 | oe_OrderEntry | Order Entry / Front Counter |
| 15 | oe_OrderEntry | RMA Entry |

The correct `alert_type_uid` for the Order Entry alert is **12**.

---

# Step 2: Locate Source Columns

Confirmed that `extended_reward` and `reward_program_id` exist in `oe_line_ud` (not `invoice_line_ud`, since this is an order entry alert):

```sql
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME IN ('extended_reward', 'reward_program_id')
  AND TABLE_NAME NOT LIKE '%view%'
ORDER BY TABLE_NAME
```

| TABLE_NAME | COLUMN_NAME |
|---|---|
| invoice_line_ud | extended_reward |
| invoice_line_ud | reward_program_id |
| oe_line_ud | extended_reward |
| oe_line_ud | reward_program_id |

`oe_line_ud` joins to `oe_line` on `order_no` and `line_no` (no `oe_line_uid` column exists on this table).

---

# Step 3: Modify the Alert View

`oe_line_ud` was not joined in `p21_view_alert_oe_OrderEntry`. Two changes were made:

**Added columns to SELECT** (before FROM clause):

```sql
-- mg add for reward alert
,CAST(COALESCE(oe_line_ud.extended_reward, 0) AS DECIMAL(19,2)) 'extended_reward'
,COALESCE(oe_line_ud.reward_program_id, '')                      'reward_program_id'
```

**Added JOIN** (after `restricted_class` LEFT JOIN):

```sql
-- mg add for reward alert
LEFT JOIN oe_line_ud ON oe_line_ud.order_no = oe_line.order_no
                    AND oe_line_ud.line_no   = oe_line.line_no
```

Full view script saved to: `C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents\SQL Server Management Studio\Views\alter_view_p21_view_alert_oe_OrderEntry_reward.sql`

> Note: `CREATE OR ALTER VIEW` preserves all existing view permissions — no re-grant needed.

---

# Step 4: Register the Tokens

Confirmed correct `available_areas` and `data_type_cd` by querying existing tokens on alert type 12:

```sql
SELECT TOP 5 t.name, t.available_areas, t.data_type_cd
FROM token t
INNER JOIN alert_type_x_token atx ON atx.token_uid = t.token_uid
WHERE atx.alert_type_uid = 12
ORDER BY t.token_uid DESC
```
-- results
name	available_areas	data_type_cd
extended_standard_cost	32	851
restricted_class_description	4	850
restricted_class_id	36	850
exp_in_stock_date_days_after_prom_date	42	851
exp_delivery_date_days_after_prom_date	42	851

Registered both tokens using `p21_apply_alert_token`:

```sql
-- Token 1: extended_reward (numeric)
EXEC [dbo].[p21_apply_alert_token]
    @alert_type_uid        = 12,
    @token_name            = N'extended_reward',
    @token_available_areas = 32,
    @token_description     = N'Extended Reward',
    @token_data_type_cd    = 851,
    @token_code_group_no   = null

-- Token 2: reward_program_id (string)
EXEC [dbo].[p21_apply_alert_token]
    @alert_type_uid        = 12,
    @token_name            = N'reward_program_id',
    @token_available_areas = 32,
    @token_description     = N'Reward Program ID',
    @token_data_type_cd    = 850,
    @token_code_group_no   = null
```

Manually updated descriptions since the proc overrides `@token_description` with the column formula:

```sql
UPDATE token SET description = 'Extended Reward'   WHERE name = 'extended_reward'
UPDATE token SET description = 'Reward Program ID' WHERE name = 'reward_program_id'
```

---

# Step 5: Fix available_areas

Tokens were initially registered with `available_areas = 32` (email body only) and did not appear in the filter token selection UI. Updated to `36` (32 + 4) to include filter conditions:

```sql
UPDATE token
SET available_areas = 36
WHERE name IN ('extended_reward', 'reward_program_id')
```

![Token not visible in filter list](C:/Claude/Missing-Extended-Reward.png)

After update, both tokens appeared correctly in the Select Tokens filter list.

---

# Final Result

Alert filters configured:

| Column | Operator | Value |
|---|---|---|
| Extended Reward | is greater than | 0 |
| Reward Program ID | equals | *(blank)* |

---

# Key Notes & Lessons Learned

- `oe_line_ud` joins to `oe_line` on `order_no` + `line_no`, not `oe_line_uid` — the UD table does not have that column.
- `p21_apply_alert_token` overrides `@token_description` with the view column formula. Always update the description manually after registration.
- `available_areas = 32` registers the token for email body only. Use `available_areas = 36` to also include filter conditions.
- `data_type_cd 850` = string/varchar, `data_type_cd 851` = numeric.
- Always test all changes in the Play/Dev database before applying to production.

---

# Files Changed

| Object | Change |
|---|---|
| dbo.p21_view_alert_oe_OrderEntry | Added `extended_reward` and `reward_program_id` columns; added LEFT JOIN to `oe_line_ud` |
| dbo.token | Registered new tokens `extended_reward` (token_uid 734) and `reward_program_id` (token_uid 735) |
| dbo.alert_type_x_token | Linked tokens 734 and 735 to alert_type_uid 12 |

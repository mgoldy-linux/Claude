# Requirements Document: Automated Sales Location Update & Message Suppression (P21)

## Target Roles

This requirement applies to the following P21 roles:

- All
- Customer Service
- Customer Service Management
- Outside Sales
- Sales Management

---

## Business Problem

### Current Logic & Issue

When a user enters a **Ship-To ID**, a business rule automatically updates the **Sales Location** to the Ship-To Default Branch.

**The Bug:** In the desktop version, if a message displays during this event in Order Entry, the interface breaks. Users become unable to select or toggle between different tabs, halting the workflow.

---

## Proposed Solution

To bypass the UI lock while preserving data integrity, the following business rules are implemented:

1. **Suppress UI Messages:** Business rule `asi_oe_suppress_oe_msgs` suppresses standard P21 system message boxes in Order Entry.
2. **Delayed Message Display:** Business rule `asi_oe_order_sales_loc_id_up` displays the suppressed warnings only after the Sales Location update is finalized, avoiding the UI lock.
3. **Front Counter Restoration:** Because message suppression is a global P21 setting, warnings must be restored specifically for Front Counter to ensure counter-specific alerts remain active:
   - `asi_fc_restore_msg_ship_to_id` — triggers when the user starts with **Ship-To ID**
   - `asi_fc_restore_msg_cust_id` — triggers when the user starts with **Customer ID**

---

## Overview

This document covers four P21 business rules that work together to implement the solution above.

---

## Business Rules Summary

| Rule | Module | Trigger | Purpose |
|---|---|---|---|
| `asi_oe_order_sales_loc_id_up` | Order Entry | `ship_to_id` field change | Auto-sets sales location; warns on overdue invoices, missing contacts, and multiple contracts |
| `asi_oe_suppress_oe_msgs` | Order Entry | Message Box Opening | Suppresses warning messages 451, 688, and 8280 globally |
| `asi_fc_restore_msg_ship_to_id` | Front Counter | `ship_to_id` field change | Re-displays warnings when ship_to_id is entered |
| `asi_fc_restore_msg_cust_id` | Front Counter | `customer_id` field change | Re-displays warnings when customer_id is entered |

---

## How the Rules Work Together

```
User enters order in Order Entry
    ├── User enters ship_to_id
    │       └── asi_oe_order_sales_loc_id_up fires
    │               ├── Sets sales_loc_id from ship-to default branch
    │               └── Displays overdue invoice, contacts, and contracts warnings
    │
    └── System raises message box 451, 688, or 8280
            └── asi_oe_suppress_oe_msgs fires → message suppressed (no interruption)

User enters order in Front Counter
    ├── User types ship_to_id
    │       └── asi_fc_restore_msg_ship_to_id fires → warnings displayed
    └── User types customer_id (ship_to_id auto-populates)
            └── asi_fc_restore_msg_cust_id fires → warnings displayed
```

> **Note:** `asi_oe_order_sales_loc_id_up` displays warnings through the business rule result message, which is separate from the P21 system message boxes suppressed by `asi_oe_suppress_oe_msgs`. Both mechanisms can fire independently.

> **Note:** When a user enters `customer_id` in Front Counter, P21 automatically populates `ship_to_id`. Because this auto-population is programmatic, it does not fire the `ship_to_id` trigger. This is why two separate Front Counter rules are required.

---

## Rule 1: `asi_oe_order_sales_loc_id_up`

### Purpose
Automatically sets the sales location from the ship-to default branch when `ship_to_id` is entered in Order Entry. Also warns the user of overdue invoices, missing contacts, and multiple contracts.

### Trigger
- **Module:** Order Entry
- **Event:** `ship_to_id` field change

### Behavior

| Action | Description |
|---|---|
| Set sales location | Looks up `default_branch` from the `ship_to` table and sets `sales_loc_id` |
| Overdue invoice warning | Displays warning if customer has unpaid invoices > 20 days past due |
| No contacts warning | Displays warning if no active contacts exist for the customer |
| Multiple contracts warning | Displays warning if more than one active contract matches the customer and ship-to |

If multiple warning conditions are true, all applicable messages are displayed together.

---

## Rule 2: `asi_oe_suppress_oe_msgs`

### Purpose
Prevents P21 system warning message boxes from interrupting automated business rule processing in Order Entry.

### Trigger
- **Module:** Any P21 module
- **Event:** Message Box Opening for messages 451, 688, or 8280

### Behavior

| Message No | Message Text | Action |
|---|---|---|
| 451 | No contacts exist for this customer. | Suppressed |
| 688 | This customer has overdue invoices. This order will be placed on credit hold. | Suppressed |
| 8280 | Multiple contracts found for Customer ID and Ship To ID combination. Please, select a Contract No. | Suppressed |

All other message numbers are passed through without modification.

---

## Rule 3: `asi_fc_restore_msg_ship_to_id`

### Purpose
Displays overdue invoice, missing contacts, and multiple contract warnings in Front Counter when a user enters a `ship_to_id`. Restores visibility of warnings suppressed globally by `asi_oe_suppress_oe_msgs`.

### Trigger
- **Module:** Front Counter
- **Event:** `ship_to_id` field change

### Behavior
When `ship_to_id` is entered, the rule looks up `customer_id` from the `ship_to` table and runs the following checks:

| Check | Condition | Message Displayed |
|---|---|---|
| Overdue invoices | Customer has unpaid invoices > 20 days past due | This customer has overdue invoices. This order will be placed on credit hold. |
| No contacts | No active contacts exist for the customer | No contacts exist for this customer. |
| Multiple contracts | More than one active contract matches the customer and ship-to | Multiple contracts found for Customer ID and Ship To ID combination. Please, select a Contract No. |

If multiple conditions are true, all applicable messages are displayed together.

---

## Rule 4: `asi_fc_restore_msg_cust_id`

### Purpose
Displays overdue invoice and missing contacts warnings in Front Counter when a user enters a `customer_id`. Companion rule to `asi_fc_restore_msg_ship_to_id` to handle the case where entering `customer_id` auto-populates `ship_to_id` programmatically and does not fire the `ship_to_id` trigger.

### Trigger
- **Module:** Front Counter
- **Event:** `customer_id` field change

### Behavior
When `customer_id` is entered, the rule reads `customer_id` directly from the form and runs the following checks:

| Check | Condition | Message Displayed |
|---|---|---|
| Overdue invoices | Customer has unpaid invoices > 20 days past due | This customer has overdue invoices. This order will be placed on credit hold. |
| No contacts | No active contacts exist for the customer | No contacts exist for this customer. |

> **Note:** The multiple contracts check (8280) is not included in this rule because `ship_to_id` is required for that check and may not be reliably available at the time `customer_id` fires. The contracts check is fully covered by `asi_fc_restore_msg_ship_to_id`.

---

## Testing & Verification

### Prerequisites
- All four rules are deployed and active in P21
- Tester has access to run SQL queries against the P21 database
- Tester has access to Order Entry and Front Counter modules
- All tests must be performed on both the **desktop** and **web** versions of P21
- Use userid **island2** for all testing
- Testing must be completed under each of the following roles assigned to island2:

| Role | Required |
|---|---|
| All | Yes |
| Customer Service | Yes |
| Customer Service Management | Yes |
| Outside Sales | Yes |
| Sales Management | Yes |
| Branch Manager | Yes |
| Warehouse | Yes |

> Each test scenario below must be repeated for every role listed above, on both desktop and web.

---

### Step 1: Find Test Customers Using SQL Queries

Run the queries below in the P21 database to identify customers and ship-to IDs for each test scenario. Each query returns up to 5 random results.

---

#### Find customers with no contacts (message 451)

```sql
SELECT TOP 5
    st.ship_to_id,
    st.customer_id,
    c.customer_name
FROM ship_to st
INNER JOIN customer c
    ON c.customer_id = st.customer_id
   AND c.delete_flag = 'N'
WHERE st.delete_flag = 'N'
  AND NOT EXISTS (
      SELECT 1
      FROM oe_contacts_customer occ
      INNER JOIN contacts con
          ON occ.contact_id = con.id
         AND con.delete_flag <> 'Y'
      WHERE occ.company_id  = 1
        AND occ.customer_id = st.customer_id
        AND occ.delete_flag <> 'Y'
  )
ORDER BY NEWID();
```

---

#### Find customers with overdue invoices (message 688)

```sql
SELECT TOP 5
    st.ship_to_id,
    st.customer_id,
    c.customer_name
FROM ship_to st
INNER JOIN customer c
    ON c.customer_id = st.customer_id
   AND c.delete_flag = 'N'
WHERE st.delete_flag = 'N'
  AND EXISTS (
      SELECT 1
      FROM p21_view_invoice_hdr inv
      WHERE inv.customer_id      = st.customer_id
        AND inv.company_no       = 1
        AND inv.approved         = 'Y'
        AND inv.paid_in_full_flag = 'N'
        AND inv.consolidated     <> 'Y'
        AND COALESCE(inv.record_type_cd, 0) <> 3023
        AND DATEDIFF(dd, inv.net_due_date, CURRENT_TIMESTAMP) > 20
        AND inv.disputed_flag    = 'N'
        AND (inv.total_amount - inv.amount_paid - inv.terms_taken - inv.allowed
             + inv.memo_amount + inv.bad_debt_amount - inv.tax_terms_taken) > 0
  )
ORDER BY NEWID();
```

---

#### Find customers with multiple contracts (message 8280)

```sql
SELECT TOP 5
    jpcs.ship_to_id,
    jpcs.customer_id,
    cust.customer_name,
    COUNT(*) AS contract_count
FROM job_price_hdr jph
INNER JOIN job_price_customer_shipto jpcs
    ON jpcs.job_price_hdr_uid = jph.job_price_hdr_uid
INNER JOIN customer cust
    ON cust.customer_id = jpcs.customer_id
   AND cust.delete_flag = 'N'
INNER JOIN ship_to st
    ON st.ship_to_id    = jpcs.ship_to_id
   AND st.delete_flag   = 'N'
WHERE EXISTS (
    SELECT 1
    FROM job_price_line jpl
    INNER JOIN customer c
        ON c.customer_id = jpcs.customer_id
       AND c.company_id  = '1'
    WHERE jpl.job_price_hdr_uid = jph.job_price_hdr_uid
      AND ((jpl.qty_ordered < jpl.qty_maximum)
        OR (jpl.qty_maximum = 0)
        OR (c.allow_exceed_job_qty = 'Y'))
)
AND jph.company_id                  = '1'
AND jpcs.row_status_flag            = 704
AND jph.row_status_flag             = 704
AND jph.cancelled                   <> 'Y'
AND jph.approved                    <> 'N'
AND jph.start_date                  <= GETDATE()
AND jph.end_date                    >= GETDATE()
GROUP BY jpcs.ship_to_id, jpcs.customer_id, cust.customer_name
HAVING COUNT(*) > 1
ORDER BY NEWID();
```

---

#### Find customers with no contacts AND overdue invoices (messages 451 + 688)

```sql
SELECT TOP 5
    st.ship_to_id,
    st.customer_id,
    c.customer_name
FROM ship_to st
INNER JOIN customer c
    ON c.customer_id = st.customer_id
   AND c.delete_flag = 'N'
WHERE st.delete_flag = 'N'
  AND NOT EXISTS (
      SELECT 1
      FROM oe_contacts_customer occ
      INNER JOIN contacts con
          ON occ.contact_id = con.id
         AND con.delete_flag <> 'Y'
      WHERE occ.company_id  = 1
        AND occ.customer_id = st.customer_id
        AND occ.delete_flag <> 'Y'
  )
  AND EXISTS (
      SELECT 1
      FROM p21_view_invoice_hdr inv
      WHERE inv.customer_id       = st.customer_id
        AND inv.company_no        = 1
        AND inv.approved          = 'Y'
        AND inv.paid_in_full_flag = 'N'
        AND inv.consolidated      <> 'Y'
        AND COALESCE(inv.record_type_cd, 0) <> 3023
        AND DATEDIFF(dd, inv.net_due_date, CURRENT_TIMESTAMP) > 20
        AND inv.disputed_flag     = 'N'
        AND (inv.total_amount - inv.amount_paid - inv.terms_taken - inv.allowed
             + inv.memo_amount + inv.bad_debt_amount - inv.tax_terms_taken) > 0
  )
ORDER BY NEWID();
```

---

#### Find customers with no contacts AND multiple contracts (messages 451 + 8280)

```sql
SELECT TOP 5
    st.ship_to_id,
    st.customer_id,
    c.customer_name
FROM ship_to st
INNER JOIN customer c
    ON c.customer_id = st.customer_id
   AND c.delete_flag = 'N'
WHERE st.delete_flag = 'N'
  AND NOT EXISTS (
      SELECT 1
      FROM oe_contacts_customer occ
      INNER JOIN contacts con
          ON occ.contact_id = con.id
         AND con.delete_flag <> 'Y'
      WHERE occ.company_id  = 1
        AND occ.customer_id = st.customer_id
        AND occ.delete_flag <> 'Y'
  )
  AND (
      SELECT COUNT(*)
      FROM job_price_hdr jph
      INNER JOIN job_price_customer_shipto jpcs
          ON jpcs.job_price_hdr_uid = jph.job_price_hdr_uid
      WHERE EXISTS (
          SELECT 1
          FROM job_price_line jpl
          INNER JOIN customer ci
              ON ci.customer_id = jpcs.customer_id
             AND ci.company_id  = '1'
          WHERE jpl.job_price_hdr_uid = jph.job_price_hdr_uid
            AND ((jpl.qty_ordered < jpl.qty_maximum)
              OR (jpl.qty_maximum = 0)
              OR (ci.allow_exceed_job_qty = 'Y'))
      )
      AND jph.company_id                = '1'
      AND jpcs.customer_id              = st.customer_id
      AND jpcs.ship_to_id               = st.ship_to_id
      AND jpcs.row_status_flag          = 704
      AND jph.row_status_flag           = 704
      AND jph.cancelled                 <> 'Y'
      AND jph.approved                  <> 'N'
      AND jph.start_date                <= GETDATE()
      AND jph.end_date                  >= GETDATE()
  ) > 1
ORDER BY NEWID();
```

---

#### Find customers with overdue invoices AND multiple contracts (messages 688 + 8280)

```sql
SELECT TOP 5
    st.ship_to_id,
    st.customer_id,
    c.customer_name
FROM ship_to st
INNER JOIN customer c
    ON c.customer_id = st.customer_id
   AND c.delete_flag = 'N'
WHERE st.delete_flag = 'N'
  AND EXISTS (
      SELECT 1
      FROM p21_view_invoice_hdr inv
      WHERE inv.customer_id       = st.customer_id
        AND inv.company_no        = 1
        AND inv.approved          = 'Y'
        AND inv.paid_in_full_flag = 'N'
        AND inv.consolidated      <> 'Y'
        AND COALESCE(inv.record_type_cd, 0) <> 3023
        AND DATEDIFF(dd, inv.net_due_date, CURRENT_TIMESTAMP) > 20
        AND inv.disputed_flag     = 'N'
        AND (inv.total_amount - inv.amount_paid - inv.terms_taken - inv.allowed
             + inv.memo_amount + inv.bad_debt_amount - inv.tax_terms_taken) > 0
  )
  AND (
      SELECT COUNT(*)
      FROM job_price_hdr jph
      INNER JOIN job_price_customer_shipto jpcs
          ON jpcs.job_price_hdr_uid = jph.job_price_hdr_uid
      WHERE EXISTS (
          SELECT 1
          FROM job_price_line jpl
          INNER JOIN customer ci
              ON ci.customer_id = jpcs.customer_id
             AND ci.company_id  = '1'
          WHERE jpl.job_price_hdr_uid = jph.job_price_hdr_uid
            AND ((jpl.qty_ordered < jpl.qty_maximum)
              OR (jpl.qty_maximum = 0)
              OR (ci.allow_exceed_job_qty = 'Y'))
      )
      AND jph.company_id                = '1'
      AND jpcs.customer_id              = st.customer_id
      AND jpcs.ship_to_id               = st.ship_to_id
      AND jpcs.row_status_flag          = 704
      AND jph.row_status_flag           = 704
      AND jph.cancelled                 <> 'Y'
      AND jph.approved                  <> 'N'
      AND jph.start_date                <= GETDATE()
      AND jph.end_date                  >= GETDATE()
  ) > 1
ORDER BY NEWID();
```

---

#### Find customers with all 3 conditions (messages 451 + 688 + 8280)

```sql
SELECT TOP 5
    st.ship_to_id,
    st.customer_id,
    c.customer_name
FROM ship_to st
INNER JOIN customer c
    ON c.customer_id = st.customer_id
   AND c.delete_flag = 'N'
WHERE st.delete_flag = 'N'
  AND NOT EXISTS (
      SELECT 1
      FROM oe_contacts_customer occ
      INNER JOIN contacts con
          ON occ.contact_id = con.id
         AND con.delete_flag <> 'Y'
      WHERE occ.company_id  = 1
        AND occ.customer_id = st.customer_id
        AND occ.delete_flag <> 'Y'
  )
  AND EXISTS (
      SELECT 1
      FROM p21_view_invoice_hdr inv
      WHERE inv.customer_id       = st.customer_id
        AND inv.company_no        = 1
        AND inv.approved          = 'Y'
        AND inv.paid_in_full_flag = 'N'
        AND inv.consolidated      <> 'Y'
        AND COALESCE(inv.record_type_cd, 0) <> 3023
        AND DATEDIFF(dd, inv.net_due_date, CURRENT_TIMESTAMP) > 20
        AND inv.disputed_flag     = 'N'
        AND (inv.total_amount - inv.amount_paid - inv.terms_taken - inv.allowed
             + inv.memo_amount + inv.bad_debt_amount - inv.tax_terms_taken) > 0
  )
  AND (
      SELECT COUNT(*)
      FROM job_price_hdr jph
      INNER JOIN job_price_customer_shipto jpcs
          ON jpcs.job_price_hdr_uid = jph.job_price_hdr_uid
      WHERE EXISTS (
          SELECT 1
          FROM job_price_line jpl
          INNER JOIN customer ci
              ON ci.customer_id = jpcs.customer_id
             AND ci.company_id  = '1'
          WHERE jpl.job_price_hdr_uid = jph.job_price_hdr_uid
            AND ((jpl.qty_ordered < jpl.qty_maximum)
              OR (jpl.qty_maximum = 0)
              OR (ci.allow_exceed_job_qty = 'Y'))
      )
      AND jph.company_id                = '1'
      AND jpcs.customer_id              = st.customer_id
      AND jpcs.ship_to_id               = st.ship_to_id
      AND jpcs.row_status_flag          = 704
      AND jph.row_status_flag           = 704
      AND jph.cancelled                 <> 'Y'
      AND jph.approved                  <> 'N'
      AND jph.start_date                <= GETDATE()
      AND jph.end_date                  >= GETDATE()
  ) > 1
ORDER BY NEWID();
```

---

### Step 2: Test Scenarios

Use the customer and ship-to IDs returned from the SQL queries above to perform the following tests.

---

#### Test 1: Order Entry — Sales location is set and warnings display

**Rule:** `asi_oe_order_sales_loc_id_up`

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Order Entry | |
| 2 | Enter a `ship_to_id` from the overdue invoices query | `sales_loc_id` is populated; message: *This customer has overdue invoices. This order will be placed on credit hold.* |
| 3 | Enter a `ship_to_id` from the no-contacts query | `sales_loc_id` is populated; message: *No contacts exist for this customer.* |
| 4 | Enter a `ship_to_id` from the multiple contracts query | `sales_loc_id` is populated; message: *Multiple contracts found for Customer ID and Ship To ID combination. Please, select a Contract No.* |
| 5 | Enter a `ship_to_id` from the all 3 conditions query | `sales_loc_id` is populated; all three messages display together |

**Pass criteria:** `sales_loc_id` is auto-populated and correct warning message(s) display for each ship_to_id entered.

---

#### Test 2: Order Entry — System message boxes are suppressed

**Rule:** `asi_oe_suppress_oe_msgs`

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Order Entry | |
| 2 | Enter a `ship_to_id` from the no-contacts query (message 451) | No P21 system message box appears |
| 3 | Enter a `ship_to_id` from the overdue invoices query (message 688) | No P21 system message box appears |
| 4 | Enter a `ship_to_id` from the multiple contracts query (message 8280) | No P21 system message box appears |

**Pass criteria:** No P21 system message boxes are displayed in Order Entry for any of the three conditions.

---

#### Test 3: Front Counter — Warnings display when ship_to_id is entered

**Rule:** `asi_fc_restore_msg_ship_to_id`

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Front Counter | |
| 2 | Enter a `ship_to_id` from the no-contacts query | Message: *No contacts exist for this customer.* |
| 3 | Enter a `ship_to_id` from the overdue invoices query | Message: *This customer has overdue invoices. This order will be placed on credit hold.* |
| 4 | Enter a `ship_to_id` from the multiple contracts query | Message: *Multiple contracts found for Customer ID and Ship To ID combination. Please, select a Contract No.* |
| 5 | Enter a `ship_to_id` from the 451 + 688 combination query | Both messages display together |
| 6 | Enter a `ship_to_id` from the 451 + 8280 combination query | Both messages display together |
| 7 | Enter a `ship_to_id` from the 688 + 8280 combination query | Both messages display together |
| 8 | Enter a `ship_to_id` from the all 3 conditions query | All three messages display together |

**Pass criteria:** Correct warning message(s) display for each ship_to_id entered.

---

#### Test 4: Front Counter — Warnings display when customer_id is entered

**Rule:** `asi_fc_restore_msg_cust_id`

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Front Counter | |
| 2 | Enter a `customer_id` from the no-contacts query | Message: *No contacts exist for this customer.* |
| 3 | Enter a `customer_id` from the overdue invoices query | Message: *This customer has overdue invoices. This order will be placed on credit hold.* |
| 4 | Enter a `customer_id` from the 451 + 688 combination query | Both messages display together |

**Pass criteria:** Correct warning message(s) display for each customer_id entered.

> **Note:** The multiple contracts warning (8280) is not expected when entering `customer_id` — it is only checked by `asi_fc_restore_msg_ship_to_id`.

---

#### Test 5: Front Counter — Both workflow paths produce warnings

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open Front Counter | |
| 2 | Enter `ship_to_id` directly for a customer with overdue invoices | Warning displays |
| 3 | Open a new Front Counter order | |
| 4 | Enter `customer_id` for the same customer (ship_to_id auto-populates) | Warning displays |

**Pass criteria:** Warning message appears in both entry workflows.

---

## Out of Scope

- These rules do not prevent the order from being saved
- `asi_oe_suppress_oe_msgs` suppresses messages globally — it applies to all Order Entry windows
- The multiple contracts check in `asi_fc_restore_msg_cust_id` is intentionally excluded as `ship_to_id` is not reliably available when `customer_id` fires
- `asi_oe_order_sales_loc_id_up` does not run in Front Counter — sales location is managed by P21 in that module

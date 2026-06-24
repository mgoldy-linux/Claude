# Test Plan — kb_Order_Validator_v2 assembly (ver 1.0.1.0)

**Purpose:** Confirm the kb_SQLHelper retirement + version bump (1.0.0.0 → 1.0.1.0) did
**not** change runtime behavior, and that error logging now lands in the native
`business_rule_log` table instead of `kb_table_br_error_log`.

**Assembly contains two rules:**
| Rule | Trigger | Calls | New connection | New error log run_type |
|------|---------|-------|----------------|------------------------|
| `kb_Order_Validator_v2` | Order **before save** (sync, can block save) | `dbo.kb_fnt_br_order_validator_v2` + Atlas surcharge | `P21SqlConnection` (framework, open) | `Synchronous (Internal)` |
| `kb_Order_Workflow_v2` | Order **after save** (async, cannot block) | `dbo.kb_proc_br_oe_hdr_note` | `ResolveConnection()` → `P21SqlConnection`, else Session fallback | `Asynchronous (Internal)` |

**Environment:** Run all cases in **P21Play** first (P21Dev.allsurfaces.com). Do NOT test in
Prod. Confirm the deployed DLL reports **File version 1.0.1.0** (right-click the DLL on the
middleware → Details) before starting.

---

## Pre-test verification queries

Run these against the **same** environment's database. Keep an SSMS tab open.

```sql
-- (A) Confirm both rules are registered/enabled. NOTE: business_rule has NO
-- assembly-name or version column, and its class_name column is the bound
-- DATAWINDOW (e.g. d_oe_header), not the .NET class -- so look up by rule_name.
-- row_status_flag: 704 = active/enabled, 705 = inactive/retired. The assembly
-- version (1.0.1.0) lives ONLY as a FILE property of the DLL on the middleware
-- (right-click DLL -> Details -> File version).
SELECT rule_name, class_name AS bound_datawindow, apply_during_save_flag,
       row_status_flag, run_type_cd, internal_rule_flag, date_last_modified
FROM   business_rule
WHERE  rule_name IN ('kb_Order_Validator_v2','kb_Order_Workflow_v2')
ORDER BY rule_name;

-- (B) Watch for new error-log rows from BOTH rules (re-run after each case)
SELECT TOP 50 date_created, rule_name, run_type, return_value,
       LEFT(return_message, 200) AS msg, user_id
FROM   business_rule_log
WHERE  rule_name IN ('kb_Order_Validator_v2','kb_Order_Workflow_v2')
  AND  log_action = 'Error'
ORDER BY date_created DESC;

-- (C) Confirm header notes the workflow rule writes (per order under test)
SELECT topic, note, date_created
FROM   oe_hdr_notepad         -- or notepad/note table per kb_proc_br_oe_hdr_note
WHERE  order_no = '<ORDER#>'
ORDER BY date_created DESC;
```

---

## A. kb_Order_Validator_v2 (before-save validator)

### A1 — Happy path, validation passes
- **Setup:** Standard order, valid customer in good credit standing, ≥1 stock line with
  qty ordered > 0, not complete, not a bundle (`product_type <> 'B'`).
- **Action:** Open a candidate order (finder below) and Save.
- **Expected:** Saves with **no** blocking message. Query (B) shows **no** new error row.
- **Proves:** `P21SqlConnection` swap works for the `kb_fnt_br_order_validator_v2` call path.
- **Bonus:** Re-saving also fires the async workflow rule (`kb_proc_br_oe_hdr_note`), so A1
  doubles as coverage for **B1**.

```sql
-- A1 FINDER: existing open orders that satisfy the happy-path setup.
-- Guarantees the validator will RUN (>=1 open line, num2>0) and the customer is not
-- credit-blocked. It can't guarantee kb_fnt_br_order_validator_v2 returns success
-- (needs the live DataSet payload), but a recent cleanly-saved order is a safe bet.
-- NOTE: bundle lines (product_type 'B') can't be filtered -- product_type is derived
-- from the item, not stored on oe_line. Single-line orders sidestep this.
-- Prefer a SAME-DAY order to minimize re-pricing side effects on re-save.
SELECT TOP 20
       h.order_no, h.order_date, h.customer_id, cu.customer_name, cu.credit_status,
       COUNT(*) AS open_qualifying_lines,
       SUM(l.qty_ordered - ISNULL(l.qty_canceled,0) - ISNULL(l.qty_invoiced,0)) AS total_open_qty
FROM   oe_hdr h
JOIN   customer cu ON cu.customer_id = h.customer_id
JOIN   oe_line  l  ON l.order_no = h.order_no
WHERE  ISNULL(h.rma_flag,'N')          <> 'Y'
  AND  ISNULL(h.warranty_rma_flag,'N') <> 'Y'
  AND  ISNULL(h.cancel_flag,'N')       <> 'Y'
  AND  ISNULL(h.completed,'N')         <> 'Y'
  AND  ISNULL(h.delete_flag,'N')       <> 'Y'
  AND  h.quote_type IS NULL                 -- exclude quotes (no literal 'quote' column)
  AND  cu.credit_status = 'NORMAL'          -- good standing; not BLOCK/HOLD/COD/PREPAY
  AND  ISNULL(l.complete,'N')          <> 'Y'   -- open line
  AND  ISNULL(l.delete_flag,'N')       <> 'Y'
  AND  ISNULL(l.cancel_flag,'N')       <> 'Y'
  AND  (l.qty_ordered - ISNULL(l.qty_canceled,0) - ISNULL(l.qty_invoiced,0)) > 0
GROUP BY h.order_no, h.order_date, h.customer_id, cu.customer_name, cu.credit_status
HAVING COUNT(*) >= 1
ORDER BY h.order_date DESC;   -- TIP: AND COUNT(*) = 1 in HAVING for the simplest single-line orders
```

### A2 — Validation fails (rule blocks save)
- **Setup:** Construct an order that `kb_fnt_br_order_validator_v2` rejects (i.e. returns
  `success_bool <> 'Y'` with a `result_message`). Use a known failing condition from the
  function's rules (e.g. missing required field the function checks).
- **Action:** Save.
- **Expected:** Save is **blocked**; the function's `result_message` is shown verbatim
  (un-escaped). No error row in (B) — this is a *validation* failure, not a *rule* error.
- **Proves:** Result/message plumbing unchanged after the connection swap.

### A3 — Skip conditions (rule returns success without calling SQL)
Run three sub-cases; **none** should call the function or block on validation:
- **A3a RMA:** header `rma_flag = 'Y'` → save proceeds, no validation.
- **A3b Quote:** `quote = 'Y'` → save proceeds.
- **A3c Cancelled:** `cancel_flag = 'Y'` → save proceeds.
- **Expected:** All save cleanly; no new (B) rows.

### A4 — No qualifying open lines (`num2 = 0`)
- **Setup:** Order where every line is complete (`oe_line_complete = 'Y'`) **or** a bundle
  (`product_type = 'B'`) **or** zero open qty.
- **Action:** Save.
- **Expected:** Function is **not** called (rule short-circuits on `num2 > 0`); save proceeds.

### A5 — Inbound fuel surcharge auto-toggle ON
- **Setup:** Order has ≥1 open line **and** an `INBOUND FUEL SURCHARGE` line with non-zero
  extended price; header `ufc_oe_hdr_ud_oe_surcharge` currently `'N'`.
- **Action:** Save.
- **Expected:** Header surcharge flag flips to `'Y'` (then function runs).

### A6 — Inbound fuel surcharge auto-toggle OFF
- **Setup:** ≥1 open line, **no** fuel-surcharge dollars (`num1 = 0`), header flag `'Y'`.
- **Action:** Save.
- **Expected:** Header surcharge flag flips to `'N'`.

### A7 — Atlas surcharge path
- **Setup:** Order where `kb_fnt_br_order_validator_v2` returns `atlas_surcharge_on = 'Y'`.
- **Action:** Save.
- **Expected:** Atlas `Surcharge.Validate` runs; if it returns a message it is shown
  (combined with the function message when both present); blocks save only if Atlas fails.
- **Proves:** Atlas dependency still wired after the rebuild.

### A8 — Error path lands in business_rule_log (KEY for this change)
- **Goal:** Force the catch block / "no data back" path so a row is written to
  `business_rule_log` with `run_type = 'Synchronous (Internal)'`.
- **Setup options (pick the safest available in Play):**
  - Temporarily rename/break `dbo.kb_fnt_br_order_validator_v2` so the SELECT throws, **or**
  - Make the function return zero rows for a test order (triggers the "Got no data back"
    branch).
- **Action:** Save a qualifying order (`num2 > 0`).
- **Expected:** User sees the generic *"…has been logged… contact ITSupport@allsurfaces.com"*
  message; **save is NOT hard-blocked** (rule returns Success on these internal errors).
  Query (B) shows a new row: `rule_name = 'kb_Order_Validator_v2'`,
  `run_type = 'Synchronous (Internal)'`, `return_value = 'Failure'`,
  `return_message` containing the subsection + exception text.
- **Cleanup:** Restore the function immediately.
- **Proves:** `LogRuleError` writes to `business_rule_log` (the retirement's main behavioral
  change). **Also confirm NO new rows appear in `kb_table_br_error_log`.**

---

## B. kb_Order_Workflow_v2 (after-save async note writer)

### B1 — Note creation happy path
- **Setup:** New non-RMA, non-quote, not-completed order (`oe_hdr_completed <> 'Y'`).
- **Action:** Save.
- **Expected:** After save completes, `dbo.kb_proc_br_oe_hdr_note` runs and header notes
  appear. Verify with query (C). No (B) error row.
- **Proves:** `ResolveConnection()` succeeds in the **async** context — **note which path it
  took** (see B4).
- **IMPORTANT — the proc is a no-op for most orders.** `kb_proc_br_oe_hdr_note` writes a
  "Freight Quote Required" note ONLY when ALL hold (proc lines 21–32):
  `kb_view_customer.credit_status IN ('COD','CASH','PREPAY')`, the order carrier ≠ the
  ship-to's default carrier, the carrier is not will-call, `freight_code_uid NOT IN
  (5,7,10,12)`, the freight charge item is zero/absent, and no mandatory freight note already
  exists. A `NORMAL`-credit order (the A1 finder) will run the proc but write nothing — fine
  to prove it runs, useless to compare note output. Use the **B1 FINDER** below to get an
  order that actually inserts a note.

```sql
-- B1 FINDER: existing orders where kb_proc_br_oe_hdr_note WOULD insert a new note.
-- Replicates the proc's exact preconditions. predicted_action tells you the branch:
--   'WOULD INSERT note'      -> clean trigger; best for B1 / the OLD-vs-NEW compare
--   'would CLEAR mandatory'  -> note already present + freight now non-zero
--   'no-op'                  -> nothing happens
-- (Bundles n/a here.) Run in Play.
;WITH oh AS (
    SELECT h.order_no, h.order_date, h.customer_id, h.address_id AS ship_to_id,
           h.carrier_id, h.freight_code_uid
    FROM   oe_hdr h
    WHERE  ISNULL(h.cancel_flag,'N')<>'Y' AND ISNULL(h.completed,'N')<>'Y'
      AND  ISNULL(h.delete_flag,'N')<>'Y' AND ISNULL(h.rma_flag,'N')<>'Y'
      AND  h.quote_type IS NULL
),
calc AS (
    SELECT oh.*, cu.credit_status,
        cust.name AS carrier_name, defc.name AS default_carrier,
        (SELECT TOP 1 ISNULL(will_call,'N') FROM kb_view_carrier WHERE name = cust.name) AS wc,
        CASE WHEN EXISTS (SELECT 1 FROM oe_line l JOIN inv_mast im ON im.inv_mast_uid=l.inv_mast_uid
                          WHERE l.order_no=oh.order_no AND l.delete_flag='N' AND im.delete_flag='N'
                            AND im.item_id IN ('FREIGHT CHARGE','UPS CHARGE','SPEEDEE CHARGE'))
             THEN 'Y' ELSE 'N' END AS freight_present,
        ISNULL((SELECT SUM(ISNULL(l.extended_price,0)) FROM oe_line l JOIN inv_mast im ON im.inv_mast_uid=l.inv_mast_uid
                WHERE l.order_no=oh.order_no AND l.delete_flag='N' AND im.delete_flag='N'
                  AND im.item_id IN ('FREIGHT CHARGE','UPS CHARGE','SPEEDEE CHARGE')),0) AS freight_amt,
        CASE WHEN (SELECT COUNT(note_id) FROM oe_hdr_notepad WHERE delete_flag='N' AND mandatory='Y'
                   AND order_no=oh.order_no AND topic='Freight Quote Required')>0 THEN 'Y' ELSE 'N' END AS note_present
    FROM oh
    JOIN kb_view_customer cu ON cu.customer_id = oh.customer_id
    LEFT JOIN kb_view_carrier cust ON cust.id = oh.carrier_id
    LEFT JOIN p21_view_ship_to st ON st.ship_to_id = oh.ship_to_id
    LEFT JOIN kb_view_carrier defc ON defc.id = st.default_carrier_id
)
SELECT TOP 20 order_no, order_date, customer_id, credit_status, carrier_name, default_carrier,
       wc, freight_code_uid, freight_present, freight_amt, note_present,
       CASE WHEN note_present='N' AND (freight_present='N' OR freight_amt=0) THEN 'WOULD INSERT note'
            WHEN note_present='Y' AND freight_present='Y' AND freight_amt<>0 THEN 'would CLEAR mandatory'
            ELSE 'no-op' END AS predicted_action
FROM calc
WHERE credit_status IN ('COD','CASH','PREPAY')
  AND carrier_name IS NOT NULL AND default_carrier IS NOT NULL AND carrier_name <> default_carrier
  AND wc = 'N' AND freight_code_uid NOT IN (5,7,10,12)
  AND note_present='N' AND (freight_present='N' OR freight_amt=0)
ORDER BY order_date DESC;
```

### B2 — Skip conditions (no note written)
- **B2a RMA:** `rma_flag = 'Y'` → ExecuteAsync returns early, no note, no proc call.
- **B2b Quote:** `quote = 'Y'` → no note.
- **B2c Completed:** `oe_hdr_completed = 'Y'` → no note.
- **Expected:** Query (C) shows no newly-added notes for these orders; no (B) error rows.

### B3 — Error path lands in business_rule_log (async)
- **Goal:** Force `kb_proc_br_oe_hdr_note` to throw (e.g. temporarily rename it in Play).
- **Action:** Save a qualifying order.
- **Expected:** **Order still saves fine** (async rule can't block). Query (B) shows a new
  row: `rule_name = 'kb_Order_Workflow_v2'`, `run_type = 'Asynchronous (Internal)'`,
  `return_value = 'Failure'`, message = *"Execution of dbo.kb_proc_br_oe_hdr_note for
  order# … failed."* + exception.
- **Cleanup:** Restore the proc.
- **Caveat:** If the async path fell back to a **Session-built** connection running as the
  end-user identity, the INSERT into `business_rule_log` could itself fail silently (logging
  is best-effort/swallowed). If you expect a row and don't get one, that's the signal to
  grant the app/user INSERT on `business_rule_log` — see B4.

### B4 — Which connection did the async rule use? (deploy-mechanics confirmation)
- **Why:** `P21SqlConnection` is only *proven* in synchronous rules. We added a fallback
  for `ExecuteAsync`. This case identifies which branch ran.
- **Method:** During B1, run an SSMS session trace / `sys.dm_exec_sessions` filter, or add a
  temporary marker, looking for `application name` =
  `P21_BusinessRule_kb_Order_Workflow_v2`. If you see that app name, the **fallback**
  (Session-built connection) was used; if not, the framework `P21SqlConnection` was used.
  ```sql
  SELECT login_name, program_name, host_name, login_time
  FROM   sys.dm_exec_sessions
  WHERE  program_name LIKE 'P21_BusinessRule_%'
  ORDER BY login_time DESC;
  ```
- **Expected / record the result:** Either path is acceptable for note creation. If fallback
  is used, confirm B3 still logs (grant may be required).

---

## C. Regression / sanity
- **C1:** Re-save an order edited by both rules (place a real order, add a line, save) and
  confirm: validator runs before save, note appears after save, no error rows, version still
  1.0.1.0 bound.
- **C2:** Confirm `kb_table_br_error_log` receives **zero** new rows from either rule across
  the whole run (the retired target should now be dead for this assembly).

---

## Sign-off checklist
- [ ] DLL on middleware reports File version **1.0.1.0**
- [ ] A1 passes, A2 blocks with message, A3a–c skip, A4 short-circuits
- [ ] A5/A6 surcharge flag toggles correctly
- [ ] A7 Atlas path runs
- [ ] A8 error → row in `business_rule_log` (`Synchronous (Internal)`), none in `kb_table_br_error_log`
- [ ] B1 note created, B2a–c skipped
- [ ] B3 error → row in `business_rule_log` (`Asynchronous (Internal)`)
- [ ] B4 connection path recorded (framework vs fallback)
- [ ] C2: zero new rows in `kb_table_br_error_log`

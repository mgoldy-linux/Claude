/* SA 55209 - Freight codes: apply the confirmed change to "Out Freight"

   CORRECTION (2026-09-28): the "Change TO" column in
   Reports\SA-55209-ShipTo-Terms-vs-FreightCode-2026-09-23.xlsx only got filled in
   for 3 of the 173 accounts -- user confirmed that was an oversight while marking
   up the sheet, not a real scope-down. All 173 accounts on the list are confirmed
   to change Prepaid -> Out Freight.

   Rather than hand-type 173 ship_to_id's, this reuses the exact filter from the
   original diagnostic query (Sql-Scripts\Customers\SA-55209-ShipTo-Terms-vs-FreightCode.sql)
   so the update set is guaranteed to match what was actually reviewed and sent.

   Two accounts on the list were flagged as edge cases when the report was built and
   are included here under "all 173" -- confirm they're really in scope before running:
     - customer_id 3023115 "Transfer To Blakely" -- reads like a placeholder/reassignment record
     - customer_id 3000889 "NE Dept of Correctional Services" -- government entity, may have
       non-standard billing arrangements terms_id wouldn't show
   If either should be excluded, add "AND s.ship_to_id NOT IN (<id>)" to the WHERE clause below.

   freight_code_uid = 2 is Out Freight; freight_code_uid = 6 is Prepaid
   -- see reference_p21_freight_code_shipto_schema.

   Run in SSMS (direct TDS connection from this session is blocked).
   Test on a lower environment (Play/Training) before Prod.
*/

-- 1) Verify current state before changing anything -- expect exactly 173 rows, all Prepaid
SELECT s.ship_to_id, c.customer_id, c.customer_name, a.name AS ship_to_name,
       c.terms_id, t.terms_desc, fc.freight_desc AS current_freight_code
FROM   ship_to s
JOIN   customer c ON s.customer_id = c.customer_id
JOIN   address  a ON a.id = s.ship_to_id
JOIN   terms    t ON c.terms_id = t.terms_id
JOIN   p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.freight_code_uid = 6          -- Prepaid
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  c.terms_id <> '21'              -- exclude Due Immediately (cash-basis, legit Prepaid)
ORDER BY c.customer_id, s.ship_to_id;

-- STOP: if the row count above isn't 173, the underlying data has moved since 9/23 --
-- re-diff against the report before proceeding, don't just run the UPDATE.

-- 2) Apply the confirmed change
UPDATE s
SET    s.freight_code_uid = 2          -- Out Freight
FROM   ship_to s
JOIN   customer c ON s.customer_id = c.customer_id
WHERE  s.freight_code_uid = 6          -- only flip rows still Prepaid; makes a re-run a no-op
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  c.terms_id <> '21';

-- expect 173 rows affected -- check @@ROWCOUNT before moving on

-- 3) Re-verify -- expect 0 rows (nothing left matching the old criteria)
SELECT s.ship_to_id, c.customer_id, c.customer_name, fc.freight_desc AS current_freight_code
FROM   ship_to s
JOIN   customer c ON s.customer_id = c.customer_id
JOIN   terms    t ON c.terms_id = t.terms_id
JOIN   p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.freight_code_uid = 6
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  c.terms_id <> '21';

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
use [P21] -- P21Play;
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

-- 1b) Backup guard: SA-55209-Backup-ShipTo-FreightCode.sql must have been run first.
--     Stops the batch if the backup table is missing or doesn't match the live Prepaid set.
IF OBJECT_ID('dbo.asi_bak_SA55209_ship_to_freight') IS NULL
   OR (SELECT COUNT(*) FROM dbo.asi_bak_SA55209_ship_to_freight b
       JOIN ship_to s ON s.ship_to_id = b.ship_to_id AND s.customer_id = b.customer_id
       WHERE s.freight_code_uid = 6) <>
      (SELECT COUNT(*) FROM ship_to s JOIN customer c ON s.customer_id = c.customer_id
       WHERE s.freight_code_uid = 6 AND c.delete_flag = 'N' AND s.delete_flag = 'N' AND c.terms_id <> '21')
BEGIN
    RAISERROR('Backup missing or out of sync with the rows to be updated - run the Backup script first. NOT updating.', 16, 1);
    RETURN;
END;

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


  -- recent update
 -- 1. Run this to see why they dropped off, meaning what they're now set to and who changed them:
/*SELECT s.ship_to_id, s.customer_id, c.customer_name, s.freight_code_uid, s.delete_flag AS st_del, c.delete_flag AS cust_del, c.terms_id, s.last_maintained_by
FROM ship_to s JOIN customer c ON c.customer_id = s.customer_id
WHERE s.ship_to_id IN (1126566, 3001467);*/
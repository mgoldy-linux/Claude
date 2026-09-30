/* SA 55209 - RESTORE (backout): put ship_to.freight_code_uid back to the backed-up value

   Only for use after SA-55209-Backup-ShipTo-FreightCode.sql has been run and the UPDATE
   has been applied. Reads dbo.asi_bak_SA55209_ship_to_freight.

   Only restores rows that are STILL Out Freight (freight_code_uid = 2). A ship-to someone
   has since changed to something else on purpose is left alone and reported, not overwritten.

   Test this in Play (after a Play backup + UPDATE) before the Prod run.
   Run in SSMS. Keep the backup table until the ticket is closed.
*/
use [P21] --P21Play;
SET NOCOUNT ON;

IF OBJECT_ID('dbo.asi_bak_SA55209_ship_to_freight') IS NULL
BEGIN
    RAISERROR('Backup table dbo.asi_bak_SA55209_ship_to_freight not found - nothing to restore from.', 16, 1);
    RETURN;
END;

-- 1) Preview: what would be restored vs skipped
SELECT CASE WHEN s.freight_code_uid = 2 THEN 'RESTORE'
            ELSE 'SKIP - changed since (now uid ' + CONVERT(varchar(12), s.freight_code_uid) + ')' END AS action,
       COUNT(*) AS rows_
FROM   dbo.asi_bak_SA55209_ship_to_freight b
JOIN   ship_to s ON s.ship_to_id = b.ship_to_id AND s.customer_id = b.customer_id
GROUP BY CASE WHEN s.freight_code_uid = 2 THEN 'RESTORE'
              ELSE 'SKIP - changed since (now uid ' + CONVERT(varchar(12), s.freight_code_uid) + ')' END;

-- 2) Restore
BEGIN TRAN;

UPDATE s
SET    s.freight_code_uid = b.old_freight_code_uid      -- 6 = Prepaid
FROM   ship_to s
JOIN   dbo.asi_bak_SA55209_ship_to_freight b
       ON b.ship_to_id = s.ship_to_id AND b.customer_id = s.customer_id
WHERE  s.freight_code_uid = 2;                          -- only rows still on the value we set

PRINT 'Rows restored: ' + CONVERT(varchar(12), @@ROWCOUNT) + ' (expect 173 in Prod unless listed as SKIP above)';

-- 3) Verify: any backed-up row not back at its original value (expect only the SKIPs from step 1)
SELECT b.ship_to_id, b.customer_id, b.old_freight_code_uid, s.freight_code_uid AS current_uid
FROM   dbo.asi_bak_SA55209_ship_to_freight b
JOIN   ship_to s ON s.ship_to_id = b.ship_to_id AND s.customer_id = b.customer_id
WHERE  s.freight_code_uid <> b.old_freight_code_uid;

-- Review the output, then run ONE of these:
-- COMMIT;
-- ROLLBACK;

/* SA 55209 - STEP 1 of 3: back up ship_to.freight_code_uid BEFORE the UPDATE

   Run order:  1) this backup   2) SA-55209-Update-FreightCode-To-OutFreight.sql   3) Restore (only if needed)

   Captures exactly the rows the UPDATE will touch (same filter: Prepaid, real terms,
   both delete_flags 'N') into dbo.asi_bak_SA55209_ship_to_freight.

   @ExpectedRows: 173 in Prod (confirmed 9/28). Play had 180 on 9/28 (stale snapshot) --
   set @ExpectedRows to whatever the verify SELECT returned in the environment you're in.

   Refuses to run if the backup table already exists (so a second run can't overwrite the
   original values with post-change ones). To redo a test run, DROP the table deliberately.

   Also export the table to Excel and attach it to the ticket (Reports\ folder).
   Run in SSMS (direct TDS connection from Claude Code is blocked).
*/

Use [P21] --P21Play;
SET NOCOUNT ON;

DECLARE @ExpectedRows int = 172;   -- Prod. Change for Play/Training.

IF OBJECT_ID('dbo.asi_bak_SA55209_ship_to_freight') IS NOT NULL
BEGIN
    RAISERROR('Backup table already exists - not overwriting. Drop it deliberately if this is a test re-run.', 16, 1);
    RETURN;
END;

SELECT s.ship_to_id,
       s.customer_id,
       s.freight_code_uid AS old_freight_code_uid,   -- 6 = Prepaid
       GETDATE()          AS backed_up_at,
       SUSER_SNAME()      AS backed_up_by
INTO   dbo.asi_bak_SA55209_ship_to_freight
FROM   ship_to s
JOIN   customer c ON s.customer_id = c.customer_id
WHERE  s.freight_code_uid = 6
  AND  c.delete_flag = 'N'
  AND  s.delete_flag = 'N'
  AND  c.terms_id <> '21';

DECLARE @n int = @@ROWCOUNT;

IF @n <> @ExpectedRows
BEGIN
    DROP TABLE dbo.asi_bak_SA55209_ship_to_freight;
    RAISERROR('Backup captured %d rows, expected %d. Table dropped. Data has moved - re-diff against the report.', 16, 1, @n, @ExpectedRows);
    RETURN;
END;

-- The restore joins on ship_to_id + customer_id; make sure that pair is unique
IF EXISTS (SELECT 1 FROM dbo.asi_bak_SA55209_ship_to_freight GROUP BY ship_to_id, customer_id HAVING COUNT(*) > 1)
BEGIN
    DROP TABLE dbo.asi_bak_SA55209_ship_to_freight;
    RAISERROR('Duplicate ship_to_id/customer_id in backup. Table dropped - investigate before proceeding.', 16, 1);
    RETURN;
END;

SELECT COUNT(*) AS backup_rows, MIN(old_freight_code_uid) AS min_old_uid, MAX(old_freight_code_uid) AS max_old_uid
FROM   dbo.asi_bak_SA55209_ship_to_freight;   -- expect @ExpectedRows, 6, 6

SELECT * FROM dbo.asi_bak_SA55209_ship_to_freight ORDER BY customer_id, ship_to_id;   -- export this to Excel


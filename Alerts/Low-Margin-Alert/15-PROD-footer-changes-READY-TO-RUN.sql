/*==============================================================================
  15 — PROD: footer changes for all four Low Margin alerts (Evan item #2)
  Target : P21 (Production).  Already applied and verified on P21Play 2026-10-06.
  Author : Mark Goldyn / Claude          Date: 2026-10-07

  *** THIS FILE RUNS AS-IS. DO NOT UNCOMMENT ANYTHING. ***
  Open it in SSMS against any database and press Execute. It sets its own
  database, applies both parts, commits each one only if it touched exactly
  2 rows, and prints the result. Scripts 12 and 14 were run on 2026-10-06 and
  changed nothing, because in those files the APPLY block sits inside a /* */
  comment -- only their PREVIEW ran. This file exists so that cannot happen.

  WHAT IT DOES
    PART A   uid 104 + 106  (Team alerts)
      - "Sales Rep and Order Taker"  ->  "Territory Manager and Order Taker"
      - "...confirm programming and GM %, Purchasing Team will confirm cost."
         -> "...confirm price programming and Standard Cost, Purchasing Team
             will confirm MAC and Supplier Cost."
      - appends to the contacts note: "For Sales Rep assignment questions,
        please contact customermaintenance@allsurfaces.com."

    PART B   uid 105 + 107  (Purchasing alerts)
      - gives them the WHOLE contacts note, which they do not currently have.
        Their own first note ("This order's margin is below 5% against MAC...")
        is NOT touched.

  Evan approved both in his 2026-10-06 13:48 reply, and confirmed that
  "Territory Manager" in the first note alongside "Sales Rep assignment" in the
  last line is DELIBERATE -- the latter is the P21 term for coding reps to
  customers. Reproduced verbatim; do not "fix" it.

  SAFETY
    - Each part runs in its own transaction and COMMITs only on exactly 2 rows;
      anything else rolls that part back and prints why. No open transaction is
      ever left behind.
    - Idempotent: both parts are guarded on 'customermaintenance' not already
      being present, so a second run is a no-op that reports 0 rows.
    - Scoped UPDATEs on alert_message.footer only. Nothing touches
      alert_implementation, so no where_clause and no trigger can be disturbed.
      This is why it is SQL and not Alert Maintenance: saving an alert in the
      client regenerates its whole where_clause from the Filter grid (trap 10),
      and uid 106's "-5% off MAC OR -5% off standard" trigger has no grid
      representation -- saving 106 in the client silently reverts it.
    - footer is a `text` column, so every read and REPLACE CASTs to varchar(max)
      first (a Prod-only text/nvarchar(max) CAST bug bit script 10). Footer line
      breaks are CRLF, verified on Prod 2026-10-06.

  Rollback is at the bottom, commented out ON PURPOSE.
==============================================================================*/
USE P21;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '================ BEFORE ================';
SELECT ai.alert_implementation_uid,
       ai.alert_implementation_name,
       already_done = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%customermaintenance%'
                           THEN 'YES - will be skipped' ELSE 'no' END,
       footer_before = CAST(am.footer AS varchar(max))
FROM   dbo.alert_implementation ai
JOIN   dbo.alert_message am ON am.alert_implementation_uid = ai.alert_implementation_uid
WHERE  ai.alert_implementation_uid IN (104,105,106,107)
ORDER BY ai.alert_implementation_uid;
GO

/*=================== PART A — uid 104 + 106 (Team alerts) ================*/
DECLARE @old_note1 varchar(500) =
  'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.';
DECLARE @new_note1 varchar(500) =
  'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.';
DECLARE @old_tail varchar(200) = 'please contact pricingsupport@allsurfaces.com.';
DECLARE @new_tail varchar(400) =
  'please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';

BEGIN TRY
  BEGIN TRAN;

  UPDATE am
  SET    am.footer = REPLACE(
                       REPLACE(CAST(ISNULL(am.footer,'') AS varchar(max)), @old_note1, @new_note1),
                       @old_tail, @new_tail)
  FROM   dbo.alert_message am
  JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
  WHERE  ai.alert_implementation_uid IN (104,106)
    AND  CAST(am.footer AS varchar(max)) NOT LIKE '%customermaintenance%';

  DECLARE @a int = @@ROWCOUNT;

  IF @a = 2
    BEGIN COMMIT; PRINT 'PART A: COMMITTED - 2 rows (104, 106).'; END
  ELSE
    BEGIN ROLLBACK;
          PRINT 'PART A: ROLLED BACK - expected 2 rows, got ' + CAST(@a AS varchar(10))
              + '. If 0, it was already applied.'; END
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'PART A: ROLLED BACK ON ERROR - ' + ERROR_MESSAGE();
END CATCH;
GO

/*============== PART B — uid 105 + 107 (Purchasing alerts) ==============*/
DECLARE @crlf  varchar(2)   = CHAR(13) + CHAR(10);
DECLARE @tail  varchar(100) = 'Email generated by P21, Have a great day!';
DECLARE @note3 varchar(500) =
  'Note: For MAC or Supplier Cost questions, please contact Purchasing Team. '
+ 'For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com. '
+ 'For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';

BEGIN TRY
  BEGIN TRAN;

  UPDATE am
  SET    am.footer = REPLACE(CAST(am.footer AS varchar(max)),
                             @tail,
                             @note3 + @crlf + @crlf + @tail)
  FROM   dbo.alert_message am
  JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
  WHERE  ai.alert_implementation_uid IN (105,107)
    AND  CAST(am.footer AS varchar(max)) NOT LIKE '%customermaintenance%'
    AND  CAST(am.footer AS varchar(max)) LIKE '%' + @tail + '%';

  DECLARE @b int = @@ROWCOUNT;

  IF @b = 2
    BEGIN COMMIT; PRINT 'PART B: COMMITTED - 2 rows (105, 107).'; END
  ELSE
    BEGIN ROLLBACK;
          PRINT 'PART B: ROLLED BACK - expected 2 rows, got ' + CAST(@b AS varchar(10))
              + '. If 0, it was already applied.'; END
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'PART B: ROLLED BACK ON ERROR - ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '================ AFTER ================';
SELECT ai.alert_implementation_uid,
       ai.alert_implementation_name,
       has_new_line = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%customermaintenance%'
                           THEN 'YES' ELSE 'NO' END,
       footer_after = CAST(am.footer AS varchar(max))
FROM   dbo.alert_implementation ai
JOIN   dbo.alert_message am ON am.alert_implementation_uid = ai.alert_implementation_uid
WHERE  ai.alert_implementation_uid IN (104,105,106,107)
ORDER BY ai.alert_implementation_uid;
GO
PRINT 'Expected: all four rows has_new_line = YES.';
PRINT 'Expected: 104/106 first note starts "Territory Manager and Order Taker".';
PRINT 'Expected: 105/107 first note UNCHANGED ("This order''s margin is below 5% against MAC...").';
GO

/*============================== ROLLBACK ==================================
  COMMENTED ON PURPOSE. Only run this to undo the change.
===========================================================================
USE P21;
GO
DECLARE @crlf  varchar(2)   = CHAR(13) + CHAR(10);
DECLARE @tail  varchar(100) = 'Email generated by P21, Have a great day!';
DECLARE @note3 varchar(500) =
  'Note: For MAC or Supplier Cost questions, please contact Purchasing Team. '
+ 'For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com. '
+ 'For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';
UPDATE am SET am.footer = REPLACE(CAST(am.footer AS varchar(max)), @note3 + @crlf + @crlf + @tail, @tail)
FROM dbo.alert_message am
JOIN dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE ai.alert_implementation_uid IN (105,107);
PRINT 'Part B reverted: ' + CAST(@@ROWCOUNT AS varchar(10));

DECLARE @new_note1 varchar(500) =
  'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.';
DECLARE @old_note1 varchar(500) =
  'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.';
DECLARE @new_tail varchar(400) =
  'please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';
DECLARE @old_tail varchar(200) = 'please contact pricingsupport@allsurfaces.com.';
UPDATE am SET am.footer = REPLACE(REPLACE(CAST(am.footer AS varchar(max)), @new_note1, @old_note1), @new_tail, @old_tail)
FROM dbo.alert_message am
JOIN dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE ai.alert_implementation_uid IN (104,106);
PRINT 'Part A reverted: ' + CAST(@@ROWCOUNT AS varchar(10));
GO
===========================================================================*/

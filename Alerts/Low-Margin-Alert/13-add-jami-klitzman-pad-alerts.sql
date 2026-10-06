/*==============================================================================
  13 — Add Jami Klitzman to the PAD alert distribution lists (Evan item #4)
  Target : P21 (Prod).  See "WHY NOT PLAY" below before changing the USE.
  Author : Mark Goldyn / Claude          Date: 2026-10-06

  Ask (Evan Jenkins, 2026-10-05 "Low Margin Alert Follow Up", item 4):
    "Please add Jami Klitzman to the distribution list for Pad Alerts."

  WHO: users.id = 'JKLITZMAN', Jami Klitzman, jklitzman@allsurfaces.com
       (delete_flag = 'N', verified on Prod 2026-10-06).
       NOTE: users row 'JBARAN' is the '** MISSPELLING ** Use JKLITZMAN' marker
       and is deleted -- do NOT use it. Several `contacts` rows still carry the
       retired @alltileccs.com domain; also not used here.

  WHERE: the two PAD alerts only --
       uid 106  Low PAD Margin Alert - Team                  -> alert_message_uid 109
       uid 107  Low PAD Margin Alert - Purchasing Esc. (MAC) -> alert_message_uid 110
       Added as To (recipient_type_cd 1281), matching how Justine Daugherty and
       Alex Sivongsay sit on these same two alerts. Not CC, not BCC.

  *** WHY THIS IS SQL AND NOT THE CLIENT ***
  Saving an alert in Alert Maintenance REGENERATES the whole where_clause from
  the Filter grid (trap 10). uid 106's "-5% off MAC OR -5% off standard" trigger
  has NO possible grid representation, so opening and saving 106 in the client
  silently reverts it to the old +5% bug. A scoped INSERT into alert_recipient
  touches no alert_implementation row and cannot disturb either trigger.

  *** WHY NOT TEST IN PLAY FIRST ***
  P21Play sends REAL email. Play's 106/107 recipient lists deliberately contain
  only mgoldyn@allsurfaces.com so test orders do not spam anyone. Putting Jami
  into Play would mail her [P21Play] test alerts for every future test. The
  INSERT below is the same shape as the 19 recipient rows already on these two
  alerts, so Play adds no information worth that cost.

  *** UID ALLOCATION ***
  counter.alert_recipient has counter_num = -1 and seq_name = 'seq_alert_recipient'
  -- P21 draws these uids from the SQL SEQUENCE, not from counter_num. Using
  NEXT VALUE FOR keeps P21 and the data in step, so there is no counter to
  realign afterwards. Verified aligned on Prod 2026-10-06:
  sys.sequences.current_value = 236, MAX(alert_recipient_uid) = 236.

  Idempotent: guarded on the address not already being on that alert_message.
==============================================================================*/
USE P21;
GO
SET NOCOUNT ON;

DECLARE @name  varchar(255) = 'Jami Klitzman';
DECLARE @email varchar(255) = 'jklitzman@allsurfaces.com';

/*------------------------------ PREVIEW -----------------------------------
  Run this block on its own first.
---------------------------------------------------------------------------*/
PRINT '=== PREVIEW 1: sequence vs data (must be equal, or seq higher) ===';
SELECT seq_current = (SELECT current_value FROM sys.sequences WHERE name='seq_alert_recipient'),
       data_max    = (SELECT MAX(alert_recipient_uid) FROM dbo.alert_recipient);

PRINT '=== PREVIEW 2: current PAD recipients + whether Jami is already there ===';
SELECT ai.alert_implementation_uid, ai.alert_implementation_name,
       am.alert_message_uid,
       recipients_now = COUNT(r.alert_recipient_uid),
       jami_already   = SUM(CASE WHEN r.alert_email_address = @email THEN 1 ELSE 0 END)
FROM dbo.alert_implementation ai
JOIN dbo.alert_message   am ON am.alert_implementation_uid = ai.alert_implementation_uid
LEFT JOIN dbo.alert_recipient r ON r.alert_message_uid = am.alert_message_uid
WHERE ai.alert_implementation_uid IN (106,107)
GROUP BY ai.alert_implementation_uid, ai.alert_implementation_name, am.alert_message_uid
ORDER BY ai.alert_implementation_uid;
GO

/*------------------------------- APPLY ------------------------------------
  Uncomment the block below to apply. Review the PREVIEW output first.
---------------------------------------------------------------------------*/
/*
USE P21;
GO
SET NOCOUNT ON;

DECLARE @name  varchar(255) = 'Jami Klitzman';
DECLARE @email varchar(255) = 'jklitzman@allsurfaces.com';

BEGIN TRY
  BEGIN TRAN;

  INSERT INTO dbo.alert_recipient
        (alert_recipient_uid, alert_message_uid, alert_email_name, alert_email_address,
         row_status_flag, date_created, date_last_modified, last_maintained_by,
         record_type_cd, recipient_type_cd)
  SELECT NEXT VALUE FOR dbo.seq_alert_recipient,
         am.alert_message_uid, @name, @email,
         704, GETDATE(), GETDATE(), 'MGOLDYN',
         1059, 1281
  FROM   dbo.alert_message am
  WHERE  am.alert_implementation_uid IN (106,107)
    AND  NOT EXISTS (SELECT 1 FROM dbo.alert_recipient r
                     WHERE r.alert_message_uid    = am.alert_message_uid
                       AND r.alert_email_address  = @email);

  PRINT 'rows inserted: ' + CAST(@@ROWCOUNT AS varchar(10)) + '  (expected 2)';

  -- verify before committing
  SELECT ai.alert_implementation_uid, ai.alert_implementation_name,
         r.alert_recipient_uid, r.alert_email_name, r.alert_email_address,
         r.recipient_type_cd, r.record_type_cd, r.row_status_flag
  FROM   dbo.alert_implementation ai
  JOIN   dbo.alert_message   am ON am.alert_implementation_uid = ai.alert_implementation_uid
  JOIN   dbo.alert_recipient r  ON r.alert_message_uid = am.alert_message_uid
  WHERE  ai.alert_implementation_uid IN (106,107)
    AND  r.alert_email_address = @email
  ORDER BY ai.alert_implementation_uid;

  COMMIT;              -- <<< change to ROLLBACK to abort
  PRINT 'COMMITTED.';
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'ROLLED BACK: ' + ERROR_MESSAGE();
END CATCH;
GO
*/

/*------------------------------ ROLLBACK ----------------------------------
  Removes Jami from both PAD alerts. Leaves the sequence where it is -- gaps in
  alert_recipient_uid are harmless and P21 never reuses them.
---------------------------------------------------------------------------*/
/*
USE P21;
GO
DELETE r
FROM   dbo.alert_recipient r
JOIN   dbo.alert_message   am ON am.alert_message_uid = r.alert_message_uid
WHERE  am.alert_implementation_uid IN (106,107)
  AND  r.alert_email_address = 'jklitzman@allsurfaces.com';
PRINT 'rows deleted: ' + CAST(@@ROWCOUNT AS varchar(10));
GO
*/

/*==============================================================================
  ZZTEST — Stale Cache Check
  Throwaway alert created purely to test whether the background alert-processing
  service (whatever drains pending_alerts for alert_type_uid=12 / type_cd=1118)
  caches its list of active alert_implementation rows at startup and never
  re-polls for newly-created ones.

  Mirrors "Test Verify Alerts" (uid 102) exactly: same trigger breadth
  (new_order = 'Y' AND rma_flag <> 'Y'), same alert_type_uid/execution_mode_cd,
  so ANY freshly-saved order (no PAD item or price override needed) should
  trip it if the processing engine can see it.

  mgoldyn ONLY. DISPOSABLE -- delete after the test, win or lose.
==============================================================================*/

USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DECLARE @name  VARCHAR(255) = 'ZZTEST Stale Cache Check';
DECLARE @user  VARCHAR(50)  = 'MGOLDYN';
DECLARE @now   DATETIME     = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
DECLARE @expiry DATETIME    = '2049-12-31 23:59:59';

/*--- teardown any prior run ---*/
DECLARE @old TABLE (uid INT);
INSERT @old SELECT alert_implementation_uid FROM alert_implementation WHERE alert_implementation_name = @name;

DELETE r FROM alert_recipient r
  JOIN alert_message m ON m.alert_message_uid = r.alert_message_uid
 WHERE m.alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_message              WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM Alert_implementation_query WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_implementation       WHERE alert_implementation_uid IN (SELECT uid FROM @old);

/*--- fresh uids via the SUPPORTED counter proc, not raw MAX+1 ---*/
DECLARE @maxImpl INT; SELECT @maxImpl = MAX(alert_implementation_uid) FROM alert_implementation;
DECLARE @maxMsg  INT; SELECT @maxMsg  = MAX(alert_message_uid)        FROM alert_message;
DECLARE @maxRcp  INT; SELECT @maxRcp  = MAX(alert_recipient_uid)      FROM alert_recipient;

EXEC p21_set_counter @counter_id = 'alert_implementation', @counter_num = @maxImpl;
EXEC p21_set_counter @counter_id = 'alert_message',        @counter_num = @maxMsg;
EXEC p21_set_counter @counter_id = 'alert_recipient',      @counter_num = @maxRcp;

DECLARE @aUid INT = @maxImpl + 1;
DECLARE @mUid INT = @maxMsg + 1;
DECLARE @rUid INT = @maxRcp + 1;

INSERT alert_implementation
  (alert_implementation_uid, alert_type_uid, alert_implementation_name, activation_date,
   expiration_date, date_created, date_last_modified, last_maintained_by, row_status_flag,
   where_clause, execution_mode_cd, next_execution_start_point, job_id, last_execution_error,
   email_notification_flag, task_notification_flag)
VALUES
  (@aUid, 12, @name, @now, @expiry, @now, @now, @user, 704,
   'new_order = ''Y'' AND rma_flag <> ''Y''', 1092, GETDATE(), '', 0, 'Y', 'N');

INSERT Alert_implementation_query
  (alert_implementation_query_uid, alert_implementation_uid, column_id, operator_cd,
   column_value, date_created, date_last_modified, last_maintained_by, row_status_flag,
   column_value_description)
SELECT (SELECT ISNULL(MAX(alert_implementation_query_uid),0)+1 FROM Alert_implementation_query),
       @aUid, t.token_uid, 1050, 'Y', @now, @now, @user, 704, 'Y'
FROM token t
JOIN alert_type_x_token x ON x.token_uid = t.token_uid
WHERE x.alert_type_uid = 12 AND t.name = 'new_order';

INSERT alert_message
  (alert_message_uid, alert_implementation_uid, subject, header, line_item, footer,
   attachment, sender_name, sender_email_address, date_created, date_last_modified,
   last_maintained_by, row_status_flag)
VALUES
  (@mUid, @aUid,
   '[ZZTEST-StaleCache] Order# <order_number> for <customer_name>',
   'Customer: (<customer_id>) <customer_name>' + CHAR(13)+CHAR(10) + 'Taken by: <taker>',
   '<item_id> - <item_description>',
   'This is a throwaway alert created via raw SQL to test whether the alert-processing engine picks up brand-new alert_implementation rows without a service restart. Safe to ignore/delete.',
   NULL, 'ZZTEST Stale Cache Check', NULL, @now, @now, @user, 704);

INSERT alert_recipient
  (alert_recipient_uid, alert_message_uid, alert_email_name, alert_email_address,
   date_created, date_last_modified, last_maintained_by, row_status_flag,
   record_type_cd, recipient_type_cd)
VALUES
  (@rUid, @mUid, 'mgoldyn', 'mgoldyn@allsurfaces.com', @now, @now, @user, 704, 1059, 1281);

COMMIT;
PRINT 'Created ZZTEST Stale Cache Check: alert_implementation_uid = ' + CAST(@aUid AS VARCHAR);
GO

/*--- Verify ---*/
SELECT ai.alert_implementation_uid, ai.alert_implementation_name, ai.row_status_flag, ai.where_clause,
       am.alert_message_uid, ar.alert_email_address
FROM alert_implementation ai
JOIN alert_message am ON am.alert_implementation_uid = ai.alert_implementation_uid
JOIN alert_recipient ar ON ar.alert_message_uid = am.alert_message_uid
WHERE ai.alert_implementation_name = 'ZZTEST Stale Cache Check';
GO

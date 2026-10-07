/*==============================================================================
  19 — New "Pricing Review" alert + exclusion on 104 (Evan #3, step 3b) — PLAY
  Target : P21Play.  Prod twin NOT written yet (uids differ between envs).
  Author : Mark Goldyn / Claude          Date: 2026-10-07

  *** THIS FILE RUNS AS-IS. DO NOT UNCOMMENT ANYTHING. ***
  DEPENDS ON scripts 16, 17 and 18 (supplier cost columns, their tokens, and
  route_pricing_only). It will fail cleanly if the alert already exists.

  Ask (Evan 2026-10-05 item #3, scoped in his 2026-10-06 reply):
    "If Standard Cost is greater than Supplier Cost AND GM % off MAC is above
     set threshold, only send alert to Alex Sivongsay and Erik Bullock."
    Main pair only (104/105), NOT the PAD pair. Threshold = the current 5%.
    "OK, let's setup as own alert... I'd like to reduce the number of emails."

  WHAT THIS CREATES (applied to Play 2026-10-07)
    alert_implementation uid 110  "Low Margin Alert - Pricing Review (Std > Supplier)"
      row_status_flag 705 = INACTIVE, per the deploy-inactive-then-flip pattern
      used for 104/105/106/107.
    alert_message        uid 113  cloned from 104's message, with one line added
      to the body: "Supplier Cost: $<unit_supplier_cost>", and its own footer.
    alert_recipient      uid 209  mgoldyn ONLY.
  AND appends " AND route_pricing_only = 'N'" to uid 104's where_clause.

  *** PLAY RECIPIENT IS DELIBERATELY NOT EVAN'S LIST ***
  Evan asked for Alex Sivongsay and Erik Bullock. They go on the PROD build.
  Play sends REAL email and its alert recipient lists are kept to mgoldyn on
  purpose so test orders do not reach anyone. Same reasoning as leaving Jami
  off Play's PAD alerts in script 13.

  *** THE TWO CLAUSES ARE EXACT COMPLEMENTS ***
  104 and 110 are character-identical except for one predicate:
      104 ... AND low_margin_flag = 'Y' AND route_pricing_only = 'N'
      110 ... AND low_margin_flag = 'Y' AND route_pricing_only = 'Y'
  low_margin_flag is kept on BOTH so the two partition exactly the same
  population and a line can never satisfy both or neither. See script 18 for
  why the rule lives in one view column instead of as NOT(A AND B) on 104 --
  short version, that would be an OR, and an OR has no Filter grid
  representation, which is what makes uid 106 unsafe to open in the client.

  *** MEASURED IMPACT (Prod, 120 days, main-pair scope) ***
    1,388 orders (26.5% of 5,240 alerting orders) move ENTIRELY to this alert.
      186 orders (3.6%) are MIXED and will fire BOTH 104 and 110 -- two emails
          where today there is one, roughly 1.5 orders a day. Tell Evan: it
          cuts against his "one email to one order" ask. Cause is that the
          where_clause is evaluated PER LINE. Fixing it needs an ORDER-level
          routing decision and belongs with his separate one-email item.
    3,666 unaffected.
  Net -1,388 / +186.

  *** BEFORE ACTIVATING (705 -> 704) ***
    1. Build a test order in Play that satisfies route_pricing_only = 'Y'
       (GM% off MAC >= 5, GM% off Standard < 5, Standard Cost > Supplier Cost,
       total > 1000, extended_standard_cost > 500, non-excluded product group).
    2. Confirm ONE email arrives, from 110 and not 104.
    3. Only then flip 110 to 704, and only on Prod with Evan's recipients.

  UID allocation: all three tables are sequence-backed (seq_alert_implementation,
  seq_alert_message, seq_alert_recipient), drawn with NEXT VALUE FOR, so nothing
  needs realigning. Verified after: seq 110 = max 110, seq 113 = max 113.

  Whole thing is one transaction: if the exclusion on 104 does not update
  exactly one row, the new alert is rolled back too.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @name   varchar(255) = 'Low Margin Alert - Pricing Review (Std > Supplier)';
DECLARE @crlf   varchar(2)   = CHAR(13) + CHAR(10);
DECLARE @excl   varchar(100) = ' AND route_pricing_only = ''N''';

BEGIN TRY
  BEGIN TRAN;

  IF EXISTS (SELECT 1 FROM dbo.alert_implementation WHERE alert_implementation_name = @name)
    BEGIN RAISERROR('Alert already exists - nothing done.',16,1); END

  DECLARE @type_uid int = (SELECT alert_type_uid FROM dbo.alert_implementation WHERE alert_implementation_uid = 104);
  DECLARE @ai int = NEXT VALUE FOR dbo.seq_alert_implementation;
  DECLARE @am int = NEXT VALUE FOR dbo.seq_alert_message;

  /* ---- 1. the alert itself, INACTIVE (705). job_id is NOT NULL -> '' ---- */
  INSERT INTO dbo.alert_implementation
        (alert_implementation_uid, alert_type_uid, alert_implementation_name,
         activation_date, expiration_date, date_created, date_last_modified,
         last_maintained_by, row_status_flag, where_clause, execution_mode_cd,
         job_id, last_execution_error, email_notification_flag, task_notification_flag,
         next_execution_start_point)
  VALUES(@ai, @type_uid, @name,
         CAST(CAST(GETDATE() AS date) AS datetime), '2049-12-31 23:59:59', GETDATE(), GETDATE(),
         'MGOLDYN', 705,
         'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'',''SURFACE'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND low_margin_flag = ''Y'' AND route_pricing_only = ''Y'' AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
         1092, '', 0, 'Y', 'N',
         /* next_execution_start_point: must NOT be left NULL. Alert Maintenance
            reads it and throws "An error has occurred accessing alert information"
            on save when it is missing. Copy whatever the live family currently
            carries - the scheduler advances them all together. */
         (SELECT next_execution_start_point FROM dbo.alert_implementation
          WHERE alert_implementation_uid = 104));

  /* ---- 2. its message, cloned from 104 + the Supplier Cost line ---- */
  INSERT INTO dbo.alert_message
        (alert_message_uid, alert_implementation_uid, row_status_flag,
         date_created, date_last_modified, last_maintained_by,
         sender_name, subject, header, line_item, footer)
  SELECT @am, @ai, 704, GETDATE(), GETDATE(), 'MGOLDYN',
         am.sender_name,
         '[P21Play] Low Margin - Pricing Review - Order# <order_number> for <customer_name> - Total: $<total_amount>',
         CAST(am.header AS varchar(max)),
         REPLACE(CAST(am.line_item AS varchar(max)),
                 'Standard Cost: $<unit_standard_cost>',
                 'Standard Cost: $<unit_standard_cost>' + @crlf + 'Supplier Cost: $<unit_supplier_cost>'),
         'Note: This order is acceptable against MAC but not against Standard Cost, and Standard Cost is above Supplier Cost - consistent with a deliberate Standard Cost increase. It has been routed to Pricing only; the Sales team has NOT been copied on this one.'
         + @crlf + @crlf +
         'Note: Extended Standard Cost is calculated using the item''s default stocking unit, not the order unit of measure. When these differ (e.g., ordered in cartons but costed per square foot), the extended cost may appear disproportionate to the unit price shown.'
         + @crlf + @crlf +
         'Note: For MAC or Supplier Cost questions, please contact Purchasing Team. For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.'
         + @crlf + @crlf +
         'Email generated by P21, Have a great day!'
         + @crlf + @crlf + '(Sent from P21Play)'
  FROM dbo.alert_message am WHERE am.alert_implementation_uid = 104;

  /* ---- 3. recipient: PLAY = mgoldyn only ---- */
  INSERT INTO dbo.alert_recipient
        (alert_recipient_uid, alert_message_uid, alert_email_name, alert_email_address,
         row_status_flag, date_created, date_last_modified, last_maintained_by,
         record_type_cd, recipient_type_cd)
  VALUES(NEXT VALUE FOR dbo.seq_alert_recipient, @am, 'mgoldyn', 'mgoldyn@allsurfaces.com',
         704, GETDATE(), GETDATE(), 'MGOLDYN', 1059, 1281);

  /* ---- 4. the matching exclusion on 104 ---- */
  UPDATE dbo.alert_implementation
  SET    where_clause = CAST(where_clause AS varchar(max)) + @excl,
         date_last_modified = GETDATE(), last_maintained_by = 'MGOLDYN'
  WHERE  alert_implementation_uid = 104
    AND  CAST(where_clause AS varchar(max)) NOT LIKE '%route_pricing_only%';
  DECLARE @u int = @@ROWCOUNT;

  IF @u <> 1
    BEGIN ROLLBACK; PRINT 'ROLLED BACK - exclusion on 104 updated ' + CAST(@u AS varchar(5)) + ' rows, expected 1.'; END
  ELSE
    BEGIN COMMIT;
          PRINT 'COMMITTED. New alert uid=' + CAST(@ai AS varchar(10))
              + ', message uid=' + CAST(@am AS varchar(10)) + ', created INACTIVE (705).'; END
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'ROLLED BACK ON ERROR - ' + ERROR_MESSAGE();
END CATCH;
GO

/*------------------------------ VERIFY ------------------------------------
  The two where_clauses must be identical except route_pricing_only Y vs N.
---------------------------------------------------------------------------*/
SELECT ai.alert_implementation_uid, ai.alert_implementation_name,
       status_ = CASE ai.row_status_flag WHEN 704 THEN 'ACTIVE' WHEN 705 THEN 'INACTIVE' END,
       wc = CAST(ai.where_clause AS varchar(max))
FROM   dbo.alert_implementation ai
WHERE  ai.alert_implementation_uid = 104
   OR  ai.alert_implementation_name = 'Low Margin Alert - Pricing Review (Std > Supplier)'
ORDER BY ai.alert_implementation_uid;

SELECT r.alert_recipient_uid, r.alert_email_name, r.alert_email_address, r.recipient_type_cd
FROM   dbo.alert_recipient r
JOIN   dbo.alert_message am ON am.alert_message_uid = r.alert_message_uid
JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE  ai.alert_implementation_name = 'Low Margin Alert - Pricing Review (Std > Supplier)';
GO

/*=============================== ROLLBACK ===================================
  COMMENTED ON PURPOSE. Removes the new alert and un-does the 104 exclusion.
=============================================================================
USE P21Play;
GO
DECLARE @ai int = (SELECT alert_implementation_uid FROM dbo.alert_implementation
                   WHERE alert_implementation_name = 'Low Margin Alert - Pricing Review (Std > Supplier)');
DELETE r FROM dbo.alert_recipient r
JOIN dbo.alert_message am ON am.alert_message_uid = r.alert_message_uid
WHERE am.alert_implementation_uid = @ai;
DELETE FROM dbo.alert_message        WHERE alert_implementation_uid = @ai;
DELETE FROM dbo.alert_implementation WHERE alert_implementation_uid = @ai;
UPDATE dbo.alert_implementation
SET    where_clause = REPLACE(CAST(where_clause AS varchar(max)), ' AND route_pricing_only = ''N''', '')
WHERE  alert_implementation_uid = 104;
PRINT 'new alert removed and 104 exclusion reverted.';
GO
=============================================================================*/

/*==============================================================================
  Low Margin Alert — Step 3: create the alert definitions
  Target : P21Play          Author: Mark Goldyn / Claude    Date: 2026-07-14
  Depends on: 01-alter-view-add-margin-columns.sql, 02-register-tokens.sql

  IDEMPOTENT + TRANSACTIONAL — deletes any prior copy by name, then rebuilds.

  ############################################################################
  ##  SAFETY: RECIPIENTS ARE mgoldyn ONLY.                                   ##
  ##  P21Play HAS LIVE SMTP (enable_email_functionality = Y, email_type =    ##
  ##  SMTP, sender noreply@allsurfaces.com).  The real recipient lists are   ##
  ##  in the deploy guide and are applied at PROD DEPLOY ONLY.               ##
  ############################################################################

  =========================  DESIGN: SPLIT BY AUDIENCE  ========================
  Evan asked for two alerts split by TRIGGER (Standard Cost vs MAC) because the
  two need different recipients.  Measured on Prod over 14 days, that design
  double-emails: 239 of 477 alerting orders trip BOTH thresholds, so the core
  team would get 716 emails, 239 of them duplicate reports of the same order.
  That works directly against Evan's stated goal of reducing email churn.

  Splitting by AUDIENCE instead gives him the same policy with no duplicates:

    ALERT 1 - "Team"                 fires on low_margin_flag = 'Y'
                                     (i.e. EITHER margin < 5%)
                                     -> Alex Sivongsay, Order Taker,
                                        Justine Daugherty, Sales Rep
                                     -> ONE email per order. Body carries BOTH
                                        GM% figures, so the reader sees which
                                        threshold failed.

    ALERT 2 - "Purchasing Escalation" fires on percent_profit_off_mac < 5
                                     -> Pam Dundas + Alex Boeve ONLY

  Core team: 716 -> 477 emails, zero duplicates.  Pam/Alex: 353 either way.
  Purchasing still sees every MAC problem; the team still sees every order once.

  Rejected: a single alert with a CONDITIONAL recipient token (an address that
  resolves only when MAC trips).  It DOES work -- p21_sp_alert_generation strips
  an <email_not_found/> recipient and still sends to everyone else -- but it also
  fires a second, bogus <email_not_found/> message that lands in alert_queued_mail
  every time it doesn't escalate (~9/day of permanent queue noise).  Not worth it.

  The live 'Low Margin Alert' (uid 97) is untouched and keeps running.
  uids: no identity columns on these tables; MAX+1 is supplied explicitly.
==============================================================================*/

USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DECLARE @nameTeam VARCHAR(255) = 'Low Margin Alert - Team';
DECLARE @namePurch VARCHAR(255) = 'Low Margin Alert - Purchasing Escalation (MAC)';
DECLARE @user    VARCHAR(50)  = 'MGOLDYN';
DECLARE @now     DATETIME     = CAST(CAST(GETDATE() AS DATE) AS DATETIME);  -- midnight, like alert 97
DECLARE @expiry  DATETIME     = '2049-12-31 23:59:59';

/*--- teardown any prior run, incl. the earlier trigger-split build ---*/
DECLARE @old TABLE (uid INT);
INSERT @old SELECT alert_implementation_uid FROM alert_implementation
 WHERE alert_implementation_name IN
   (@nameTeam, @namePurch, 'Low Margin Alert - Standard Cost', 'Low Margin Alert - MAC');

DELETE r FROM alert_recipient r
  JOIN alert_message m ON m.alert_message_uid = r.alert_message_uid
 WHERE m.alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_message              WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM Alert_implementation_query WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_implementation       WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_queued_mail          WHERE subject LIKE '[[]TEST-Play]%';

/*--- new uids ---*/
DECLARE @aTeam  INT = (SELECT ISNULL(MAX(alert_implementation_uid),0) + 1 FROM alert_implementation);
DECLARE @aPurch INT = @aTeam + 1;
DECLARE @mTeam  INT = (SELECT ISNULL(MAX(alert_message_uid),0) + 1 FROM alert_message);
DECLARE @mPurch INT = @mTeam + 1;

/*--- shared filter predicate, cloned from live alert 97 ---*/
DECLARE @common VARCHAR(2000) =
    'new_order = ''Y'' AND total_amount > 1000 AND corp_address_id <> 1046538'
  + ' AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'')'
  + ' AND customer_id NOT IN (3021352,3023035,3023036)'
  + ' AND taker NOT LIKE ''%ESTORE%'' AND extended_standard_cost > ''500'' AND rma_flag <> ''Y''';

/*==============================  ALERTS  ==============================*/
INSERT alert_implementation
  (alert_implementation_uid, alert_type_uid, alert_implementation_name, activation_date,
   expiration_date, date_created, date_last_modified, last_maintained_by, row_status_flag,
   where_clause, execution_mode_cd, next_execution_start_point, job_id, last_execution_error,
   email_notification_flag, task_notification_flag)
VALUES
  -- ALERT 1: either threshold -> the team.  low_margin_flag precomputes the OR,
  -- because P21 ANDs its filter rows and cannot express an OR in the grid.
  (@aTeam, 12, @nameTeam, @now, @expiry, @now, @now, @user, 705,
   'low_margin_flag = ''Y'' AND ' + @common, 1092, GETDATE(), '', 0, 'Y', 'N'),
  -- ALERT 2: MAC only -> purchasing
  (@aPurch, 12, @namePurch, @now, @expiry, @now, @now, @user, 705,
   'percent_profit_off_mac < 5 AND ' + @common, 1092, GETDATE(), '', 0, 'Y', 'N');

/*==========================  FILTER ROWS  =============================
  token uids: 403 new_order | 26 total_amount | 30 corp_address_id
              173 product_group_id | 29 customer_id | 111 taker
              734 extended_standard_cost | 742 low_margin_flag | 740 pct_off_mac
  operators : 1050 equals | 1049 > | 1048 < | 1053 <> | 1094 not one of
              1102 does not contain
======================================================================*/
DECLARE @q INT = (SELECT ISNULL(MAX(alert_implementation_query_uid),0) FROM Alert_implementation_query);

;WITH f AS (
    SELECT a.uid, x.column_id, x.operator_cd, x.column_value
    FROM (VALUES (@aTeam, 742, 1050, 'Y'),      -- low_margin_flag equals Y
                 (@aPurch, 740, 1048, '5')      -- percent_profit_off_mac < 5
         ) a(uid, trig_col, trig_op, trig_val)
    CROSS APPLY (VALUES
          (a.trig_col, a.trig_op, a.trig_val)                 -- THE TRIGGER
        , (403, 1050, 'Y')                                    -- new_order = Y
        , (26,  1049, '1000')                                 -- total_amount > 1000
        , (30,  1053, '1046538')                              -- corp_address_id <> ...
        , (173, 1094, 'OCHARGE,SAMPLES,PAD')                  -- product_group not one of
        , (29,  1094, '3021352,3023035,3023036')              -- customer_id not one of
        , (111, 1102, 'ESTORE')                               -- taker does not contain
        , (734, 1049, '500')                                  -- extended_standard_cost > 500
    ) x(column_id, operator_cd, column_value)
)
INSERT Alert_implementation_query
  (alert_implementation_query_uid, alert_implementation_uid, column_id, operator_cd,
   column_value, date_created, date_last_modified, last_maintained_by, row_status_flag,
   column_value_description)
SELECT @q + ROW_NUMBER() OVER (ORDER BY uid, column_id),
       uid, column_id, operator_cd, column_value, @now, @now, @user, 704, column_value
FROM f;

/*============================  EMAIL BODY  ===========================*/
DECLARE @header VARCHAR(MAX) =
     'Customer: (<customer_id>) <customer_name> <contact_name>' + CHAR(13)+CHAR(10)
  +  'Taken by: <taker>'                                        + CHAR(13)+CHAR(10)
  +  'Sales Rep: <primary_salesrep_name>'                       + CHAR(13)+CHAR(10)
  -- Evan asked for "Loc # and Name if possible" on both.
  +  'Sales Location ID: <sales_location_id> - <sales_location_name>'   + CHAR(13)+CHAR(10)
  +  'Ship Location ID: <source_location_id> - <ship_location_name>'    + CHAR(13)+CHAR(10)
  +  'Job Number: <job_name>'                                   + CHAR(13)+CHAR(10)
  +  'Number of Lines: <total_line_items>'                      + CHAR(13)+CHAR(10)
  +  'Validation: <validation_status>'                          + CHAR(13)+CHAR(10)
  +  '--------------------------------------------------------';

-- BOTH GM% figures appear on every email, in both alerts. That is what lets one
-- message serve both thresholds -- the reader sees which one failed.
DECLARE @line VARCHAR(MAX) =
     'Lines Items:'                                                        + CHAR(13)+CHAR(10)
  +  '<item_id> - <item_description>'                                      + CHAR(13)+CHAR(10)
  +  'Order Qty: <order_quantity>'                                         + CHAR(13)+CHAR(10)
  +  'Sell Price: $<unit_price>'                                           + CHAR(13)+CHAR(10)
  +  'MAC: $<unit_mac>'                                                    + CHAR(13)+CHAR(10)
  +  'Standard Cost: $<unit_standard_cost>'                                + CHAR(13)+CHAR(10)
  +  'Price Page Description: <price_page_description>'                    + CHAR(13)+CHAR(10)
  +  'Req Date: <line_required_date>'                                      + CHAR(13)+CHAR(10)
  +  'Unit of Measure: <unit_of_measure>'                                  + CHAR(13)+CHAR(10)
  +  'Percent Profit off MAC: <percent_profit_off_mac>'                    + CHAR(13)+CHAR(10)
  +  'Percent Profit off Standard Cost: <percent_profit_off_standard_cost>';

DECLARE @footerTeam VARCHAR(MAX) =
     'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Note: Extended Standard Cost is calculated using the item''s default stocking unit, not the order unit of measure. When these differ (e.g., ordered in cartons but costed per square foot), the extended cost may appear disproportionate to the unit price shown.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Note: For MAC or Supplier Cost questions, please contact Purchasing Team. For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Email generated by P21, Have a great day!';

DECLARE @footerPurch VARCHAR(MAX) =
     'Note: This order''s margin is below 5% against MAC. Purchasing Team, please verify MAC and Supplier Cost. If MAC is the issue, please notify Finance.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Note: Extended Standard Cost is calculated using the item''s default stocking unit, not the order unit of measure. When these differ (e.g., ordered in cartons but costed per square foot), the extended cost may appear disproportionate to the unit price shown.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Email generated by P21, Have a great day!';

-- sender_email_address MUST be NULL, never '' -- P21 only falls back to
-- alert_default_smtp_sender_email when it IS NULL. An empty string parks the mail
-- in alert_queued_mail as reason_cd 1060 "Email system down" (misleading).
INSERT alert_message
  (alert_message_uid, alert_implementation_uid, subject, header, line_item, footer,
   attachment, sender_name, sender_email_address, date_created, date_last_modified,
   last_maintained_by, row_status_flag)
VALUES
  (@mTeam, @aTeam,
   '[TEST-Play] Low Margin - Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footerTeam, NULL, 'Alert - Low Margin', NULL, @now, @now, @user, 704),
  (@mPurch, @aPurch,
   '[TEST-Play] Low Margin vs MAC (Purchasing) - Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footerPurch, NULL, 'Alert - Low Margin (Purchasing)', NULL, @now, @now, @user, 704);

/*=====================  RECIPIENTS — mgoldyn ONLY IN PLAY  ============
  PROD (from the deploy guide):
    Alert 1 "Team"  -> asivongsay@allsurfaces.com          (Alex Sivongsay)
                       <taker_email>                        (Order Taker - token)
                       jdaugherty@allsurfaces.com           (Justine Daugherty)
                       <primary_salesrep_email>             (Sales Rep - token)
    Alert 2 "Purch" -> Pam Dundas + Alex Boeve  (addresses still to obtain)
  record_type_cd 1059 = Email Recipient (NOT NULL).
  recipient_type_cd  1281 = To, 1282 = CC, 1283 = BCC.
======================================================================*/
DECLARE @r INT = (SELECT ISNULL(MAX(alert_recipient_uid),0) FROM alert_recipient);

INSERT alert_recipient
  (alert_recipient_uid, alert_message_uid, alert_email_name, alert_email_address,
   date_created, date_last_modified, last_maintained_by, row_status_flag,
   record_type_cd, recipient_type_cd)
VALUES
  (@r + 1, @mTeam,  'mgoldyn', 'mgoldyn@allsurfaces.com', @now, @now, @user, 704, 1059, 1281),
  (@r + 2, @mPurch, 'mgoldyn', 'mgoldyn@allsurfaces.com', @now, @now, @user, 704, 1059, 1281);

COMMIT;
PRINT 'Created: Team = ' + CAST(@aTeam AS VARCHAR) + ', Purchasing = ' + CAST(@aPurch AS VARCHAR);
GO

/*--- Verify ---*/
SELECT ai.alert_implementation_uid AS uid, ai.alert_implementation_name AS name,
       ai.row_status_flag, ai.where_clause,
       filters    = (SELECT COUNT(*) FROM Alert_implementation_query q WHERE q.alert_implementation_uid = ai.alert_implementation_uid),
       recipients = (SELECT COUNT(*) FROM alert_recipient r JOIN alert_message m ON m.alert_message_uid=r.alert_message_uid
                     WHERE m.alert_implementation_uid = ai.alert_implementation_uid)
FROM   alert_implementation ai
WHERE  ai.alert_type_uid = 12 AND ai.alert_implementation_name LIKE 'Low Margin Alert -%'
ORDER BY ai.alert_implementation_uid;
GO

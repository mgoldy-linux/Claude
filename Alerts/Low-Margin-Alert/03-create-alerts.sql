/*==============================================================================
  Low Margin Alert — Step 3: create the two alert definitions
  Target : P21Play          Author: Mark Goldyn / Claude    Date: 2026-07-14
  Depends on: 01-alter-view..., 02-register-tokens...

  IDEMPOTENT + TRANSACTIONAL — deletes any prior copy by name, then rebuilds.

  ############################################################################
  ##  SAFETY: RECIPIENTS ARE mgoldyn ONLY.                                   ##
  ##  P21Play HAS LIVE SMTP (enable_email_functionality = Y, email_type =    ##
  ##  SMTP, sender noreply@allsurfaces.com).  Evan's real recipient list     ##
  ##  (Alex Sivongsay, Order Taker, Justine Daugherty, Sales Rep, + Pam      ##
  ##  Dundas & Alex Boeve on the MAC alert) is applied at PROD DEPLOY ONLY.  ##
  ##  See the deploy guide.  DO NOT add real recipients in Play.             ##
  ############################################################################

  Built as TWO alerts, per Evan's spec (his Standard Cost and MAC triggers have
  different recipient lists, and a P21 alert has one recipient set).
  NB: measured on Prod, 239 of 477 alerting orders trip BOTH triggers, so this
  design double-emails them (716 emails/14d vs 477 for a combined alert). A
  'low_margin_flag' token was registered to allow a single combined alert later
  with no further view change.  Evan's call.

  None of this touches the live 'Low Margin Alert' (uid 97) — it keeps running.

  uids: no identity columns on these tables; MAX+1 is supplied explicitly.
==============================================================================*/

USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DECLARE @nameStd VARCHAR(255) = 'Low Margin Alert - Standard Cost';
DECLARE @nameMac VARCHAR(255) = 'Low Margin Alert - MAC';
DECLARE @user    VARCHAR(50)  = 'MGOLDYN';
DECLARE @now     DATETIME     = GETDATE();
DECLARE @expiry  DATETIME     = '2049-12-31 23:59:59';

/*--- teardown any prior run (children first — FK order) ---*/
DECLARE @old TABLE (uid INT);
INSERT @old SELECT alert_implementation_uid FROM alert_implementation
 WHERE alert_implementation_name IN (@nameStd, @nameMac);

DELETE r FROM alert_recipient r
  JOIN alert_message m ON m.alert_message_uid = r.alert_message_uid
 WHERE m.alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_message              WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM Alert_implementation_query WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_implementation       WHERE alert_implementation_uid IN (SELECT uid FROM @old);

/*--- new uids ---*/
DECLARE @aStd INT = (SELECT ISNULL(MAX(alert_implementation_uid),0) + 1 FROM alert_implementation);
DECLARE @aMac INT = @aStd + 1;
DECLARE @mStd INT = (SELECT ISNULL(MAX(alert_message_uid),0) + 1 FROM alert_message);
DECLARE @mMac INT = @mStd + 1;

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
   where_clause, execution_mode_cd, job_id, last_execution_error,
   email_notification_flag, task_notification_flag)
VALUES
  (@aStd, 12, @nameStd, @now, @expiry, @now, @now, @user, 705,
   'percent_profit_off_standard_cost < 5 AND ' + @common, 1092, '', 0, 'Y', 'N'),
  (@aMac, 12, @nameMac, @now, @expiry, @now, @now, @user, 705,
   'percent_profit_off_mac < 5 AND ' + @common, 1092, '', 0, 'Y', 'N');

/*==========================  FILTER ROWS  =============================
  token uids: 403 new_order | 26 total_amount | 30 corp_address_id
              173 product_group_id | 29 customer_id | 111 taker
              734 extended_standard_cost | 741 pct_off_std | 740 pct_off_mac
  operators : 1050 equals | 1049 > | 1048 < | 1053 <> | 1094 not one of
              1102 does not contain
======================================================================*/
DECLARE @q INT = (SELECT ISNULL(MAX(alert_implementation_query_uid),0) FROM Alert_implementation_query);

;WITH f AS (
    SELECT a.uid, x.column_id, x.operator_cd, x.column_value
    FROM (VALUES (@aStd, 741), (@aMac, 740)) a(uid, trigger_token)
    CROSS APPLY (VALUES
          (a.trigger_token, 1048, '5')                        -- THE TRIGGER (< 5%)
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

/*============================  EMAIL BODY  ============================
  Evan's mock, 2026-06-30.  New vs the live alert:
    header    + Sales Rep, Sales Location ID, Ship Location ID
    line item + Sell Price, MAC, Standard Cost, Price Page Description,
                Percent Profit off MAC, Percent Profit off Standard Cost
    footer    + 2 notes (the stocking-unit note already existed)
======================================================================*/
DECLARE @header VARCHAR(MAX) =
     'Customer: (<customer_id>) <customer_name> <contact_name>' + CHAR(13)+CHAR(10)
  +  'Taken by: <taker>'                                        + CHAR(13)+CHAR(10)
  +  'Sales Rep: <primary_salesrep_name>'                       + CHAR(13)+CHAR(10)
  +  'Sales Location ID: <sales_location_id>'                   + CHAR(13)+CHAR(10)
  +  'Ship Location ID: <source_location_id>'                   + CHAR(13)+CHAR(10)
  +  'Job Number: <job_name>'                                   + CHAR(13)+CHAR(10)
  +  'Number of Lines: <total_line_items>'                      + CHAR(13)+CHAR(10)
  +  'Validation: <validation_status>'                          + CHAR(13)+CHAR(10)
  +  '--------------------------------------------------------';

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

DECLARE @footer VARCHAR(MAX) =
     'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Note: Extended Standard Cost is calculated using the item''s default stocking unit, not the order unit of measure. When these differ (e.g., ordered in cartons but costed per square foot), the extended cost may appear disproportionate to the unit price shown.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Note: For MAC or Supplier Cost questions, please contact Purchasing Team. For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com.' + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
  +  'Email generated by P21, Have a great day!';

INSERT alert_message
  (alert_message_uid, alert_implementation_uid, subject, header, line_item, footer,
   attachment, sender_name, sender_email_address, date_created, date_last_modified,
   last_maintained_by, row_status_flag)
VALUES
  (@mStd, @aStd,
   '[TEST-Play] Low Margin (Standard Cost) Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footer, NULL, 'Alert - Low Margin (Standard Cost)', NULL, @now, @now, @user, 704),
  (@mMac, @aMac,
   '[TEST-Play] Low Margin (MAC) Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footer, NULL, 'Alert - Low Margin (MAC)', NULL, @now, @now, @user, 704);
-- ⚠ sender_email_address MUST be NULL, never '' (empty string).
--   P21 falls back to system_setting alert_default_smtp_sender_email ONLY when
--   this is NULL. An empty string is not NULL, so it tried to send FROM an empty
--   address and parked the mail in alert_queued_mail with reason_cd 1060 =
--   "Email system down" -- which reads like an infrastructure outage but is not.
--   The working alert (uid 97) has NULL here.

/*=====================  RECIPIENTS — mgoldyn ONLY  ====================*/
DECLARE @r INT = (SELECT ISNULL(MAX(alert_recipient_uid),0) FROM alert_recipient);

-- record_type_cd 1059 = 'Email Recipient' (NOT NULL; the only value in use)
-- recipient_type_cd 1281 = To, 1282 = CC, 1283 = BCC
INSERT alert_recipient
  (alert_recipient_uid, alert_message_uid, alert_email_name, alert_email_address,
   date_created, date_last_modified, last_maintained_by, row_status_flag,
   record_type_cd, recipient_type_cd)
VALUES
  (@r + 1, @mStd, 'mgoldyn', 'mgoldyn@allsurfaces.com', @now, @now, @user, 704, 1059, 1281),  -- To
  (@r + 2, @mMac, 'mgoldyn', 'mgoldyn@allsurfaces.com', @now, @now, @user, 704, 1059, 1281);  -- To

COMMIT;
PRINT 'Created alerts: Standard Cost = ' + CAST(@aStd AS VARCHAR) + ', MAC = ' + CAST(@aMac AS VARCHAR);
GO

/*--- Verify ---*/
SELECT ai.alert_implementation_uid AS uid, ai.alert_implementation_name AS name,
       ai.row_status_flag, ai.where_clause,
       filters   = (SELECT COUNT(*) FROM Alert_implementation_query q WHERE q.alert_implementation_uid = ai.alert_implementation_uid),
       recipients= (SELECT COUNT(*) FROM alert_recipient r JOIN alert_message m ON m.alert_message_uid=r.alert_message_uid
                    WHERE m.alert_implementation_uid = ai.alert_implementation_uid)
FROM   alert_implementation ai
WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Standard Cost','Low Margin Alert - MAC')
ORDER BY ai.alert_implementation_uid;
GO

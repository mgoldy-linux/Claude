/*==============================================================================
  Low PAD Margin Alert — create the alert definitions (PAD-scoped duplicate of
  Low Margin Alert - Team / Purchasing Escalation).
  Target : P21Play          Author: Mark Goldyn / Claude    Date: 2026-07-31
  Depends on: 01-alter-view-add-margin-columns.sql, 02-register-tokens.sql
              (already applied to Play; same view/tokens are reused, no new
              columns or tokens needed for this alert)

  IDEMPOTENT + TRANSACTIONAL -- deletes any prior copy by name, then rebuilds.

  ############################################################################
  ##  SAFETY: RECIPIENTS ARE mgoldyn ONLY.                                   ##
  ##  P21Play HAS LIVE SMTP. Real recipients are applied at PROD DEPLOY ONLY,##
  ##  same as Low Margin Alert - Team / Purchasing Escalation.               ##
  ############################################################################

  =========================  WHY THIS ALERT EXISTS  =========================
  Duplicate of the just-rebuilt Low Margin Alert (Team/Purchasing split), but
  scoped to the PAD product group -- which the original alert deliberately
  EXCLUDES (product_group_id NOT IN ('OCHARGE','SAMPLES','PAD')). This gives
  PAD orders their own low-margin alert on the SAME modern trigger (MAC /
  Standard Cost via low_margin_flag / percent_profit_off_mac), replacing the
  older, separate 'Low PAD Margin Alert' (active since 2025-12-18, triggers
  on the legacy line_item_profit_percentage < -5 column, Product Group ID
  EQUALS PAD, Taker "does not begin with" ESTORE).

  Decisions confirmed with user (2026-07-31):
  - Trigger: reuse the NEW low_margin_flag / percent_profit_off_mac columns,
    NOT the old line_item_profit_percentage measure -- keeps every Low Margin
    variant on one consistent margin definition.
  - Recipients: same Team + Purchasing Escalation split as the non-PAD alert.
  - Taker filter: NOT LIKE '%ESTORE%' (does not CONTAIN), matching the
    non-PAD alert -- NOT "does not begin with" as the old PAD alert has it.

  The old 'Low PAD Margin Alert' (Product Group ID = PAD, legacy trigger) is
  UNTOUCHED and keeps running -- same "old alert stays live" pattern as uid 97.
  uids: no identity columns on these tables; MAX+1 is supplied explicitly.
  Token uids resolved BY NAME (not hardcoded) -- they differ across envs.
==============================================================================*/

USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DECLARE @nameTeam VARCHAR(255) = 'Low PAD Margin Alert - Team';
DECLARE @namePurch VARCHAR(255) = 'Low PAD Margin Alert - Purchasing Escalation (MAC)';
DECLARE @user    VARCHAR(50)  = 'MGOLDYN';
DECLARE @now     DATETIME     = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
DECLARE @expiry  DATETIME     = '2049-12-31 23:59:59';
DECLARE @nl VARCHAR(2) = CHAR(13)+CHAR(10);
DECLARE @br VARCHAR(4) = CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10);

/*--- teardown any prior run ---*/
DECLARE @old TABLE (uid INT);
INSERT @old SELECT alert_implementation_uid FROM alert_implementation
 WHERE alert_implementation_name IN (@nameTeam, @namePurch);

DELETE r FROM alert_recipient r
  JOIN alert_message m ON m.alert_message_uid = r.alert_message_uid
 WHERE m.alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_message              WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM Alert_implementation_query WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_implementation       WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_queued_mail          WHERE subject LIKE '[[]TEST-Play]%Low PAD Margin%';

/*--- new uids ---*/
DECLARE @aTeam  INT = (SELECT ISNULL(MAX(alert_implementation_uid),0) + 1 FROM alert_implementation);
DECLARE @aPurch INT = @aTeam + 1;
DECLARE @mTeam  INT = (SELECT ISNULL(MAX(alert_message_uid),0) + 1 FROM alert_message);
DECLARE @mPurch INT = @mTeam + 1;

/*--- shared filter predicate: same as Low Margin Alert EXCEPT product_group_id
      is now EQUALS 'PAD' instead of NOT IN ('OCHARGE','SAMPLES','PAD') ---*/
DECLARE @common VARCHAR(2000) =
    'new_order = ''Y'' AND total_amount > 1000 AND corp_address_id <> 1046538'
  + ' AND product_group_id = ''PAD'''
  + ' AND customer_id NOT IN (3021352,3023035,3023036)'
  + ' AND taker NOT LIKE ''%ESTORE%'' AND extended_standard_cost > ''500'' AND rma_flag <> ''Y''';

/*==============================  ALERTS  ==============================*/
INSERT alert_implementation
  (alert_implementation_uid, alert_type_uid, alert_implementation_name, activation_date,
   expiration_date, date_created, date_last_modified, last_maintained_by, row_status_flag,
   where_clause, execution_mode_cd, next_execution_start_point, job_id, last_execution_error,
   email_notification_flag, task_notification_flag)
VALUES
  (@aTeam, 12, @nameTeam, @now, @expiry, @now, @now, @user, 704,
   'low_margin_flag = ''Y'' AND ' + @common, 1092, GETDATE(), '', 0, 'Y', 'N'),
  (@aPurch, 12, @namePurch, @now, @expiry, @now, @now, @user, 704,
   'percent_profit_off_mac < 5 AND ' + @common, 1092, GETDATE(), '', 0, 'Y', 'N');

/*==========================  FILTER ROWS  =============================
  Resolved BY TOKEN NAME (not hardcoded uid) -- token uids differ per env.
======================================================================*/
DECLARE @q INT = (SELECT ISNULL(MAX(alert_implementation_query_uid),0) FROM Alert_implementation_query);

;WITH tok AS (
    SELECT t.token_uid, t.name
    FROM token t
    JOIN alert_type_x_token x ON x.token_uid = t.token_uid
    WHERE x.alert_type_uid = 12
      AND t.name IN ('new_order','total_amount','corp_address_id','product_group_id',
                     'customer_id','taker','extended_standard_cost',
                     'low_margin_flag','percent_profit_off_mac')
),
f AS (
    SELECT a.uid, x.token_name, x.operator_cd, x.column_value
    FROM (VALUES (@aTeam, 'low_margin_flag', 1050, 'Y'),
                 (@aPurch, 'percent_profit_off_mac', 1048, '5')
         ) a(uid, trig_name, trig_op, trig_val)
    CROSS APPLY (VALUES
          (a.trig_name, a.trig_op, a.trig_val)                       -- THE TRIGGER
        , ('new_order', 1050, 'Y')
        , ('total_amount', 1049, '1000')
        , ('corp_address_id', 1053, '1046538')
        , ('product_group_id', 1050, 'PAD')                          -- equals, not "not one of"
        , ('customer_id', 1094, '3021352,3023035,3023036')
        , ('taker', 1102, 'ESTORE')                                  -- does not CONTAIN
        , ('extended_standard_cost', 1049, '500')
    ) x(token_name, operator_cd, column_value)
)
INSERT Alert_implementation_query
  (alert_implementation_query_uid, alert_implementation_uid, column_id, operator_cd,
   column_value, date_created, date_last_modified, last_maintained_by, row_status_flag,
   column_value_description)
SELECT @q + ROW_NUMBER() OVER (ORDER BY f.uid, tok.token_uid),
       f.uid, tok.token_uid, f.operator_cd, f.column_value, @now, @now, @user, 704, f.column_value
FROM f
JOIN tok ON tok.name = f.token_name;

/*============================  EMAIL BODY  ===========================
  Same design/tokens as Low Margin Alert - Team / Purchasing -- only the
  subject/sender_name mention "PAD" so recipients can tell the alerts apart.
======================================================================*/
DECLARE @header VARCHAR(MAX) =
     'Customer: (<customer_id>) <customer_name> <contact_name>'           + @nl
  +  'Taken by: <taker>'                                                  + @nl
  +  'Sales Rep: <primary_salesrep_name>'                                 + @nl
  +  'Sales Location: <sales_location_id> - <sales_location_name>'        + @nl
  +  'Ship Location: <source_location_id> - <ship_location_name>'         + @nl
  +  'Job: <job_name>   |   Lines: <total_line_items>   |   Validation: <validation_status>' + @nl
  +  '------------------------------------------------------------';

DECLARE @line VARCHAR(MAX) =
     'Lines Items:'                                                        + @nl
  +  '<item_id> - <item_description>'                                      + @br
  +  'Order Qty: <order_quantity>'                                         + @br
  +  'Sell Price: $<unit_price>'                                           + @br
  +  'MAC: $<unit_mac>'                                                    + @nl
  +  'Standard Cost: $<unit_standard_cost>'                                + @nl
  +  'Price Page Description: <price_page_description>'                    + @nl
  +  'Req Date: <line_required_date>   |   UOM: <unit_of_measure>'         + @nl
  +  'Percent Profit off MAC: <percent_profit_off_mac>%   |   Percent Profit off Standard Cost: <percent_profit_off_standard_cost>%';

DECLARE @footerTeam VARCHAR(MAX) =
     'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.' + @br
  +  'Note: Extended Standard Cost is calculated using the item''s default stocking unit, not the order unit of measure. When these differ (e.g., ordered in cartons but costed per square foot), the extended cost may appear disproportionate to the unit price shown.' + @br
  +  'Note: For MAC or Supplier Cost questions, please contact Purchasing Team. For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com.' + @br
  +  'Email generated by P21, Have a great day!';

DECLARE @footerPurch VARCHAR(MAX) =
     'Note: This order''s margin is below 5% against MAC. Purchasing Team, please verify MAC and Supplier Cost. If MAC is the issue, please notify Finance.' + @br
  +  'Note: Extended Standard Cost is calculated using the item''s default stocking unit, not the order unit of measure. When these differ (e.g., ordered in cartons but costed per square foot), the extended cost may appear disproportionate to the unit price shown.' + @br
  +  'Email generated by P21, Have a great day!';

INSERT alert_message
  (alert_message_uid, alert_implementation_uid, subject, header, line_item, footer,
   attachment, sender_name, sender_email_address, date_created, date_last_modified,
   last_maintained_by, row_status_flag)
VALUES
  (@mTeam, @aTeam,
   '[TEST-Play] Low PAD Margin - Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footerTeam, NULL, 'Alert - Low PAD Margin', NULL, @now, @now, @user, 704),
  (@mPurch, @aPurch,
   '[TEST-Play] Low PAD Margin vs MAC (Purchasing) - Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footerPurch, NULL, 'Alert - Low PAD Margin (Purchasing)', NULL, @now, @now, @user, 704);

/*=====================  RECIPIENTS — mgoldyn ONLY IN PLAY  ===========
  PROD (once Play-tested): same real list as Low Margin Alert -
    Team  -> asivongsay@allsurfaces.com, <taker_email>, jdaugherty@allsurfaces.com, <primary_salesrep_email>
    Purch -> pdundas@allsurfaces.com, aboeve@allsurfaces.com
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
PRINT 'Created: PAD Team = ' + CAST(@aTeam AS VARCHAR) + ', PAD Purchasing = ' + CAST(@aPurch AS VARCHAR);
GO

/*--- Verify ---*/
SELECT ai.alert_implementation_uid AS uid, ai.alert_implementation_name AS name,
       ai.row_status_flag, ai.where_clause,
       filters    = (SELECT COUNT(*) FROM Alert_implementation_query q WHERE q.alert_implementation_uid = ai.alert_implementation_uid),
       recipients = (SELECT COUNT(*) FROM alert_recipient r JOIN alert_message m ON m.alert_message_uid=r.alert_message_uid
                     WHERE m.alert_implementation_uid = ai.alert_implementation_uid)
FROM   alert_implementation ai
WHERE  ai.alert_type_uid = 12 AND ai.alert_implementation_name LIKE 'Low PAD Margin Alert -%'
ORDER BY ai.alert_implementation_uid;
GO

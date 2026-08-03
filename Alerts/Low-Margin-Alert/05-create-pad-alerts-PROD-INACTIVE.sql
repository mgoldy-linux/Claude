/*==============================================================================
  Low PAD Margin Alert — PROD variant: create the alert definitions,
  DEPLOYED INACTIVE (705), same preservation pattern as
  03-create-alerts-PROD-INACTIVE.sql.
  Target : P21 (Prod)      Author: Mark Goldyn / Claude    Date: 2026-08-03
  Depends on: 01/02-...-PROD.sql (already applied to Prod 2026-07-31 -- same
              view/tokens are reused, nothing new needed here)

  IDEMPOTENT + TRANSACTIONAL -- deletes any prior copy by name, then rebuilds.

  ############################################################################
  ##  Deployed INACTIVE (705) -- confirmed with user 2026-08-03. No PAD-     ##
  ##  alert-equivalent sign-off (like Evan's for the main pair) has          ##
  ##  happened yet. Real recipients are baked in but WILL NOT fire until     ##
  ##  someone explicitly flips row_status_flag to 704.                      ##
  ############################################################################

  The older, separate 'Low PAD Margin Alert' (legacy line_item_profit_percentage
  trigger, Product Group ID = PAD) is UNTOUCHED and keeps running in Prod.
  uids: no identity columns on these tables; MAX+1 is supplied explicitly.
  Token uids resolved BY NAME, not hardcoded (differ across envs).
==============================================================================*/

USE P21;
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

/*--- teardown any prior run of THIS script ---*/
DECLARE @old TABLE (uid INT);
INSERT @old SELECT alert_implementation_uid FROM alert_implementation
 WHERE alert_implementation_name IN (@nameTeam, @namePurch);

DELETE r FROM alert_recipient r
  JOIN alert_message m ON m.alert_message_uid = r.alert_message_uid
 WHERE m.alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_message              WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM Alert_implementation_query WHERE alert_implementation_uid IN (SELECT uid FROM @old);
DELETE FROM alert_implementation       WHERE alert_implementation_uid IN (SELECT uid FROM @old);

/*--- new uids ---*/
DECLARE @aTeam  INT = (SELECT ISNULL(MAX(alert_implementation_uid),0) + 1 FROM alert_implementation);
DECLARE @aPurch INT = @aTeam + 1;
DECLARE @mTeam  INT = (SELECT ISNULL(MAX(alert_message_uid),0) + 1 FROM alert_message);
DECLARE @mPurch INT = @mTeam + 1;

/*--- shared filter predicate: same as Low Margin Alert EXCEPT product_group_id
      is EQUALS 'PAD' instead of NOT IN ('OCHARGE','SAMPLES','PAD') ---*/
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
  -- row_status_flag = 705 = INACTIVE. Flip to 704 only once someone signs off:
  --   UPDATE alert_implementation SET row_status_flag = 704
  --   WHERE alert_implementation_name IN (@nameTeam, @namePurch);
  (@aTeam, 12, @nameTeam, @now, @expiry, @now, @now, @user, 705,
   'low_margin_flag = ''Y'' AND ' + @common, 1092, GETDATE(), '', 0, 'Y', 'N'),
  (@aPurch, 12, @namePurch, @now, @expiry, @now, @now, @user, 705,
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

/*============================  EMAIL BODY  ===========================*/
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

-- Subject lines have NO [TEST-Play] tag -- real Prod subject.
INSERT alert_message
  (alert_message_uid, alert_implementation_uid, subject, header, line_item, footer,
   attachment, sender_name, sender_email_address, date_created, date_last_modified,
   last_maintained_by, row_status_flag)
VALUES
  (@mTeam, @aTeam,
   'Low PAD Margin - Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footerTeam, NULL, 'Alert - Low PAD Margin', NULL, @now, @now, @user, 704),
  (@mPurch, @aPurch,
   'Low PAD Margin vs MAC (Purchasing) - Order# <order_number> for <customer_name> - Total: $<total_amount>',
   @header, @line, @footerPurch, NULL, 'Alert - Low PAD Margin (Purchasing)', NULL, @now, @now, @user, 704);

/*=====================  RECIPIENTS — THE REAL LIST  ===================
  Same real list as Low Margin Alert - Team / Purchasing Escalation.
======================================================================*/
DECLARE @r INT = (SELECT ISNULL(MAX(alert_recipient_uid),0) FROM alert_recipient);

INSERT alert_recipient
  (alert_recipient_uid, alert_message_uid, alert_email_name, alert_email_address,
   date_created, date_last_modified, last_maintained_by, row_status_flag,
   record_type_cd, recipient_type_cd)
VALUES
  -- Team alert
  (@r + 1, @mTeam,  'Alex Sivongsay',  'asivongsay@allsurfaces.com', @now, @now, @user, 704, 1059, 1281),
  (@r + 2, @mTeam,  'Order Taker',     '<taker_email>',              @now, @now, @user, 704, 1059, 1281),
  (@r + 3, @mTeam,  'Justine Daugherty','jdaugherty@allsurfaces.com',@now, @now, @user, 704, 1059, 1281),
  (@r + 4, @mTeam,  'Sales Rep',       '<primary_salesrep_email>',   @now, @now, @user, 704, 1059, 1281),
  -- Purchasing Escalation alert
  (@r + 5, @mPurch, 'Pam Dundas',      'pdundas@allsurfaces.com',    @now, @now, @user, 704, 1059, 1281),
  (@r + 6, @mPurch, 'Alex Boeve',      'aboeve@allsurfaces.com',     @now, @now, @user, 704, 1059, 1281);

COMMIT;
PRINT 'Created (INACTIVE, 705): PAD Team = ' + CAST(@aTeam AS VARCHAR) + ', PAD Purchasing = ' + CAST(@aPurch AS VARCHAR);
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

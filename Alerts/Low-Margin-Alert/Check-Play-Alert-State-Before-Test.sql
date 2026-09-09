/*==============================================================================
  Check-Play-Alert-State-Before-Test.sql     READ-ONLY. Run in SSMS vs P21Play.

  *** PRE-FLIGHT. Run this BEFORE building any test order in Play. ***

  Why: P21Play was refreshed 2026-09-06 FROM Prod. Prod's four Low Margin
  alerts went LIVE (row_status_flag 704) with REAL recipients on 2026-09-04.
  So Play's restored copy is very likely ACTIVE with REAL recipients -- and
  Play has live SMTP (enable_email_functionality = Y).

  A test order built right now could genuinely email Alex Sivongsay, Justine
  Daugherty, Erik Bullock, Evan Jenkins, Jere Butler, the RSM and the sales
  rep. That has already happened twice on this project post-refresh.

  DO NOT build a test order until Q1 shows 705, or Q2 shows mgoldyn-only.

  Q0  Column names for the alert tables (safety net if a join below errors)
  Q1  Status of the four alerts
  Q2  Recipients on each
  Q3  Test-order feasibility -- stock on hand for the known recipe
  Q4  A natural NOT-overridden low-margin example, to show the other rendering
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;

/*------------------------------------------------------------------ Q0 -----
  Run this first. If Q2's join errors on a column name, the answer is here.
---------------------------------------------------------------------------*/
PRINT '=== Q0: alert table columns ===';
SELECT  TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM    INFORMATION_SCHEMA.COLUMNS
WHERE   TABLE_NAME IN ('alert_recipient','alert_message','alert_implementation')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

/*------------------------------------------------------------------ Q1 -----
  704 = ACTIVE (fires) / 705 = INACTIVE. Anything 704 here is a live-fire risk.
---------------------------------------------------------------------------*/
PRINT '=== Q1: alert status in PLAY ===';
SELECT  ai.alert_implementation_uid
      , ai.alert_implementation_name
      , ai.row_status_flag
      , state = CASE ai.row_status_flag
                     WHEN 704 THEN '*** ACTIVE - WILL FIRE ***'
                     WHEN 705 THEN 'inactive (safe)'
                     ELSE 'other' END
      , ai.last_maintained_by
      , ai.date_last_modified
FROM    dbo.alert_implementation ai
WHERE   ai.alert_implementation_name LIKE '%Margin%'
ORDER BY ai.alert_implementation_name;
GO

/*------------------------------------------------------------------ Q2 -----
  Who would actually receive a test fire.
  recipient_type_cd: 1281 = To, 1282 = CC, 1283 = BCC. record_type_cd 1059.
  Anything that is not mgoldyn@allsurfaces.com is a real person.
---------------------------------------------------------------------------*/
PRINT '=== Q2: recipients in PLAY ===';
SELECT  ai.alert_implementation_name
      , ar.alert_email_address
      , ar.recipient_type_cd
      , placement = CASE ar.recipient_type_cd
                         WHEN 1281 THEN 'To'
                         WHEN 1282 THEN 'CC'
                         WHEN 1283 THEN 'BCC'
                         ELSE CAST(ar.recipient_type_cd AS VARCHAR(20)) END
      , ar.row_status_flag
      , risk = CASE WHEN ar.alert_email_address LIKE '%mgoldyn%' THEN 'self - safe'
                    ELSE '*** REAL PERSON ***' END
FROM        dbo.alert_recipient      ar
JOIN        dbo.alert_message        am ON am.alert_message_uid        = ar.alert_message_uid
JOIN        dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE       ai.alert_implementation_name LIKE '%Margin%'
ORDER BY    ai.alert_implementation_name, ar.recipient_type_cd, ar.alert_email_address;
GO

/*------------------------------------------------------------------ Q3 -----
  The known-good test recipe from 2026-08-28 was MAP1785142 @ location 100,
  100 EA, sell price overridden to $16.00. The 9/6 refresh reset inventory to
  Prod's state, so availability must be re-checked -- the 8/28 session lost a
  first attempt to a 0-on-hand block.
---------------------------------------------------------------------------*/
PRINT '=== Q3: test item availability + current costs ===';
SELECT  im.item_id
      , il.location_id
      , il.qty_on_hand
      , qty_available = il.qty_on_hand - ISNULL(il.qty_allocated,0)
      , il.moving_average_cost
      , il.standard_cost
      , il.stockable
FROM        dbo.inv_mast im
JOIN        dbo.inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid
WHERE       im.item_id IN ('MAP1785142','ROB7399-1')
  AND       il.location_id IN (100, 120)
ORDER BY    im.item_id, il.location_id;
GO

/*------------------------------------------------------------------ Q4 -----
  Evan should see BOTH renderings: overridden (the recipe above produces
  price_edit = 'Y') and NOT overridden (price_edit blank/N).

  Q3b on Prod showed 12,140 low-margin lines in 120 days, 4,439 flagged 'Y' --
  so ~7,700 tripped the alert WITHOUT an override. This finds recent Play
  examples, to reuse the item/customer rather than invent one.
---------------------------------------------------------------------------*/
PRINT '=== Q4: recent low-margin lines that were NOT overridden ===';
SELECT TOP (20)
        ol.order_no
      , im.item_id
      , ol.unit_price
      , ol.system_calc_unit_price
      , ol.manual_price_overide
      , ol.price_page_uid
      , il.moving_average_cost
      , il.standard_cost
      , pct_off_mac = CAST((ol.unit_price - COALESCE(il.moving_average_cost * ol.pricing_unit_size,0))
                           / NULLIF(ol.unit_price,0) * 100 AS DECIMAL(19,2))
      , ol.date_created
FROM        dbo.oe_line  ol
JOIN        dbo.inv_mast im ON im.inv_mast_uid = ol.inv_mast_uid
JOIN        dbo.inv_loc  il ON il.inv_mast_uid = ol.inv_mast_uid
                           AND il.location_id  = ol.source_loc_id
WHERE       ol.date_created >= DATEADD(DAY, -60, GETDATE())
  AND       COALESCE(ol.manual_price_overide,'N') <> 'Y'
  AND       ISNULL(ol.unit_price,0) <> 0
  AND     ( (ol.unit_price - COALESCE(il.moving_average_cost * ol.pricing_unit_size,0)) / ol.unit_price * 100 < 5
         OR (ol.unit_price - COALESCE(il.standard_cost       * ol.pricing_unit_size,0)) / ol.unit_price * 100 < 5 )
ORDER BY    ol.date_created DESC;
GO

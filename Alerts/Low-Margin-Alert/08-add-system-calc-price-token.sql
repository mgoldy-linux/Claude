/*==============================================================================
  08 — Add the system-calculated (pre-override) price to the Low Margin alerts
  Target : P21Play ONLY. Do not run against Prod without the drift check below.
  Author : Mark Goldyn / Claude          Date: 2026-09-09
  Depends on: 01 (margin columns) and 07 (rsm_email) already deployed.

  Ask (Evan Jenkins, 2026-09-04; refined by the user 2026-09-09 after the first
  test emails came through): show what the price WOULD have been next to the
  overridden Sell Price -- "see both where the original price calculated from
  and whether that price was overridden on the order."

  Source: oe_line.system_calc_unit_price -- P21 stores the pre-edit calculated
  price on the line. Nothing needs re-deriving from the pricing engine. It is
  NOT currently in this view (verified: 0 occurrences), hence this script.

  ── Two columns added ──────────────────────────────────────────────────────
  1. system_calc_price      -- REQUESTED. The pre-override calculated price.
  2. price_override_display -- OPTIONAL, see note. Friendly Yes/No for the
                               override flag.

  Why (1) is varchar with a fallback rather than a plain decimal:
  measured on Prod over 120 days, system_calc_unit_price is NULL on 115,763
  lines and ZERO on 106,502 -- 222,265 of 788,109 (28%). Rendering those as
  "$0.00" would state that the system calculated zero, which is false. The
  "(not calculated)" fallback mirrors the (no price page) treatment Evan
  already signed off on for price_page_description (2026-07-17).
  ⚠ Because the '$' lives INSIDE the column, the message body must NOT prefix
  it with another '$'. See the body snippet at the bottom.

  Why (2) is here at all — delete this column and its token if not wanted:
  price_edit renders from ISNULL(oe_line.manual_price_overide, ''), so a line
  that was NOT overridden renders an EMPTY STRING -- "Price Overridden:" with
  nothing after it, which reads as broken. Only the positive case ('Y') has
  actually been observed in a fired email so far. Since the view is being
  altered anyway, fixing this costs nothing extra. price_edit is left alone.

  NULL-token safety (per the 2026-08-11 hardening, script 06): both columns are
  CASE expressions that ALWAYS return a value, never NULL. This matters --
  p21_sp_alert_generation chains REPLACE() per token registered for the alert
  TYPE, and REPLACE() returns NULL if any argument is NULL, so one NULL column
  can blank the body of ANY OE alert, not just this one.

  kb_/js_ (standing rule): none involved. Both columns are expressions over
  oe_line, which is already in the FROM.
  Performance: no new join, no new table, no added reads. Two computed columns
  on a row set the view already produces.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'));
DECLARE @colAnchor NVARCHAR(100) = '''percent_profit_off_standard_cost''';   -- added by script 01
DECLARE @pos INT;

IF @sql IS NULL
BEGIN
    RAISERROR('View p21_view_alert_oe_OrderEntry not found.', 16, 1);
    RETURN;
END

/*--- 1. CREATE -> ALTER (OBJECT_DEFINITION prepends newlines; never assume pos 1) ---*/
SET @pos = CHARINDEX('CREATE', @sql);
IF @pos = 0 BEGIN RAISERROR('CREATE keyword not found.', 16, 1); RETURN; END
SET @sql = STUFF(@sql, @pos, 6, 'ALTER');

/*--- 2. Append the new columns after the last script-01 column ---*/
IF CHARINDEX('system_calc_price', @sql) > 0
    PRINT 'SKIP: system_calc_price already present.';
ELSE
BEGIN
    SET @pos = CHARINDEX(@colAnchor, @sql);
    IF @pos = 0
    BEGIN
        RAISERROR('Column anchor ''percent_profit_off_standard_cost'' not found -- view has drifted. STOP and re-cut.', 16, 1);
        RETURN;
    END

    SET @sql = STUFF(@sql, @pos + LEN(@colAnchor), 0,
          CHAR(10) + '		-- mg add: pre-override calculated price (Evan Jenkins, 2026-09-09)'
        + CHAR(10) + '		,CASE WHEN ISNULL(oe_line.system_calc_unit_price, 0) = 0 THEN ''(not calculated)'''
        + CHAR(10) + '		      ELSE ''$'' + CONVERT(VARCHAR(20), CAST(oe_line.system_calc_unit_price AS DECIMAL(19,2)))'
        + CHAR(10) + '		 END ''system_calc_price''   -- ''$'' is INSIDE the value; do not prefix another one in the body'
        + CHAR(10) + '		,CASE WHEN ISNULL(oe_line.manual_price_overide, '''') = ''Y'' THEN ''Yes'' ELSE ''No'''
        + CHAR(10) + '		 END ''price_override_display''  -- price_edit renders blank for No; this never does'
    );

    PRINT 'ADD: system_calc_price + price_override_display queued.';
    EXEC sp_executesql @sql;
    PRINT 'DONE: view altered.';
END
GO

/*==============================  TOKENS  ====================================
  available_areas = 4  -> line-item body (per feedback_p21_alert_available_areas)
  data_type_cd    = 850 -> varchar (both columns are varchar by design)
  NOTE: p21_apply_alert_token overwrites the description with the raw column
  formula, so the UPDATE below is NOT optional -- it is what makes the token
  readable in the client's Column dropdown.
===========================================================================*/
DECLARE @rc INT;

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'system_calc_price',
     @token_available_areas=4, @token_description=N'Calculated Price (pre-override)',
     @token_data_type_cd=850, @token_code_group_no=NULL;

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'price_override_display',
     @token_available_areas=4, @token_description=N'Price Overridden (Yes/No)',
     @token_data_type_cd=850, @token_code_group_no=NULL;

UPDATE token SET description = 'Calculated Price (pre-override)' WHERE name = 'system_calc_price';
UPDATE token SET description = 'Price Overridden (Yes/No)'       WHERE name = 'price_override_display';
GO

/*==============================  VERIFY  ==================================*/
PRINT '=== columns present? ===';
SELECT COLUMN_NAME, DATA_TYPE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'p21_view_alert_oe_OrderEntry'
  AND  COLUMN_NAME IN ('system_calc_price','price_override_display','price_edit');
GO

PRINT '=== tokens registered? ===';
SELECT t.token_uid, t.name, t.description, t.available_areas, t.data_type_cd
FROM   dbo.token t
JOIN   dbo.alert_type_x_token x ON x.token_uid = t.token_uid
WHERE  x.alert_type_uid = 12
  AND  t.name IN ('system_calc_price','price_override_display','price_edit');
GO

/*  Sanity-check the values on real lines, including the fallback path.
    The view itself cannot be queried for a processed order (INNER JOIN to the
    transient pending_alerts queue), so check the underlying expressions.      */
PRINT '=== value spot-check, incl. the (not calculated) path ===';
SELECT TOP (20)
       l.order_no, l.line_no, im.item_id, l.unit_price, l.system_calc_unit_price
     , system_calc_price = CASE WHEN ISNULL(l.system_calc_unit_price,0) = 0 THEN '(not calculated)'
                                ELSE '$' + CONVERT(VARCHAR(20), CAST(l.system_calc_unit_price AS DECIMAL(19,2))) END
     , price_override_display = CASE WHEN ISNULL(l.manual_price_overide,'') = 'Y' THEN 'Yes' ELSE 'No' END
FROM      dbo.oe_line  l
JOIN      dbo.inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
WHERE     l.date_created >= DATEADD(DAY,-30,GETDATE())
ORDER BY  l.date_created DESC;
GO

/*==========================  MESSAGE BODY  ================================
  Then, in the P21 client, on the Team alert's line-item body. Note there is
  NO '$' before <system_calc_price> -- the column supplies its own.

    Order Qty: <order_quantity>

    Sell Price: $<unit_price>   |   Calculated Price: <system_calc_price>

    MAC: $<unit_mac>
    Standard Cost: $<unit_standard_cost>
    Price Page Description: <price_page_description>
    Price Overridden: <price_override_display>
    Req Date: <line_required_date>   |   UOM: <unit_of_measure>
    Percent Profit off MAC: <percent_profit_off_mac>%   |   Percent Profit off Standard Cost: <percent_profit_off_standard_cost>%

  Keeping Calculated Price on the Sell Price line preserves the blank-line
  spacing around Order Qty / Sell Price that Evan signed off on 2026-07-22.

==============================  PROD NOTES  ================================
  Do NOT run this file against Prod. Per the standing rule, first diff Prod's
  live view against Play's -- Prod is still missing script 06's NULL hardening,
  so the definitions are known to differ, and this script edits whatever
  definition it finds. Build a PROD-suffixed copy from Prod's OWN current
  definition (the pattern used for 07-add-rsm-token-PROD.sql), and run it
  outside business hours: Prod's copy of this view is live for other, currently
  firing alerts, not just this family.

===============================  ROLLBACK  =================================
  Re-run the pre-change definition with CREATE OR ALTER (capture
  OBJECT_DEFINITION to a file BEFORE running this script), then drop the
  tokens, children first:
      DELETE FROM Alert_implementation_query WHERE column_id IN (<uids>)
      DELETE FROM alert_type_x_token         WHERE token_uid IN (<uids>)
      DELETE FROM token                      WHERE token_uid IN (<uids>)
  Removing the two <tokens> from the message body is enough to stop them
  appearing, without touching the view at all.
===========================================================================*/

/*==============================================================================
  09 — Add pricing_unit_size to the Low Margin alerts (PROD)
  Target : P21 (Prod) ONLY. Built from Prod's own current view definition,
           after confirming (2026-09-17) it is byte-identical to the copy
           captured 2026-09-14 -- no drift since.
  Author : Mark Goldyn / Claude          Date: 2026-09-17

  Ask (Evan Jenkins, 2026-09-14/16): Sell Price, MAC, and Standard Cost can
  each be quoted per a different unit than the order's displayed UOM (the
  item's PRICING unit, oe_line.pricing_unit / pricing_unit_size, vs the ORDER
  unit, oe_line.unit_of_measure -- see feedback_p21_pricing_unit_vs_order_unit
  and reference_p21_price_override_fields). Measured on Prod over 120 days,
  788,109... no -- 9,783 low-margin alert lines specifically: 18.2% have a
  pricing unit CODE different from the order UOM, 11.2% have a size-conversion
  factor (pricing_unit_size <> 1) even when the codes match. Evan's own
  simplification (9/16): "Let's just add the Unit Size for now" -- skips the
  per-value unit-code tags from the original ask, just wants the conversion
  factor shown once per line.

  Source: oe_line.pricing_unit_size -- already used INSIDE this view's own
  cost/price math (unit_mac, unit_standard_cost, low_margin_flag,
  percent_profit_off_mac/standard_cost, extended_standard_cost, etc.) but
  never itself exposed as an output column (verified: 0 occurrences as a
  column ALIAS in the view before this script).

  One column added: pricing_unit_size (decimal). NULL-safe via ISNULL -- per
  the 2026-08-11 hardening rule (script 06), any NULL token can blank the
  WHOLE message body of any OE alert via p21_sp_alert_generation's REPLACE()
  chain, not just this alert's own placeholder.

  kb_/js_ (standing rule): none involved -- a computed column over oe_line,
  already in the FROM.
  Performance: no new join, no new table, no added reads -- a passthrough
  column on a row set the view already produces.
==============================================================================*/
USE P21;
GO
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'));
DECLARE @colAnchor NVARCHAR(100) = '''ship_location_name''';   -- last column in the current SELECT list
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

/*--- 2. Append the new column after the last existing column ---*/
IF CHARINDEX('''pricing_unit_size''', @sql) > 0
    PRINT 'SKIP: pricing_unit_size already present.';
ELSE
BEGIN
    SET @pos = CHARINDEX(@colAnchor, @sql);
    IF @pos = 0
    BEGIN
        RAISERROR('Column anchor ''ship_location_name'' not found -- view has drifted. STOP and re-cut.', 16, 1);
        RETURN;
    END

    SET @sql = STUFF(@sql, @pos + LEN(@colAnchor), 0,
          CHAR(10) + '		-- mg add: pricing unit size (Evan Jenkins, 2026-09-16 -- "Let''s just add the Unit Size for now")'
        + CHAR(10) + '		,CAST(ISNULL(oe_line.pricing_unit_size, 1) AS DECIMAL(19,2)) ''pricing_unit_size'''
    );

    PRINT 'ADD: pricing_unit_size queued.';
    EXEC sp_executesql @sql;
    PRINT 'DONE: view altered.';
END
GO

/*==============================  TOKEN  ======================================
  available_areas = 4  -> line-item body (per feedback_p21_alert_available_areas)
  data_type_cd    = 853 -> decimal (per feedback_p21_alerts trap 3)
  NOTE: p21_apply_alert_token overwrites the description with the raw column
  formula, so the UPDATE below is NOT optional.
===========================================================================*/
DECLARE @rc INT;

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'pricing_unit_size',
     @token_available_areas=4, @token_description=N'Pricing Unit Size',
     @token_data_type_cd=853, @token_code_group_no=NULL;

UPDATE token SET description = 'Pricing Unit Size' WHERE name = 'pricing_unit_size';
GO

/*==============================  VERIFY  ==================================*/
PRINT '=== column present? ===';
SELECT COLUMN_NAME, DATA_TYPE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'p21_view_alert_oe_OrderEntry'
  AND  COLUMN_NAME = 'pricing_unit_size';
GO

PRINT '=== token registered? ===';
SELECT t.token_uid, t.name, t.description, t.available_areas, t.data_type_cd
FROM   dbo.token t
JOIN   dbo.alert_type_x_token x ON x.token_uid = t.token_uid
WHERE  x.alert_type_uid = 12
  AND  t.name = 'pricing_unit_size';
GO

/*  Sanity-check the values on real lines. The view itself cannot be queried
    for a processed order (INNER JOIN to the transient pending_alerts queue),
    so check the underlying expression against real recent lines.            */
PRINT '=== value spot-check ===';
SELECT TOP (20)
       l.order_no, l.line_no, im.item_id, l.unit_of_measure AS order_uom,
       l.pricing_unit, l.pricing_unit_size,
       pricing_unit_size_col = CAST(ISNULL(l.pricing_unit_size, 1) AS DECIMAL(19,2))
FROM      dbo.oe_line  l
JOIN      dbo.inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
WHERE     l.date_created >= DATEADD(DAY,-30,GETDATE())
  AND     l.pricing_unit_size <> 1
ORDER BY  l.date_created DESC;
GO

/*==========================  MESSAGE BODY  ================================
  Added to the line-item body of all four alerts, on the Req Date/UOM line:

    Req Date: <line_required_date>   |   UOM: <unit_of_measure>   |   Unit Size: <pricing_unit_size>

  Keeps the single-line spacing already established for this cluster.
===============================  ROLLBACK  =================================
  Re-run the pre-change definition with CREATE OR ALTER (backup captured
  BEFORE this script ran, at
  scratchpad\p21_view_alert_oe_OrderEntry-PROD-20260917-BEFORE-unitsize.sql),
  then drop the token, child table first:
      DELETE FROM Alert_implementation_query WHERE column_id IN (<uid>)
      DELETE FROM alert_type_x_token         WHERE token_uid IN (<uid>)
      DELETE FROM token                      WHERE token_uid IN (<uid>)
  Removing <pricing_unit_size> from the message body is enough to stop it
  appearing, without touching the view at all.
===========================================================================*/

/*==============================================================================
  Low Margin Alert — Step 1: add margin columns to p21_view_alert_oe_OrderEntry
  Target : P21Play  (then, unchanged, P21 Prod)
  Author : Mark Goldyn / Claude          Date: 2026-07-14
  Rollback: ROLLBACK-p21_view_alert_oe_OrderEntry-Play-BEFORE.sql

  IDEMPOTENT — re-running is safe (each insertion is skipped if already present).

  WHY THESE FORMULAS
  ------------------
  inv_loc costs (standard_cost, moving_average_cost) are stored per BASE unit.
  oe_line.unit_price is per PRICING unit.  To compare them, the cost must be
  converted into the pricing unit:

        cost_in_pricing_unit = inv_loc.<cost> * oe_line.pricing_unit_size

  This mirrors kb_fn_pricing_convert (amount / from_size * to_size) -- the
  from_size term drops out because the BASE unit's unit_size is always 1
  (verified across all 137,049 items in p21_view_item_uom, zero exceptions).
  So there is no item_uom join, no scalar UDF, and NO kb_ dependency.

  NB: the ORDER unit (oe_line.unit_of_measure) is NOT the PRICING unit.  Using
  the order UOM here would inflate cost by up to 2100x (e.g. KARVGW86T: ordered
  in PA = 2100 SF, but priced per SF).  Use pricing_unit_size, as P21 does.

  Margin convention: percent, off sell price -- matching the existing
  line_item_profit_percentage column and the "less than 5" trigger.
        (unit_price - cost) / unit_price * 100

  Decimals: CAST AS DECIMAL, never p21_fn_MaskDecimal (which is hardcoded to
  DECIMAL(19,6) and puts raw 6-decimal values in the alert email).
==============================================================================*/

USE P21;
GO

SET NOCOUNT ON;

DECLARE @sql       NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'));
DECLARE @colAnchor NVARCHAR(100) = '''reward_program_id''';          -- last column in the SELECT list
DECLARE @joinAnchor NVARCHAR(200) = 'LEFT JOIN oe_line_ud ON oe_line_ud.order_no = oe_line.order_no AND oe_line_ud.line_no = oe_line.line_no';
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

/*--- 2. New columns, appended after the last SELECT column ---*/
IF CHARINDEX('percent_profit_off_mac', @sql) > 0
    PRINT 'SKIP: margin columns already present.';
ELSE
BEGIN
    SET @pos = CHARINDEX(@colAnchor, @sql);
    IF @pos = 0 BEGIN RAISERROR('Column anchor ''reward_program_id'' not found.', 16, 1); RETURN; END

    SET @sql = STUFF(@sql, @pos + LEN(@colAnchor), 0,
          CHAR(10) + '		-- mg add: Low Margin Alert (Evan Jenkins request, 2026-07)'
        + CHAR(10) + '		,COALESCE(NULLIF(price_page.description, ''''), ''(no price page)'') ''price_page_description''  -- (no price page) when line not priced from a price page (uid=0); Evan 2026-07-17'
        + CHAR(10) + '		,CAST(COALESCE(inv_loc.moving_average_cost * oe_line.pricing_unit_size, 0) AS DECIMAL(19,2)) ''unit_mac'''
        + CHAR(10) + '		,CAST(COALESCE(inv_loc.standard_cost       * oe_line.pricing_unit_size, 0) AS DECIMAL(19,2)) ''unit_standard_cost'''
        + CHAR(10) + '		,CAST(CASE WHEN ISNULL(oe_line.unit_price, 0) = 0 THEN 0'
        + CHAR(10) + '		           ELSE (oe_line.unit_price - COALESCE(inv_loc.moving_average_cost * oe_line.pricing_unit_size, 0))'
        + CHAR(10) + '		                / oe_line.unit_price * 100 END AS DECIMAL(19,2)) ''percent_profit_off_mac'''
        + CHAR(10) + '		,CAST(CASE WHEN ISNULL(oe_line.unit_price, 0) = 0 THEN 0'
        + CHAR(10) + '		           ELSE (oe_line.unit_price - COALESCE(inv_loc.standard_cost * oe_line.pricing_unit_size, 0))'
        + CHAR(10) + '		                / oe_line.unit_price * 100 END AS DECIMAL(19,2)) ''percent_profit_off_standard_cost'''
        -- single-filter convenience: P21 ANDs its filter rows, so an OR must be precomputed here.
        -- Lets one alert cover both thresholds later without another view change.
        + CHAR(10) + '		,CASE WHEN ISNULL(oe_line.unit_price, 0) = 0 THEN ''N'''
        + CHAR(10) + '		      WHEN (oe_line.unit_price - COALESCE(inv_loc.moving_average_cost * oe_line.pricing_unit_size, 0)) / oe_line.unit_price * 100 < 5'
        + CHAR(10) + '		        OR (oe_line.unit_price - COALESCE(inv_loc.standard_cost       * oe_line.pricing_unit_size, 0)) / oe_line.unit_price * 100 < 5'
        + CHAR(10) + '		      THEN ''Y'' ELSE ''N'' END ''low_margin_flag'''
    );
    PRINT 'ADD: 6 columns queued.';
END

/*--- 3. Location NAMES (Evan: "Loc # and Name if possible") ---*/
IF CHARINDEX('sales_location_name', @sql) > 0
    PRINT 'SKIP: location name columns already present.';
ELSE
BEGIN
    SET @pos = CHARINDEX('''low_margin_flag''', @sql);
    IF @pos = 0 BEGIN RAISERROR('Column anchor ''low_margin_flag'' not found.', 16, 1); RETURN; END

    SET @sql = STUFF(@sql, @pos + LEN('''low_margin_flag'''), 0,
          CHAR(10) + '		,COALESCE(loc_sales.location_name,  '''') ''sales_location_name'''
        + CHAR(10) + '		,COALESCE(loc_source.location_name, '''') ''ship_location_name'''
    );
    PRINT 'ADD: 2 location name columns queued.';
END

/*--- 4. Joins: price_page + the two location lookups -------------------------
  location is 1 row per location_id (64/64 verified) -- no fan-out.
  loc_sales  = oe_hdr.location_id   (the SALES location)
  loc_source = oe_line.source_loc_id (the SOURCE/ship-from location -- this is
               also the location the costs are read from, per the system setting
               use_sales_loc_for_source_costs = N)
----------------------------------------------------------------------------*/
IF CHARINDEX('LEFT JOIN price_page', @sql) > 0
    PRINT 'SKIP: price_page already joined.';
ELSE
BEGIN
    SET @pos = CHARINDEX(@joinAnchor, @sql);
    IF @pos = 0 BEGIN RAISERROR('Join anchor (oe_line_ud) not found.', 16, 1); RETURN; END

    SET @sql = STUFF(@sql, @pos + LEN(@joinAnchor), 0,
        CHAR(10) + 'LEFT JOIN price_page ON price_page.price_page_uid = oe_line.price_page_uid');
    PRINT 'ADD: price_page join queued.';
END

-- NB: guard on the JOIN text, not just 'loc_sales' -- the column added above
-- already references loc_sales.location_name, so a bare 'loc_sales' check
-- matches the column and skips the join, leaving an unbindable identifier.
IF CHARINDEX('LEFT JOIN location AS loc_sales', @sql) > 0
    PRINT 'SKIP: location joins already present.';
ELSE
BEGIN
    SET @pos = CHARINDEX(@joinAnchor, @sql);
    IF @pos = 0 BEGIN RAISERROR('Join anchor (oe_line_ud) not found.', 16, 1); RETURN; END

    SET @sql = STUFF(@sql, @pos + LEN(@joinAnchor), 0,
          CHAR(10) + 'LEFT JOIN location AS loc_sales  ON loc_sales.location_id  = oe_hdr.location_id'
        + CHAR(10) + 'LEFT JOIN location AS loc_source ON loc_source.location_id = oe_line.source_loc_id');
    PRINT 'ADD: 2 location joins queued.';
END

PRINT 'Applying ALTER VIEW, length = ' + CAST(LEN(@sql) AS VARCHAR(20));
EXEC sp_executesql @sql;
GO

/*--- 4. Verify ---*/
SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'p21_view_alert_oe_OrderEntry'
  AND  COLUMN_NAME IN ('price_page_description','unit_mac','unit_standard_cost',
                       'percent_profit_off_mac','percent_profit_off_standard_cost','low_margin_flag',
                       'sales_location_name','ship_location_name')
ORDER BY COLUMN_NAME;
GO

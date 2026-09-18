/*==============================================================================
  09 — Add pricing_unit_size to the Low Margin alerts (PLAY)
  Target : P21Play ONLY. Run 2026-09-17 to prove the design before the Prod
           copy (09-add-pricing-unit-size-PROD.sql, same script shape).
  Author : Mark Goldyn / Claude          Date: 2026-09-17

  Same ask/rationale as the PROD script — see that file's header for the
  full Evan Jenkins background and the 18.2%/11.2% measurement. This copy
  differs only in USE P21Play and the column anchor, matched against Play's
  own current view text (Play carries the 2026-08-11 NULL-token hardening,
  script 06, that Prod does not — captured and diffed before writing).

  Result: pricing_unit_size added (token_uid 746, available_areas=4,
  data_type_cd=853), confirmed present + registered. Verified working via
  a real fired test (order 6062517, not yet a successful full alert fire —
  see the project memory for the still-open test-order troubleshooting).
==============================================================================*/
USE P21Play;
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

SET @pos = CHARINDEX('CREATE', @sql);
IF @pos = 0 BEGIN RAISERROR('CREATE keyword not found.', 16, 1); RETURN; END
SET @sql = STUFF(@sql, @pos, 6, 'ALTER');

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
          CHAR(10) + '		-- mg add: pricing unit size (Evan Jenkins, 2026-09-16 -- "Let''s just add the Unit Size for now") -- PLAY test copy of 09-add-pricing-unit-size-PROD.sql'
        + CHAR(10) + '		,CAST(ISNULL(oe_line.pricing_unit_size, 1) AS DECIMAL(19,2)) ''pricing_unit_size'''
    );

    PRINT 'ADD: pricing_unit_size queued.';
    EXEC sp_executesql @sql;
    PRINT 'DONE: view altered.';
END
GO

DECLARE @rc INT;
EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'pricing_unit_size',
     @token_available_areas=4, @token_description=N'Pricing Unit Size',
     @token_data_type_cd=853, @token_code_group_no=NULL;
UPDATE token SET description = 'Pricing Unit Size' WHERE name = 'pricing_unit_size';
GO

PRINT '=== column present? ===';
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'p21_view_alert_oe_OrderEntry' AND COLUMN_NAME = 'pricing_unit_size';
GO

PRINT '=== token registered? ===';
SELECT t.token_uid, t.name, t.description, t.available_areas, t.data_type_cd
FROM dbo.token t JOIN dbo.alert_type_x_token x ON x.token_uid = t.token_uid
WHERE x.alert_type_uid = 12 AND t.name = 'pricing_unit_size';
GO

/*===============================  ROLLBACK  =================================
  Re-run the pre-change definition with CREATE OR ALTER (backup captured
  BEFORE this script ran, at
  scratchpad\p21_view_alert_oe_OrderEntry-PLAY-20260917-BEFORE.sql),
  then drop the token, child table first:
      DELETE FROM Alert_implementation_query WHERE column_id IN (746)
      DELETE FROM alert_type_x_token         WHERE token_uid IN (746)
      DELETE FROM token                      WHERE token_uid IN (746)
===========================================================================*/

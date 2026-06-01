-- ============================================================
-- Fix: Widen varchar(1000) -> varchar(MAX) in
--      apc_business_rule_extensions_xml type and all 8 dependent procs.
--
-- Root cause: OE notes fields longer than 1000 chars cause a truncation
--   error when DynaChange passes form data (including the notes field)
--   into the apc_business_rule_extensions_xml table type parameter.
--   The kb_Order_Validator_v2 business rule fires on w_order_entry_sheet
--   save, triggering all surcharge procedures that use this type.
--
-- Affected columns in type + @returnData in each proc:
--   fieldAlias, fieldValue, fieldOriginalValue
--
-- Also drops apc_debug_surcharge_shipping (created from @returnData in
--   apc_od_apply_surcharge_shipping) so it is recreated with wider cols.
--
-- Run on: P21Play first, then P21 (prod) after verification.
-- ============================================================

-- Step 1: Capture all 8 procedure definitions before dropping anything
DROP TABLE IF EXISTS #proc_defs;
CREATE TABLE #proc_defs (proc_name nvarchar(200), definition nvarchar(MAX));
INSERT INTO #proc_defs (proc_name, definition)
SELECT o.name, m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE o.name IN (
    'apc_fe_conv_limit_class_surcharge',
    'apc_fe_conv_verify_surcharge_price_edit',
    'apc_fe_val_update_surcharge_price',
    'apc_od_apply_surcharge',
    'apc_od_apply_surcharge_fc',
    'apc_od_apply_surcharge_shipping',
    'apc_os_conv_validate_surcharge_oe',
    'apc_os_conv_validate_surcharge_shipping'
);

DECLARE @captured int = @@ROWCOUNT;
PRINT 'Captured ' + CAST(@captured AS varchar) + ' of 8 procedure definitions.';
IF @captured <> 8
BEGIN
    RAISERROR('Expected 8 procedures, found %d. Aborting -- check proc names.', 16, 1, @captured);
    DROP TABLE #proc_defs;
    RETURN;
END

-- Step 2: Drop the debug table (was created from @returnData; cols will mismatch after fix)
DROP TABLE IF EXISTS dbo.apc_debug_surcharge_shipping;
PRINT 'Dropped apc_debug_surcharge_shipping (will be recreated on next proc execution).';

-- Step 3: Drop all 8 dependent procedures
DROP PROCEDURE IF EXISTS dbo.apc_fe_conv_limit_class_surcharge;
DROP PROCEDURE IF EXISTS dbo.apc_fe_conv_verify_surcharge_price_edit;
DROP PROCEDURE IF EXISTS dbo.apc_fe_val_update_surcharge_price;
DROP PROCEDURE IF EXISTS dbo.apc_od_apply_surcharge;
DROP PROCEDURE IF EXISTS dbo.apc_od_apply_surcharge_fc;
DROP PROCEDURE IF EXISTS dbo.apc_od_apply_surcharge_shipping;
DROP PROCEDURE IF EXISTS dbo.apc_os_conv_validate_surcharge_oe;
DROP PROCEDURE IF EXISTS dbo.apc_os_conv_validate_surcharge_shipping;
PRINT 'Dropped 8 procedures.';

-- Step 4: Drop and recreate the type with wider columns
DROP TYPE IF EXISTS dbo.apc_business_rule_extensions_xml;

CREATE TYPE dbo.apc_business_rule_extensions_xml AS TABLE
(
    className           varchar(100),
    fieldTitle          varchar(100),
    fieldName           varchar(100),
    fieldAlias          varchar(MAX),
    fieldValue          varchar(MAX),
    modifiedFlag        char(1)   DEFAULT 'N',
    [readOnly]          char(1)   DEFAULT 'Y',
    rowID               int,
    dataType            varchar(100),
    triggerField        char(1)   DEFAULT 'N',
    triggerRow          char(1)   DEFAULT 'N',
    fieldOriginalValue  varchar(MAX),
    updateSequence      int       DEFAULT 0,
    setFocus            char(1)   DEFAULT 'N',
    baseClassName       varchar(100),
    newRow              char(1)   DEFAULT 'N',
    allowCascade        char(1)   DEFAULT 'Y'
);
PRINT 'Type recreated: fieldAlias, fieldValue, fieldOriginalValue now varchar(MAX).';

-- Step 4b: Restore EXECUTE permission on the type
GRANT EXECUTE ON TYPE::dbo.apc_business_rule_extensions_xml TO p21_application_role;
GRANT EXECUTE ON TYPE::dbo.apc_business_rule_extensions_xml TO PxxiUser;
PRINT 'EXECUTE granted on type to p21_application_role and PxxiUser.';

-- Step 5: Recreate all 8 procedures with varchar(1000) -> varchar(MAX)
--   The blanket replace covers fieldAlias/fieldValue/fieldOriginalValue in @returnData
--   and local @ruleMessage/@calcMessage variables -- all safe to widen.
DECLARE @sql        nvarchar(MAX);
DECLARE @proc_name  nvarchar(200);
DECLARE @definition nvarchar(MAX);

DECLARE proc_cursor CURSOR FAST_FORWARD FOR
    SELECT proc_name, definition FROM #proc_defs;

OPEN proc_cursor;
FETCH NEXT FROM proc_cursor INTO @proc_name, @definition;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @definition;

    -- Widen all varchar(1000) occurrences
    SET @sql = REPLACE(@sql, 'varchar(1000)', 'varchar(MAX)');

    -- Convert CREATE PROCEDURE -> CREATE OR ALTER PROCEDURE
    SET @sql = STUFF(@sql, CHARINDEX('CREATE', UPPER(@sql)), 6, 'CREATE OR ALTER');

    EXEC sp_executesql @sql;
    PRINT 'Recreated: ' + @proc_name;

    FETCH NEXT FROM proc_cursor INTO @proc_name, @definition;
END

CLOSE proc_cursor;
DEALLOCATE proc_cursor;
DROP TABLE #proc_defs;

-- Step 6: Restore EXECUTE permissions on all recreated procedures
GRANT EXECUTE ON dbo.apc_fe_conv_limit_class_surcharge              TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_fe_conv_verify_surcharge_price_edit        TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_fe_val_update_surcharge_price              TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_od_apply_surcharge                         TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_od_apply_surcharge_fc                      TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_od_apply_surcharge_shipping                TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_os_conv_validate_surcharge_oe              TO p21_application_role, PxxiUser;
GRANT EXECUTE ON dbo.apc_os_conv_validate_surcharge_shipping        TO p21_application_role, PxxiUser;
PRINT 'EXECUTE granted on all 8 procedures to p21_application_role and PxxiUser.';

-- Verification: confirm type columns are now varchar(MAX) (max_length = -1)
PRINT '--- Verification ---';
SELECT c.name AS column_name, c.max_length
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
WHERE tt.name = 'apc_business_rule_extensions_xml'
ORDER BY c.column_id;

PRINT 'Done. Test: open order 5866763 in P21 Play and save a note longer than 1000 chars.';

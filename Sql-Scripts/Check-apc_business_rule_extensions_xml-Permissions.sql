-- ============================================================
-- Pre-check: Verify state of apc_business_rule_extensions_xml
--   type and all 8 dependent procs BEFORE running the fix.
--
-- Run on: P21Play (P21Dev.allsurfaces.com), then P21 (prod).
-- ============================================================

-- Section 1: Type column widths (fieldAlias/fieldValue/fieldOriginalValue should be 1000 before fix)
PRINT '=== Type column widths ===';
SELECT
    c.name                                                              AS column_name,
    CASE c.max_length WHEN -1 THEN 'varchar(MAX)'
                      ELSE 'varchar(' + CAST(c.max_length AS varchar) + ')'
    END                                                                 AS current_type,
    CASE c.max_length WHEN -1 THEN 'OK (already MAX)' ELSE 'NEEDS FIX' END AS status
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
WHERE tt.name = 'apc_business_rule_extensions_xml'
ORDER BY c.column_id;

-- Section 2: EXECUTE permissions on the type (expect 2 rows: p21_application_role + PxxiUser)
PRINT '=== Type permissions (expect 2 rows) ===';
SELECT
    pr.name         AS grantee,
    dp.permission_name,
    dp.state_desc
FROM sys.database_permissions dp
JOIN sys.database_principals pr  ON pr.principal_id  = dp.grantee_principal_id
JOIN sys.table_types          tt ON tt.user_type_id  = dp.major_id
WHERE tt.name = 'apc_business_rule_extensions_xml'
ORDER BY pr.name;

-- Section 3: All 8 procs must exist (expect 8 rows)
PRINT '=== Procedures (expect 8 rows) ===';
SELECT
    name,
    create_date,
    modify_date
FROM sys.objects
WHERE name IN (
    'apc_fe_conv_limit_class_surcharge',
    'apc_fe_conv_verify_surcharge_price_edit',
    'apc_fe_val_update_surcharge_price',
    'apc_od_apply_surcharge',
    'apc_od_apply_surcharge_fc',
    'apc_od_apply_surcharge_shipping',
    'apc_os_conv_validate_surcharge_oe',
    'apc_os_conv_validate_surcharge_shipping'
)
ORDER BY name;

-- Section 4: EXECUTE permissions on all 8 procs (expect 16 rows: 2 grantees x 8 procs)
PRINT '=== Proc permissions (expect 16 rows) ===';
SELECT
    o.name          AS proc_name,
    pr.name         AS grantee,
    dp.permission_name,
    dp.state_desc
FROM sys.database_permissions dp
JOIN sys.database_principals pr ON pr.principal_id = dp.grantee_principal_id
JOIN sys.objects              o  ON o.object_id    = dp.major_id
WHERE o.name IN (
    'apc_fe_conv_limit_class_surcharge',
    'apc_fe_conv_verify_surcharge_price_edit',
    'apc_fe_val_update_surcharge_price',
    'apc_od_apply_surcharge',
    'apc_od_apply_surcharge_fc',
    'apc_od_apply_surcharge_shipping',
    'apc_os_conv_validate_surcharge_oe',
    'apc_os_conv_validate_surcharge_shipping'
)
ORDER BY o.name, pr.name;

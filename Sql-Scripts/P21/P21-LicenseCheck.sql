SELECT license_types.license_type_cd AS license_type_cd
, license_types.license_type AS license_type
, dbo.p21_fn_getrawlicensecountvalue(license_types.license_type_cd, system_setting.configuration_id) AS raw_license_capacity
, 0 license_capacity
, dbo.p21_fn_getconnectioncountbylicensetype(DB_NAME(), license_types.license_type_cd) AS licenses_in_use
, ISNULL( SUM( CASE PATINDEX( 'PXXI/SQLCA/%/DESKTOP-' + license_types.license_type + '%', sysproc.[program_name] ) WHEN 0 THEN 0 ELSE 1 END ), 0 ) AS licenses_in_use_desktop
, ISNULL( SUM( CASE PATINDEX( 'PXXI/SQLCA/%/UISERVER-' + license_types.license_type + '%', sysproc.[program_name] ) WHEN 0 THEN 0 ELSE 1 END ), 0 ) AS licenses_in_use_uiserver
, CAST( [configuration].configuration_id AS int ) AS configuration_id
FROM system_setting
CROSS JOIN (
SELECT [value] AS configuration_id
FROM system_setting
WHERE [name] = 'configuration_id'
AND configuration_id = 0
) AS [configuration]
CROSS JOIN (
SELECT code_p21.code_no AS license_type_cd
, code_p21.code_description AS license_type
, code_p21.code_sub_description AS license_count_setting
FROM code_x_code_group_p21
JOIN code_p21 ON ( code_p21.code_no = code_x_code_group_p21.code_no )
WHERE code_x_code_group_p21.code_group_no = 2287
) AS license_types
CROSS JOIN (
SELECT * FROM p21_fnt_sysprocesses()
) AS sysproc
WHERE ( system_setting.[name] = license_types.license_count_setting )
AND ( system_setting.configuration_id = [configuration].configuration_id )
GROUP BY system_setting.configuration_id
, license_types.license_type
, license_types.license_type_cd
, [configuration].configuration_id
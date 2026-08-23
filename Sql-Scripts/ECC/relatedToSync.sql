SELECT name, value
FROM system_setting
WHERE name LIKE '%use_service_broker%'
OR name LIKE '%split_sync%'

EXEC p21_ecc_sb_trigger_status @TransferType = NULL

SELECT CASE
WHEN is_broker_enabled = 1
THEN 'Enabled'
ELSE 'Disabled'
END
FROM sys.databases WHERE name = 'p21'

SELECT * FROM ecc_sb_cuco
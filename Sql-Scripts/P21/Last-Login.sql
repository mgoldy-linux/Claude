SELECT TOP 500 
    created_by AS login_id,
    date_created AS login_date,
    new_value AS login_result,
    SUBSTRING(auxiliary_value, CHARINDEX('[Host:',auxiliary_value)+6, CHARINDEX(']',SUBSTRING(auxiliary_value, CHARINDEX('[Host:',auxiliary_value)+6+1,4000))) AS host,
    SUBSTRING(auxiliary_value, CHARINDEX('[SPID:',auxiliary_value)+6, CHARINDEX(']',SUBSTRING(auxiliary_value, CHARINDEX('[SPID:',auxiliary_value)+6+1,4000))) AS spid,
    SUBSTRING(auxiliary_value, CHARINDEX('[NetworkAddr:',auxiliary_value)+13, CHARINDEX(']',SUBSTRING(auxiliary_value, CHARINDEX('[NetworkAddr:',auxiliary_value)+13+1,4000))) AS ip_address,
    SUBSTRING(auxiliary_value, CHARINDEX('[App:',auxiliary_value)+5, CHARINDEX(']',SUBSTRING(auxiliary_value, CHARINDEX('[App:',auxiliary_value)+5+1,4000))) AS p21_version,
    key2_value AS login_description,
    auxiliary_value 
FROM audit_trail WITH(NOLOCK)
WHERE source_area_cd = 1418 AND column_changed = 'user_login' AND key1_cd = 'login_name' 
    --AND key1_value = 'mgoldyn'
ORDER BY date_created DESC
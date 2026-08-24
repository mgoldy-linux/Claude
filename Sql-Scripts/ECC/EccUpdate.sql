/*
	2020-09-18 08:44:09 -Mike Kniaziewicz
	Mark, could you run this query against the play database and let me know when that has been completed: 
	UPDATE dbo.system_setting SET value = 'Y' 
	FROM dbo.system_setting 
	WHERE name = 'ecc_use_Tls12'
*/

select name,value,data_type_cd,date_created
from system_setting
WHERE name = 'ecc_use_Tls12'

UPDATE dbo.system_setting SET value = 'Y' 
FROM dbo.system_setting 
WHERE name = 'ecc_use_Tls12'

select name,value,data_type_cd,date_created
from system_setting
WHERE name = 'ecc_use_Tls12'

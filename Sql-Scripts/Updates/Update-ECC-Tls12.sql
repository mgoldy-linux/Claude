-- mike k of epicor

use P21Play

select *
from dbo.system_setting
WHERE name = 'ecc_use_Tls12'

UPDATE dbo.system_setting SET value = 'Y' 
FROM dbo.system_setting 
WHERE name = 'ecc_use_Tls12' 

select *
from dbo.system_setting
WHERE name = 'ecc_use_Tls12'
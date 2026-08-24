use [P21Play]
go

-- verify null
select upc_code, check_digit
from inventory_supplier
where inv_mast_uid = '49961'

-- update
Update inventory_supplier
set upc_code = '80067518525', check_digit = (select * from dbo.CalculateCheckDigitUPC(80067518525))
where inv_mast_uid = '49961'

-- check results
select upc_code, check_digit
from inventory_supplier
where inv_mast_uid = '49961'
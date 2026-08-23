/*
select * from dbo.CalculateCheckDigitUPC(877960356763)
select * from dbo.CalculateCheckDigitUPC(87796148581)
select * from dbo.CalculateCheckDigitUPC(87796148581)

select item_id,item_desc,short_code,upc_code,check_digit,m.inv_mast_uid,
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026111'--'2101026091' --  '2101026186'
*/
select * from dbo.CalculateCheckDigitUPC(87796186910)
select * from dbo.CalculateCheckDigitUPC(0087796186910)
select * from dbo.CalculateCheckDigitUPC(87796308558)
select * from dbo.CalculateCheckDigitUPC(87796311923)
select * from dbo.CalculateCheckDigitUPC(80067502153)
select * from dbo.CalculateCheckDigitUPC(87796036918)
select * from dbo.CalculateCheckDigitUPC(87796036680)
select * from dbo.CalculateCheckDigitUPC(80067533885)
select * from dbo.CalculateCheckDigitUPC(88856904693)
select * from dbo.CalculateCheckDigitUPC(88856912952)

select *
from Bar_Timken_Item_ID_Labels_VW
where [UPC Code] in ('877961869106','877963085581','877963119238')

select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid,(select * from dbo.CalculateCheckDigitUPC(0087796308558))[CorrectCheckDigit]
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id in ('2101026154','2101048586','2101026180')

select item_id,item_desc,short_code,upc_code,check_digit,m.inv_mast_uid,isu.date_last_modified,isu.last_maintained_by,isu.supplier_id,isu.division_id
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101051577'
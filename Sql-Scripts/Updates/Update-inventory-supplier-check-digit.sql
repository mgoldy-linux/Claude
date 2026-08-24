/* --1
select *
from Bar_Timken_Item_ID_Labels_VW
where [UPC Code] = '877961485813' --'877960365984'

select inv_mast_uid
from inv_mast
where item_id = '2101026186'--  '2101026143'

select *
from inventory_supplier
where inv_mast_uid = 26188 --26145
*/
/* --2
update inventory_supplier
set check_digit = 4 --8
where inv_mast_uid = 26188 --26145

select *
from inventory_supplier
where inv_mast_uid = 26188 --26145

select *
from Bar_Timken_Item_ID_Labels_VW
where [UPC Code] = '877961485814'
*/
/*
-- start
select *
from Bar_Timken_Item_ID_Labels_VW
where SIMG in ('2101026180','2101048586','2101026154')

select *
from Bar_Timken_Item_ID_Labels_VW
where [UPC Code] in ('877961869106','877963085581','87796311923')
--3
select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026154'

update inventory_supplier
set check_digit = 2
where inv_mast_uid = 26156 --26145

select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026154'
-- 4
select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101048586'

update inventory_supplier
set check_digit = 6
where inv_mast_uid = 48591 --26145

select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101048586'
--5
select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026180'

update inventory_supplier
set check_digit = 6
where inv_mast_uid = 26182 --26145

select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026180'

-- Finish
select *
from Bar_Timken_Item_ID_Labels_VW
where [UPC Code] in ('00877961869102','877963085586','87796311926')
*/
--6
select * from dbo.CalculateCheckDigitUPC(87796039445) --(87796036598) --(87796039445)--(87796036918)
select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026114'--'2101052079' --'2101026143' -- '2101026114' --'2101026111'

update inventory_supplier
set check_digit = 2
where inv_mast_uid = 26116 --52185 -- 26116 --26145

select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026114'
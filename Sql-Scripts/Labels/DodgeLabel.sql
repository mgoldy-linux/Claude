/*
	05/11/2020 - final dodge label query
	05/18/2020 - determine the UPC value is missing check digit, create function CalculateCheckDigitUPC to resolve this
*/

Use P21;

select distinct case 
	when LEN(item_id) = 8 then Right(item_id,6)
	when LEN(item_id) = 9 then Right(item_id,7)
	when LEN(item_id) = 10 then Right(item_id,8)
	when LEN(item_id) = 11 then Right(item_id,9)
	when LEN(item_id) = 12 then Right(item_id,10)
	when LEN(item_id) = 13 then Right(item_id,11)
	when LEN(item_id) = 14 then Right(item_id,12)
	when LEN(item_id) = 15 then Right(item_id,13)
	end[Item ID],
	item_desc[Description],
	case when a.phys_country is null then 'US'
	else  a.phys_country
	end[COO],upc_code
from p21_item_view iv
join address a 
on iv.supplier_id = a.corp_address_id
where iv.item_id like 'D-%' and iv.delete_flag = 'N' --and upc_code is null
order by [Item ID]
-- issue many address missing physical country & city
-- not helpful inventory_supplier, contacts_x_supplier
-- len to find the longest description for testing

select item_desc,extended_desc,item_id,
	case  when iv.supplier_id = 100 then 'US'
		  when iv.supplier_id = 300 then 'US'
		  when iv.supplier_id = 15815 then 'US'
		  when iv.supplier_id = 15915 then 'US'
		  when iv.supplier_id = 16070 then 'US'
		  when iv.supplier_id = 16167 then 'China'
		  when iv.supplier_id = 16173 then 'US'
		  when iv.supplier_id = 17017 then 'US'
		  else 'Unknown'
  end[COO], len(extended_desc)[length]
from p21_item_view iv
join address a
on iv.supplier_id = a.corp_address_id
where iv.class_id1 = 'IPTCI' and item_desc like 'UCP 205 16%'
--order by length desc


/*
select inv_mast_uid, item_id, delete_flag, class_id1,item_desc,short_code,extended_desc
from  inv_mast
where item_desc like 'UCP 205%'

select distinct corp_address_id, phys_country, phys_state,phys_city
from address
where phys_country is null and phys_state is null

select *
from address
where corp_address_id = 16348

select *
from supplier

select distinct corp_address_id, phys_country, phys_state,phys_city,*
from address
where corp_address_id = 17017

select distinct primary_supplier_id,a.phys_country,a.phys_state
from inv_loc il
join address a
on il.primary_supplier_id = a.corp_address_id

select Distinct iv.supplier_id,a.phys_country
from p21_item_view iv
join address a
on iv.supplier_id = a.corp_address_id
where iv.class_id1 = 'IPTCI'
order by supplier_id
*/

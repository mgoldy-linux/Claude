select item_desc,extended_desc,item_id,
	case  when iv.supplier_id = 100 then 'US'
		  when iv.supplier_id = 300 then 'US'
		  when iv.supplier_id = 15815 then 'US'
		  when iv.supplier_id = 15887 then 'US'
		  when iv.supplier_id = 15915 then 'US'
		  when iv.supplier_id = 16070 then 'US'
		  when iv.supplier_id = 16013 then 'China'
		  when iv.supplier_id = 16167 then 'China'
		  when iv.supplier_id = 16169 then 'Canada'
		  when iv.supplier_id = 16173 then 'US'
		  when iv.supplier_id = 16361 then 'US'
		  when iv.supplier_id = 17017 then 'US'
		  else 'Unknown'
  end[COO],supplier_name
from p21_item_view iv
join address a
on iv.supplier_id = a.id
where iv.delete_flag = 'N' and inactive = 'N' and class_id1 = 'IPTCI' and id in ('100','300','15815','15887','15915','16013','16070','16167','16169','16173','16361','17017')
order by item_id

select distinct supplier_id
from p21_item_view iv
where class_id1 = 'IPTCI'
order by supplier_id


select *
from p21_item_view iv
where class_id1 = 'IPTCI' and supplier_id = 16169
order by supplier_id


select id,corp_address_id,phys_country,mail_country
from address 
where id in ('100','300','15815','15915','16070','16167','16173','17017')

select *
from address
where id = 16361

select supplier_name,*
from supplier
where supplier_id = '16361'

select item_desc,extended_desc,item_id,*
from inv_mast
where item_desc like 'SBLF 205 16 G H4%'

select *
from inv_xref
--where their_item_id = '400118704836'
where inv_mast_uid = 28758

select *
from inv_mast
where item_id = 'UCT20720RM'
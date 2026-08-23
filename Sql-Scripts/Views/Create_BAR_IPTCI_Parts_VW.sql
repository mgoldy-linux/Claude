/*
		03/29/2021 - create view for IPTCI labels - testing in Play
		All bartender views will begin with BAR
*/
use P21Play;
/*
if OBJECT_ID ('Bar_IPTCI_Parts_VW', 'V') is not null
drop view Bar_IPTCI_Parts_VW;
go

create view [dbo].[Bar_IPTCI_Parts_VW] AS
*/
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

go 
/*
grant select on object::Bar_IPTCI_Parts_VW to p21_application_role
grant select on object::Bar_IPTCI_Parts_VW to PxxiUser
grant select on object::Bar_IPTCI_Parts_VW to [PTIDOM\P21Users]
*/
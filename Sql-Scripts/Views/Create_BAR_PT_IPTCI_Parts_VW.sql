/*
		03/29/2021 - create view base on pick tickets for IPTCI labels - testing in Play
		All bartender views will begin with BAR
*/
use P21Play;

if OBJECT_ID ('Bar_PT_IPTCI_Parts_VW', 'V') is not null
drop view Bar_PT_IPTCI_Parts_VW;
go

create view [dbo].[Bar_PT_IPTCI_Parts_VW] AS


select p.pick_ticket_no,item_id,item_desc,m.extended_desc,format(qty_ordered,'N0')[Qty2Print],h.order_no
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
where h.location_id = 300 and assembly = 'n' and h.date_created  > DATEADD(DAY,-100,GetDate())

go 

grant select on object::Bar_PT_IPTCI_Parts_VW to p21_application_role
grant select on object::Bar_PT_IPTCI_Parts_VW to PxxiUser
grant select on object::Bar_PT_IPTCI_Parts_VW to [PTIDOM\P21Users]

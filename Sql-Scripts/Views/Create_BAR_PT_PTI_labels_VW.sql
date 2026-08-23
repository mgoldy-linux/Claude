/*
		04/26/2021 - create view base on pick tickets for PTI labels - testing in Play first
		All bartender views will begin with BAR
		04/26/2021 where h.location_id = 100 and assembly = 'B' and h.date_created  > DATEADD(DAY,-100,GetDate())
		05/03/2021 - update where cause to this: where h.location_id = 100 and h.date_created  > DATEADD(DAY,-100,GetDate()) and l.delete_flag = 'N' and l.detail_type = 0
					l.detail_type = 0 for full item id
		05/05/2021 added product group id and their item id for other company's part we sale
		05/07/2021 - add printed flag, reduce down to 63 days, don't need check digit
		07/19/2021 - changed to 365 for testing 
		08/10/2021 - change premissions to select,update,references
		08/11/2021 - removed customer id and filter of invoice_no, and oe pick ticket delete flag, add distinct to prevent duplicate created by inventory supplier
		08/24/2021 - remove their item id, add customer part number
		08/03/2022 - add l.qty_on_pick_tickets != 0 to prevent print items not in stock
		08/11/2022 - change order filter to not completed, filter out quotes too
		08/12/2022 - remove line detail type causes duplicates - neeed to research alt way
*/
use P21Play;
--use P21;

/*
if OBJECT_ID ('Bar_PT_PTI_Labels_VW', 'V') is not null
drop view Bar_PT_PTI_Labels_VW;
go

create view [dbo].[Bar_PT_PTI_Labels_VW] AS
*/

select distinct p.pick_ticket_no[Pick_Ticket_No],item_id[Item_ID],item_desc[Item_Desc],format(qty_ordered,'N0')[Qty2Print],h.order_no[Order_No],m.default_product_group[Product_Group],"UPC" = 
case 
	when m.default_product_group in ('K1','K1CR','K1SE') then l.customer_part_number
	when (upc_or_ean_id is NULL) then l.customer_part_number
	when default_product_group not in ('K1','K1CR','K1SE') then upc_or_ean_id
end,class_id1,m.extended_desc[item_ext_desc]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
left join inv_xref x
on h.customer_id = x.customer_id and m.inv_mast_uid = x.inv_mast_uid
where h.location_id = 100 and h.completed = 'N' and projected_order = 'N' and l.delete_flag = 'N' and l.detail_type = 0 and default_product_group not in ('OTHERCHG','D1') and h.rma_flag = 'N' and p.delete_flag = 'N' and p.invoice_no is null 
and l.qty_on_pick_tickets != 0 -- and h.order_no = 1305701
--order by Pick_Ticket_No

go 
/*
grant select on object::Bar_PT_PTI_Labels_VW to p21_application_role
grant select on object::Bar_PT_PTI_Labels_VW to PxxiUser
grant select on object::Bar_PT_PTI_Labels_VW to [PTIDOM\P21Users]
*/


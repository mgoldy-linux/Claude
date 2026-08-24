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

SELECT p.pick_ticket_no, m.item_id, m.item_desc, format(p.print_quantity, 'N0') AS Qty2Print, m.upc_or_ean_id, h.order_no, m.default_product_group AS Product_Group, CASE WHEN m.default_product_group IN ('K1', 'K1CR', 'K1SE') 
THEN l.customer_part_number WHEN upc_or_ean_id IS NULL AND upc_code IS NOT NULL THEN concat(upc_code, check_digit) WHEN (upc_or_ean_id IS NULL) 
THEN l.customer_part_number WHEN default_product_group NOT IN ('K1', 'K1CR', 'K1SE') THEN upc_or_ean_id END AS UPC, m.class_id1, m.extended_desc AS item_ext_desc, h.ship2_name
FROM  dbo.oe_pick_ticket_detail AS p 
INNER JOIN dbo.inv_mast AS m 
ON p.inv_mast_uid = m.inv_mast_uid 
INNER JOIN dbo.oe_pick_ticket AS op 
ON p.pick_ticket_no = op.pick_ticket_no 
INNER JOIN dbo.oe_hdr AS h 
ON op.order_no = h.order_no 
INNER JOIN dbo.oe_line AS l 
ON h.order_no = l.order_no AND p.inv_mast_uid = l.inv_mast_uid AND p.oe_line_no = l.line_no 
LEFT OUTER JOIN dbo.inv_xref AS x 
ON h.customer_id = x.customer_id AND m.inv_mast_uid = x.inv_mast_uid 
INNER JOIN dbo.inventory_supplier AS s 
ON m.inv_mast_uid = s.inv_mast_uid AND l.supplier_id = s.supplier_id
WHERE (m.default_product_group NOT IN ('OTHERCHG', 'D1') OR  m.default_product_group IS NULL) AND (h.rma_flag = 'N') AND (op.delete_flag = 'N') AND (op.invoice_no IS NULL) AND (l.qty_on_pick_tickets <> 0) AND (p.print_quantity <> 0) AND (h.location_id = 100) AND (h.completed IN ('N', 
                         'T')) AND (h.projected_order = 'N') AND (l.delete_flag = 'N') AND (l.detail_type = 0)
/*
go 

grant select on object::Bar_PT_PTI_Labels_VW to p21_application_role
grant select on object::Bar_PT_PTI_Labels_VW to PxxiUser
grant select on object::Bar_PT_PTI_Labels_VW to [PTIDOM\P21Users]
*/


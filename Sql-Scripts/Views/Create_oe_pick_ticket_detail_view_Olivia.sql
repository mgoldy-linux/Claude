/*
	03/27/2020 When you have a chance next week, would you add a calculated field to my view oe_pick_ticket_detail_view_Olivia? “EstimatedSales” = qty_to_pick * unit_price

*/

Use P21;

/*
if OBJECT_ID('A_oe_pick_ticket_detail_view_Olivia') IS NOT NULL
drop view [A_oe_pick_ticket_detail_view_Olivia];
go
create view [dbo].[A_oe_pick_ticket_detail_view_Olivia] AS
*/


SELECT        pd.pick_ticket_no, dbo.oe_pick_ticket.order_no, pd.oe_line_no, pd.inv_mast_uid, dbo.oe_line.product_group_id AS Expr1, 
                         pd.qty_to_pick, dbo.oe_line.unit_price,(pd.qty_to_pick * dbo.oe_line.unit_price )[EstimatedSales], dbo.oe_hdr.customer_id, dbo.oe_hdr.order_date, dbo.oe_hdr.delete_flag, dbo.customer.salesrep_id, dbo.customer.class_1id, dbo.customer.class_2id, 
                         dbo.customer.class_3id, dbo.customer.class_4id, dbo.customer.class_5id, dbo.oe_hdr.location_id, dbo.A_oe_pick_tickets_shipped_Olivia.c_ship_date, dbo.A_oe_pick_tickets_shipped_Olivia.c_tracking_no, 
                         dbo.A_oe_pick_tickets_shipped_Olivia.c_carrier, dbo.A_oe_pick_tickets_shipped_Olivia.loc, dbo.A_oe_pick_tickets_shipped_Olivia.location_id AS Expr2, dbo.A_oe_pick_tickets_shipped_Olivia.projected_order, 
                         dbo.A_oe_pick_tickets_shipped_Olivia.cancel_flag, dbo.A_oe_pick_tickets_shipped_Olivia.shipment_id, dbo.A_oe_pick_tickets_shipped_Olivia.Order_Amt, dbo.A_oe_pick_tickets_shipped_Olivia.invoice_no
FROM            dbo.oe_pick_ticket_detail pd INNER JOIN
                         dbo.oe_pick_ticket ON pd.pick_ticket_no = dbo.oe_pick_ticket.pick_ticket_no INNER JOIN
                         dbo.oe_line ON dbo.oe_pick_ticket.order_no = dbo.oe_line.order_no AND pd.oe_line_no = dbo.oe_line.line_no INNER JOIN
                         dbo.oe_hdr ON dbo.oe_pick_ticket.order_no = dbo.oe_hdr.order_no INNER JOIN
                         dbo.customer ON dbo.oe_hdr.customer_id = dbo.customer.customer_id INNER JOIN
                         dbo.A_oe_pick_tickets_shipped_Olivia ON pd.pick_ticket_no = dbo.A_oe_pick_tickets_shipped_Olivia.pick_ticket_no



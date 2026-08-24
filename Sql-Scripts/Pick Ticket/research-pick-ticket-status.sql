select *
from oe_pick_ticket 
where order_no = 1653769

--Warehouse Activity Tab on Order Entry: 1578668 (MOTION IND-EDEN PRAIRIE,MN) Quote: N*
SELECT
   oe_pick_ticket.pick_ticket_no,
   oe_pick_ticket.print_date print_date,
   oe_pick_ticket.invoice_no,
   CASE WHEN COALESCE(oe_pick_ticket.invoice_no, 0) = 0 THEN '' ELSE 'Shipped' END picking_status,
   CASE WHEN COALESCE(oe_pick_ticket.invoice_no, 0) = 0 THEN 0 ELSE 100 END percent_picked,
   '' bin,
   CASE WHEN group_pick_ticket_hdr.transaction_type_cd = 1941 THEN group_pick_ticket_hdr.group_pick_ticket_hdr_uid ELSE NULL END,
   CASE WHEN group_pick_ticket_hdr.transaction_type_cd = 1941 THEN group_pick_ticket_hdr.row_status_flag ELSE NULL END,
   CASE WHEN group_pick_ticket_hdr.transaction_type_cd = 1881 THEN group_pick_ticket_hdr.group_pick_ticket_hdr_uid ELSE NULL END,
   NULL,
   group_pick_ticket_hdr.location_id
FROM
   oe_pick_ticket
   INNER JOIN oe_hdr ON oe_hdr.order_no = oe_pick_ticket.order_no
   INNER JOIN location ON location.location_id = oe_pick_ticket.location_id
   AND location.rf_enabled_flag = 'Y'
   AND oe_pick_ticket.delete_flag = 'N'
   LEFT JOIN group_pick_ticket_detail ON group_pick_ticket_detail.pick_ticket_no = oe_pick_ticket.pick_ticket_no
   LEFT JOIN group_pick_ticket_hdr ON group_pick_ticket_hdr.group_pick_ticket_hdr_uid = group_pick_ticket_detail.group_pick_ticket_hdr_uid
   AND group_pick_ticket_hdr.transaction_type_cd IN (1881, 1941)

   select top 6 *
   from    group_pick_ticket_hdr

   select top 6 *
   from    group_pick_ticket_detail

   select distinct group_pick_ticket_hdr_uid
   from  group_pick_ticket_detail
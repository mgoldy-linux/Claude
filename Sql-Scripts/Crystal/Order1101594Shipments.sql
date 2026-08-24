--Shipments Tab on Order Drill Down By Order: 1101594 (BDI - ADDISON IL - 11)*
SELECT oe_pick_ticket.pick_ticket_no,   
       oe_pick_ticket.print_date,   
       COALESCE(p21_view_clippership_return_10004.carrier_name, address.name) c_carrier,
       COALESCE(p21_view_clippership_return_10004.tracking_no, ptshipment.shipment_id, oe_pick_ticket.tracking_no) c_tracking_no,
       COALESCE(p21_view_clippership_return_10004.total_charge_foreign, oe_pick_ticket.freight_out) c_freight_out,   
       oe_pick_ticket.freight_in,   
       oe_pick_ticket.pick_and_hold,   
       COALESCE(p21_view_clippership_return_10004.shipped_date, oe_pick_ticket.ship_date) c_ship_date,
       oe_pick_ticket.invoice_no,   
       oe_pick_ticket.auxiliary,   
       oe_pick_ticket.direct_shipment,   
       oe_pick_ticket.delete_flag  
       ,oe_pick_ticket.company_id
         , oe_pick_ticket.outgoing_freight_cost
      ,oe_pick_ticket.order_no
FROM   oe_pick_ticket
       LEFT JOIN p21_view_clippership_return_10004 ON (p21_view_clippership_return_10004.pick_ticket_no = oe_pick_ticket.pick_ticket_no)
                                                  AND (p21_view_clippership_return_10004.delete_flag = 'N')
       LEFT JOIN shipment AS ptshipment ON ( ptshipment.row_status_flag = 2175 )
            AND ( 
                     ptshipment.transaction_type_cd = 1000
                     AND ptshipment.transaction_no = oe_pick_ticket.pick_ticket_no 
                  )
       LEFT JOIN address ON (address.id = oe_pick_ticket.carrier_id)
WHERE  (oe_pick_ticket.order_no = 1101594) AND
       (oe_pick_ticket.delete_flag = 'N')
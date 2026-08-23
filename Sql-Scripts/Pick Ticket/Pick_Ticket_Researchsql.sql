select *
from p21_view_audit_trail_oe_pick_ticket_1122
where key1_value = 2162851 

select *
from p21_view_support_sql_invoice_oe_pick_ticket
where pick_ticket_no = 2162851

select item_id,pick_ticket_no,line_number,qty_to_pick,inv_mast_uid
from p21_view_support_sql_salesorder_oe_pick_ticket_detail
where pick_ticket_no = 2162851

select pick_ticket_no,inv_mast_uid,po_no,ship2_name,item_id,item_desc
from pick_ticket_view_139
where pick_ticket_no = 2162851

select pick_ticket_no,order_no,location_id,delete_flag,line_number,item_id,item_desc,unit_of_measure,qty_to_pick,customer_id,third_party_billing_flag,assembly
from pathguide_pick_ticket_view
where pick_ticket_no = 2162851

select *
from p21_view_manifest_pick_ticket_rate_shop
where ReleaseIdentification = 2162851

select *
from pathguide_pick_ticket_view_no_notes
where pick_ticket_no = 2162851

select top 5 *
from p21_view_manifest_pick_ticket_data
where [Shipment.ReleaseIdentification] = 2162851

select *
from pathguide_pick_ticket_view_no_notes
where pick_ticket_no = 2162851

select  *
from p21_view_unconfirmed_pick_ticket_report
where pick_ticket_no = 2162851
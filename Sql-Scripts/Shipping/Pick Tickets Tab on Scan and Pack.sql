select top 100 p.scan_pack_uid, p.location_ID, i.invoice_date, i.invoice_no, i.order_no,pick_ticket_no 
from invoice_hdr I join oe_pick_ticket P 
on i.order_no=p.order_no  where year(I.invoice_date) = '2024'  
and customer_id = '16425' and p.scan_pack_uid is null order by i.invoice_date desc

select top 100 p.scan_pack_uid, p.location_ID, i.invoice_date, i.invoice_no, i.order_no ,pick_ticket_no,sp.scan_pack_uid
from invoice_hdr I 
join oe_pick_ticket P 
on i.order_no=p.order_no 
join scan_pack sp
on P.scan_pack_uid = sp.scan_pack_uid
 where year(I.invoice_date) = '2024'  
and customer_id = '16425' and p.scan_pack_uid is not null order by i.invoice_date desc

select *
from scan_pack
where scan_pack_uid = 30126

--Pick Tickets Tab on Scan and Pack
SELECT
   TOP 100 scan_pack.scan_pack_uid,
   scan_pack.row_status_flag,
   scan_pack.date_created,
   scan_pack.created_by,
   scan_pack.date_last_modified,
   scan_pack.last_maintained_by,
    pick_ticket_no,
   oe_hdr.ship2_name,
   oe_hdr.ship2_add1,
   oe_hdr.ship2_add2,
   oe_hdr.ship2_city,
   oe_hdr.ship2_state,
   oe_hdr.ship2_zip,
   oe_hdr.ship2_country,
   'Y' c_retrieved,
   COALESCE(customer.mfr_no, '0000000') mfr_no,
   customer.customer_id,
   oe_pick_ticket.location_id,
   CASE WHEN scan_pack.row_status_flag = 700 THEN 'Y' ELSE 'N' END delete_flag,
   CASE WHEN scan_pack.row_status_flag = 701 THEN 'Y' ELSE 'N' END complete_flag,
   'N' prnt_crtn_lbl_display,
   'N' prnt_ship_lbl_display,
   'N' prnt_ucc128_lbl_display,
   COALESCE(customer.send_ucc128info, 'N') send_ucc128info,
   COALESCE(
      customer.prnt_carton_label_after_final_pkg_flag,
      location_packing_options.prnt_carton_label_after_final_pkg_flag
   ) prnt_crtn_lbl_after_finalize,
   COALESCE(
      customer.prnt_shipping_lbl_after_final_pkg_flag,
      location_packing_options.prnt_shipping_lbl_after_final_pkg_flag
   ) prnt_ship_lbl_after_finalize,
   COALESCE(
      customer.prnt_ucc128_label_after_final_pkg_flag,
      'N'
   ) prnt_ucc128_lbl_after_finalize,
   oe_hdr.carrier_id,
  --contact_name,
   scan_pack.source_cd,
   'N' c_send_edi_753_flag,
   scan_pack.prnt_ucc128_lbl_display_flag
FROM
   scan_pack
   LEFT JOIN oe_pick_ticket ON (
      oe_pick_ticket.scan_pack_uid = scan_pack.scan_pack_uid
   )
   LEFT JOIN oe_hdr ON (oe_hdr.order_no = oe_pick_ticket.order_no)
   LEFT JOIN customer ON (customer.customer_id = oe_hdr.customer_id)
   AND (customer.company_id = oe_pick_ticket.company_id)
   LEFT JOIN location_packing_options ON location_packing_options.location_id = oe_pick_ticket.location_id
WHERE
   scan_pack.row_status_flag <> 700 and year(scan_pack.date_created) = 2024 and customer.customer_id = 16425
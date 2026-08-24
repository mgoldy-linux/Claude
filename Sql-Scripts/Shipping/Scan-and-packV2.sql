Use P21Sand;

SELECT TOP 200 sp.scan_pack_uid,ih.invoice_no,pc.code_description[Status],sp.date_created,sp.created_by,sp.date_last_modified,sp.last_maintained_by,pick_ticket_no,oh.ship2_name,oh.ship2_add1,oh.ship2_add2,oh.ship2_city,oh.ship2_state,oh.ship2_zip,oh.ship2_country,COALESCE(c.mfr_no,'0000000') mfr_no,c.customer_id,opt.location_id,
CASE 
WHEN sp.row_status_flag = 700 THEN 'Y' ELSE 'N' 
END delete_flag,
CASE 
WHEN sp.row_status_flag = 701 THEN 'Y' ELSE 'N' 
END complete_flag,'N' prnt_crtn_lbl_display,COALESCE(c.send_ucc128info, 'N') send_ucc128info,COALESCE(c.prnt_carton_label_after_final_pkg_flag,lpo.prnt_carton_label_after_final_pkg_flag) prnt_crtn_lbl_after_finalize,COALESCE(c.prnt_shipping_lbl_after_final_pkg_flag,lpo.prnt_shipping_lbl_after_final_pkg_flag) prnt_ship_lbl_after_finalize,COALESCE(c.prnt_ucc128_label_after_final_pkg_flag,'N') prnt_ucc128_lbl_after_finalize,oh.carrier_id,
CASE
WHEN sp.source_cd = 1122 then 'SHIPPING' ELSE 'NOT SHIPPING'
END [P21 Source],sp.prnt_ucc128_lbl_display_flag  
FROM scan_pack sp
LEFT JOIN oe_pick_ticket opt
ON (   opt.scan_pack_uid = sp.scan_pack_uid)
LEFT JOIN oe_hdr oh
ON (oh.order_no = opt.order_no)
LEFT JOIN customer c
ON (c.customer_id = oh.customer_id)AND (c.company_id = opt.company_id)
LEFT JOIN location_packing_options lpo
ON lpo.location_id = opt.location_id
LEFT JOIN invoice_hdr ih
on ih.order_no = oh.order_no
JOIN code_p21 pc
on sp.row_status_flag = pc.code_no
WHERE sp.row_status_flag <> 700 and year(sp.date_created) = 2024 and c.customer_id = 16425
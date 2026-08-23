
SELECT ih.invoice_no,oh.po_no,ih.ship_to_id,ih.order_no,il.line_no,
case
 when (DATEDIFF(day,ol.required_date,ih.invoice_date)+ 2) between 0 and 2 then 'On Time'
  when (DATEDIFF(day,ol.required_date,ih.invoice_date)+ 2) > 2 then Cast(DATEDIFF(day,ol.required_date,ih.invoice_date) as VarChar(5)) + ' Days Late'
  else Cast(DATEDIFF(day,ih.invoice_date,ol.required_date) as VarChar(5)) + ' Days Early'
end[Days Late/Early],convert(varchar(10),ol.required_date,120)[required_date],convert(varchar(10),ih.invoice_date,120)[invoice_date],convert(varchar(10),oh.order_date,120)[order_date],opt.print_date,COALESCE(clip.shipped_date,opt.ship_date) c_ship_date,Convert(varchar(12),DATEADD(MINUTE,DATEDIFF(MINUTE,opt.print_date,COALESCE(clip.shipped_date,opt.ship_date)),0),114)[Diff Print Ship Time],DATEDIFF(day,ol.required_date,COALESCE(clip.shipped_date,opt.ship_date))[Diff btw Ship Request Dates],DATEDIFF(day,opt.print_date,ol.required_date)[Diff btw Print Request Dates], DATEDIFF(day,oh.order_date,opt.print_date)[Diff btw Order Print Dates]
FROM invoice_line il
INNER JOIN invoice_hdr ih 
ON ih.invoice_no = il.invoice_no 
INNER JOIN p21_fnt_get_customers('MGOLDYN') AS c 
ON c.customer_id = ih.customer_id_number AND c.company_id = ih.company_no
LEFT JOIN inv_mast m 
ON (m.inv_mast_uid = il.inv_mast_uid)
LEFT JOIN product_group
ON il.product_group_id = product_group.product_group_id AND ih.company_no = product_group.company_id
LEFT JOIN supplier 
ON il.supplier_id = supplier.supplier_id
LEFT JOIN price_family
ON (price_family.price_family_uid = m.default_price_family_uid)
LEFT JOIN discount_group AS sales_discount_group 
ON (sales_discount_group.discount_group_id = il.sales_discount_group_id)
LEFT JOIN discount_group AS purchase_disc_group 
ON (purchase_disc_group.discount_group_id = m.default_purchase_disc_group)
LEFT JOIN inventory_supplier 
ON m.inv_mast_uid = inventory_supplier.inv_mast_uid AND inventory_supplier.supplier_id = il.supplier_id
LEFT JOIN class as class_id1
ON m.class_id1 = class_id1.class_id AND class_id1.class_type='IV' AND class_id1.class_number=1
LEFT JOIN class as class_id2
ON m.class_id2 = class_id2.class_id AND class_id2.class_type='IV' AND class_id2.class_number=2
LEFT JOIN class as class_id3
ON m.class_id3 = class_id3.class_id AND class_id3.class_type='IV' AND class_id3.class_number=3
LEFT JOIN class as class_id4
ON m.class_id4 = class_id4.class_id AND class_id4.class_type='IV' AND class_id4.class_number=4
LEFT JOIN class as class_id5
ON m.class_id5 = class_id5.class_id AND class_id5.class_type='IV' AND class_id5.class_number=5
LEFT JOIN manufacturing_class
ON inventory_supplier.manufacturing_class_id = manufacturing_class.manufacturing_class_id
LEFT JOIN oe_hdr oh
ON il.order_no = oh.order_no
LEFT JOIN oe_line ol 
ON il.order_no = ol.order_no AND il.oe_line_number = ol.line_no
LEFT JOIN location AS source_location
ON source_location.location_id = ol.source_loc_id
LEFT JOIN location 
ON location.location_id = oh.location_id
LEFT JOIN inv_loc 
ON ih.sales_location_id = inv_loc.location_id AND inv_loc.inv_mast_uid = il.inv_mast_uid
INNER JOIN company 
ON ih.company_no = company.company_id 
LEFT JOIN currency_line 
ON currency_line.currency_line_uid = 
ih.currency_line_uid
LEFT JOIN currency_hdr 
ON currency_hdr.currency_id = (COALESCE(currency_line.to_currency_id, company.home_currency_id))
LEFT JOIN code_p21 AS code_invoice_line_type
ON il.invoice_line_type = code_invoice_line_type.code_no
LEFT JOIN class AS class1
ON c.class_1id = class1.class_id AND class1.class_type='CS' AND class1.class_number=1 
LEFT JOIN class AS class2
ON c.class_2id = class2.class_id AND class2.class_type='CS' AND class2.class_number=2 
LEFT JOIN class AS class3
ON c.class_3id = class3.class_id AND class3.class_type='CS' AND class3.class_number=3 
LEFT JOIN class AS class4
ON c.class_4id = class4.class_id AND class4.class_type='CS' AND class4.class_number=4 
LEFT JOIN class AS class5
ON c.class_5id = class5.class_id AND class5.class_type='CS' AND class5.class_number=5 
LEFT JOIN ship_to
ON ih.ship_to_id = ship_to.ship_to_id AND ih.company_no = ship_to.company_id
LEFT JOIN class AS ship_to_class1 
ON ship_to.class1_id = ship_to_class1.class_id AND ship_to_class1.class_type='CS' AND ship_to_class1.class_number=1 
LEFT JOIN class AS ship_to_class2 
ON ship_to.class2_id = ship_to_class2.class_id AND ship_to_class2.class_type='CS' AND ship_to_class2.class_number=2 
LEFT JOIN class AS ship_to_class3 
ON ship_to.class3_id = ship_to_class3.class_id AND ship_to_class3.class_type='CS' AND ship_to_class3.class_number=3 
LEFT JOIN class AS ship_to_class4 
ON ship_to.class4_id = ship_to_class4.class_id AND ship_to_class4.class_type='CS' AND ship_to_class4.class_number=4 
LEFT JOIN class AS ship_to_class5 
ON ship_to.class5_id = ship_to_class5.class_id AND ship_to_class5.class_type='CS' AND ship_to_class5.class_number=5 
LEFT JOIN class AS oeclass1
ON oh.class_1id = oeclass1.class_id AND oeclass1.class_type='OE' AND oeclass1.class_number=1
LEFT JOIN class AS oeclass2
ON oh.class_2id = oeclass2.class_id AND oeclass2.class_type='OE' AND oeclass2.class_number=2 
LEFT JOIN class AS oeclass3
ON oh.class_3id = oeclass3.class_id AND oeclass3.class_type='OE' AND oeclass3.class_number=3 
LEFT JOIN class AS oeclass4
ON oh.class_4id = oeclass4.class_id AND oeclass4.class_type='OE' AND oeclass4.class_number=4 
LEFT JOIN class AS oeclass5
ON oh.class_5id = oeclass5.class_id AND oeclass5.class_type='OE' AND oeclass5.class_number=5 
LEFT JOIN purchase_class 
ON inv_loc.purchase_class = purchase_class.purchase_class_id
LEFT JOIN shipping_route 
ON oh.shipping_route_uid =shipping_route.shipping_route_uid
LEFT JOIN invoice_hdr_salesrep 
ON ( invoice_hdr_salesrep.invoice_number = ih.invoice_no AND invoice_hdr_salesrep.salesrep_id = ih.salesrep_id AND invoice_hdr_salesrep.primary_salesrep='Y' )
LEFT JOIN contacts 
ON contacts.id = invoice_hdr_salesrep.salesrep_id
LEFT JOIN contacts as oe_contact 
on oe_contact.id = oh.contact_id
JOIN oe_pick_ticket opt
ON (opt.invoice_no = ih.invoice_no)
LEFT JOIN p21_view_clippership_return_10004 clip
ON (clip.pick_ticket_no = opt.pick_ticket_no) AND (clip.delete_flag = 'N')
WHERE ih.company_no = '1' AND c.customer_id in (54210,54533,113521) and invoice_date between '2024-02-01' and '2024-03-01' -- and oh.order_no = 1538243 ---   AND ih.invoice_date >= DATEADD(day, -90, current_timestamp)
order by invoice_no
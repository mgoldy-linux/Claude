/*
	Item IDs on order_no 5061126 whose primary supplier (location-level)
	is supplier_id 3003683.

	oe_line has no item_id column -- must resolve it via inv_mast_uid.
*/

DECLARE @order_no int = 5061126;
DECLARE @supplier_id int = 3003683;

SELECT DISTINCT
	oh.order_no,
	ol.line_no,
	im.item_id,
	im.item_desc,
	ol.qty_ordered,
	ol.unit_price,
	il.primary_supplier_id,
	s.supplier_name
FROM oe_hdr oh
JOIN oe_line ol
	ON ol.order_no = oh.order_no
	AND ol.delete_flag = 'N'
JOIN inv_mast im
	ON im.inv_mast_uid = ol.inv_mast_uid
JOIN inv_loc il
	ON il.inv_mast_uid = ol.inv_mast_uid
	AND il.location_id = ol.source_loc_id
JOIN supplier s
	ON s.supplier_id = il.primary_supplier_id
WHERE oh.order_no = @order_no
	AND il.primary_supplier_id = @supplier_id
ORDER BY ol.line_no;

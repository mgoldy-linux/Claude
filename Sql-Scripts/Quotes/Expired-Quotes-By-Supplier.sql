/*
	Expired quotes containing at least one line whose item's primary
	supplier (location-level) matches the given supplier_id.

	"Expired"  = quote_hdr.expiration_date has passed
	"Open"     = not cancelled, not completed/converted, quote itself not marked complete

	supplier_id here is the P21 `supplier` table PK (as used on
	inv_loc.primary_supplier_id / inventory_supplier.supplier_id) --
	NOT the same key space as vendor.vendor_id.
*/

DECLARE @supplier_id int = 3003683;

SELECT DISTINCT
	oh.order_no,
	oh.customer_id,
	c.customer_name,
	oh.order_date,
	qh.expiration_date,
	DATEDIFF(day, qh.expiration_date, GETDATE())	AS days_expired,
	oh.taker,
	s.supplier_id,
	s.supplier_name
FROM oe_hdr oh
JOIN quote_hdr qh
	ON qh.oe_hdr_uid = oh.oe_hdr_uid
JOIN customer c
	ON c.customer_id = oh.customer_id
JOIN oe_line ol
	ON ol.order_no = oh.order_no
	AND ol.delete_flag = 'N'
JOIN inv_loc il
	ON il.inv_mast_uid = ol.inv_mast_uid
	AND il.location_id = ol.source_loc_id
JOIN supplier s
	ON s.supplier_id = il.primary_supplier_id
WHERE oh.delete_flag = 'N'
	AND oh.cancel_flag = 'N'
	AND oh.completed = 'N'
	AND ISNULL(qh.complete_flag, 'N') = 'N'
	AND qh.expiration_date IS NOT NULL
	AND qh.expiration_date < GETDATE()
	AND il.primary_supplier_id = @supplier_id
ORDER BY qh.expiration_date;

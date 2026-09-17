/*
	Stockable items missing UPC/EAN, by location.

	UPC/EAN live on inventory_supplier (per item x supplier), NOT on inv_loc
	or inv_mast -- see Items-Missing-Supplier-UPC-EAN.sql. Resolved here to
	each location's primary supplier via inv_loc.primary_supplier_id, same
	join used across the other supplier-by-location scripts in this repo.
	"Stockable" = inv_loc.stockable = 'Y'.
*/

--------------------------------------------------------------------------
-- 3) Count of stockable items per location missing BOTH UPC and EAN
--    (on the primary supplier's item record)
--------------------------------------------------------------------------
SELECT
	il.location_id,
	loc.location_name,
	COUNT(*) AS missing_upc_and_ean_count
FROM inv_loc il
JOIN location loc
	ON loc.location_id = il.location_id
	AND loc.delete_flag = 'N'
JOIN inv_mast im
	ON im.inv_mast_uid = il.inv_mast_uid
	AND im.delete_flag = 'N'
JOIN inventory_supplier isup
	ON isup.inv_mast_uid = il.inv_mast_uid
	AND isup.supplier_id = il.primary_supplier_id
	AND isup.delete_flag = 'N'
WHERE il.stockable = 'Y'
	AND NULLIF(LTRIM(RTRIM(isup.upc_code)), '') IS NULL
	AND NULLIF(LTRIM(RTRIM(isup.ean_code)), '') IS NULL
GROUP BY il.location_id, loc.location_name
ORDER BY missing_upc_and_ean_count DESC;


--------------------------------------------------------------------------
-- 4) Item IDs missing BOTH UPC and EAN at location 221, with primary supplier
--------------------------------------------------------------------------
SELECT
	im.item_id,
	im.item_desc,
	il.location_id,
	s.supplier_id,
	s.supplier_name
FROM inv_loc il
JOIN inv_mast im
	ON im.inv_mast_uid = il.inv_mast_uid
	AND im.delete_flag = 'N'
JOIN inventory_supplier isup
	ON isup.inv_mast_uid = il.inv_mast_uid
	AND isup.supplier_id = il.primary_supplier_id
	AND isup.delete_flag = 'N'
JOIN supplier s
	ON s.supplier_id = il.primary_supplier_id
	AND s.delete_flag = 'N'
WHERE il.location_id = 221
	AND il.stockable = 'Y'
	AND NULLIF(LTRIM(RTRIM(isup.upc_code)), '') IS NULL
	AND NULLIF(LTRIM(RTRIM(isup.ean_code)), '') IS NULL
ORDER BY im.item_id;

/*
	Perf note: per Items-Missing-Supplier-UPC-EAN.sql, UPC/EAN are ~98%/74%
	unpopulated P21-wide, so query 3's blank-string tests (non-SARGable) are
	filtering a mostly-empty column -- the real cost driver is the
	inv_loc/inventory_supplier join, not the blank check. Confirm actual
	logical reads from the plan cache before adding an index; if this becomes
	a recurring report, a filtered/covering index on
	inventory_supplier(inv_mast_uid, supplier_id) INCLUDE (upc_code, ean_code)
	would help both queries here.
*/

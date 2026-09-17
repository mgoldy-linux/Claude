/*
	Expired-quote / primary-supplier cleanup analysis.

	Context: the P21 "clean out expired quotes" tool throws
	"The primary supplier for a location cannot be deleted" once a quote is
	cleared -- because the supplier tied to that quote's line items is still
	set as the primary supplier at one or more locations. These two queries
	identify (1) which suppliers are driving open/expired quotes, and
	(2) every item/location where that supplier would need to be reassigned
	before it can be removed.

	"Open, expired" quote = quote_hdr.expiration_date has passed, and the
	quote/order is not cancelled, not completed, not marked complete on
	quote_hdr.

	supplier_id = P21 `supplier` table PK (inv_loc.primary_supplier_id /
	inventory_supplier.supplier_id) -- not vendor.vendor_id.
*/

--------------------------------------------------------------------------
-- 1) Count of open, expired quotes per supplier
--    (supplier = primary supplier, at the ship-from location, of at least
--    one line on the quote)
--------------------------------------------------------------------------
SELECT
	s.supplier_id,
	s.supplier_name,
	COUNT(DISTINCT oh.order_no)                      AS expired_quote_count,
	CONVERT(char(10), MAX(qh.expiration_date), 120)  AS latest_expired_quote_date
FROM oe_hdr oh
JOIN quote_hdr qh
	ON qh.oe_hdr_uid = oh.oe_hdr_uid
JOIN oe_line ol
	ON ol.order_no = oh.order_no
	AND ol.delete_flag = 'N'
JOIN inv_loc il
	ON il.inv_mast_uid = ol.inv_mast_uid
	AND il.location_id = ol.source_loc_id
JOIN supplier s
	ON s.supplier_id = il.primary_supplier_id
	AND s.delete_flag = 'N'
WHERE oh.delete_flag = 'N'
	AND oh.cancel_flag = 'N'
	AND oh.completed = 'N'
	AND ISNULL(qh.complete_flag, 'N') = 'N'
	AND qh.expiration_date IS NOT NULL
	AND qh.expiration_date < GETDATE()
GROUP BY s.supplier_id, s.supplier_name
ORDER BY expired_quote_count DESC;


--------------------------------------------------------------------------
-- 2) For each supplier from query 1: how many items it's primary supplier
--    for, pivoted so each location_id is its own column -- the "how much
--    has to be reassigned before this supplier can be deleted" count.
--    Dynamic PIVOT because the set of location_ids isn't fixed; pattern
--    follows Sql-Scripts\Sales\PivotSalesKPIAttempt1.sql.
--------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#supplier_loc_counts') IS NOT NULL DROP TABLE #supplier_loc_counts;

;WITH expired_quote_suppliers AS (
	SELECT DISTINCT il.primary_supplier_id AS supplier_id
	FROM oe_hdr oh
	JOIN quote_hdr qh
		ON qh.oe_hdr_uid = oh.oe_hdr_uid
	JOIN oe_line ol
		ON ol.order_no = oh.order_no
		AND ol.delete_flag = 'N'
	JOIN inv_loc il
		ON il.inv_mast_uid = ol.inv_mast_uid
		AND il.location_id = ol.source_loc_id
	WHERE oh.delete_flag = 'N'
		AND oh.cancel_flag = 'N'
		AND oh.completed = 'N'
		AND ISNULL(qh.complete_flag, 'N') = 'N'
		AND qh.expiration_date IS NOT NULL
		AND qh.expiration_date < GETDATE()
)
SELECT
	s.supplier_id,
	s.supplier_name,
	il.location_id,
	COUNT(*) AS primary_supplier_item_count
INTO #supplier_loc_counts
FROM inv_loc il
JOIN expired_quote_suppliers eqs
	ON eqs.supplier_id = il.primary_supplier_id
JOIN inv_mast im
	ON im.inv_mast_uid = il.inv_mast_uid
	AND im.delete_flag = 'N'
JOIN supplier s
	ON s.supplier_id = il.primary_supplier_id
	AND s.delete_flag = 'N'
GROUP BY s.supplier_id, s.supplier_name, il.location_id;

DECLARE @loc_columns  NVARCHAR(MAX), @pivot_query NVARCHAR(MAX);

SELECT @loc_columns = STRING_AGG(QUOTENAME(CAST(location_id AS varchar(10))), ',')
	WITHIN GROUP (ORDER BY location_id)
FROM (SELECT DISTINCT location_id FROM #supplier_loc_counts) AS loc;
-- If STRING_AGG isn't available (pre-SQL Server 2017), swap for the usual
-- FOR XML PATH('') string-concat pattern instead.

SET @pivot_query = N'
SELECT supplier_id, supplier_name, ' + @loc_columns + N'
FROM #supplier_loc_counts
PIVOT (
	SUM(primary_supplier_item_count)
	FOR location_id IN (' + @loc_columns + N')
) AS pvt
ORDER BY supplier_name;';

EXEC sp_executesql @pivot_query;

DROP TABLE #supplier_loc_counts;

/*
	Perf note: query 2 filters inv_loc by primary_supplier_id against a
	small supplier set from query 1 -- if inv_loc.primary_supplier_id isn't
	indexed, both queries will scan inv_loc/oe_line in full. Worth checking
	sys.dm_db_index_usage_stats for an existing index before assuming a scan
	is fine; recommend one on inv_loc(primary_supplier_id) INCLUDE
	(inv_mast_uid, location_id) if this becomes a recurring report rather
	than a one-off.
*/

/* =====================================================================
   Inventory Value by Location, Manufacturer & Brand -- MAP & ROP,
   with primary_supplier column added

   Prototype: does adding a manufacturer-level "primary supplier" column
   fit the Inventory-sheet query without changing its row grain?
   primary_supplier is one value per class_id1 (the #1 supplier by item
   count within that class, $-tiebreak if needed - same logic as
   Manufacturer-Primary-Supplier-analysis-source-query.sql). LEFT JOINed
   on p21_view_inv_mast.class_id1 = ps.mfr_code, so it cannot fan out
   rows - confirm row count/Value still equal the MAP/ROP-only baseline.
   ===================================================================== */

;WITH mfr_supplier AS (
    SELECT im.class_id1 AS mfr_code,
           isup.supplier_id, s.supplier_name,
           COUNT(DISTINCT im.inv_mast_uid) AS item_ct
    FROM inv_mast im
    JOIN inventory_supplier isup
         ON isup.inv_mast_uid = im.inv_mast_uid
         AND isup.delete_flag = 'N'
    JOIN supplier s ON s.supplier_id = isup.supplier_id
    WHERE im.delete_flag = 'N'
      AND im.class_id1 IN ('MAP','ROP')
    GROUP BY im.class_id1, isup.supplier_id, s.supplier_name
),
max_ct AS (
    SELECT mfr_code, MAX(item_ct) AS max_ct FROM mfr_supplier GROUP BY mfr_code
),
po_dollars AS (
    SELECT im.class_id1 AS mfr_code, h.supplier_id,
           SUM(l.qty_received * l.unit_price) AS received_dollars_12mo
    FROM po_hdr h
    JOIN po_line l ON l.po_no = h.po_no AND l.delete_flag = 'N'
    JOIN inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
    WHERE h.order_date >= DATEADD(MONTH, -12, GETDATE())
      AND im.class_id1 IN ('MAP','ROP')
    GROUP BY im.class_id1, h.supplier_id
),
primary_supplier AS (
    SELECT ms.mfr_code, ms.supplier_id, ms.supplier_name,
           ROW_NUMBER() OVER (
               PARTITION BY ms.mfr_code
               ORDER BY ms.item_ct DESC, ISNULL(pd.received_dollars_12mo,0) DESC, ms.supplier_id ASC
           ) AS rnk
    FROM mfr_supplier ms
    JOIN max_ct mx ON mx.mfr_code = ms.mfr_code
    LEFT JOIN po_dollars pd ON pd.mfr_code = ms.mfr_code AND pd.supplier_id = ms.supplier_id
)
SELECT
	CASE
		WHEN p21_view_inventory_value_report.location_id = 222 THEN 220
		WHEN p21_view_inventory_value_report.location_id = 185 THEN 180
		WHEN p21_view_inventory_value_report.location_id = 122 THEN 125
		WHEN p21_view_inventory_value_report.location_id = 181 THEN 183
		WHEN p21_view_inventory_value_report.location_id = 124 THEN 121
		WHEN p21_view_inventory_value_report.location_id = 107 THEN 100
		WHEN p21_view_inventory_value_report.location_id = 0 THEN 100
	  ELSE p21_view_inventory_value_report.location_id
	  END AS 'Loc ID', --a
	p21_view_inv_mast.class_id1 as 'Manufacturer Code', --b
	mfr_class.class_description as 'Manufacturer Name', --c
	ps.supplier_name as 'Primary Supplier', --c2

	SUM(CASE WHEN p21_view_inventory_value_report.use_lot_cost = 'N' AND p21_view_inventory_value_report.qty_on_hand = p21_view_inventory_value_report.special_layer_qty
			THEN CAST(p21_view_inventory_value_report.special_layer_value as decimal (15,5))
		WHEN p21_view_inventory_value_report.use_lot_cost = 'N' AND p21_view_inventory_value_report.special_layer_qty = 0
			THEN CAST((p21_view_inventory_value_report.qty_on_hand * p21_view_inventory_value_report.cost) as decimal (15,5))
		WHEN p21_view_inventory_value_report.use_lot_cost = 'N' AND p21_view_inventory_value_report.qty_on_hand <> p21_view_inventory_value_report.special_layer_qty  AND p21_view_inventory_value_report.special_layer_qty > 0
			THEN CAST((p21_view_inventory_value_report.special_layer_value + ((p21_view_inventory_value_report.qty_on_hand - p21_view_inventory_value_report.special_layer_qty) * p21_view_inventory_value_report.cost)) as decimal (15,5))
		ELSE CAST(p21_view_inventory_value_report.lot_value as decimal (15,5))
	END) AS Value -- f

	, l.location_name
	, u.brand

FROM p21_view_inventory_value_report

	LEFT JOIN p21_view_inv_mast
		ON p21_view_inventory_value_report.item_id = p21_view_inv_mast.item_id
	LEFT JOIN p21_view_class
		ON p21_view_inv_mast.class_id2 = p21_view_class.class_id
			and p21_view_class.class_type = 'IV'
			and p21_view_class.class_number = 2
	LEFT JOIN p21_view_class mfr_class
		ON p21_view_inv_mast.class_id1 = mfr_class.class_id
			and mfr_class.class_type = 'IV' and mfr_class.class_number = 1
	LEFT JOIN primary_supplier ps
		ON ps.mfr_code = p21_view_inv_mast.class_id1
		AND ps.rnk = 1
	LEFT JOIN p21_view_location l
		on	CASE
				WHEN p21_view_inventory_value_report.location_id = 222 THEN 220
				WHEN p21_view_inventory_value_report.location_id = 185 THEN 180
				WHEN p21_view_inventory_value_report.location_id = 122 THEN 125
				WHEN p21_view_inventory_value_report.location_id = 181 THEN 183
				WHEN p21_view_inventory_value_report.location_id = 124 THEN 121
				WHEN p21_view_inventory_value_report.location_id = 107 THEN 100
				WHEN p21_view_inventory_value_report.location_id = 0 THEN 100
				ELSE p21_view_inventory_value_report.location_id
			END = l.location_id
	LEFT JOIN location_ud u
		on CASE
				WHEN p21_view_inventory_value_report.location_id = 222 THEN 220
				WHEN p21_view_inventory_value_report.location_id = 185 THEN 180
				WHEN p21_view_inventory_value_report.location_id = 122 THEN 125
				WHEN p21_view_inventory_value_report.location_id = 181 THEN 183
				WHEN p21_view_inventory_value_report.location_id = 124 THEN 121
				WHEN p21_view_inventory_value_report.location_id = 107 THEN 100
				WHEN p21_view_inventory_value_report.location_id = 0 THEN 100
				ELSE p21_view_inventory_value_report.location_id
			END = u.location_id
WHERE
	ISNULL(p21_view_inventory_value_report.product_group_id,'') not in ('SAMPLES')
	AND p21_view_inv_mast.class_id1 IN ('MAP','ROP')
GROUP BY
	CASE
		WHEN p21_view_inventory_value_report.location_id = 222 THEN 220
		WHEN p21_view_inventory_value_report.location_id = 185 THEN 180
		WHEN p21_view_inventory_value_report.location_id = 122 THEN 125
		WHEN p21_view_inventory_value_report.location_id = 181 THEN 183
		WHEN p21_view_inventory_value_report.location_id = 124 THEN 121
		WHEN p21_view_inventory_value_report.location_id = 107 THEN 100
		WHEN p21_view_inventory_value_report.location_id = 0 THEN 100
	  ELSE p21_view_inventory_value_report.location_id
	  END
	, p21_view_inv_mast.class_id1
	, mfr_class.class_description
	, ps.supplier_name
	, l.location_name
	, u.brand
ORDER BY
	u.brand
	, CASE
		WHEN p21_view_inventory_value_report.location_id = 222 THEN 220
		WHEN p21_view_inventory_value_report.location_id = 185 THEN 180
		WHEN p21_view_inventory_value_report.location_id = 122 THEN 125
		WHEN p21_view_inventory_value_report.location_id = 181 THEN 183
		WHEN p21_view_inventory_value_report.location_id = 124 THEN 121
		WHEN p21_view_inventory_value_report.location_id = 107 THEN 100
		WHEN p21_view_inventory_value_report.location_id = 0 THEN 100
	  ELSE p21_view_inventory_value_report.location_id
	  END
	, mfr_class.class_description

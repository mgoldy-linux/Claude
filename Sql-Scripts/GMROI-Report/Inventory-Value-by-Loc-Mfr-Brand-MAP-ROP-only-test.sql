/* =====================================================================
   Inventory Value by Location, Manufacturer & Brand -- MAP & ROP only
   Base: "C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents\SQL Server
   Management Studio\Inventory\Inventory Value by Location, Manufacturer &
   Brand.sql" (feeds qryInventoryValuebyLocation, the Inventory sheet of
   the GMROI workbook). Unchanged except for the added class_id1 filter.
   Used to prototype adding a primary-supplier column, same pattern as
   Trailing-90-Day-qry-MAP/ROP-with-primary-supplier-test.sql.
   ===================================================================== */

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

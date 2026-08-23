--Inventory Tab on Item Master Inquiry: 3535-2-7/8 (100)
SELECT
   inv_loc.qty_on_hand,
   inv_loc.qty_in_process,
   inv_loc.order_quantity,
   inv_loc.qty_allocated,
   inv_loc.qty_backordered,
   inv_loc.qty_in_transit,
   inv_loc.location_id,
   COALESCE(inv_loc_stock_status.qty_for_process, 0) qty_for_process,
   COALESCE(inv_loc_stock_status.qty_for_production, 0) qty_for_production,
   COALESCE(inv_loc_stock_status.qty_to_transfer, 0) qty_to_transfer,
   COALESCE(inv_loc_stock_status.qty_on_release_schedule, 0) qty_on_release_schedule,
   COALESCE(inv_loc_stock_status.qty_in_production, 0) qty_in_production,
   COALESCE(inv_loc_stock_status.qty_non_pickable, 0) qty_non_pickable,
   COALESCE(inv_loc_stock_status.qty_quarantined, 0) qty_quarantined,
   item_uom.unit_size,
   item_uom.unit_of_measure,
   COALESCE(inv_loc_stock_status.qty_frozen, 0) qty_frozen,
   COALESCE(inv_loc_stock_status.qty_on_sales_order, 0) qty_on_sales_order,
   0.000000000 'qty_in_vessel',
   truncate_available.value truncate_available_value,
   location.location_name,
   COALESCE(inv_loc_stock_status.qty_on_special_po, 0) 'qty_on_special_po',
   COALESCE(inv_loc_stock_status.qty_on_ds_po, 0) 'qty_on_ds_po',
   0.000000000 'qty_in_vessel_special',
   0.000000000 qty_on_future_order
FROM
   inv_loc
   INNER JOIN inv_mast ON inv_mast.inv_mast_uid = inv_loc.inv_mast_uid
   INNER JOIN item_uom ON item_uom.unit_of_measure = inv_mast.default_selling_unit
   AND item_uom.inv_mast_Uid = inv_mast.inv_mast_Uid
   LEFT JOIN inv_loc_stock_status ON inv_loc_stock_status.location_id = inv_loc.location_id
   AND inv_loc_stock_status.inv_mast_uid = inv_loc.inv_mast_uid
   INNER JOIN system_setting AS truncate_available ON truncate_available.name = 'truncate_available'
   INNER JOIN location ON location.location_id = inv_loc.location_id
WHERE
   (
      inv_loc.location_id BETWEEN 100
      AND 350
   )
   AND (inv_loc.inv_mast_uid = 6135)
   AND (inv_loc.company_id = 1)
   AND (
      inv_loc.delete_flag = 'N'
      OR inv_loc.delete_flag IS NULL
   )
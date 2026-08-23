--Form View Tab on Edit Inventory Cost: Location ID: 100; Item ID: 0318C (New)
SELECT inv_mast.item_id,   
         fifo_layers.date_received,
         fifo_layers.cost,
         CASE Coalesce(inv_mast_lot.use_lot_cost_as_inventory_cost, 'N')
         WHEN 'Y' THEN
            lot.sku_cost
         ELSE   
            fifo_layers.cost
         END new_cost,
         fifo_layers.qty_received,   
         fifo_layers.fifo_layer_qty,   
         fifo_layers.trans_ref_no,   
         fifo_layers.complete,   
         company.company_id,   
         fifo_layers.journal,   
         fifo_layers.document_no,   
         location.location_id,   
         fifo_layers.fifo_layer_number,   
         fifo_layers.period_created,   
         fifo_layers.year_created,   
         fifo_layers.period_completed,   
         fifo_layers.year_completed,   
         (1 * fifo_layer_qty) compute_fifo_layer_qty,
         company.company_name,
         inv_mast.item_desc,
         location.location_name, 
         'Y' c_RetrievedRow,
         lot.lot,
         lot.qty_on_hand,
         Coalesce(inv_mast_lot.use_lot_cost_as_inventory_cost, 'N'),
         lot.sku_cost,
         COALESCE(inv_loc_stock_status.qty_on_special_po_cost, 0) qty_on_special_po_cost
    FROM inv_loc
         INNER JOIN company ON inv_loc.company_id = company.company_id
         INNER JOIN location ON inv_loc.location_id = location.location_id
         INNER JOIN inv_mast ON inv_loc.inv_mast_uid = inv_mast.inv_mast_uid
         LEFT OUTER JOIN fifo_layers ON fifo_layers.location_id = inv_loc.location_id
            AND fifo_layers.inv_mast_uid = inv_loc.inv_mast_uid
            AND fifo_layers.complete = 'N'
         LEFT JOIN inv_mast_lot ON inv_mast.inv_mast_uid = inv_mast_lot.inv_mast_uid
            AND inv_mast_lot.use_lot_cost_as_inventory_cost = 'Y'
         LEFT JOIN lot ON inv_mast_lot.inv_mast_uid = lot.inv_mast_uid
            AND inv_loc.location_id = lot.location_id
            AND lot.qty_on_hand > 0
         LEFT JOIN   inv_loc_stock_status ON inv_loc_stock_status.inv_mast_uid = inv_loc.inv_mast_uid AND inv_loc_stock_status.location_id = inv_loc.location_id
    WHERE 
         inv_mast.delete_flag = 'N' 
         AND location.delete_flag = 'N'
         AND company.delete_flag  = 'N'
         AND inv_mast.other_charge_item = 'N'
         AND inv_loc.qty_on_hand > 0

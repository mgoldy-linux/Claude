--DS d_ds_inv_mast_lot_item_id
SELECT inv_mast_lot.inv_mast_lot_uid,inv_mast_lot.inv_mast_uid,    inv_mast_lot.auto_assign_lots,    inv_mast_lot.assignment_option,    inv_mast_lot.lot_assignment_required,    inv_mast.item_id,    inv_mast_lot.date_created,  inv_mast_lot.date_last_modified,  inv_mast_lot.last_maintained_by,    inv_mast_lot.use_system_setting_lot_assign,    inv_mast_lot.use_lot_cost_as_inventory_cost,    inv_mast_lot.lot_attribute_group_uid, inv_mast_lot.use_last_customer_lot_flag, inv_mast_lot.item_lot_exp_warning_days,    inv_mast_lot.belt_item_flag 
FROM inv_mast_lot  
INNER JOIN inv_mast 
ON inv_mast.inv_mast_uid = inv_mast_lot.inv_mast_uid 
--WHERE inv_mast.item_id = '3021850000REVA'
--WHERE inv_mast.item_id = '689-2RSA1CNHANGU225%'
--WHERE inv_mast.item_id = '3021364000'
WHERE inv_mast.item_id = '3021363000'
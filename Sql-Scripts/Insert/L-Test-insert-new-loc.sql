-- test add location sql insert 
use P21Sand;
INSERT INTO inv_loc ( location_id, company_id, date_created, last_maintained_by, gl_account_no, purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max, stockable, replenishment_location, months_in_season, product_group_id, purchase_class, date_last_modified, last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, price1, price2, price3, price4, price5, price6, price7, price8, price9, price10, track_bins, default_in_oe, usage_lock, primary_bin, tax_group_id, requisition, inv_mast_uid, lot_bin_integration, default_shipment, buy, make, periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items, allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd, behaves_like_lock_flag, delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag, iva_taxable_flag, iqs_item_flag, slab_track_bins_flag ) VALUES ( 300, '1', GETDATE(), 'mgoldyn-sql', '14010000100', 'P', 0.000000000, 'Y', 6.800000000, 0.000000000, 0.000000000, 0.000000000, 'Y', 410, 0, 'B4', 'D', GETDATE(), 0.000000000, 'TRITAN', 'TRITAN', 'N', 'Up To', 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 'Y', 'N', 'N', 'NO_PRIMARY', 'NOTAX', 'N', 105566, 'N', 1138, 'Y', 'N', 0, 0, 'N', 'N', 'N', 'N', 1885, 1780, 'N', 'N', 40, 'N', 'N', 'N', 'N', 'N' )

select MAX (inv_bin_uid)
from inv_bin
--- need max  inv_bin_uid - need to check for missing bin
INSERT INTO inv_bin ( company_id, location_id, bin, quantity, date_created, date_last_modified, last_maintained_by, inv_mast_uid, qty_allocated, inv_bin_uid, row_status_flag ) VALUES ( '1', 300, 'NO_PRIMARY', 0.000000000, GETDATE(), GETDATE(), 'mgoldyn-sql', 105566, 0.000000000, 659663, 1037 )

select MAX (inventory_supplier_x_loc_uid)
from inventory_supplier_x_loc

-- need max inventory_supplier_x_loc_uid
INSERT INTO inventory_supplier_x_loc (inventory_supplier_x_loc_uid, inventory_supplier_uid, location_id, primary_supplier, average_lead_time, row_status_flag, date_created, date_last_modified, last_maintained_by, vmi_status, loc_list_price, loc_cost) VALUES ( 687904, 128688, 300, 'Y', 0, 704, GETDATE(), GETDATE(), 'mgoldyn-sql', 1271, 0.000000000, 0.000000000 )

select MAX (inv_loc_msp_uid)
from inv_loc_msp

INSERT INTO inv_loc_msp ( inv_loc_msp_uid, inv_mast_uid, location_id, receipt_process_flag, row_status_flag, date_created, created_by, date_last_modified, last_maintained_by ) VALUES ( 477802, 105566, 300, 'N', 704, GETDATE(), 'mgoldyn-sql', GETDATE(), 'mgoldyn-sql' )
-- script did the item twice, why?

select location_id, company_id, date_created, last_maintained_by, gl_account_no, purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max, stockable, replenishment_location, months_in_season, product_group_id, purchase_class, date_last_modified, last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, price1, price2, price3, price4, price5, price6, price7, price8, price9, price10, track_bins, default_in_oe, usage_lock, primary_bin, tax_group_id, requisition, inv_mast_uid, lot_bin_integration, default_shipment, buy, make, periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items, allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd, behaves_like_lock_flag, delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag, iva_taxable_flag, iqs_item_flag, slab_track_bins_flag
from dbo.inv_loc
where inv_mast_uid =  119676 and location_id = 100

/* I didn't try the update statement
select inv_mast_uid,*
from dbo.inv_loc
where location_id = 100 and sales_discount_group = 'IPTCI' and price_family_uid is null and sellable = 'Y' and purchase_class = 'D'

update dbo.inv_loc
set price_family_uid = 2
where location_id = 100 and sales_discount_group = 'IPTCI'

select inv_mast_uid,purchase_class,*
from dbo.inv_loc
where inv_mast_uid in (32075, 32466)  and location_id = 100
*/

INSERT INTO inv_loc (location_id, company_id, date_created, last_maintained_by, gl_account_no,purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max,stockable, replenishment_location, months_in_season, product_group_id, purchase_class, date_last_modified,last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, price1, price2,price3, price4, price5, price6, price7, price8, price9, price10, track_bins, default_in_oe, usage_lock,primary_bin, tax_group_id, requisition, inv_mast_uid, lot_bin_integration, default_shipment, buy, make,periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items,allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd,behaves_like_lock_flag, delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag,iva_taxable_flag, iqs_item_flag, slab_track_bins_flag )VALUES( 440, '1', GETDATE(), 'mgoldyn-sql','14010000100', 'P',0.000000000, 'Y',0.000000000, 0.000000000, 0.000000000, 0.000000000,'N', 100, 0, 'B4','D', GETDATE(), 0.000000000 , 'IPTCI','IPTCI', 'N', 'Up To',47.550000000, 0.000000000 , 0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000,0.000000000, 'Y', 'N', 'N', 'NO_PRIMARY', 'NOTAX', 'N', 32466, 'N', 1138, 'N', 'N', 0, 0, 'N', 'N', 'N', 'N', 1885, 1785, 'N', 'N', , '','N', 'N', '', '')

select location_id, company_id, date_created, last_maintained_by, gl_account_no, purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max, stockable, replenishment_location, months_in_season, product_group_id, purchase_class, date_last_modified, last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, price1, price2, price3, price4, price5, price6, price7, price8, price9, price10, track_bins, default_in_oe, usage_lock, primary_bin, tax_group_id, requisition, inv_mast_uid, lot_bin_integration, default_shipment, buy, make, periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items, allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd, behaves_like_lock_flag, delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag, iva_taxable_flag, iqs_item_flag, slab_track_bins_flag
from dbo.inv_loc
where /*inv_mast_uid =  32466 and*/ location_id = 100 and sales_discount_group = 'IPTCI' and price_family_uid is null and sellable = 'Y'

select price_family_uid,sales_discount_group,*
from inv_loc
where inv_mast_uid = 32463 

select location_id, company_id, date_created, last_maintained_by, gl_account_no, purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max, stockable, replenishment_location, months_in_season, product_group_id, purchase_class, date_last_modified, last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, price1, price2, price3, price4, price5, price6, price7, price8, price9, price10, track_bins, default_in_oe, usage_lock, primary_bin, tax_group_id, requisition, inv_mast_uid, lot_bin_integration, default_shipment, buy, make, periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items, allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd, behaves_like_lock_flag, delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag, iva_taxable_flag, iqs_item_flag, slab_track_bins_flag
from dbo.inv_loc
where inv_mast_uid =  41210 and location_id = 100

INSERT INTO inventory_supplier_x_loc (inventory_supplier_x_loc_uid, inventory_supplier_uid, location_id,primary_supplier, average_lead_time, row_status_flag, date_created, date_last_modified, last_maintained_by,vmi_status,override_vmi_status, loc_list_price,loc_cost,manual_lead_time) VALUES (775522399,186915,440, 'Y', 0, 704,GetDate(), GetDate(), 'mgoldyn-sql', ,300,0.000000000,0.000000000,0)

select inventory_supplier_uid
from dbo.inventory_supplier 
where inv_mast_uid = 3600 and supplier_id = 115718

select row_status_flag,vmi_status, loc_list_price, loc_cost,manual_lead_time
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 186177 and location_id = 100

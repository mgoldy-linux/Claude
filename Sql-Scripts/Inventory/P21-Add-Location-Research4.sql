select item_id,location_id, company_id, l.date_created, l.last_maintained_by, gl_account_no, purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max, stockable, replenishment_location, months_in_season, product_group_id, purchase_class, 1date_last_modified, last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, 1.price1, 1.price2, 1.price3, 1.price4, 1.price5, 1.price6, 1.price7, 1.price8, 1.price9, 1.price10, track_bins, default_in_oe, usage_lock, primary_bin, tax_group_id, 1.requisition, 1.inv_mast_uid, lot_bin_integration, default_shipment, buy, make, periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items, allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd, behaves_like_lock_flag, 1.delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag, 1.iva_taxable_flag, 1.iqs_item_flag, slab_track_bins_flag
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid 
where location_id = 100 and price_family_uid is null and m.class_id1 = 'PTI' and class_id2 = 'EPL'

select row_status_flag,vmi_status, loc_list_price, loc_cost,manual_lead_time
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = $inventory_supplier_uid and location_id = $copy_id
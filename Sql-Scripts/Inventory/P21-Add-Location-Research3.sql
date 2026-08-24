use P21Sand;

select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id,isu.supplier_id,isxl.primary_supplier
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where item_id = '2100039247' and l.location_id = 410 and primary_supplier = 'Y'

select location_id, company_id, date_created, last_maintained_by, gl_account_no, purch_or_transfer, next_due_in_po_cost, sellable, moving_average_cost, standard_cost, inv_min, inv_max, stockable, replenishment_location, months_in_season, product_group_id, purchase_class, date_last_modified, last_rec_po, purchase_discount_group, sales_discount_group, no_charge, replenishment_method, price1, price2, price3, price4, price5, price6, price7, price8, price9, price10, track_bins, default_in_oe, usage_lock, primary_bin, tax_group_id, requisition, inv_mast_uid, lot_bin_integration, default_shipment, buy, make, periods_to_supply_min, periods_to_supply_max, discontinued, allow_ds_discontinued_items, allow_sp_discontinued_items, pattern_manually_edited_flag, demand_pattern_behavior_cd, demand_pattern_cd, behaves_like_lock_flag, delete_flag, price_family_uid, main_bulk_location_flag, drp_item_flag, iva_taxable_flag, iqs_item_flag, slab_track_bins_flag 
from inv_loc
where inv_mast_uid = 113951 and location_id = 100 -- not in (150,200,350,420,440,450,460,470,510,520)

select company_id, location_id, bin, quantity, date_created, date_last_modified, last_maintained_by, inv_mast_uid, qty_allocated, inv_bin_uid, row_status_flag
from dbo.inv_bin 
where inv_mast_uid = 105566 and location_id =300


select inventory_supplier_uid
from dbo.inventory_supplier 
where inv_mast_uid = 105566 and supplier_id = 47614


select inventory_supplier_uid,average_lead_time,row_status_flag,vmi_status, loc_list_price, loc_cost,manual_lead_time
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 51256 and location_id = 100

select m.inv_mast_uid,isu.inventory_supplier_uid 
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101049593'

select distinct receipt_process_uid
from inv_loc_msp
where location_id = 410 and inv_mast_uid = 105566


INSERT INTO inventory_supplier_x_loc (inventory_supplier_x_loc_uid, inventory_supplier_uid, location_id,
primary_supplier, average_lead_time, row_status_flag, date_created, date_last_modified, last_maintained_by,
vmi_status,override_vmi_status, loc_list_price,loc_cost,manual_lead_time) VALUES (367085658,51256,300, 'Y', 0, 704,
GetDate(), GetDate(), 'mgoldyn-sql', ,300,0.000000000,0.000000000,30)
select *
from inv_loc_msp
where receipt_process_uid = 3

select isux.inventory_supplier_uid,m.inv_mast_uid,supplier_id
from dbo.inventory_supplier_x_loc isux
join dbo.inventory_supplier isu
on isux.inventory_supplier_uid = isu.inventory_supplier_uid
join dbo.inv_mast m
on isu.inv_mast_uid = m.inv_mast_uid
where vmi_status is null and location_id = 100 and class_id1 = 'PTI' and class_id2 = 'EPL'

exec sp_help inventory_supplier_x_loc
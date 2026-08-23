-- query to add quantity to make 

declare @default_company_id varchar(1),
		@default_customer_id varchar(6),
		@default_sales_location_id varchar(4),
		@default_source_location_id varchar(4),
		@default_ship_to_id varchar(6);


select *
from inv_loc inv_loc_source
INNER JOIN inv_mast on 
(inv_mast.inv_mast_uid = inv_loc_source.inv_mast_uid)
LEFT JOIN inv_loc_stock_status on (inv_loc_stock_status.inv_mast_uid = inv_loc_source.inv_mast_uid) and
(inv_loc_stock_status.location_id = inv_loc_source.location_id)
INNER JOIN item_uom on (item_uom.inv_mast_uid = inv_mast.inv_mast_uid) and
(item_uom.unit_of_measure = inv_mast.default_selling_unit)
INNER JOIN address on (address.id = inv_loc_source.location_id)
LEFT JOIN (select drv_inv_loc.inv_mast_uid, drv_inv_loc.location_id, drv_inv_loc.product_group_id, drv_inv_loc.sellable, drv_inv_loc.delete_flag
			from inv_loc drv_inv_loc) as inv_loc_sales on (inv_loc_sales.inv_mast_uid = inv_mast.inv_mast_uid) and
(inv_loc_sales.location_id = CAST(@default_sales_location_id as DECIMAL(19,9)))
CROSS JOIN system_setting ss_truncate_avaible
LEFT JOIN assembly_hdr on assembly_hdr.inv_mast_uid = inv_mast.inv_mast_uid
LEFT JOIN item_revision on item_revision.inv_mast_uid = inv_mast.inv_mast_uid and
COALESCE (inv_mast.use_revisions_flag, 'N') = 'Y' and inv_loc_source.stockable = 'Y'
LEFT JOIN p21_view_getrevisionlotquantity on p21_view_getrevisionlotquantity.inv_mast_uid = inv_mast.inv_mast_uid and
p21_view_getrevisionlotquantity.location_id = inv_loc_source.location_id and 
item_revision.item_revision_uid = p21_view_getrevisionlotquantity.item_revision_uid
INNER JOIN location on location.location_id = inv_loc_source.location_id
INNER JOIN _oe_QTM  on _oe_QTM.assy_item_id = inv_mast.item_id --add only this p21 sql editor
where inv_mast.delete_flag = 'N' and (inv_loc_source.delete_flag = 'N' OR inv_loc_source.delete_flag IS NULL) and (inv_loc_sales.delete_flag = 'N' or inv_loc_sales.delete_flag IS NULL) and
inv_loc_source.requisition = 'N' and ((inv_loc_source.location_id = CAST(@default_source_location_id as DECIMAL(19,9))) or 'Y' = 'Y') and
ss_truncate_avaible.name = 'truncate_available' and location.location_type NOT IN (1331) and inv_mast.product_type <>'B' and location.location_type = 1330 
order by inv_mast.item_id, inv_loc_source.location_id --add only this p21 sql editor, leave out order by
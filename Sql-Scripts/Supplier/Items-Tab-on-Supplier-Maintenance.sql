--Items Tab on Supplier Maintenance: 47614 (Data Import Vendor)*
  SELECT inventory_supplier.division_id,   
         inventory_supplier.supplier_id,   
         division.division_name,   
         inv_mast.item_id,   
         inv_mast.item_desc,inv_mast.class_id2,   
         inventory_supplier.lead_time_days,   
         inventory_supplier.check_digit,   
         inventory_supplier.catalog_name,   
         inventory_supplier.catalog_page,   
         inventory_supplier.msds,   
         inventory_supplier.delete_flag,   
         inventory_supplier.date_created,   
         inventory_supplier.date_last_modified,   
         inventory_supplier.last_maintained_by,   
         inventory_supplier.supplier_part_no,   
         inventory_supplier.supplier_sort_code,   
         inventory_supplier.list_price,   
         inventory_supplier.cost,   
         inventory_supplier.manufacturing_class_id,   
         manufacturing_class.manufacturing_class_desc,   
         inventory_supplier.upc_code,   
         inventory_supplier.backhaul_type, 
      inventory_supplier.inventory_supplier_uid,
      COALESCE(inventory_supplier_trade.certificate_of_origin_file_path, ''),
      inventory_supplier_trade.certificate_of_origin_exp_date,
      COALESCE(inventory_supplier_trade.certificate_of_origin_file_path, '') cc_certificate_of_origin_file_path_orig,
      inventory_supplier_trade.certificate_of_origin_exp_date cc_certificate_of_origin_exp_date_orig,
      COALESCE(inventory_supplier_trade.inventory_supplier_trade_uid, 0),
      COALESCE(inventory_supplier_trade.country_of_origin, ''),
      COALESCE(inventory_supplier_trade.country_of_origin, '') cc_country_of_origin_orig,
      inventory_supplier.buyback_supplier_part_no,
      inventory_supplier.buyback_uom
    FROM
          inventory_supplier
         INNER JOIN inv_mast ON 
            inv_mast.inv_mast_uid = inventory_supplier.inv_mast_uid
         INNER JOIN division ON 
            inventory_supplier.division_id = division.division_id
            AND inventory_supplier.supplier_id = division.supplier_id
         LEFT JOIN manufacturing_class ON 
            manufacturing_class.manufacturing_class_id = inventory_supplier.manufacturing_class_id
      LEFT JOIN inventory_supplier_trade ON 
            inventory_supplier_trade.inventory_supplier_uid = inventory_supplier.inventory_supplier_uid      
    WHERE 
         inventory_supplier.supplier_id = 47614 and inv_mast.class_id1 != 'MD' and inv_mast.class_id2 != 'NOTEPL'
         AND inventory_supplier.delete_flag = 'N'
         AND inv_mast.delete_flag = 'N'
    ORDER BY 
          inventory_supplier.division_id ASC,   
         inv_mast.item_id ASC   

/*
select *
from inv_mast 
where item_id = '21050007747'
*/
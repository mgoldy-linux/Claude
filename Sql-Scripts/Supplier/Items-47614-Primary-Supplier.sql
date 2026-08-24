--Items Tab on Supplier Maintenance: 47614 (Data Import Vendor)*
  SELECT inv_mast.item_id,   
         inv_mast.item_desc,inv_mast.class_id2,   
         inventory_supplier.delete_flag[supplier-delete-flag],   
         inventory_supplier.cost,   
         inventory_supplier.manufacturing_class_id,   
         manufacturing_class.manufacturing_class_desc,   
         inventory_supplier.upc_code,   
         COALESCE(inventory_supplier_trade.country_of_origin, '')[COO]
    FROM
          inventory_supplier
         INNER JOIN inv_mast ON 
            inv_mast.inv_mast_uid = inventory_supplier.inv_mast_uid
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


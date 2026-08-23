SELECT        isup.future_cost, CONVERT(datetime, CONVERT(char(10), isup.effective_date, 120), 120) AS effective_date, mc.manufacturing_class_desc, supplier_ud.legacy_id, supplier_ud.legacy_company, 
                         inv_loc.qty_backordered AS qty_backordered_inventory, iss.qty_on_sales_order, iss.qty_for_production, iss.qty_on_release_schedule AS on_sched, iss.qty_in_production, iss.qty_non_pickable, iss.qty_quarantined, 
                         iss.qty_frozen, iss.qty_on_sales_quote, iss.qty_on_special_po, iss.qty_on_ds_po, iss.qty_on_special_po_cost, 
                         inv_loc.qty_on_hand - inv_loc.qty_allocated - iss.qty_quarantined - inv_loc.qty_backordered + inv_loc.qty_in_transit + inv_loc.qty_in_process + inv_loc.order_quantity AS Net_qty_available, 
                         drv_vessel_receipts_lines.total_qty_on_vessel AS qty_on_vessel, COALESCE (inv_loc.delete_flag, 'N') AS ItemLocDelete, inv_loc.company_id AS Company, inv_loc.location_id AS Location, 
                         inv_loc.inv_mast_uid AS InvenMastId, inv_loc.purchase_class AS PurchClass, inv_loc.purchase_discount_group AS PurchDiscGroup, inv_loc.sales_discount_group AS SalesDiscGroup, inv_loc.stockable AS Stock, 
                         inv_loc.no_charge AS NoCharge, inv_loc.requisition AS Requsition, inv_loc.replenishment_location AS ReplLoc, inv_loc.replenishment_method AS ReplMethod, inv_loc.period_first_stocked AS FirstPeriod, 
                         inv_loc.year_first_stocked AS FirstYear, inv_loc.primary_bin AS Bin, inv_loc.tax_group_id AS TaxGroup, inv_loc.deadstock_flag AS DeadStock, inv_loc.on_release_schedule_flag AS OnRelease, 
                         inv_loc.on_backorder_flag AS OnBO, inv_loc.buy, inv_loc.make, inv_loc.discontinued, inv_loc.track_bins, inv_loc.primary_supplier_id AS SupplierId, inv_loc.product_group_id AS ProdGroup, CONVERT(datetime, 
                         CONVERT(char(10), inv_loc.date_last_modified, 120), 120) AS DateMod, CONVERT(datetime, CONVERT(char(10), inv_loc.date_created, 120), 120) AS DateCreated, CONVERT(datetime, CONVERT(char(10), inv_loc.last_sale_date, 
                         120), 120) AS LastSale, CONVERT(datetime, CONVERT(char(10), inv_loc.last_purchase_date, 120), 120) AS LastPurchase, COALESCE (inv_loc.standard_cost, 0) AS STCost, COALESCE (inv_loc.moving_average_cost, 0) 
                         AS MACost, COALESCE (inv_loc.qty_on_hand, 0) AS QtyOnHand, COALESCE (P21invvalue.qty_on_hand, 0) - P21invvalue.special_layer_qty AS Non_Special_Qty_on_hand, FifoLayers.cost AS fifo_cost, 
                         COALESCE (inv_loc.order_quantity, 0) AS QtyOrdered, COALESCE (inv_loc.qty_in_transit, 0) AS QtyInTransit, COALESCE (inv_loc.qty_in_process, 0) AS QtyInProcess, COALESCE (inv_loc.qty_allocated, 0) AS QtyAlloc, 
                         COALESCE (inv_loc.qty_backordered, 0) AS QtyBO, COALESCE (inv_loc.qty_reserved_due_in, 0) AS QtyReserved, CAST(inv_loc.inv_min AS decimal(19, 0)) AS Minimum, inv_loc.inv_min - inv_loc.qty_on_hand AS Min_OH, 
                         inv_loc.inv_max - inv_loc.qty_on_hand AS Max_OH, inv_loc.inv_max - inv_loc.qty_on_hand - COALESCE (inv_loc.qty_in_transit, 0) AS Qty_in_transit_mx_oh, inv_loc.standard_cost, CAST(inv_loc.inv_max AS decimal(19, 0)) 
                         AS Maximum, CAST(inv_mast.weight AS decimal(19, 4)) AS weight, COALESCE (CAST(inv_loc.price1 AS decimal(19, 4)), 0) AS LocationPrice1, COALESCE (CAST(inv_loc.price2 AS decimal(19, 4)), 0) AS LocationPrice2, 
                         COALESCE (CAST(inv_loc.price3 AS decimal(19, 4)), 0) AS LocationPrice3, COALESCE (CAST(inv_loc.price4 AS decimal(19, 4)), 0) AS LocationPrice4, COALESCE (CAST(inv_loc.price5 AS decimal(19, 4)), 0) AS LocationPrice5, 
                         COALESCE (CAST(inv_loc.price6 AS decimal(19, 4)), 0) AS LocationPrice6, COALESCE (CAST(inv_loc.price7 AS decimal(19, 4)), 0) AS LocationPrice7, COALESCE (CAST(inv_loc.price8 AS decimal(19, 4)), 0) AS LocationPrice8, 
                         COALESCE (CAST(inv_loc.price9 AS decimal(19, 4)), 0) AS LocationPrice9, COALESCE (CAST(inv_loc.price10 AS decimal(19, 4)), 0) AS LocationPrice10, COALESCE (CONVERT(datetime, CONVERT(char(10), inv_loc.last_sale_date, 
                         120), 120), '1/1/1990') AS Last_Sale_Date, inv_mast.item_desc AS ItemDesc, inv_mast.extended_desc AS ExtendedDesc, inv_mast.item_id AS ItemId, inv_mast.class_id1 AS Class1, inv_mast.product_type AS ProdType, 
                         inv_mast.vendor_consigned AS Consign, inv_mast.serialized, inv_mast.catalog_item AS Catalog, COALESCE (inv_mast.delete_flag, 'N') AS MasterDelete, inv_mast.class_id3 AS Class3, inv_mast.class_id2 AS Class2, 
                         inv_mast.class_id4 AS Class4, inv_mast.class_id5 AS Class5, inv_mast.last_maintained_by, inv_mast.inactive, inv_mast.short_code, inv_mast.track_lots, inv_mast.default_product_group, 
                         inv_mast.default_sales_discount_group, inv_mast.default_purchase_disc_group, inv_mast.sales_pricing_unit, inv_mast.other_charge_item, inv_mast.default_selling_unit, inv_mast.update_via_pricing_service, 
                         inv_mast.default_purchasing_unit, inv_mast.convert_quantities, inv_mast.haz_mat_flag, inv_mast.class_code, inv_mast.item_terms_discount_pct, inv_mast.tpcx_status, inv_mast.default_transfer_unit, 
                         CAST(inv_mast.keywords AS varchar(1000)) AS keywords, inv_mast.purchase_pricing_unit, inv_mast.commodity_code, CONVERT(datetime, CONVERT(char(10), inv_mast.date_last_modified, 120), 120) AS InvMastDateModified, 
                         CONVERT(datetime, CONVERT(char(10), inv_mast.date_created, 120), 120) AS InvMastDateCreated, CAST(inv_mast.net_weight AS decimal(19, 4)) AS net_weight, CAST(inv_mast.cube AS decimal(19, 4)) AS cube, 
                         CAST(inv_mast.purchasing_weight AS decimal(19, 4)) AS purchasing_weight, COALESCE (CAST(inv_mast.price1 AS decimal(19, 4)), 0) AS MasterPrice1, COALESCE (CAST(inv_mast.price2 AS decimal(19, 4)), 0) AS MasterPrice2, 
                         COALESCE (CAST(inv_mast.price3 AS decimal(19, 4)), 0) AS MasterPrice3, COALESCE (CAST(inv_mast.price4 AS decimal(19, 4)), 0) AS MasterPrice4, COALESCE (CAST(inv_mast.price5 AS decimal(19, 4)), 0) AS MasterPrice5, 
                         COALESCE (CAST(inv_mast.price6 AS decimal(19, 4)), 0) AS MasterPrice6, COALESCE (CAST(inv_mast.price7 AS decimal(19, 4)), 0) AS MasterPrice7, COALESCE (CAST(inv_mast.price8 AS decimal(19, 4)), 0) AS MasterPrice8, 
                         COALESCE (CAST(inv_mast.price9 AS decimal(19, 4)), 0) AS MasterPrice9, COALESCE (CAST(inv_mast.price10 AS decimal(19, 4)), 0) AS MasterPrice10, CAST(inv_mast.sales_pricing_unit_size AS decimal(19, 4)) 
                         AS sales_pricing_unit_size, CAST(inv_mast.purchase_pricing_unit_size AS decimal(19, 4)) AS purchase_pricing_unit_size, COALESCE (vwR12Items.R12QtyShip, 0) AS R12QtyShip, COALESCE (vwR12Items.R12Sales, 0) 
                         AS R12Sales, COALESCE (vwR12Items.R12Cost, 0) AS R12Cost, COALESCE (vwR12Items.R12GM, 0) AS R12GM, COALESCE (vwR12Items.R12MonthsSold, 0) AS R12MonthsSold, COALESCE (vwR12Items.R12Lines, 0) 
                         AS R12Lines, COALESCE (vwR12Items.R12QtyShip / 12, 0) AS R12AvgUnits, COALESCE (vwR12Items.R12Cost / 12, 0) AS R12AvgCost, COALESCE (vwR12Items.R12DirectQtyShip, 0) AS R12DirectQtyShip, 
                         COALESCE (vwR12Items.R12DirectSales, 0) AS R12DirectSales, COALESCE (vwR12Items.R12DirectCost, 0) AS R12DirectCost, COALESCE (vwR12Items.R12DirectGM, 0) AS R12DirectGM, 
                         COALESCE (vwR12Items.R12DirectLines, 0) AS R12DirectLines, COALESCE (vwR12Items.R12WarehouseQtyShip, 0) AS R12WarehouseQtyShip, COALESCE (vwR12Items.R12WarehouseSales, 0) AS R12WarehouseSales, 
                         COALESCE (vwR12Items.R12WarehouseCost, 0) AS R12WarehouseCost, COALESCE (vwR12Items.R12WarehouseGM, 0) AS R12WarehouseGM, COALESCE (vwR12Items.R12WarehouseLines, 0) AS R12WarehouseLines, 
                         COALESCE (vwR12Items.R12Cost / 365, 0) AS AvgDailyCogs, COALESCE (vwR12Items.r12Avg_unit_price, 0) AS R12Avg_unit_price, vwR12Items.qty_ship_30, vwR12Items.qty_ship_60, vwR12Items.qty_ship_90, 
                         vwR12Items.rma_30, vwR12Items.rma_60, vwR12Items.rma_90, loc.location_name AS LocationName, branch.branch_id AS BranchID, loc.delete_flag AS LocationDelete, branch.branch_description AS branchname, 
                         div.division_name, pg.product_group_desc AS ProdGroupDesc, sup.supplier_name AS SupplierName, company.company_name, dpg.product_group_desc AS Default_Product_Group_Desc, 
                         Purchase_Class.purchase_class_description AS PurchClassDesc, Tax_group_hdr.tax_group_description, COALESCE (item_commission_class.commission_class_desc, 'Blank') AS commission_class_id, 
                         discount_group_dp.discount_group_description AS DefaultPurchGroup, discount_group_p.discount_group_description AS PurchGroup, discount_group_ds.discount_group_description AS defaultSalesGroup, 
                         discount_group_s.discount_group_description AS SalesGroup, COALESCE (Contacts.first_name + ' ' + Contacts.last_name, 'Blank') AS BuyerName, v.vendor_name, v.vendor_id, dbo.Item_notes.ItemNotes AS Item_Notes, 
                         ROUND(CASE WHEN P21invvalue.cost_basis = 'FIFO' THEN P21invvalue.fifo_layer_value WHEN P21invvalue.cost_basis = 'Lot' AND 
                         P21invvalue.track_lots = 'Y' THEN P21invvalue.lot_value WHEN P21invvalue.track_lots = 'N' OR
                         P21invvalue.cost_basis <> 'Lot' THEN CASE WHEN P21invvalue.cost_basis = 'FIFO' THEN P21invvalue.fifo_layer_qty WHEN P21invvalue.cost_basis = 'Lot' THEN P21invvalue.lot_qty ELSE P21invvalue.qty_on_hand - P21invvalue.special_layer_qty
                          END * round(P21invvalue.cost, CAST
                             ((SELECT        value
                                 FROM            [P21].dbo.system_setting AS system_setting
                                 WHERE        name = 'decimal_precision_price_cost') AS int)) ELSE 0 END, 2) + P21invvalue.special_layer_value AS Value, 
                         ROUND(CASE WHEN P21invvalue.cost_basis = 'FIFO' THEN P21invvalue.fifo_layer_value WHEN P21invvalue.cost_basis = 'Lot' AND 
                         P21invvalue.track_lots = 'Y' THEN P21invvalue.lot_value WHEN P21invvalue.track_lots = 'N' OR
                         P21invvalue.cost_basis <> 'Lot' THEN CASE WHEN P21invvalue.cost_basis = 'FIFO' THEN P21invvalue.fifo_layer_qty WHEN P21invvalue.cost_basis = 'Lot' THEN P21invvalue.lot_qty ELSE P21invvalue.qty_on_hand - P21invvalue.special_layer_qty
                          END * round(P21invvalue.cost, CAST
                             ((SELECT        value
                                 FROM            [P21].dbo.system_setting AS system_setting
                                 WHERE        name = 'decimal_precision_price_cost') AS int)) ELSE 0 END, 2) AS Non_special_Value, COALESCE (inv_loc.qty_on_hand, 0) * COALESCE (inv_loc.moving_average_cost, 0) AS Value_Mavg, 
                         COALESCE (inv_loc.qty_on_hand, 0) * COALESCE (inv_loc.standard_cost, 0) AS ValueSC, COALESCE (P21invvalue.special_layer_qty, 0) AS Special_Qty, COALESCE (P21invvalue.special_layer_value, 0) AS Special_Value, 
                         COALESCE (CASE WHEN special_layer_qty = 0 THEN 0 ELSE special_layer_value / special_layer_qty END, 0) AS SpecialCost, iss.qty_to_transfer, inv_loc.qty_on_hand - inv_loc.qty_allocated - COALESCE (iss.qty_non_pickable,
                          0) - COALESCE (iss.qty_quarantined, 0) - COALESCE (iss.qty_frozen, 0) AS AvailToAllocate, class.class_description AS class1desc, CLass2.class_description AS class2desc, CLass3.class_description AS class3desc, 
                         CLass4.class_description AS class4desc, CLass5.class_description AS class5desc, isup.upc_code, isup.supplier_part_no, isup.manufacturing_class_id, isup.division_id, COALESCE (CAST(isup.list_price AS decimal(19, 4)), 0) 
                         AS list_price, COALESCE (CAST(isup.cost AS decimal(19, 4)), 0) AS cost, COALESCE (sup.buyer_id, 'Blank') AS buyer_id, isxl.average_lead_time, COALESCE (FifoLayers.cost, 0) AS FIFOCost, COALESCE (FifoLayers.fifo_layer_qty,
                          0) AS FIFOQty, COALESCE (CAST(FifoLayers.fifo_value AS decimal(19, 4)), 0) AS FIFOValue, COALESCE (periodusage.Period1Usage, 0) AS Period1Usage, COALESCE (periodusage.Period2Usage, 0) AS Period2Usage, 
                         COALESCE (periodusage.Period3Usage, 0) AS Period3Usage, COALESCE (periodusage.Period4Usage, 0) AS Period4Usage, COALESCE (periodusage.Period5Usage, 0) AS Period5Usage, COALESCE (periodusage.Period6Usage, 
                         0) AS Period6Usage, COALESCE (periodusage.Period7Usage, 0) AS Period7Usage, COALESCE (periodusage.Period8Usage, 0) AS Period8Usage, COALESCE (periodusage.Period9Usage, 0) AS Period9Usage, 
                         COALESCE (periodusage.Period10Usage, 0) AS Period10Usage, COALESCE (periodusage.Period11Usage, 0) AS Period11Usage, COALESCE (periodusage.Period12Usage, 0) AS Period12Usage, 
                         COALESCE (periodusage.PeriodCurrentUsage, 0) AS PeriodCurrentUsage, COALESCE (periodusage.Period1Orders, 0) AS Period1Orders, COALESCE (periodusage.Period2Orders, 0) AS Period2Orders, 
                         COALESCE (periodusage.Period3Orders, 0) AS Period3Orders, COALESCE (periodusage.Period4Orders, 0) AS Period4Orders, COALESCE (periodusage.Period5Orders, 0) AS Period5Orders, 
                         COALESCE (periodusage.Period6Orders, 0) AS Period6Orders, COALESCE (periodusage.Period7Orders, 0) AS Period7Orders, COALESCE (periodusage.Period8Orders, 0) AS Period8Orders, 
                         COALESCE (periodusage.Period9Orders, 0) AS Period9Orders, COALESCE (periodusage.Period10Orders, 0) AS Period10Orders, COALESCE (periodusage.Period11Orders, 0) AS Period11Orders, 
                         COALESCE (periodusage.Period12Orders, 0) AS Period12Orders, COALESCE (periodusage.PeriodCurrentOrders, 0) AS PeriodCurrentOrders, COALESCE (periodusage.sched1_usage, 0) AS sched1_usage, 
                         COALESCE (periodusage.sched2_usage, 0) AS sched2_usage, COALESCE (periodusage.sched3_usage, 0) AS sched3_usage, COALESCE (periodusage.sched4_usage, 0) AS sched4_usage, 
                         COALESCE (periodusage.sched5_usage, 0) AS sched5_usage, COALESCE (periodusage.sched6_usage, 0) AS sched6_usage, COALESCE (periodusage.sched1_usage, 0) + COALESCE (periodusage.sched2_usage, 0) 
                         + COALESCE (periodusage.sched3_usage, 0) + COALESCE (periodusage.sched4_usage, 0) + COALESCE (periodusage.sched5_usage, 0) + COALESCE (periodusage.sched6_usage, 0) AS Total_sched_usage_6M, 
                         COALESCE (periodusage.Period1Usage, 0) + COALESCE (periodusage.Period2Usage, 0) + COALESCE (periodusage.Period3Usage, 0) + COALESCE (periodusage.Period4Usage, 0) + COALESCE (periodusage.Period5Usage, 0) 
                         + COALESCE (periodusage.Period6Usage, 0) + COALESCE (periodusage.Period7Usage, 0) + COALESCE (periodusage.Period8Usage, 0) + COALESCE (periodusage.Period9Usage, 0) + COALESCE (periodusage.Period10Usage, 0) 
                         + COALESCE (periodusage.Period11Usage, 0) + COALESCE (periodusage.Period12Usage, 0) AS Total12PeriodUsage, CAST(periodusage.Forecast_usage AS decimal(19, 4)) AS forecast_usage, 
                         COALESCE (periodusage.Period1Usage, 0) + COALESCE (periodusage.Period2Usage, 0) + COALESCE (periodusage.Period3Usage, 0) + COALESCE (periodusage.Period4Usage, 0) + COALESCE (periodusage.Period5Usage, 0) 
                         + COALESCE (periodusage.Period6Usage, 0) AS Periods1T6, COALESCE (periodusage.Period7Usage, 0) + COALESCE (periodusage.Period8Usage, 0) + COALESCE (periodusage.Period9Usage, 0) 
                         + COALESCE (periodusage.Period10Usage, 0) + COALESCE (periodusage.Period11Usage, 0) + COALESCE (periodusage.Period12Usage, 0) AS Periods7T12, COALESCE (periodusage.Period1Orders, 0) 
                         + COALESCE (periodusage.Period2Orders, 0) + COALESCE (periodusage.Period3Orders, 0) + COALESCE (periodusage.Period4Orders, 0) + COALESCE (periodusage.Period5Orders, 0) + COALESCE (periodusage.Period6Orders, 0) 
                         + COALESCE (periodusage.Period7Orders, 0) + COALESCE (periodusage.Period8Orders, 0) + COALESCE (periodusage.Period9Orders, 0) + COALESCE (periodusage.Period10Orders, 0) + COALESCE (periodusage.Period11Orders, 
                         0) + COALESCE (periodusage.Period12Orders, 0) AS Total12PeriodOrders, ROUND(CASE WHEN inv_loc.replenishment_method = 'Min/Max' THEN inv_loc.inv_min ELSE COALESCE (Daily_Usage, 0) 
                         * ((isxl.average_lead_time * COALESCE (sup.lead_time_safety_factor, 1)) + COALESCE (sup.review_cycle, 0) + (COALESCE (g.safety_stock_days, 0) * COALESCE (high_safety_stock_factor, 1))) END, 0) AS order_point, 
                         dbo.Alt_codes.alt_code, vwR12Items.orders_1, vwR12Items.orders_2, vwR12Items.orders_3, vwR12Items.orders_4, vwR12Items.orders_5, vwR12Items.orders_6, vwR12Items.orders_7, vwR12Items.orders_8, 
                         vwR12Items.orders_9, vwR12Items.orders_10, vwR12Items.orders_11, vwR12Items.orders_12, vwR12Items.R12OrderAmt, vwR12Items.R12AvgOrderPrice, COALESCE (vwR12Items.last_ship_date, '1/1/1990') AS last_ship_date,
                          COALESCE (vwR12Items.last_xfer_date, '1/1/1990') AS last_xfer_date, COALESCE (vwR12Items.last_prod_order_date, '1/1/1990') AS last_prod_order_date, COALESCE (vwR12Items.last_order_date, '1/1/1990') 
                         AS last_order_date, COALESCE (vwR12Items.last_purch_date, '1/1/1990') AS last_purch_date, COALESCE (vwR12Items.first_purch_date, '1/1/1990') AS first_purch_date, COALESCE (vwR12Items.last_xfer_to_date, '1/1/1990') 
                         AS last_xfer_to_date, CASE WHEN max_date > CONVERT(datetime, CONVERT(char(10), inv_loc.date_created, 120), 120) THEN max_date ELSE CONVERT(datetime, CONVERT(char(10), inv_loc.date_created, 120), 120) 
                         END AS Max_date, DATEDIFF(mm, CASE WHEN max_date > CONVERT(datetime, CONVERT(char(10), inv_loc.date_created, 120), 120) THEN max_date ELSE CONVERT(datetime, CONVERT(char(10), inv_loc.date_created, 120), 
                         120) END, GETDATE()) AS Months_old, vwR12Items.shipped_1, vwR12Items.shipped_2, vwR12Items.shipped_3, vwR12Items.shipped_4, vwR12Items.shipped_5, vwR12Items.shipped_6, vwR12Items.shipped_7, 
                         vwR12Items.shipped_8, vwR12Items.shipped_9, vwR12Items.shipped_10, vwR12Items.shipped_11, vwR12Items.shipped_12, vwR12Items.shipped_mtd, 
                         vwR12Items.shipped_1 + vwR12Items.shipped_2 + vwR12Items.shipped_3 + vwR12Items.shipped_4 + vwR12Items.shipped_5 + vwR12Items.shipped_6 + vwR12Items.shipped_7 + vwR12Items.shipped_8 + vwR12Items.shipped_9
                          + vwR12Items.shipped_10 + vwR12Items.shipped_11 + vwR12Items.shipped_12 + vwR12Items.shipped_mtd AS total_shipped_last_12_mtd, inv_mast.created_by, vwR12Items.qty_shipped_30d, vwR12Items.qty_shipped_60d, 
                         vwR12Items.qty_shipped_90d, g.safety_stock_days, dbo.p21_fnt_CalcLeadTimeDays(sup.lead_time_source, ls.lead_time_source, sup.average_lead_time, ls.average_lead_time, isxl.average_lead_time) AS lead_time_days, 
                         g.blanket_PO_qty, inv_loc.qty_on_hand - inv_loc.qty_allocated - iss.qty_quarantined - inv_loc.qty_backordered + inv_loc.qty_in_transit + inv_loc.qty_in_process + inv_loc.order_quantity AS Net_stock, 
                         demand.code_description AS demand_pattern, safetys.code_description AS safety_stock_type, beh.code_description AS demand_pattern_behavior, inv_loc.periods_to_supply_max, inv_loc.periods_to_supply_min, 
                         inv_loc.replenishment_method, inv_loc.last_rec_po, inv_loc.last_rec_po_with_disc, isup.supplier_sort_code, iud.legacy_item_id, iud.legacy_item_description, bu.old_bin, container.container, 
                         container.qty_on_container AS total_qty_on_container
FROM            P21.dbo.inv_loc AS inv_loc WITH (nolock) LEFT OUTER JOIN
                         P21.dbo.inv_mast AS inv_mast WITH (nolock) ON inv_loc.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.inv_mast_ud AS iud ON iud.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.inv_mast_lot AS invml WITH (nolock) ON inv_mast.inv_mast_uid = invml.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.company AS company WITH (nolock) ON inv_loc.company_id = company.company_id LEFT OUTER JOIN
                         P21.dbo.product_group AS pg WITH (nolock) ON inv_loc.company_id = pg.company_id AND inv_loc.product_group_id = pg.product_group_id LEFT OUTER JOIN
                         P21.dbo.product_group AS dpg WITH (nolock) ON inv_loc.company_id = dpg.company_id AND inv_mast.default_product_group = dpg.product_group_id LEFT OUTER JOIN
                         P21.dbo.purchase_class AS Purchase_Class WITH (nolock) ON Purchase_Class.purchase_class_id = inv_loc.purchase_class LEFT OUTER JOIN
                         P21.dbo.location AS loc WITH (nolock) ON inv_loc.location_id = loc.location_id LEFT OUTER JOIN
                         P21.dbo.branch AS branch WITH (nolock) ON loc.default_branch_id = branch.branch_id AND loc.company_id = branch.company_id LEFT OUTER JOIN
                         P21.dbo.supplier AS sup WITH (nolock) ON inv_loc.primary_supplier_id = sup.supplier_id LEFT OUTER JOIN
                         P21.dbo.class AS class WITH (nolock) ON inv_mast.class_id1 = class.class_id AND class.class_number = 1 AND class.class_type = 'iv' AND class.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass2 WITH (nolock) ON inv_mast.class_id2 = CLass2.class_id AND CLass2.class_number = 2 AND CLass2.class_type = 'iv' AND CLass2.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass3 WITH (nolock) ON inv_mast.class_id3 = CLass3.class_id AND CLass3.class_number = 3 AND CLass3.class_type = 'iv' AND CLass3.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass4 WITH (nolock) ON inv_mast.class_id4 = CLass4.class_id AND CLass4.class_number = 4 AND CLass4.class_type = 'iv' AND CLass4.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass5 WITH (nolock) ON inv_mast.class_id5 = CLass5.class_id AND CLass5.class_number = 5 AND CLass5.class_type = 'iv' AND CLass5.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.inventory_supplier AS isup ON isup.inv_mast_uid = inv_loc.inv_mast_uid AND isup.supplier_id = inv_loc.primary_supplier_id LEFT OUTER JOIN
                         P21.dbo.division AS div WITH (nolock) ON isup.supplier_id = div.supplier_id AND isup.division_id = div.division_id LEFT OUTER JOIN
                         P21.dbo.p21_view_inventory_value_report AS P21invvalue ON inv_loc.company_id = P21invvalue.company_id AND inv_loc.location_id = P21invvalue.location_id AND 
                         inv_loc.inv_mast_uid = P21invvalue.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.item_commission_class AS item_commission_class WITH (nolock) ON item_commission_class.commission_class_id = inv_mast.commission_class_id AND item_commission_class.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.discount_group AS discount_group_dp WITH (nolock) ON discount_group_dp.delete_flag = 'N' AND discount_group_dp.discount_group_id = inv_mast.default_purchase_disc_group LEFT OUTER JOIN
                         P21.dbo.discount_group AS discount_group_p WITH (nolock) ON discount_group_p.delete_flag = 'N' AND discount_group_p.discount_group_id = inv_loc.purchase_discount_group LEFT OUTER JOIN
                         P21.dbo.discount_group AS discount_group_s WITH (nolock) ON discount_group_s.delete_flag = 'N' AND discount_group_s.discount_group_id = inv_loc.sales_discount_group LEFT OUTER JOIN
                         P21.dbo.discount_group AS discount_group_ds WITH (nolock) ON discount_group_ds.delete_flag = 'N' AND discount_group_ds.discount_group_id = inv_mast.default_sales_discount_group LEFT OUTER JOIN
                         P21.dbo.tax_group_hdr AS Tax_group_hdr WITH (nolock) ON Tax_group_hdr.tax_group_id = inv_loc.tax_group_id AND Tax_group_hdr.company_id = inv_loc.company_id LEFT OUTER JOIN
                         P21.dbo.contacts AS Contacts WITH (nolock) ON sup.buyer_id = Contacts.id LEFT OUTER JOIN
                         P21.dbo.vendor_supplier AS vendor_supplier WITH (nolock) ON inv_loc.primary_supplier_id = vendor_supplier.supplier_id AND inv_loc.company_id = vendor_supplier.company_id AND vendor_supplier.delete_flag = 'n' AND 
                         vendor_supplier.primary_vendor = 'y' LEFT OUTER JOIN
                         P21.dbo.vendor AS v WITH (nolock) ON v.vendor_id = vendor_supplier.vendor_id AND inv_loc.company_id = v.company_id LEFT OUTER JOIN
                         dbo.R12_sales AS vwR12Items ON inv_loc.company_id = vwR12Items.company_no AND inv_loc.inv_mast_uid = vwR12Items.inv_mast_uid AND inv_loc.location_id = vwR12Items.sales_location_id LEFT OUTER JOIN
                             (SELECT        company_id, location_id, inv_mast_uid, SUM(fifo_layer_qty) AS fifo_layer_qty, AVG(cost) AS cost, SUM(fifo_layer_qty * cost) AS fifo_value
                               FROM            P21.dbo.p21_view_fifo_layers AS P21_view_fifo_layers WITH (nolock)
                               WHERE        (period_completed IS NULL)
                               GROUP BY company_id, location_id, inv_mast_uid) AS FifoLayers ON inv_loc.company_id = FifoLayers.company_id AND inv_loc.location_id = FifoLayers.location_id AND 
                         inv_loc.inv_mast_uid = FifoLayers.inv_mast_uid LEFT OUTER JOIN
                         dbo.Period_usage AS periodusage ON inv_loc.inv_mast_uid = periodusage.inv_mast_uid AND inv_loc.location_id = periodusage.location_id LEFT OUTER JOIN
                             (SELECT        inventory_supplier_uid, primary_supplier, average_lead_time, location_id
                               FROM            P21.dbo.inventory_supplier_x_loc AS inventory_supplier_x_loc
                               WHERE        (row_status_flag = 704)) AS isxl ON isxl.inventory_supplier_uid = isup.inventory_supplier_uid AND inv_loc.location_id = isxl.location_id LEFT OUTER JOIN
                         P21.dbo.inv_loc_stock_status AS iss ON inv_loc.inv_mast_uid = iss.inv_mast_uid AND inv_loc.location_id = iss.location_id LEFT OUTER JOIN
                         dbo.Alt_codes ON dbo.Alt_codes.inv_Mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         dbo.Item_notes ON dbo.Item_notes.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                             (SELECT        r.inv_mast_uid, r.location_id, r.safety_stock_days, r.recommended_qty_to_order_calc, r.average_lead_time, r.recommended_qty_to_order, r.blanket_PO_qty, r.net_stock
                               FROM            P21.dbo.gpor_run AS r RIGHT OUTER JOIN
                                                             (SELECT        inv_mast_uid, location_id, MAX(gpor_run_uid) AS max_date
                                                               FROM            P21.dbo.gpor_run
                                                               GROUP BY inv_mast_uid, location_id) AS g ON g.inv_mast_uid = r.inv_mast_uid AND g.location_id = r.location_id AND g.max_date = r.gpor_run_uid) AS g ON g.inv_mast_uid = inv_mast.inv_mast_uid AND 
                         g.location_id = inv_loc.location_id LEFT OUTER JOIN
                         P21.dbo.code_p21 AS demand ON demand.code_no = inv_loc.demand_pattern_cd LEFT OUTER JOIN
                         P21.dbo.code_p21 AS safetys ON safetys.code_no = inv_loc.safety_stock_type LEFT OUTER JOIN
                         P21.dbo.code_p21 AS beh ON beh.code_no = inv_loc.demand_pattern_behavior_cd LEFT OUTER JOIN
                         P21.dbo.location_supplier AS ls WITH (nolock) ON ls.location_id = inv_loc.location_id AND ls.supplier_id = inv_loc.primary_supplier_id LEFT OUTER JOIN
                         P21.dbo.manufacturing_class AS mc WITH (nolock) ON mc.manufacturing_class_id = isup.manufacturing_class_id LEFT OUTER JOIN
                         P21.dbo.supplier_ud AS supplier_ud WITH (nolock) ON supplier_ud.supplier_id = inv_loc.primary_supplier_id LEFT OUTER JOIN
                             (SELECT        vessel_receipts_hdr.location_id, po_line.inv_mast_uid, SUM(vessel_receipts_line.container_qty_received) AS total_qty_on_vessel
                               FROM            P21.dbo.vessel_receipts_line AS vessel_receipts_line WITH (nolock) INNER JOIN
                                                         P21.dbo.vessel_receipts_hdr AS vessel_receipts_hdr ON vessel_receipts_hdr.vessel_receipts_hdr_uid = vessel_receipts_line.vessel_receipts_hdr_uid LEFT OUTER JOIN
                                                         P21.dbo.po_line AS po_line WITH (nolock) ON po_line.po_line_uid = vessel_receipts_line.po_line_uid
                               WHERE        (vessel_receipts_line.row_status_flag = 702) AND (vessel_receipts_hdr.row_status_flag = 972)
                               GROUP BY vessel_receipts_hdr.location_id, po_line.inv_mast_uid) AS drv_vessel_receipts_lines ON drv_vessel_receipts_lines.inv_mast_uid = inv_loc.inv_mast_uid AND 
                         drv_vessel_receipts_lines.location_id = inv_loc.location_id LEFT OUTER JOIN
                         P21.dbo.bin_ud AS bu WITH (nolock) ON bu.bin_id = inv_loc.primary_bin AND bu.location_id = inv_loc.location_id AND bu.company_id = inv_loc.company_id LEFT OUTER JOIN
                             (SELECT        p.inv_mast_uid, b.location_id, string_agg(b.container_name, ';') AS container, SUM(bp.po_container_unit_qty) AS qty_on_container
                               FROM            P21.dbo.container_building_po AS bp WITH (nolocK) LEFT OUTER JOIN
                                                         P21.dbo.container_building AS b WITH (nolock) ON b.container_building_uid = bp.container_building_uid LEFT OUTER JOIN
                                                         P21.dbo.po_line AS p WITH (nolock) ON p.po_line_uid = bp.po_line_uid LEFT OUTER JOIN
                                                         P21.dbo.vessel_receipts_container AS vs WITH (nolock) ON vs.container_building_uid = b.container_building_uid
                               WHERE        (bp.row_status_flag = 702) AND (bp.po_container_unit_qty > 0) AND (p.complete = 'n') AND (ISNULL(p.cancel_flag, 'n') = 'n') AND (ISNULL(p.delete_flag, 'n') = 'n') AND (vs.received_date IS NULL) AND 
                                                         (vs.vessel_receipts_container_uid IS NOT NULL)
                               GROUP BY p.inv_mast_uid, b.location_id) AS container ON container.inv_mast_uid = inv_mast.inv_mast_uid AND container.location_id = inv_loc.location_id
-- I must change costs effective today from suppliers 46620 and 46621. 

select distinct isu.Supplier_id[Supplier ID],d.division_name[Supplier Name],item_id[Item ID],item_desc[Item Desc],m.extended_desc[Ext Desc],cost[Cost (Supplier)],
format(max(il.last_purchase_date),'MM/dd/yyyy')[Last Purch Date],stockable[Stock],sxl.average_lead_time[Avg Lead Time],supplier_sort_code[Supplier Sort Code],isu.effective_date[Effective Date],
isu.future_cost[Future Cost],catalog_item
from dbo.inventory_supplier isu
join dbo.division d
on isu.supplier_id = d.supplier_id
join dbo.inv_mast m
on isu.inv_mast_uid = m.inv_mast_uid and m.delete_flag = 'N'
join dbo.inv_loc il
on m.inv_mast_uid =il.inv_mast_uid 
join dbo.inventory_supplier_x_loc sxl
on isu.inventory_supplier_uid = sxl.inventory_supplier_uid
where isu.division_id IN (46620,46621) 
group by isu.Supplier_id,d.division_name,item_id,item_desc,m.extended_desc,cost,stockable,average_lead_time,supplier_sort_code,isu.effective_date,isu.future_cost,catalog_item


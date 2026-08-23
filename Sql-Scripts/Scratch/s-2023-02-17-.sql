select s.manufacturing_class_id,m.inv_mast_uid,supplier_id,s.delete_flag
    from dbo.inventory_supplier s
    join dbo.inv_mast m
    on s.inv_mast_uid = m.inv_mast_uid
    where m.item_id = '2101024758' --and supplier_id = $supplier_id

    select distinct si.manufacturing_class_id,m.item_id,item_desc,m.default_purchase_disc_group,si.supplier_id,supplier_name--,ist.country_of_origin
    from dbo.inventory_supplier si
    join dbo.inv_mast m
    on si.inv_mast_uid = m.inv_mast_uid
	join dbo.supplier s
	on si.supplier_id = s.supplier_id
	--join inventory_supplier_trade ist
	--on si.inventory_supplier_uid = ist.inventory_supplier_uid
    where m.item_id = '21039286' -- '2101111817' --'2101024758'--

select *
from inv_mast_ud
--where simg_number = '2103000008'
order by date_created desc
select ilss.*
from dbo.inv_mast m
join dbo.inv_loc_stock_status ilss
on m.inv_mast_uid = ilss.inv_mast_uid
where item_id = '2101080868'

select *
from dbo.inv_tran
where inv_mast_uid = 81164 and trans_type = 'PO'

exec p21_get_item_location_qty 1,100,'2101070684'

exec p21_item_info '2101070684'


select top 5*
from p21_item_tran_view
where inv_mast_uid = 81164

select qty_on_po, *
from p21_item_location_view
where inv_mast_uid = 81164 and location_id = 430 -- primary_supplier cause extra line
order by location_id 

select top 5*
from p21_view_inv_tran
where inv_mast_uid = 81164

exec sp_help p21_fnt_get_linkable_transactions

select *
from p21_fnt_get_linkable_transactions (100,'2101070684', 


select *
from inv_mast
where inv_mast_uid = 2748 

select item_id, cogs_amount, gl_cogs
from invoice_line 
where invoice_no in ('4003145924','4003143130','4003144930','4003145757') and line_no = 1


select *
from Bar_Solve_Items_VW
where UPC != ''

exec sp_help p21_merge_items_app
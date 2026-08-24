-- convert(varchar(10),ih.invoice_date,120)

with getUIDS (SIMG,item_desc,extended_desc,inv_mast_uid,product_group_desc)
as
(
select item_id,item_desc,extended_desc,m.inv_mast_uid,product_group_desc
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.product_group pg
on l.product_group_id = pg.product_group_id
where item_desc like 'D-%' and m.delete_flag = 'N'
)
select h.invoice_no,convert(varchar(10),h.invoice_date,120)[invoice_date],product_group_desc,SIMG,g.item_desc,extended_desc,cast(qty_shipped as int)[qty_shipped],cast(qty_requested as int)[qty_requested],cast((qty_requested - qty_shipped) as int)[Backorder],Convert(DECIMAL(10,2),unit_price)[unit_price],Convert(DECIMAL(10,2),il.extended_price)[total_line_amount],Convert(DECIMAL(10,2),cogs_amount)[cogs_amount],Convert(DECIMAL(10,2),(cogs_amount/  qty_shipped))[Unit COGS],format(((unit_price - (cogs_amount/qty_shipped)))/unit_price,'P2')[Margin%],il.order_no,note
from getUIDS g
join dbo.invoice_line il
on g.inv_mast_uid = il.inv_mast_uid
join dbo.invoice_hdr h
on il.invoice_no = h.invoice_no
left join dbo.oe_line_notepad oln
on il.order_no = oln.order_no and il.oe_line_number = oln.line_no
where unit_price > 0  -- and SIMG = '2101009144' --and h.invoice_no = '0123106'
order by invoice_no

select *
from invoice_hdr
where invoice_no = '3083996'

select unit_price,cogs_amount,cogs_amount/qty_shipped,order_no
from invoice_line
where invoice_no = '3083996'

select il.item_id[SIMG],im.item_desc,SUM(qty_shipped)[Total Shipped 2023],SUM(h.total_amount)[Total Sales 2023]--floor(ISNULL(qty_shipped,0))[qty_shipped],
from invoice_hdr h
join invoice_line il
on h.invoice_no = il.invoice_no
join inv_mast im
on il.inv_mast_uid = im.inv_mast_uid
where invoice_date between '2023-01-01' and '2024-01-01' and im.item_desc like 'KOL%'
group by il.item_id,im.item_desc
order by SIMG

-- quick check
select il.item_id[SIMG],im.item_desc,qty_shipped,(h.total_amount)
from invoice_hdr h
join invoice_line il
on h.invoice_no = il.invoice_no
join inv_mast im
on il.inv_mast_uid = im.inv_mast_uid
where invoice_date between '2023-01-01' and '2024-01-01' and im.item_id in ('2101000430','2101000431','2101000436')

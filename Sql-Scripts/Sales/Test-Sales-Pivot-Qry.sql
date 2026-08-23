select h.branch_id, h.customer_id, h.bill2_name,h.bill2_city,h.bill2_state,cs.salesrep_id,c.class_2id,c.class_4id,t.territory_desc,(il.extended_price*il.qty_shipped)[Line_total],(left(datename(month,invoice_date),3) + ' ' + left(datename(YEAR,invoice_date),4))[MonThYearShipped]
from dbo.invoice_hdr h
join dbo.invoice_line il
on h.invoice_no = il.invoice_no
join inv_mast im
on il.inv_mast_uid = im.inv_mast_uid
join dbo.customer_salesrep cs
on h.customer_id = cs.customer_id
join dbo.customer c
on h.customer_id = c.customer_id
left join territory_x_customer txc
on c.customer_id = txc.customer_id
left join territory t
on txc.territory_uid = t.territory_uid
where invoice_date between '2022-07-01' and '2023-07-01' and h.branch_id not in (200,510,520,530) and il.product_group_id != 'OTHERCHG'
order by customer_id


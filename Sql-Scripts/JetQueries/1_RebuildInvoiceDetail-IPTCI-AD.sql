-- For Clark FY21 & 22
-- 07/11/2022  - Price 7
use P21;

declare
@StartDate date = '2022-09-01',
@EndDate date = '2022-09-30',
@Branch int = 300;

select case
	when h.total_amount >= 0 then 'Invoice' 
	else 'CM'
end[Source],h.invoice_no,format(h.invoice_date,'yyyy-MM-dd')[Posting Date],format(order_date,'yyyy-MM-dd')[order_date],h.sold_to_customer_id,customer_name,c.class_2id,c.class_3id,h.customer_id,c.class_1id,c.pricing_method_cd,l.line_no,l.item_id,l.item_desc,product_group_id,qty_shipped,unit_price,extended_price,m.inv_mast_uid,
case
	when product_group_id = 'M2' then 'PTI-OEM-' + product_group_id
	else 'PTI-DIST-' + product_group_id
end[DIST LIBRARY Starting 4/19/21],
case
	when product_group_id = 'M2' then 'PTI-OEM-' + product_group_id
	else 'PTI-DIST-' + product_group_id + '-20-21'
end[DIST LIBRARY before 4/19/21],m.price1,m.price7,m.price8,m.price9
from customer c
join invoice_hdr h
on c.customer_id = h.sold_to_customer_id
join invoice_line l
on h.invoice_no = l.invoice_no
join inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
where class_2id in ('AD','PURVIS','IDC-USA') and class_3id not in ('ADWHSE''GERBERS''OHIOTR''RICHMOND''T.E.C.''BDS2''ANDREWS''PROEQU''WEIMER2''MRT') and invoice_date between @StartDate and @EndDate and branch_id = @Branch and product_group_id not in ('OTHERCHG','Null') and qty_shipped != 0 and invoice_line_type = 0
order by c.customer_id




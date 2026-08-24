--02/09/23 clark can I get this query for BL from July 1, 2022 thru Dec 31, 2022?   Is there a way to add default price family ID 

--use [P21Play2021.1.4420Local];
use P21;

declare
@StartDate date = '2022-07-01',
@EndDate date = '2022-12-31';
--@Branch int = 400;

select case
	when h.total_amount >= 0 then 'Invoice' 
	else 'CM'
end[Source],h.invoice_no,format(h.invoice_date,'yyyy-MM-dd')[Posting Date],format(order_date,'yyyy-MM-dd')[order_date],h.sold_to_customer_id,customer_name,c.class_2id,c.class_3id,h.customer_id,c.class_1id,c.pricing_method_cd,l.line_no,l.item_id,l.item_desc,l.product_group_id,qty_shipped,unit_price,extended_price,m.inv_mast_uid,
case
	when l.product_group_id = 'M2' then 'PTI-OEM-' + l.product_group_id
	else 'PTI-DIST-' + l.product_group_id
end[DIST LIBRARY Starting 4/19/21],
case
	when l.product_group_id = 'M2' then 'PTI-OEM-' + l.product_group_id
	else 'PTI-DIST-' + l.product_group_id + '-20-21'
end[DIST LIBRARY before 4/19/21],m.price1,m.price7,m.price8,m.price9,m.default_price_family_uid,pf.price_family_desc
from dbo.customer c
join dbo.invoice_hdr h
on c.customer_id = h.sold_to_customer_id
join dbo.invoice_line l
on h.invoice_no = l.invoice_no
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
left join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
where (class_1id not in ('IPTCI','LMS','PTI') or class_1id is null) and invoice_date between @StartDate and @EndDate and branch_id like '4%' and l.product_group_id not in ('OTHERCHG','Null') and qty_shipped != 0 and invoice_line_type = 0

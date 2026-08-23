-- 01/21/20 trying to get summary of Ad- customers
with cteGetInVNo(Cid,CustName,Ino,DateC)
as
(
	select c.customer_id,customer_name,invoice_no,h.date_created
	from customer c
	join invoice_hdr h
	on c.customer_id = h.customer_id
	where customer_name like 'AD-%' and h.date_created between '2019-10-01' and '2020-01-01' 
)
select CustName,Ino,SUM(extended_price)[InvcTotal]
from cteGetInVNo c
join invoice_line l
on c.Ino = l.invoice_no
group by CustName,Ino



 

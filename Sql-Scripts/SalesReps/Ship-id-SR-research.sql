-- comparing customer to customer-salesrep table
select c.customer_id, c.customer_name,  c.salesrep_id[Customer-TB-SR],csr.salesrep_id[CSR-TB-SR]
from dbo.customer c
left join dbo.customer_salesrep csr
on c.customer_id = csr.customer_id
where delete_flag = 'N'  

select c.customer_id,c.salesrep_id[Customer-TB-SR],s.ship_to_id,ss.salesrep_id[s2s-SR]
from dbo.customer c
join dbo.ship_to s
on c.customer_id = s.customer_id
join ship_to_salesrep ss
on s.ship_to_id = ss.ship_to_id
where c.delete_flag = 'N' and s.delete_flag = 'N' and primary_salesrep = 'Y' -- and c.customer_id = 12822
order by c.customer_id,ship_to_id
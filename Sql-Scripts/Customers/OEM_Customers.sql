Use P21;
--Use Play2;
with firstRound(default_branch_id,customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,sales_manager_id,sales_rep_name,salesrep_id,class_2id,class_4id)
as
(
	select  c.default_branch_id,customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,co.sales_manager_id,(co.first_name +  ' ' + co.last_name)[Sales Rep Name],c.salesrep_id,c.class_2id,c.class_4id
	from customer c
	join address a
	on c.customer_id = a.id
	join contacts co
	on c.salesrep_id = co.id
	where c.delete_flag = 'N' and a.delete_flag = 'N'  and c.class_4id like 'OEM%'
)
select fR.default_branch_id,customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,(co2.first_name +  ' ' + co2.last_name)[sales manager],sales_rep_name,salesrep_id,fR.class_2id,fR.class_4id
from firstRound fR
left join contacts co2
on fr.sales_manager_id = co2.id 

--order by c.date_last_modified desc

select c.customer_id, a.corp_address_id,c.customer_name, a.phys_address1, a.phys_address2, a.phys_city, a.phys_state,ship_to_id,c.class_1id,class_2id,class_3id
	from customer c
	join address a
	on c.customer_id = a.id
	join ship_to s
	on c.customer_id = s.customer_id
where c.delete_flag = 'N'
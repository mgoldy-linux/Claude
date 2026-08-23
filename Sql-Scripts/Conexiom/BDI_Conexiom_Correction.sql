-- get BDI branch's address
		select a.name[BDI_Branch_Name],phys_address1,default_branch_id[PTI_Default_Branch],a.phys_postal_code,customer_id,customer_id[ShipTo_ID]
		from customer c	
		join address a
		on c.customer_id = a.id
		where c.class_2id like 'BDI%' and c.delete_flag = 'N' and phys_postal_code = '65802' -- and phys_address1 like '%Route%' --and a.name not like '%Bill To'

-- Check for Primary Contact
		select *
		from contacts
		where address_id = 14045

-- Check po uses 
		select order_no
		from oe_hdr
		where po_no = '4502782395-X45'
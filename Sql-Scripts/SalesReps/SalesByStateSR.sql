	Select ship2_state,sum(extended_price)[CY2021]
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join inv_mast m
	on m.inv_mast_uid = l.inv_mast_uid
	join oe_hdr_salesrep s
	on h.order_no = s.order_number 
	where approved = 'Y' and order_date between '2021-01-01' and '2021-12-31' and h.projected_order = 'N'  and completed = 'Y' and ship2_state not in ('VE','SK','NS','PR','QC','ON','AB','AUCKLAND','BANGKOK','BC','MB','MX','NB','NL','PE','SANTIAGO') and m.class_id1 = 'PTI' and salesrep_id = 1021 --and rma_flag = 'N'-- and extended_price !=0 
	group by ship2_state
	order by ship2_state

	Select ship2_state,Sum(extended_price)[TotalSales]
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join oe_hdr_salesrep s
	on h.order_no = s.order_number 
	where approved = 'Y' and year(order_date) = 2020 and h.projected_order = 'N'  and completed = 'Y' and  salesrep_id in (1017) and extended_price !=0  and rma_flag = 'N' -- and ship2_state = 'NC'
	group by ship2_state
	order by TotalSales 

	Select ship2_state, h.invoice_no,sum(total_amount)[CY2021],invoice_type
	from invoice_hdr h
	join invoice_line l
	on h.invoice_no = l.invoice_no
	where year(order_date) = 2021 and h.salesrep_id = 1021 and ship2_state = 'MN' and extended_price !=0 
	group by ship2_state, h.invoice_no,invoice_type
	-- year total invoice
	Select sum(extended_price)[CY2021]
	from invoice_hdr h
	join invoice_line l
	on h.invoice_no = l.invoice_no and extended_price !=0 
	where year(invoice_date) = 2019 and h.salesrep_id = 1021 --and rma_flag = 'N'-- and extended_price !=0 
	-- year order total
	Select sum(extended_price)[CY2021]
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join oe_hdr_salesrep s
	on l.order_no = s.order_number 
	where year(order_date) = 2019 and salesrep_id = 1021 --and rma_flag = 'N'-- and extended_price !=0 
	

	Select ship2_state, Sum(total_amount)
	from invoice_hdr h
	where year(invoice_date) = 2021 and h.salesrep_id = 1021 
	group by ship2_state
	select *
	from invoice_hdr 
	where invoice_no = '3100131'

		select *
	from invoice_line 
	where invoice_no = '3110290'


	Select h.invoice_date,h.invoice_no,ship2_state,total_amount
	from invoice_hdr h
	join invoice_line l
	on h.invoice_no = l.invoice_no 
	where year(invoice_date) = 2019 and h.salesrep_id = 1021  and ship2_state = 'MN' and l.qty_shipped > 0 
	order by ship2_state

	select *
	from rma_receipt_hdr

	select ship2_state, sum(extended_price)
	from oe_hdr h
	join oe_hdr_salesrep s
	on h.order_no = s.order_number
	join invoice_line l
	on h.order_no = l.order_no
	where rma_flag = 'Y' and year(order_date) = 2019 and salesrep_id in (1023,10659)
	group by ship2_state


	select i.ship2_state,sum(total_amount)[Correct]
	from oe_hdr h
	join invoice_hdr i
	on h.order_no = i.order_no
	where rma_flag = 'Y' and year(h.order_date) = 2019 and salesrep_id in (1031)
	group by i.ship2_state


	select total_amount,*
	from invoice_hdr
	where Year(invoice_date) = 2019 and ship2_state = 'NC'and salesrep_id in (1023,10659)

	select *
	from oe_hdr
	where order_no = 11141
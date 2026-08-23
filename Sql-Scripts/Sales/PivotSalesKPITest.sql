DECLARE @query NVARCHAR(MAX);

set @query = '	
	select *
	from (
		select h.branch_id, h.customer_id, h.bill2_name,h.bill2_city,h.bill2_state,cs.salesrep_id,c.class_2id,c.class_4id,coalesce(t.territory_desc,'''')[territory_desc],(il.extended_price*il.qty_shipped)[Line_Total],(left(datename(month,invoice_date),3) + '' '' + left(datename(YEAR,invoice_date),4))[MonThYearShipped]
		from invoice_hdr h
		join invoice_line il
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
		where invoice_date between ''2022-07-01'' and ''2023-07-01''and h.branch_id not in (200,510,520,530) and il.product_group_id != ''OTHERCHG''
		)
		as s
		PIVOT
		(
			SUM(Line_Total)
			for [MonthYearShipped]
			in ([Jul 2022],[Aug 2022],[Sep 2022],[Oct 2022],[Nov 2022],[Dec 2022],[Jan 2023], [Feb 2023],[Mar 2023],[Apr 2023],[May 2023],[Jun 2023])
		)
		as Mpivot
		order by customer_id
		'
		
exec sp_executesql @query
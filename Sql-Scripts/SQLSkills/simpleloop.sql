declare @counter int
	set @counter = 0
	while @counter < 10
	

Begin
select sum(l.extended_price)[Total4Week]
        from oe_hdr h
        join customer c
        on h.customer_id = c.customer_id
        join oe_line l
        on h.order_no = l.order_no
        join inv_mast im
		on l.inv_mast_uid = im.inv_mast_uid and im.other_charge_item = 'N'
        where approved = 'Y' and year(order_date) = 2021 and extended_price !=0 and salesrep_id = 18353 and DATEPART(WEEK, order_date) = @counter
		set @counter = @counter + 1
End
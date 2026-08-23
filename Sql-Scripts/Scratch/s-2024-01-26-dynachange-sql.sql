select *
from message_log
where user_id = 'STACY.BROCATO' and  message_date > '2024-01-26 12:00:00.000'
order by message_no desc

select *
from address_ud

Set IDENTITY_INSERT dbo.address_ud ON

select cancel_flag,*
from oe_hdr
where order_no = 1597488

select cancel_flag,*
from oe_line
where order_no = 1597488
order by line_no


--exec p21_repair_sales_orders 1597488

--DS d_ds_oe_line_dataentry
UPDATE oe_line SET date_last_modified = '2024-01-25 14:47:50.851', last_maintained_by = 'MGOLDYN', cancel_flag = 'Y' WHERE "line_no" = 8 AND "order_no" = '1597488' AND "cancel_flag" = 'N'

select COUNT(*)[numof]
from inv_mast
where delete_flag = 'N'


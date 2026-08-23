SELECT
    name
FROM
   sys.procedures 
WHERE
   name LIKE '%order%'

select *
from oe_hdr_rma
where date_created between '2023-02-01' and '2023-02-03'

select rma_delivery_list_status, rma_expiration_date, order_no, order_date, oe_hdr_uid,validation_status
from oe_hdr 
where date_created between '2023-02-01' and '2023-02-03' and rma_flag = 'Y' and completed = 'N'


select oe_hdr_uid,*
from oe_hdr
where order_no = 1397028

select *
from oe_line_rma
where row_status_flag = 700

select oe_hdr_uid,[cod_flag],[fob_flag],[order_cost_basis],[apply_builder_allowance_flag],order_cost_basis,profit_percent
from oe_hdr
where cancel_flag = 'Y' and completed = 'Y'
--where order_no in (1397028,1397034)

select cancel_flag, complete,extended_price
from oe_line
where order_no = 1397028

select *
from customer_order_history_daily
where customer_id = 10514 and year(date_ordered) = 2023 and MONTH(date_ordered) = 2
order by date_last_modified desc

exec p21_customer_order_history_daily_rebuild 

exec p21_customer_order_history_rebuild

exec p21_df_complete_open_quotes

exec p21_edi846_loc_info 1, 16425, 410, 410,410,410

exec p21_outlook_get_contacts
declare @maxorderno int;

set @maxorderno = (select max(order_no) from oe_hdr) + 1000

select @maxorderno

exec p21_set_counter @counter_id='oe_hdr', @counter_num = '1068591'

select max(order_no)[order_no] from oe_hdr
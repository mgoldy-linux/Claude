select *
from p21_fnt_packing_list_line('1','3157431','3157431','100','100',0,12990,' ','ZZZZZZZZZZ',' ','ZZZZZ',0,999999999,'2019-01-01 00:00:00','2021-11-26 23:59:59',2161776,2161776,0,9999) 
where qty_shipped > 0

select order_no,qty_ordered,qty_shipped,qty_remaining,remaining_qty,qty_invoiced,order_type,line_number,p21_fnt_packing_list_line.item_id,m.class_id1
FROM   p21_fnt_packing_list_line('1','0','9999999999','100','100',0,999999999,' ','ZZZZZZZZZZ',' ','ZZZZZ',0,999999999,'1990-01-01 00:00:00','2021-10-26 23:59:59',2100000,2166283,0,9999) 
join inv_mast m
on p21_fnt_packing_list_line.item_id = m.item_id
where (qty_ordered != qty_invoiced)  and remaining_qty = 0 and order_no is not null
order by order_no

select distinct order_no
FROM   p21_fnt_packing_list_line('1','0','9999999999','200','200',0,999999999,' ','ZZZZZZZZZZ',' ','ZZZZZ',0,999999999,'1990-01-01 00:00:00','2021-10-26 23:59:59',2100000,2166283,0,9999) 
where (qty_ordered != qty_invoiced)  and remaining_qty = 0 and order_no is not null
order by order_no


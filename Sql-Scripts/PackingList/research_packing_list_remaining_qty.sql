-- research packing list remaining qty

select *
from p21_fnt_packing_list_line('1','3157431','3157431','100','100',0,12990,' ','ZZZZZZZZZZ',' ','ZZZZZ',0,999999999,'2019-01-01 00:00:00','2021-11-26 23:59:59',2161776,2161776,0,9999) 

select *
from oe_line
where order_no = 1196539
select *
FROM p21_fnt_uc_packinglist_hdr('1','0','9999999999',' ','ZZZZZZ',0,99999999,' ','ZZZZZZZZZZ',' ','ZZZZZZ',0,99999999,'1/1/1950 00:00:00','12/31/2049 00:00:00',2171509,2171509,0,9999,NULL,NULL,NULL,NULL,NULL)
left join _CR_PT_Release_VW 
on p21_fnt_uc_packinglist_hdr.order_no = _CR_PT_Release_VW.order_no

select *
from oe_hdr 
where order_no = 1209093

select *
from oe_pick_ticket
where order_no = 1209093

select *
from oe_line
where order_no = 1209093

select *
from _CR_PT_Release_VW 
select *
FROM  p21_fnt_uc_packinglist_line('1','0','9999999999',' ','ZZZZZZ',0,99999999,' ','ZZZZZZZZZZ',' ','ZZZZZZ',0,99999999,'1950-01-01 00:00:00','2049-12-31 00:00:00',2303595,23035956,0,9999,NULL ,NULL ,NULL ,NULL ,NULL )

select *
from p21_fnt_uc_packinglist_hdr('1','0','9999999999',' ','ZZZZZZ',0,99999999,' ','ZZZZZZZZZZ',' ','ZZZZZZ',0,99999999,'1950-01-01 00:00:00','2049-12-31 00:00:00',2303595,23035956,0,9999,NULL ,NULL ,NULL ,NULL ,NULL )

sp_help p21_fnt_uc_packinglist_line

select *
from inv_mast
where item_desc = 'D-046315'
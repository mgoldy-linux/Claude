select order_no,release_no,release_date,release_qty,allocated_qty,expedite_value,expedite_type,pick_value,pick_type,printed,date_created,date_last_modified,last_maintained_by,line_no,oe_line_schedule_uid,inv_mast_uid,edit_flag,release_status_flag
from dbo.oe_line_schedule
where order_no like '14082%'

select order_no, release_no,release_date
from dbo.oe_line_schedule
where order_no = '1408348'

select max(oe_line_schedule_uid)[max]
from dbo.oe_line_schedule

exec sp_help oe_line_schedule

select inv_mast_uid,line_no
from dbo.oe_line
where order_no = '1408348'

--line 1
insert into oe_line_schedule ("order_no","release_no","release_date","release_qty","allocated_qty","expedite_value","expedite_type","pick_value","pick_type","printed","date_created","date_last_modified","last_maintained_by","line_no","oe_line_schedule_uid","inv_mast_uid","edit_flag","release_status_flag")
values ('1408348', 1, '2049-12-31',10000,40,0,'Days(s)',0,'Days(s)','N',GETDATE(),GETDATE(),'mgoldyn-sql','1',6879894,111368,'N','F')

--line 2
insert into oe_line_schedule ("order_no","release_no","release_date","release_qty","allocated_qty","expedite_value","expedite_type","pick_value","pick_type","printed","date_created","date_last_modified","last_maintained_by","line_no","oe_line_schedule_uid","inv_mast_uid","edit_flag","release_status_flag")
values ('1408348', 1, '2049-12-31',10000,10000,0,'Days(s)',0,'Days(s)','N',GETDATE(),GETDATE(),'mgoldyn-sql','2',6879895,113199,'N','F')

--line 3
insert into oe_line_schedule ("order_no","release_no","release_date","release_qty","allocated_qty","expedite_value","expedite_type","pick_value","pick_type","printed","date_created","date_last_modified","last_maintained_by","line_no","oe_line_schedule_uid","inv_mast_uid","edit_flag","release_status_flag")
values ('1408348', 1, '2049-12-31',10000,10000,0,'Days(s)',0,'Days(s)','N',GETDATE(),GETDATE(),'mgoldyn-sql','3',6879896,113200,'N','F')

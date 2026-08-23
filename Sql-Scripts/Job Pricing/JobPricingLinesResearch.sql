select j.price,m.inv_mast_uid,job_price_line_uid,job_price_hdr_uid,row_status_flag,j.date_last_modified,j.date_created,j.last_maintained_by,line_no,all_discount_groups_flag
from job_price_line j
join inv_mast m
on j.inv_mast_uid = m.inv_mast_uid 
where /*item_id = '2101028832' and*/ job_price_hdr_uid = 16
order by line_no


exec sp_help job_price_line

use P21Play;
select job_price_line_uid,job_price_hdr_uid,row_status_flag,date_last_modified,date_created,last_maintained_by,line_no,all_discount_groups_flag,inv_mast_uid
from job_price_line j
where job_price_hdr_uid = 16

select *
from job_price_hdr

select * 
from job_price_line
where job_price_hdr_uid = 4
select max(job_price_line_uid)[jlMax]
        from job_price_line


exec p21_set_counter @counter_id='job_price_line' ,@counter_num = 7550

select *
from job_price_line
where job_price_hdr_uid = 16
order by job_price_line_uid desc

select *
from po_hdr
where supplier_id = 49626

select *
from inv_mast 
where item_id = '2101069676' --'2101069675'
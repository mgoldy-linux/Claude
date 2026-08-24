select top 25 *
from process_x_transaction_detail
where process_x_transaction_uid = 9038
order by start_date desc

-- need to use audit_trail because no complete date in process table
select process_x_transaction_uid[Transaction Number],process_name, item_id[SIMG],item_desc,begin_date,at.date_created[completed_date],DATEDIFF(MI,begin_date,at.date_created)[Diff in Minutes],DATEDIFF(HH,begin_date,at.date_created)[Diff in Hours],raw_qty_requested,finished_qty_completed,pxt.last_maintained_by
from dbo.process_x_transaction pxt
join dbo.inv_mast m
on pxt.raw_inv_mast_uid = m.inv_mast_uid
left join dbo.audit_trail at
on convert (varchar(8),pxt.process_x_transaction_uid) = at.key1_value and table_changed = 'process_x_transaction'  and column_changed = 'completed_date' 
where process_cd = 'QC'
Order by begin_date desc
--where process_x_transaction_uid = 9038

select distinct process_name
from p21_view_wip_report
order by process_name
-- creatin portal missing complete time
select process_x_transaction_uid, process_name,finished_item_id,finished_item_desc,date_created,date_last_modified,raw_qty_requested,''[finished_qty_completed],last_maintained_by
from p21_view_wip_report
where  process_name = 'Quality Inspections' and process_x_transaction_uid = 1003

select *
from  process_x_transaction
where process_x_transaction_uid = 9038
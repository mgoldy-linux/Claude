--USe P21Local2020;

select pick_ticket_no,p.order_no,print_date,h.requested_date,p.invoice_no,p.location_id[pick_loc],p.delete_flag,h.location_id,h.carrier_id[order carrier id],p.carrier_id[Pick carrier ID],ship2_country
from oe_pick_ticket p
join oe_hdr h
on p.order_no = h.order_no
where p.delete_flag = 'N' and p.location_id in (100) and print_date > '2024-03-01'
order by print_date desc

select last_run_status,scheduled_job_uid,*
from scheduled_job
where name like 'P%460%' and delete_flag = 'N'

select *
from scheduled_job_history
where scheduled_job_uid = 442565
order by job_run_at_date desc

select *
from scheduled_job_history
where job_run_status = 'Failed'
order by job_run_at_date desc


select pick_ticket_no,p.order_no,print_date,h.requested_date,p.invoice_no,p.location_id[pick_loc],p.delete_flag,h.location_id
from oe_pick_ticket p
join oe_hdr h
on p.order_no = h.order_no
where p.pick_ticket_no = 2473140
order by print_date desc

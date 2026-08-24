select oh.order_no, oh.location_id,pt.pick_ticket_no,
case 
 when pt.freight_code_uid = 2 then 'BILLBACK'
 when pt.freight_code_uid = 2 then 'FREE FREIGHT'
 else 'Missing'
end[freight_code] ,pt.freight_in,pt.freight_out[PT_FreightOut],clp.invoice_no,pt.tracking_no,clp.total_charge,clp.carrier_name,clp.tracking_no,pt.invoice_no
from dbo.oe_hdr oh
join dbo.oe_pick_ticket pt
on oh.order_no = pt.order_no
join dbo.clippership_return_10004 clp
on pt.pick_ticket_no = clp.pick_ticket_no
where third_party_billing_flag = 'S' and   total_charge > 0 and pt.freight_out = 0 and (pt.tracking_no != '* * CANCELLED * *' or pt.tracking_no is null) and oh.location_id = 100 and oh.date_created > '2023-01-01'
order by order_no, oh.date_created desc

-- standard
select oh.order_no, oh.location_id,pt.pick_ticket_no,
case 
 when pt.freight_code_uid = 2 then 'BILLBACK'
 when pt.freight_code_uid = 2 then 'FREE FREIGHT'
 else 'Missing'
end[freight_code] ,pt.freight_in,pt.freight_out[PT_FreightOut],clp.invoice_no,pt.tracking_no,clp.total_charge,clp.carrier_name,clp.tracking_no,pt.invoice_no
from dbo.oe_hdr oh
join dbo.oe_pick_ticket pt
on oh.order_no = pt.order_no
join dbo.clippership_return_10004 clp
on pt.pick_ticket_no = clp.pick_ticket_no
where third_party_billing_flag = 'S' and   total_charge > 0 and pt.freight_out = 0 and (pt.tracking_no != '* * CANCELLED * *' or pt.tracking_no is null) and oh.location_id = 100 and oh.date_created > '2023-01-01'
order by order_no, location_id, oh.date_created desc

-- pt freight where invoice = 0
select oh.order_no, oh.location_id,pt.pick_ticket_no,
case 
 when pt.freight_code_uid = 2 then 'BILLBACK'
 when pt.freight_code_uid = 2 then 'FREE FREIGHT'
 else 'Missing'
end[freight_code] ,pt.freight_in,pt.freight_out[PT_FreightOut],clp.invoice_no,pt.tracking_no,clp.total_charge,clp.carrier_name
from dbo.oe_hdr oh
join dbo.oe_pick_ticket pt
on oh.order_no = pt.order_no
join dbo.clippership_return_10004 clp
on pt.pick_ticket_no = clp.pick_ticket_no
where third_party_billing_flag = 'B' and   total_charge = 0 and pt.freight_out > 0 and pt.tracking_no != '* * CANCELLED * *'
order by location_id, oh.date_created desc

-- standard pt freight where invoice = 0
select oh.order_no, oh.location_id,pt.pick_ticket_no,
case 
 when pt.freight_code_uid = 2 then 'BILLBACK'
 when pt.freight_code_uid = 2 then 'FREE FREIGHT'
 else 'Missing'
end[freight_code] ,pt.freight_in,pt.freight_out[PT_FreightOut],clp.invoice_no,pt.tracking_no,clp.total_charge,clp.carrier_name
from dbo.oe_hdr oh
join dbo.oe_pick_ticket pt
on oh.order_no = pt.order_no
join dbo.clippership_return_10004 clp
on pt.pick_ticket_no = clp.pick_ticket_no
where third_party_billing_flag = 'S' and   total_charge = 0 and pt.freight_out > 0 and pt.tracking_no != '* * CANCELLED * *'
order by location_id, oh.date_created desc


select top 10 *
from clippership_return_10004
order by shipped_date desc

select *
from invoice_hdr 
where order_no = '1371295'

select *
from invoice_line 
where invoice_no = '3292950'

select *
from freight_code
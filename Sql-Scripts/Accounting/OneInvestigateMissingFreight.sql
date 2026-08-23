select oh.order_no, oh.location_id,pt.pick_ticket_no,
case 
 when pt.freight_code_uid = 2 then 'BILLBACK'
 when pt.freight_code_uid = 2 then 'FREE FREIGHT'
 else 'Missing'
end[freight_code] ,pt.freight_in,pt.freight_out[PT_FreightOut],oh.freight_out,clp.invoice_no,pt.tracking_no,clp.total_charge,clp.carrier_name,third_party_billing_flag,pt.tracking_no
from dbo.oe_hdr oh
join dbo.oe_pick_ticket pt
on oh.order_no = pt.order_no
join dbo.clippership_return_10004 clp
on pt.pick_ticket_no = clp.pick_ticket_no
where oh.order_no =  1380843--1393346
order by location_id, oh.date_created desc

--where third_party_billing_flag = 'S' and   total_charge > 0 and pt.freight_out = 0 and pt.tracking_no != '* * CANCELLED * *'
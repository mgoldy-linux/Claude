select *
from po_hdr
where location_id = 100
order by receipt_date desc
--order by date_due desc

select *
from po_line
where po_no = 4004811
--where po_no = 4003736
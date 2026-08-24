-- ticket # 368

select *
from po_hdr
where po_no = 4011332

select *
from po_line
where po_no = 4011332

update dbo.po_hdr
set complete = 'N'
where po_no = 4011332

update dbo.po_line
set complete = 'N'
where po_no = 4011332

select *
from po_hdr
where po_no = 4011332

select *
from po_line
where po_no = 4011332
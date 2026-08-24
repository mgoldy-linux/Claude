exec sp_help p21_view_po_hdr

EXEC sp_helpconstraint po_hdr

exec sp_helpdb P21Sand

EXEC sp_helpdevice;

select *
from inv_xref
where their_item_id = '35JA16'

select *
from inv_mast
where inv_mast_uid = 70375

select oe_hdr_uid,ship2_add3,*
from oe_hdr
where order_no = 1598119

select *
from rma_receipt_hdr
where oe_hdr_uid =593040 

select *
from oe_hdr
where po_no = '40649290'
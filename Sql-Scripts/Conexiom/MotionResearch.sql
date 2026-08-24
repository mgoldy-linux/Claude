Select item_id, item_desc, extended_desc,class_id1,class_id2
from inv_mast
--where item_id = 'SUCSF207-22'
where item_id = '55G221601-BOX' or  item_id = 'SUCSF207-22'

select *
from oe_hdr
where po_no = 'AR57-00177576'

select *
from oe_line
where order_no = 1131618

select *
from contacts
where address_id = 14720

select customer_name
from customer
where customer_id = 14720
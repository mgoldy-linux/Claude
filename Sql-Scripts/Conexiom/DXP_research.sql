select customer_id, customer_name
from customer
where customer_name like '%DXP%' and default_branch_id = 300

select customer_id, customer_name
from customer
where class_2id = 'DXP'

select po_no, order_no
from oe_hdr
where customer_id = 14936 and approved = 'Y'
order by po_no

select *
from inv_mast
where inv_mast_uid = 36356 or inv_mast_uid = 31471 or inv_mast_uid = 38860

select inv_mast_uid, customer_part_number,qty_ordered
from oe_line
where order_no = 1017581
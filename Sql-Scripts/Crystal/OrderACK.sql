select *
from p21_view_ord_ack_line
where order_no = 1080517
order by line_number

select *
from oe_pick_ticket
where order_no = 1080517

select dflt_purchase_pricing_unit,*
from inventory_supplier
where inv_mast_uid = 26101

select *
from inv_mast
where item_id = 'T-100088408'

select *
from p21_bill_of_materials
where item_id = 'T-100088408'

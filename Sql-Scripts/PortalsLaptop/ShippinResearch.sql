select *
from p21_view_support_sql_salesorder_oe_pick_ticket_detail
where pick_ticket_no = 2015818

select *
from oe_line_schedule
where order_no = 1013641 and inv_mast_uid = 28007

select pick_ticket_no,line_number,ship_quantity,inv_mast_uid
from oe_pick_ticket_detail
where pick_ticket_no = 2015818  and inv_mast_uid = 28007


/* nothing in table
select *
from oe_pick_ticket_detail_pkg
where pick_ticket_no = 2015818

select *
from oe_pick_ticket_detail_room

select *
from delivery_pick_ticket_detail

select *
from p21_delivery_report_view
*/

select qty_ordered, qty_to_pick, qty_remaining,order_line_number,order_number,ordered_as,upc_code
from p21_fnt_all_pick_ticket_line (2015818,2015818,100)
where detail_type = 0

select *
from sys.function_order_columns
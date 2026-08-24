select * 
from _CR_PT_2Build_VW a
where a.pick_ticket_no = 2165030

select *
from _CR_PT_SubAsbly_VW
where pick_ticket_no = 2146057

select * 
from _CR_PT_2Build_VW a
join _CR_PT_SubAsbly_VW s
on a.pick_ticket_no = s.pick_ticket_no  and a.oe_line_uid = s.parent_oe_line_uid
where a.pick_ticket_no = 2146057



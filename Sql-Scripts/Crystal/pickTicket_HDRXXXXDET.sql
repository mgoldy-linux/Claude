--- these work for play 2493725 lines 7 & * are production order

Select *
from p21_fnt_all_pick_ticket_hdr (2482025,2482025,1,100,0,GETDATE())

select *
from p21_fnt_all_pick_ticket_line(2482025,2482025,100)
order by line_seq_no		

-- not working
select *
from p21_fnt_all_pick_ticket_line(2473140,2473140,410)
order by line_seq_no		
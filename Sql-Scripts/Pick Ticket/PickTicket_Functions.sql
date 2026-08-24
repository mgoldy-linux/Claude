select *
from p21_fnt_all_pick_ticket_hdr (2156350,2156350,1,100,1,getdate())

select inv_mast_uid, *
from p21_fnt_all_pick_ticket_line(2156350, 2156350, 100)

select *
from p21_fnt_all_components(19428)


exec sp_help p21_fnt_item_list

exec sp_help p21_cancel_pick_ticket
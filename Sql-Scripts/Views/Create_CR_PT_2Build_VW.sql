-- create a view of just parts to buid

use P21Local2020;
--use P21Play;
--use P21;
/*
if OBJECT_ID ('_CR_PT_2Build_VW', 'V') is not null
drop view _CR_PT_2Build_VW;
go

create view [dbo].[_CR_PT_2Build_VW] AS
*/
select order_no,line_seq_no,m.item_id,item_desc,qty_ordered,primary_bin,unit_of_measure,qty_on_hand,parent_oe_line_uid,oe_line_uid
from oe_line o
join inv_mast m
on o.inv_mast_uid = m.inv_mast_uid
join inv_loc l
on l.inv_mast_uid = m.inv_mast_uid and o.source_loc_id = l.location_id
where assembly = 'B' and o.delete_flag = 'N'  and o.date_created > DATEADD(DAY,-90,GetDate())

/*
go 

grant select on object::_CR_PT_2Build_VW to admin
grant select on object::_CR_PT_2Build_VW to crystal
grant select on object::_CR_PT_2Build_VW to [PTIDOM\P21Users]
*/
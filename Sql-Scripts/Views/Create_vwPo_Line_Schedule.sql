-- For Joe Wise WebQuery

use P21Play;
--use P21;

/*
if OBJECT_ID ('vwPo_Line_Schedule', 'V') is not null
drop view vwPo_Line_Schedule;
go

create view [dbo].[vwPo_Line_Schedule] AS
*/

select pl.po_no,pl.line_no,item_id,item_desc,pl.qty_ordered,release_no,release_date,pls.release_qty,pls.qty_received
from dbo.po_line_schedule pls
join dbo.po_line pl
on pls.po_line_uid = pl.po_line_uid
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid

/*
go 

grant select,update,references on object::vwPo_Line_Schedule to p21_application_role
grant select,update,references on object::vwPo_Line_Schedule to PxxiUser
grant select,update,references on object::vwPo_Line_Schedule to [PTIDOM\P21Users]
*/
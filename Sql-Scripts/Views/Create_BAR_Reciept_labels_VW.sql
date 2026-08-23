-- 07/09/2021 create a view receipts for Receiving per Ralph
-- 03/25/2022 change for QC

use P21Play;
--use P21;
/*
if OBJECT_ID ('BAR_Receipt_VW', 'V') is not null
drop view BAR_Receipt_VW;
go

create view [dbo].[BAR_Receipt_VW] AS
*/

select item_id,item_desc, external_reference_no,r.date_created,convert(int,qty_received)[qty_received],m.class_id1
from inventory_receipts_line r
join inv_mast m
on r.inv_mast_uid = m.inv_mast_uid
join inventory_receipts_hdr h
on r.receipt_number = h.receipt_number
where r.date_created > DATEADD(DAY,-77,GetDate()) 

/*
go 

grant select on object::BAR_Receipt_VW to admin
grant select on object::BAR_Receipt_VW to crystal
grant select on object::BAR_Receipt_VW to [PTIDOM\P21Users]
*/


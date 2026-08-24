-- xref for power bi 
use P21Sand;
--use P21Play;
--use P21;
/*
if OBJECT_ID ('MasterDrive_items_xref_vw', 'V') is not null
drop view MasterDrive_items_xref_vw;
go

create view [dbo].[MasterDrive_items_xref_vw] AS
*/

SELECT item_id AS SIMG, item_desc, 'MASTERDRIVE' AS Brand, class_id5 AS PackType,default_product_group,supplier_id,isu.primary_supplier_flag
FROM dbo.inv_mast AS m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
WHERE (class_id1 IN ('MD', 'MBL')) AND (m.delete_flag = 'N')  and supplier_id != 9999 --and item_id = '2105010820'

/*
go
grant select,update,references on object::MasterDrive_items_xref_vw to p21_application_role
grant select,update,references on object::MasterDrive_items_xref_vw to PxxiUser
grant select,update,references on object::MasterDrive_items_xref_vw to [PTIDOM\P21Users]
*/
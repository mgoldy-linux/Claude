--use P21Play;
use P21;

select MAX(address_ud_uid)
from address_ud

Set IDENTITY_INSERT address_ud ON
/*
insert into address_ud (address_ud_uid,id,date_created,created_by,date_last_modified,last_maintained_by,carrier_group_solve)
values (170, 193506,GETDATE(),'mgoldyn-sql',GETDATE(),'mgoldyn-sql','Trucking')
*/
insert into address_ud (address_ud_uid,id,date_created,created_by,date_last_modified,last_maintained_by,carrier_group_solve)
values (171, 193543,GETDATE(),'mgoldyn-sql',GETDATE(),'mgoldyn-sql','Trucking')

insert into address_ud (address_ud_uid,id,date_created,created_by,date_last_modified,last_maintained_by,carrier_group_solve)
values (172, 193544,GETDATE(),'mgoldyn-sql',GETDATE(),'mgoldyn-sql','Trucking')

select *
from address_ud
where address_ud_uid in (171,172)

Set IDENTITY_INSERT address_ud OFF
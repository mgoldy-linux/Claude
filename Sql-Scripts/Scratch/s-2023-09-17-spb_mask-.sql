select oh.order_no, ol.inv_mast_uid, ol.line_no,item_id, item_desc--,ul.spb_mask
from dbo.oe_hdr oh
join dbo.oe_line ol
on oh.order_no = ol.order_no
join dbo.inv_mast m
on m.inv_mast_uid = ol.inv_mast_uid
--join dbo.oe_line_ud ul
--on ol.order_no = ul.order_no and ol.line_no = ul.line_no
where source_location_id = 530

select oh.order_no, ol.inv_mast_uid, ol.line_no,item_id, item_desc,ul.created_by,ul.spb_mask
from dbo.oe_hdr oh
join dbo.oe_line ol
on oh.order_no = ol.order_no
join dbo.inv_mast m
on m.inv_mast_uid = ol.inv_mast_uid
left join dbo.oe_line_ud ul
on ol.order_no = ul.order_no and ol.line_no = ul.line_no
where location_id = 530 and oh.delete_flag = 'N' and oh.cancel_flag = 'N' and ol.delete_flag = 'N' --and oh.order_no = '1485021'

select top 3 *
from oe_line_ud 
where order_no =  1485012

exec sp_help oe_line_ud

select MAX(oe_line_ud_uid)[max]
from oe_line_ud 

Set IDENTITY_INSERT oe_line_ud ON

insert into oe_line_ud (oe_line_ud_uid, order_no, line_no,date_created,created_by,date_last_modified,last_maintained_by,spb_mask)
VALUES ( 50196,'1517809',1,GetDate(),'mgoldyn-sql',Getdate(),'mgoldyn-sql','RETURN RESTOCKING FEE')

Set IDENTITY_INSERT oe_line_ud OFF

update dbo.oe_line_ud
set spb_mask = '.0937 440C'
where order_no = '1534596' and line_no = 1

select oh.order_no, ol.inv_mast_uid, ol.line_no,item_id, item_desc,ul.created_by,ul.spb_mask,oh.delete_flag,oh.cancel_flag,ol.delete_flag
from dbo.oe_hdr oh
join dbo.oe_line ol
on oh.order_no = ol.order_no
join dbo.inv_mast m
on m.inv_mast_uid = ol.inv_mast_uid
left join dbo.oe_line_ud ul
on ol.order_no = ul.order_no and ol.line_no = ul.line_no
where location_id = 530 and oh.order_no =  '1517809'

update dbo.oe_line_ud
set spb_mask = 'MISCELLANEOUS NON-INVENTORY ITEM'
where order_no = '1517809' and line_no = 1

select source_location_id,source_id,*
from oe_hdr 
where order_no = '1485021'

Set IDENTITY_INSERT oe_line_ud ON
insert into oe_line_ud ("oe_line_ud_uid", "order_no", "line_no","date_created","created_by","date_last_modified","last_maintained_by","spb_mask")
values (50198,'1528640',1,GetDate(),'mgoldyn-sql',Getdate(),'mgoldyn-sql','SFRW156ZZA3MC3SRL')

Set IDENTITY_INSERT oe_line_ud OFF
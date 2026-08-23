Use Play2;

Set IDENTITY_INSERT dbo. vessel_receipts_hdr_ud ON
insert into dbo.vessel_receipts_hdr_ud ("vessel_receipts_hdr_ud_uid","vessel_receipts_hdr_uid","date_created",	"created_by","date_last_modified","last_maintained_by","status1","lfd1")
values (1,1290,GETDATE(),'mgoldyn-sql',GETDATE(),'mgoldyn-sql','Departed Port/Airport','2023-04-27')

Set IDENTITY_INSERT dbo. vessel_receipts_hdr_ud OFF

select *
from dbo.vessel_receipts_hdr_ud
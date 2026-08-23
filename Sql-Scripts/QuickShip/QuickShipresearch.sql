select *
from Logs
order by TimeStamp desc

-- gives type of label
select *
from Document
order by CreateDate desc
--manager type
select *
from DocumentManager

select *
from WorkstationDocument
order by WorkstationId

-- workstation information
select *
from Workstation
where WorkstationId = '24B67882-D95F-4893-8915-AA7F0130B924'

Update WorkstationDocument
Set Destination = '\\wh\ Zebra LP 2844' where Destination = 'Microsoft Print to PDF'

select *
from DocumentManager
where DocumentManagerId = '3CA5DA2A-54CF-4F67-BE40-17A093EA5FE5'

-- restoring settings to 20210401
Update WorkstationDocument
set Destination = 'SAVIN MP 2554 clt' where WorkstationDocumentId =  'EDBE11E6-2F77-44ED-A58B-AADB00EBD47C'

Update WorkstationDocument
set Destination = 'SAVIN MP 2554 clt' where WorkstationDocumentId =  'D79B4015-BE70-4A6C-8BD8-AADB00EBD477'
-- NY-410-Lexmark B3340dw   change to \\tritan-410-01-T\Lexmark Universal v2 XL   this is all reports
-- Microsoft Print to PDF  change to \\tritan-410-01-T\Zebra ZP 450 CTP this is all labels
use QuickShip;
/*
select * from WorkstationDocument
where WorkstationId = 'A8522F5A-215D-4C84-918C-AEE4013E5676' and WorkstationDocumentId != '1F3313D0-4153-4D1D-9A37-AEE4013E568C'

update WorkstationDocument
set Destination = '\\tritan-410-01-T\Lexmark Universal v2 XL'
where WorkstationId = 'A8522F5A-215D-4C84-918C-AEE4013E5676' and WorkstationDocumentId != '1F3313D0-4153-4D1D-9A37-AEE4013E568C'

select * from WorkstationDocument
where WorkstationId = 'A8522F5A-215D-4C84-918C-AEE4013E5676' and WorkstationDocumentId != '1F3313D0-4153-4D1D-9A37-AEE4013E568C'
*/
select * from WorkstationDocument
where WorkstationDocumentId = '1F3313D0-4153-4D1D-9A37-AEE4013E568C'

update WorkstationDocument
set Destination = '\\tritan-410-01-T\Zebra ZP 450 CTP'
where WorkstationDocumentId = '1F3313D0-4153-4D1D-9A37-AEE4013E568C'

select * from WorkstationDocument
where WorkstationDocumentId = '1F3313D0-4153-4D1D-9A37-AEE4013E568C'
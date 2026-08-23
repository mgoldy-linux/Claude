-- this BOL stopped the queue tracking number 02633608910

use QuickShip;

select *
from BOLHeader
where TrackingNumber = '02633608910'
order by CreateDate desc

select *
from BOLLine
where BOLHeaderId = '75552D4F-96DB-40E9-BA85-ADE400EDDFDC'

select *
from BOLClass


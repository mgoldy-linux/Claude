--use P21Sand;
use P21;

Select '210'[Record Type],a.id[External ID],
case 
when id = 1 then 'Solve IMG'
when id = 100 then 'PTI'
when id = 150 then 'DJ REPS'
when id = 200 then 'LMS'
when id = 300 then 'IPTCI'
when id = 350 then 'DJ REPS'
when id like '4%0' then 'Tritan'
when id = 510 then 'SST'
when id = 511 then 'BAD BOY'
when id = 520 then 'USA Rollers'
when id = 530 then 'SPB-USA'
when id = 601 then 'MASTERDRIVE'
when id = 602 then 'CLIFFORD SALES & MARKETING'
when id = 603 then 'PTM INDUSTRIES'
when id = 604 then 'SYMBIA OF COLORADO LLC'
when id = 605 then 'PTM INDUSTRIES'
when id = 606 then 'TAYLOR INDUSTRIAL SALES'
when id = 607 then 'MANNING & ASSOCIATES'
when id = 608 then 'B & G WAREHOUSE SERVICES'
when id = 609 then 'FLECK BEARING'
else name
end[Name],mail_address1[Address 1],mail_address2[Address 2],mail_address3[Address 3],mail_city[City],mail_state[State/Province],mail_postal_code[Postal Code],mail_country[Country Code],''[Future]
from address a
join po_hdr ph
on a.id = ph.branch_id
where ph.po_no in (4013889,4013545,4013872,4013104,4013423,4012437,4013417,4012410,4013416,4013510,4013016,4013137,4011341,4013508,4013566,4013351,4012998,4013248,4013389,4013004,4013053,4013566,4012729,4013015,4013508,4013014,4013105,4013045,4011435,4012766,4013053,4011341,4013280)

/*
select *
from po_hdr
where po_no in (4016190,4014887,4013705)

select top 8 *
from apinv_hdr
where po_no in ('4016190','4014887','4013705')
*/
 
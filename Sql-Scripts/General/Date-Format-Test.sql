select order_no, convert(varchar(10),oh.order_date,1)[1 Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

select order_no, convert(varchar(10),oh.order_date,108)[108 Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

select order_no, convert(varchar(10),oh.order_date,114)[114 Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

select order_no, convert(varchar(10),oh.order_date,120)[120 Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

--FORMAT(value, format, culture)
select order_no, format(oh.order_date,'yyyy-MM-dd')[yyyy-MM-dd Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

--FORMAT(value, format, culture)
select order_no, format(oh.order_date,'hh:mm')[hour:min Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

--FORMAT(value, format, culture)
select order_no, format(oh.order_date,'dd:hh:mm')[day:hour:min Format]
from oe_hdr oh
where order_no between 1594226 and 1594246 and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

-- no format hour
select opt.print_date,opt.ship_date,DATEDIFF(HOUR,opt.print_date,opt.ship_date)[Diff]
from oe_pick_ticket opt
where pick_ticket_no between 2481337 and 2481347 and delete_flag = 'N'

-- no format min
-- Convert(varchar(12),DATEADD(minute,DATEDIFF(MINUTE,opt.print_date,COALESCE(clip.shipped_date,opt.ship_date)),0),114)[Print Ship Time Diff]
select opt.print_date,opt.ship_date,Format(DATEADD(minute,DATEDIFF(MINUTE,opt.print_date,opt.ship_date),1),'hh:mm')[Diff]
from oe_pick_ticket opt
where pick_ticket_no between 2481337 and 2481347 and delete_flag = 'N'

-- test case else Cast(DATEDIFF(day,ih.invoice_date,ol.required_date) as VarChar(5)) + ' Days Early'
select opt.print_date,opt.ship_date,
case 
 when DATEDIFF(HOUR,opt.print_date,opt.ship_date) > 25 then Cast(DATEDIFF(DAY,opt.print_date,opt.ship_date) as VarChar(2)) + ':' + Cast(DATEDIFF(HOUR,opt.print_date,opt.ship_date)%24 as VarChar(3)) + ':' + Cast(DATEDIFF(MINUTE,opt.print_date,opt.ship_date)%60 as VarChar(5))
  when DATEDIFF(HOUR,opt.print_date,opt.ship_date) between 24 and 25 then '0:' + Cast(DATEDIFF(HOUR,opt.print_date,opt.ship_date) as VarChar(2)) + ':' + Cast((DATEDIFF(MINUTE,opt.print_date,opt.ship_date) -1440) as VarChar(2)) 
 --else '0:' + Cast(DATEDIFF(HOUR,opt.print_date,opt.ship_date) as VarChar(2)) + ':' + Cast((DATEDIFF(MINUTE,opt.print_date,opt.ship_date) - (DATEDIFF(HOUR,opt.print_date,opt.ship_date)*60)) as VarChar(5)) 
 else '0:' + Cast(DATEDIFF(HOUR,opt.print_date,opt.ship_date) as VarChar(2)) + ':' + Cast(DATEDIFF(MINUTE,opt.print_date,opt.ship_date)%60 as VarChar(5)) 
 
 end [Diff] 
 
from oe_pick_ticket opt
where pick_ticket_no between 2481337 and 2481347 and delete_flag = 'N'
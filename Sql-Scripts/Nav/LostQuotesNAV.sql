-- per email from george

use NAVPROD;

Select h.No_[Quote no],h.[Sell-to Customer No_],[Ship-to Name],[Customer Posting Group],[Salesperson Code],[Order Date],l.No_[Item_id],Description,Quantity,[Customer Extended Amount]
from [PT International Corp_$Sales Header] h
join [PT International Corp_$Sales Line] l
on h.No_ = l.[Document No_]
where h.[Document Type] = 0 and [Order Date] between '2017-12-31 00:00:00.000' and '2019-09-30 00:00:00.000' and [Customer Extended Amount] > 10000
order by [Order Date] desc

select No_[Item_id],Description,Quantity,[Customer Extended Amount]
from [PT International Corp_$Sales Line]
where [Document No_] = 'SQ21162'
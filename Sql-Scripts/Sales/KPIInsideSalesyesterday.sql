select taker,count(distinct h.order_no)[countOfOrders],sum(extended_price)[Total]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where year(h.date_created) = year(getdate()) and month(h.date_created) = month(getdate()) and day(h.date_created) = day(getdate()) and h.delete_flag = 'N' and projected_order = 'N' and h.cancel_flag = 'N' and other_charge = 'N' and l.delete_flag = 'N' and l.cancel_flag = 'N'  and source_location_id = 100
group by taker

-- quotes
select taker,count(distinct h.order_no)[countOfQuotes],sum(extended_price)[Total]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where year(h.date_created) = year(getdate()) and month(h.date_created) = month(getdate()) and day(h.date_created) = day(getdate()) and h.delete_flag = 'N' and projected_order = 'Y' and h.cancel_flag = 'N'  and source_location_id = 100
group by taker

select taker,count(distinct h.order_no)[countOfRMAs],sum(extended_price)[Total]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where year(h.date_created) = year(getdate()) and month(h.date_created) = month(getdate()) and day(h.date_created) = day(getdate()) and rma_flag = 'Y' and source_location_id = 100
group by taker
select u.*
from dbo.inv_period_usage u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
where location_id like '4%' and item_id = '2101070343'

select *
from dbo.p21_view_inv_period_usage
where item_id = '2101070343'
order by demand_period_uid desc

select *
from dbo.demand_period
order by demand_period_uid desc


exec p21_item_info 2101070343, 410, 70512
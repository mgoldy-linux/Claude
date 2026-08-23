-- get sales for parts

with Mparts(invmastuid)
as
(
	select inv_mast_uid
	from inv_mast
	where item_id like 'M-%'
),
Meyn2021(inv_mast_uid21,Sales2021)
as
(
	select inv_mast_uid,Sum(extended_price)--,source_loc_id  -- add if preformance slow
	from oe_line ol
	where ol.delete_flag = 'N' and datepart(yyyy,DateAdd("m",6,required_date)) = 2021 
	group by inv_mast_uid,source_loc_id
),
Meyn2020(inv_mast_uid20,Sales2020)
as
(
	select inv_mast_uid,Sum(extended_price)
	from oe_line ol
	where ol.delete_flag = 'N' and datepart(yyyy,DateAdd("m",6,required_date)) = 2020
	group by inv_mast_uid
)
	select mp.invmastuid,convert(varchar,cast(isnull(M20.Sales2020,0) as Money),1)[FS20],convert(varchar,cast(isnull(M21.Sales2021,0) as Money),1)[FS21]
	from Mparts mp
	left join Meyn2020 M20
	on mp.invmastuid = M20.inv_mast_uid20
	left join Meyn2021 M21
	on mp.invmastuid = M21.inv_mast_uid21	
	order by mp.invmastuid
/*
select *
from inv_loc_stock_status
where inv_mast_uid = 51026
*/

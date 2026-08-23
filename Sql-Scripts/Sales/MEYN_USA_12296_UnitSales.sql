-- get sales for parts, sample inv_mast_uid = 16817

with Mparts(invmastuid)
as
(
	select inv_mast_uid
	from inv_mast
	where item_id like 'M-%'
),
Meyn2022(inv_mast_uid22,UnitSales2022)
as
(
	select inv_mast_uid,Sum(qty_shipped)
	from invoice_hdr h
	join invoice_line il
	on h.invoice_no = il.invoice_no
	where invoice_date between '2021-07-01' and '2022-06-30'
	group by inv_mast_uid
),
Meyn2021(inv_mast_uid21,UnitSales2021)
as
(
	select inv_mast_uid,Sum(qty_shipped)
	from invoice_hdr h
	join invoice_line il
	on h.invoice_no = il.invoice_no
	where invoice_date between '2020-07-01' and '2021-06-30'
	group by inv_mast_uid
),
Meyn2020(inv_mast_uid20,UnitSales2020)
as
(
	select inv_mast_uid,Sum(qty_shipped)
	from invoice_hdr h
	join invoice_line il
	on h.invoice_no = il.invoice_no
	where invoice_date between '2019-07-01' and '2020-06-30'
	group by inv_mast_uid
)
	select mp.invmastuid,convert(int,isnull(M20.UnitSales2020,0))[FS20],convert(int,isnull(M21.UnitSales2021,0))[FS21],convert(int,isnull(M22.UnitSales2022,0))[FS22]
	from Mparts mp
	left join Meyn2020 M20
	on mp.invmastuid = M20.inv_mast_uid20
	left join Meyn2021 M21
	on mp.invmastuid = M21.inv_mast_uid21
	left join Meyn2022 M22
	on mp.invmastuid = M22.inv_mast_uid22		
	order by mp.invmastuid
/*
select *
from inv_loc_stock_status
where inv_mast_uid = 51026


select item_id
from inv_mast
where inv_mast_uid = 16820
where item_id = 'M-0008.4286'

select *
from invoice_line
where inv_mast_uid = 16817 and date_created between '2019-07-01' and '2020-06-30'
order by date_created
*/
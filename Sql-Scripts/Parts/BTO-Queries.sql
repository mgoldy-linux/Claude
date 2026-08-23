--use Play2;

select m.item_id, item_desc, extended_desc, legacy_item_id,l.discontinued,l.sellable,x.their_item_id,x.customer_id, m.inv_mast_uid
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where bto_flag = 'Y'  and m.delete_flag = 'N' and location_id = 300 --and item_id = '2101032122'
order by item_id

-- BTO w\Customer Part Numbers
select l.discontinued,m.item_id,u.legacy_item_id,item_desc,l.sellable,x.their_item_id,x.customer_id
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where bto_flag = 'Y'  and m.delete_flag = 'N' and location_id = 300 --and item_id = '2101032122'
order by item_id

-- BTO on Orders with Customer P/N
select l.discontinued,m.item_id,u.legacy_item_id,item_desc,l.sellable,x.their_item_id,x.customer_id,l.location_id, l.delete_flag,m.inv_mast_uid,ol.order_no, qty_on_hand, qty_ordered,oh.projected_order,rma_flag, order_date
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
left join dbo.inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
join dbo.oe_line ol
on m.inv_mast_uid = ol.inv_mast_uid
join dbo.oe_hdr oh
on ol.order_no = oh.order_no
where bto_flag = 'Y'  and m.delete_flag = 'N' and their_item_id is null and ol.complete = 'N' and rma_flag = 'Y'--and item_id = '2101032122' and location_id = 300 
order by order_no desc

-- BTO NOT on Orders
select l.discontinued,m.item_id,u.legacy_item_id,item_desc,l.sellable,x.their_item_id,x.customer_id,l.location_id, l.delete_flag,m.inv_mast_uid,ol.order_no
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
left join dbo.inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
left join dbo.oe_line ol
on m.inv_mast_uid = ol.inv_mast_uid
where bto_flag = 'Y'  and m.delete_flag = 'N' and their_item_id is null and ol.order_no is null --and item_id = '2101032122' and location_id = 300 
order by order_no desc

-- just part numbers
select distinct m.inv_mast_uid
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where bto_flag = 'Y'  and m.delete_flag = 'N' and l.delete_flag = 'N' --and item_id = '2101032122'
order by inv_mast_uid


-- BTO on Quotes
select l.discontinued,m.item_id,u.legacy_item_id,item_desc,l.sellable,l.location_id, l.delete_flag,m.inv_mast_uid,ol.order_no,order_date, qty_on_hand, qty_ordered,oh.projected_order,rma_flag
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.oe_line ol
on m.inv_mast_uid = ol.inv_mast_uid
join dbo.oe_hdr oh
on ol.order_no = oh.order_no
where bto_flag = 'Y'  and m.delete_flag = 'N' and ol.complete = 'N' and rma_flag = 'N' and projected_order = 'Y'--and item_id = '2101032122' and location_id = 300 
order by order_no desc

-- for powershell, canacelling Quotes
select ol.order_no,oh.oe_hdr_uid
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.oe_line ol
on m.inv_mast_uid = ol.inv_mast_uid
join dbo.oe_hdr oh
on ol.order_no = oh.order_no
where bto_flag = 'Y'  and m.delete_flag = 'N' and ol.complete = 'N' and rma_flag = 'N' and projected_order = 'Y'--and item_id = '2101032122' and location_id = 300 
order by order_no desc

select *
from inv_mast
where inv_mast_uid = 102953





-- 1383168
select oh.rma_flag
from dbo.oe_line ol
join dbo.oe_hdr oh
on ol.order_no = oh.order_no
where inv_mast_uid = 31214  and ol.complete = 'N'


select *
from inv_mast
where item_id = '2101033865'
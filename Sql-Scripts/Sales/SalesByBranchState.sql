-- Need to fix address' country first, if null will distort the data
-- for missing state & country will go by taker

with getPTI([State],PTI)
as
(
	Select ship2_state,sum(extended_price)
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join inv_mast m
	on m.inv_mast_uid = l.inv_mast_uid
	where approved = 'Y' and order_date between '2021-01-01' and '2021-12-31' and h.projected_order = 'N' and ship2_country not in ('CZ','CR','EC','IN','PE','PL','BR','CA','NZ','TH','MX','DO','CN') and completed = 'Y' and ship2_state not in ('PR','QC','ON') and m.class_id1 = 'PTI' --and rma_flag = 'N'-- and extended_price !=0 
	group by ship2_state
	),
	getIPTCI([State],IPTCI)
as
(
	Select ship2_state,sum(extended_price)
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join inv_mast m
	on m.inv_mast_uid = l.inv_mast_uid
	where approved = 'Y' and order_date between '2021-01-01' and '2021-12-31' and h.projected_order = 'N' and ship2_country not in ('CZ','CR','EC','IN','PE','PL','BR','CA','NZ','TH','MX','DO','CN') and completed = 'Y' and ship2_state not in ('PR','QC','ON') and m.class_id1 = 'IPTCI' --and rma_flag = 'N'-- and extended_price !=0 
	group by ship2_state
),
	getLMS([State],LMS)
as
(
	Select ship2_state,sum(extended_price)
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join inv_mast m
	on m.inv_mast_uid = l.inv_mast_uid
	where approved = 'Y' and order_date between '2021-01-01' and '2021-12-31' and h.projected_order = 'N' and ship2_country not in ('CZ','CR','EC','IN','PE','PL','BR','CA','NZ','TH','MX','DO','CN') and completed = 'Y' and ship2_state not in ('PR','QC','ON') and m.class_id1 = 'LMS' --and rma_flag = 'N'-- and extended_price !=0 
	group by ship2_state
)		
select p.State,PTI,LMS,IPTCI
from getPTI p
left join getLMS l
on p.State = l.State
left join getIPTCI m
on p.State = m.State
order by p.State
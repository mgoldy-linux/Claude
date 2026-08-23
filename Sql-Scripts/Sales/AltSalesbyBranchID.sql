select distinct taker
from oe_hdr h
where ship2_state is null and ship2_country is null and order_date between '2021-01-01' and '2021-12-31'


-- PTI
select Sum(extended_price)
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where ship2_state is null and ship2_country is null and taker in ('WCR','BWOLF','MBRENNING','CARTER','CARTER','DEBRAS','SBRASWELL','JJARRETT') and order_date between '2021-01-01' and '2021-12-31'

-- LMS
select Sum(extended_price)
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where ship2_state is null and ship2_country is null and taker in ('CPRENTICE') and order_date between '2021-01-01' and '2021-12-31'

-- IPTCI
select Sum(extended_price)
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where ship2_state is null and ship2_country is null and taker in ('JSCHAPER','SESTERBERG','DWALD','CXM','JRENAUD','TTOLLBERG','RWHITAKER') and order_date between '2021-01-01' and '2021-12-31'
-- need to update the dates 

Use P21Play;

-- Check Current PricePages
-- PTI DIST
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like 'PTI-DIST%' --and effective_date > '2021-10-24'
order by effective_date desc, product_group_id
-- PTI OEM
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like 'PTI-OEM%' and effective_date > '2021-10-24'
order by effective_date desc, product_group_id
-- IPTCI 
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like 'IPTCI%' and effective_date > '2021-10-24'
order by effective_date desc, product_group_id

-- PTI Expired Price Pages
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like '%-APR-OCT21' 
order by effective_date desc, product_group_id

-- IPTCI Expired Price Pages
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like '%21-21' 
order by effective_date desc, product_group_id

-- search for role
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like '%r%' 
order by effective_date desc, product_group_id

-- check one group 
-- PTI DIST
select description, discount_group_id,product_group_id,effective_date,expiration_date
from price_page
where description Like 'PTI-DIST-S1%' --and effective_date > '2021-10-24'
order by effective_date desc, product_group_id
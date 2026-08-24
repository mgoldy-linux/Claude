job_price_customer_shipto.customer_id
job_price_customer_shipto.ship_to_id
job_price_customer_shipto.row_status_flag.
address.name

use P21Play;

select row_status_flag,*
from job_price_customer_shipto
where customer_id = 10806

/*
insert into job_price_customer_shipto (job_price_cust_shipto_uid,job_price_hdr_uid,company_id,customer_id, ship_to_id, preferred_location_id,row_status_flag)
values(106190,2,1,10793,29141,100,704)


insert into job_price_customer_shipto (job_price_cust_shipto_uid,job_price_hdr_uid,company_id,customer_id, ship_to_id, row_status_flag)
values(106191,2,1,10806,10806,704)
*/
select max(job_price_cust_shipto_uid)[max-uid]
from job_price_customer_shipto
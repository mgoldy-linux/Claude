select * from p21_view_counter where id = 'job_price_customer_shipto'
select max(job_price_cust_shipto_uid) from job_price_customer_shipto


update counter set column_name = 'job_price_cust_shipto_uid' where id = 'job_price_customer_shipto'


exec p21_set_counter @counter_id = 'job_price_customer_shipto', @set_to_table_value = 1

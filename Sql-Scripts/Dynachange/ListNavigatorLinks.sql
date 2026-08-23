select *
from dc_nav_drill
where source_window = 'w_customer_master_inquiry'
order by date_last_modified desc
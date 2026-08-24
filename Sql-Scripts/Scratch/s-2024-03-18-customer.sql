select distinct req_pymt_upon_release_of_items
from customer

select *
from dbo.customer
where req_pymt_upon_release_of_items = 'Y' and delete_flag = 'N'

select distinct days_overdue_for_credit_hold added
from customer
select top 5 *
from p21_view_vendor

select top 5 *
from p21_view_payments
where year_for_period = 2024

select top 5 *
from p21_view_payment_detail
where check_no = '001022'

-- no data
select top 5 *
from p21_view_vendor_rebate

--
select top 5 *
from payments
where year_for_period = 2024
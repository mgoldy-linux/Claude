use P21;
--PTI Sales
select period_balance/1000[Product Sales]
from [dbo].[p21_bal_view_derived_home_amts]
where account_no = 41000000100 and period = 3 and year_for_period = 2020
-- PTI Returns
select period_balance/1000[Returns], *
from [dbo].[p21_bal_view_derived_home_amts]
where account_no LIKE '420%100' and period = 3 and year_for_period = 2020


-- PTI Returns
select period_balance/1000[Discounts], *
from [dbo].[p21_bal_view_derived_home_amts]
where account_no like '430%100' and period = 3 and year_for_period = 2020
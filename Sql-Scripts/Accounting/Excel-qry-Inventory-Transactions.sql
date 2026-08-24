-- inventory transactions for Audit email from Clark
-- first tab, Move Inv_mast_uid  to 3rd column
select item_id, item_desc, t.*
from inv_tran t
join inv_mast m
on t.inv_mast_uid = m.inv_mast_uid
where year_for_period = 2022 and trans_type = 'WO' -- tab name
order by period

-- 2nd tab, Move Inv_mast_uid to 3rd column
select item_id, item_desc, t.*
from inv_tran t
join inv_mast m
on t.inv_mast_uid = m.inv_mast_uid
where year_for_period = 2022 and trans_type = 'RECPT' -- tab name
order by period
use P21Sand;

select top 9 *
from p21_view_stockstatus_report

select top 9 *
from p21_view_forward_stock_analysis

-- empty
select top 9 *
from inventory_movement_deposit

-- return nothing, Commands completed successfully.
exec p21_inv_bin

exec p21_item_info '2101001061'

select *
from inv_loc_stock_status
where inv_mast_uid = 1063

select *
from p21_view_inv_loc_stock_status
where inv_mast_uid = 30357

select top 9 *
from inv_loc 
where inv_mast_uid = 30357

select top 9 *
from activity_trans

select top 9 *
from transfer_line
where inv_mast_uid = 1063

select top 9 *
from p21_inventory_rebuild
where inv_mast_uid = 1063

select top 9 *
from p21_inventory_usage_all_view
where inv_mast_uid = 1063 and year_for_period = 2024

select top 9 *
from p21_inventory_usage_view
where year_for_period = 2024 and class_id1 = 'PTI' and class_id2 = 'EPL'

select top 9 *
from p21_view_inv_tran
where location_id = 100 and year_for_period = 2024 and qty_on_bo > 0 

SELECT p21_view_inv_mast.item_id, p21_view_inv_mast.item_desc,
p21_view_inv_tran.location_id, SUM(CASE WHEN trans_date < CONVERT(DATETIME,
'2023-12-01 00:00:00', 102) THEN quantity ELSE 0 END)
AS [12/31/08], SUM(CASE WHEN trans_date < CONVERT(DATETIME, '2024-01-01
00:00:00',
102) THEN quantity ELSE 0 END) AS [1/31/09], SUM(CASE
WHEN trans_date < CONVERT(DATETIME, '2009-03-01 00:00:00', 102)
THEN quantity ELSE 0 END) AS [2/28/09], SUM(CASE WHEN
trans_date < CONVERT(DATETIME, '2009-04-01 00:00:00', 102) THEN quantity
ELSE 0 END)
AS [3/31/09], SUM(CASE WHEN trans_date <
CONVERT(DATETIME, '2009-05-01 00:00:00', 102) THEN quantity ELSE 0 END) AS
[4/30/09],
SUM(CASE WHEN trans_date < CONVERT(DATETIME,
'2009-06-01 00:00:00', 102) THEN quantity ELSE 0 END) AS [5/31/09]
FROM p21_view_inv_tran INNER JOIN
p21_view_inv_mast ON p21_view_inv_tran.inv_mast_uid p21_view_inv_mast.inv_mast_uid
GROUP BY p21_view_inv_tran.location_id, p21_view_inv_mast.item_id,
p21_view_inv_mast.item_desc
ORDER BY p21_view_inv_mast.item_id, p21_view_inv_tran.location_id
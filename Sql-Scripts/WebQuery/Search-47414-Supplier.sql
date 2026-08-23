/*
FROM            dbo.vwinventory_lvl1 LEFT OUTER JOIN
(SELECT        inv_loc.inv_mast_uid, inv_loc.location_id, CASE WHEN COALESCE (inv_period_usage.forecast_usage, 0.000000000) 
* company.number_of_demand_periods / item_uom.unit_size > COALESCE (NULLIF (location.high_velocity_level, 0), CAST(ss_high.value AS DECIMAL(9))) THEN COALESCE (high_level_months, 0.000000000) 
WHEN COALESCE (inv_period_usage.forecast_usage, 0.000000000) * company.number_of_demand_periods / item_uom.unit_size > COALESCE (NULLIF (location.mid_velocity_level, 0), 
CAST(ss_mid.value AS DECIMAL(9))) THEN COALESCE (mid_level_months, 0.000000000) ELSE COALESCE (low_level_months, 0.000000000) END AS periods_to_supply
FROM P21.dbo.inv_loc AS inv_loc INNER JOIN
P21.dbo.company AS company ON company.company_id = inv_loc.company_id INNER JOIN
P21.dbo.inv_mast AS inv_mast ON inv_loc.inv_mast_uid = inv_mast.inv_mast_uid AND inv_mast.delete_flag = 'N' INNER JOIN
P21.dbo.location AS location ON location.location_id = inv_loc.location_id INNER JOIN
P21.dbo.item_uom AS item_uom ON item_uom.inv_mast_uid = inv_mast.inv_mast_uid AND item_uom.unit_of_measure = inv_mast.default_selling_unit LEFT OUTER JOIN
P21.dbo.purchase_class AS purchase_class ON purchase_class.purchase_class_id = inv_loc.purchase_class LEFT OUTER JOIN
P21.dbo.demand_period AS demand_period ON demand_period.company_id = inv_loc.company_id AND GETDATE() BETWEEN demand_period.beginning_date AND demand_period.ending_date LEFT OUTER JOIN
P21.dbo.inv_period_usage AS inv_period_usage WITH (NOLOCK) ON inv_period_usage.demand_period_uid = demand_period.demand_period_uid AND 
inv_period_usage.inv_mast_uid = inv_loc.inv_mast_uid AND inv_period_usage.location_id = inv_loc.location_id CROSS JOIN
P21.dbo.system_setting AS ss_cost_basis CROSS JOIN
P21.dbo.system_setting AS ss_high CROSS JOIN
P21.dbo.system_setting AS ss_mid CROSS JOIN
P21.dbo.system_setting AS eoqlimit
*/

select *
from inv_mast 
where item_id = '2105010772'

select *
from inv_loc
where inv_mast_uid = 131572

select inventory_supplier_uid,*
from inventory_supplier 
where supplier_id = 47614 and delete_flag = 'Y' and inv_mast_uid = 131572
--where inv_mast_uid = 131572

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 185637

select *
from item_uom
where inv_mast_uid = 131572

Select *
from inv_period_usage
where location_id = 601
--where inv_mast_uid = 131572

Select *
from purchase_class

select *
from p21_view_inventory_value_report
where inv_mast_uid = 131572

select *
from inv_mast_lot
where inv_mast_uid = 131572

select *
from inv_mast_ud
where inv_mast_uid = 131572

select *
from inv_loc_stock_status
where inv_mast_uid = 131572

select *
from item_notepad
where inv_mast_uid = 131572
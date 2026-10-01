/*
SA 55678 - Supplier Cost Changes in Last 7 Days (Jere's workbook) - source discovery

The workbook's Header / Location tabs have these columns:
  Header  : supplier, item_id, date_created, old_value, new_value, created_by, Comments
  Location: supplier, item_id, location, date_created, old_value, new_value, created_by, Comments
That column set (old_value / new_value / created_by / date_created) is the P21 audit_trail
shape. Working theory: Header = inventory_supplier.cost, Location = inventory_supplier_x_loc.loc_cost.
NOT verified against the DB yet - run each step in SSMS (Prod, read-only) and compare to the
sample rows in the workbook (e.g. ALT50903 15.45 <- 14.72 on 2024-08-29 by AHI\ereyes;
FUT150553219-22 @ loc 380, 2.99 -> 2.85 on 2024-09-03).
*/

-- STEP 1: which columns/tables does audit_trail record for supplier cost?
select table_changed, column_changed, column_description, key1_cd, key2_cd, count(*) cnt, max(date_created) last_seen
from audit_trail
where table_changed in ('inventory_supplier','inventory_supplier_x_loc')
  and (column_changed like '%cost%')
  and date_created >= dateadd(day,-30,getdate())
group by table_changed, column_changed, column_description, key1_cd, key2_cd
order by cnt desc;

-- STEP 2: eyeball raw rows (last 7 days) to see how keys map back to item/supplier/location
select top 50 *
from audit_trail
where table_changed in ('inventory_supplier','inventory_supplier_x_loc')
  and column_changed like '%cost%'
  and date_created >= dateadd(day,-7,getdate())
order by date_created desc;

-- STEP 3: confirm a known 2024 sample row is still in audit_trail (shows whether audit data goes back that far / matches)
select top 20 *
from audit_trail
where table_changed = 'inventory_supplier'
  and new_value like '15.45%' and old_value like '14.72%'
  and date_created >= '2024-08-29' and date_created < '2024-08-30';

/*
After STEP 1-3: the final query joins audit_trail -> inventory_supplier (-> inventory_supplier_x_loc
for Location) -> inv_mast (item_id) and supplier (supplier name), filtered to
date_created >= DATEADD(day,-7, CAST(GETDATE() AS date)). Prove equivalence against the workbook
rows, then hand Jere a view / saved query to point Power Query at.

Standing rule: no kb_/js_/ds_ objects used here. Measure logical reads before shipping.
*/

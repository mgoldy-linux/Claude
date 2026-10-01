/*
SA 55678 - Supplier Cost Changes in Last 7 Days (refreshable source for Jere's workbook)
Mapping confirmed from audit_trail rows (Step 2, 2026-10-01):
  Header   tab = table_changed 'inventory_supplier'       / column_changed 'cost'      (key3 = supplier_id)
  Location tab = table_changed 'inventory_supplier_x_loc' / column_changed 'loc_cost'  (key2 = location_id, key3 = supplier_id)
  item_id from inv_mast via audit_trail.inv_mast_uid; supplier name from supplier.supplier_id.
Output columns match the workbook tables (Query1 / Query2) in order. Comments is left to Excel (hand-typed).

OPEN: AHI\sqlsvc rows (nightly job, ~8 rows at 22:58 on 9/30) and bulk dnguyen edits are included.
Jere's 2024 sample was mostly ereyes/bjepsen - ask whether sqlsvc/system rows should be excluded
(add: AND a.created_by <> 'AHI\sqlsvc').
*/

DECLARE @Since datetime = DATEADD(day, -7, CAST(GETDATE() AS date));   -- rolling 7 days; confirm with Jere

-- ===== HEADER tab =====
SELECT  s.supplier_name              AS supplier,
        m.item_id                    AS item_id,
        a.date_created               AS date_created,
        a.old_value                  AS old_value,
        a.new_value                  AS new_value,
        a.created_by                 AS created_by
FROM    audit_trail a
JOIN    inv_mast m ON m.inv_mast_uid = a.inv_mast_uid
LEFT JOIN supplier s ON s.supplier_id = TRY_CONVERT(decimal(19,0), a.key3_value)
WHERE   a.table_changed  = 'inventory_supplier'
  AND   a.column_changed = 'cost'
  AND   a.date_created  >= @Since
ORDER BY m.item_id, a.date_created;

-- ===== LOCATION tab =====
SELECT  s.supplier_name              AS supplier,
        m.item_id                    AS item_id,
        a.key2_value                 AS location,
        a.date_created               AS date_created,
        a.old_value                  AS old_value,
        a.new_value                  AS new_value,
        a.created_by                 AS created_by
FROM    audit_trail a
JOIN    inv_mast m ON m.inv_mast_uid = a.inv_mast_uid
LEFT JOIN supplier s ON s.supplier_id = TRY_CONVERT(decimal(19,0), a.key3_value)
WHERE   a.table_changed  = 'inventory_supplier_x_loc'
  AND   a.column_changed = 'loc_cost'
  AND   a.date_created  >= @Since
ORDER BY m.item_id, a.key2_value, a.date_created;

/*
Perf notes (measure before shipping): audit_trail is huge - confirm the plan seeks on date_created
(or table_changed/column_changed) rather than scanning; check logical reads via
sys.dm_exec_query_stats. If it scans, test adding a lower bound on audit_trail_uid
(e.g. >= the min uid for @Since) as the seek predicate.
No kb_/js_/ds_ objects used.
*/

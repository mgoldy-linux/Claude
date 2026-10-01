/*
SA 55678 - refreshable source for "Supplier Cost Changes in Last 7 Days" (Jere's workbook)
DRAFT - not deployed. Test in Play first, then Prod. Source logic proven by the discovery script
(Sql-Scripts/Supplier/SA-55678-Supplier-Cost-Changes-Discovery.sql); the equivalent queries
returned 118 header / 7 location rows on 2026-10-01.

Rolling window is inside the view (last 7 days from midnight). If Jere wants a different window or
sqlsvc excluded, change it here once - the workbook just refreshes.
*/

CREATE OR ALTER VIEW dbo.asi_view_supplier_cost_changes_hdr
AS
SELECT  s.supplier_name  AS supplier,
        m.item_id        AS item_id,
        a.date_created   AS date_created,
        a.old_value      AS old_value,
        a.new_value      AS new_value,
        a.created_by     AS created_by
FROM    dbo.audit_trail a
JOIN    dbo.inv_mast m ON m.inv_mast_uid = a.inv_mast_uid
LEFT JOIN dbo.supplier s ON s.supplier_id = TRY_CONVERT(decimal(19,0), a.key3_value)
WHERE   a.table_changed  = 'inventory_supplier'
  AND   a.column_changed = 'cost'
  AND   a.date_created  >= DATEADD(day, -7, CAST(GETDATE() AS date));
GO

CREATE OR ALTER VIEW dbo.asi_view_supplier_cost_changes_loc
AS
SELECT  s.supplier_name  AS supplier,
        m.item_id        AS item_id,
        a.key2_value     AS location,
        a.date_created   AS date_created,
        a.old_value      AS old_value,
        a.new_value      AS new_value,
        a.created_by     AS created_by
FROM    dbo.audit_trail a
JOIN    dbo.inv_mast m ON m.inv_mast_uid = a.inv_mast_uid
LEFT JOIN dbo.supplier s ON s.supplier_id = TRY_CONVERT(decimal(19,0), a.key3_value)
WHERE   a.table_changed  = 'inventory_supplier_x_loc'
  AND   a.column_changed = 'loc_cost'
  AND   a.date_created  >= DATEADD(day, -7, CAST(GETDATE() AS date));
GO

-- New objects need an explicit grant (per P21 convention)
GRANT SELECT ON dbo.asi_view_supplier_cost_changes_hdr TO p21_application_role;
GRANT SELECT ON dbo.asi_view_supplier_cost_changes_loc TO p21_application_role;
GO

-- Sanity check: expect ~118 / ~7 today
SELECT COUNT(*) AS hdr_rows FROM dbo.asi_view_supplier_cost_changes_hdr;
SELECT COUNT(*) AS loc_rows FROM dbo.asi_view_supplier_cost_changes_loc;

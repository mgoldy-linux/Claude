/* ============================================================================
   Find the lookup/codes table (if any) behind inv_loc.safety_stock_type, to
   get a definitive code -> label mapping ("By ABC Class" / "Days" /
   "Deviation Multiplier" / "Service Level") instead of inferring it from one
   item's current UI display. The values seen in Training (0, 1261, 1716) are
   large surrogate-style codes, not a simple 0/1/2 enum, which suggests a real
   lookup table exists somewhere rather than a hardcoded client-side enum.

   Run in: P21Training (or wherever you want the mapping confirmed).
   READ-ONLY.
   ============================================================================ */
USE P21Training;
GO

/* ---- 1. Does safety_stock_type have an FK to another table? -------------- */
SELECT fk.name AS fk_name,
       OBJECT_NAME(fk.parent_object_id)      AS child_table,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS child_column,
       OBJECT_NAME(fk.referenced_object_id)  AS parent_table,
       COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS parent_column
FROM   sys.foreign_keys fk
JOIN   sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
WHERE  fk.parent_object_id = OBJECT_ID('dbo.inv_loc')
  AND  COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = 'safety_stock_type';
GO

/* ---- 2. Common P21 generic-codes table names -- check which exist -------- */
SELECT name FROM sys.tables
WHERE  name IN ('codes','p21_codes','p21_view_codes','generic_codes','code_p21',
                'safety_stock_type_codes','p21_view_safety_stock_type')
   OR  name LIKE '%safety_stock%';
GO

/* ---- 3. If a generic codes table exists (adjust name/columns from #2),
          look for entries related to safety_stock_type or the 4 known
          labels. Example shape -- EDIT the table/column names once #2
          tells you what actually exists: -----------------------------------
SELECT *
FROM   dbo.codes
WHERE  code_type = 'SAFETY_STOCK_TYPE'
   OR  description IN ('By ABC Class','Days','Deviation Multiplier','Service Level');
--------------------------------------------------------------------------- */
GO

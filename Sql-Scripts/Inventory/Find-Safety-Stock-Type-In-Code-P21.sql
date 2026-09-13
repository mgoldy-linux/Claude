/* ============================================================================
   code_p21 exists (confirmed) -- structure unknown. Rather than guess column
   names, list its columns first, then dynamically search every character
   column for the 4 known safety-stock-type labels ("By ABC Class", "Days",
   "Deviation Multiplier", "Service Level") to find the actual rows and see
   what column holds the numeric code that maps to inv_loc.safety_stock_type.

   Run in: P21Training.  READ-ONLY.
   ============================================================================ */
USE P21Training;
GO

/* ---- 1. column list ------------------------------------------------------- */
SELECT c.name AS column_name, TYPE_NAME(c.user_type_id) AS data_type, c.max_length
FROM   sys.columns c
WHERE  c.object_id = OBJECT_ID('dbo.code_p21')
ORDER  BY c.column_id;
GO

/* ---- 2. dynamic search across every character column for the 4 labels ---- */
DECLARE @search_sql nvarchar(max);

SELECT @search_sql = STRING_AGG(CAST(
    'SELECT ''' + c.name + ''' AS found_in_column, * FROM dbo.code_p21 WHERE [' + c.name + '] IN (' +
    'N''By ABC Class'', N''Days'', N''Deviation Multiplier'', N''Service Level'', ' +
    'N''ABC Class'', N''SAFETY_STOCK_TYPE'', N''safety_stock_type'')'
    AS nvarchar(max)), N' UNION ALL ')
FROM   sys.columns c
WHERE  c.object_id = OBJECT_ID('dbo.code_p21')
  AND  TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar');

IF @search_sql IS NOT NULL
    EXEC sp_executesql @search_sql;
GO

/* ---- 3. fallback -- if #2 finds nothing, just eyeball a sample ----------- */
SELECT TOP (50) * FROM dbo.code_p21;
GO

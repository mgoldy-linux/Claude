-- Compare two orders: one that gives the "may currently be edited by" popup (@bad) vs one that does not (@good).
-- Read-only. Shows what is different so only orders that really have the problem get fixed.
-- Part 1: oe_hdr column-by-column (differences only)
-- Part 2: oe_line summary per order (disposition / complete / delete / cancel flags)
-- Part 3: (optional) every table with an order_no / order_number column - row counts side by side.
--         Off by default; it touches many tables, so turn on only if Parts 1-2 show nothing.
USE P21;
SET NOCOUNT ON;

DECLARE @bad  int = 6162302;   -- gives the popup
DECLARE @good int = 6155280;   -- no popup
DECLARE @scan_all_tables bit = 0;

------------------------------------------------------------------------------------------
-- Part 1: oe_hdr columns that differ
------------------------------------------------------------------------------------------
/*DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(CAST(
    'SELECT ''' + c.name + ''' AS column_name, '
  + 'CAST(b.[' + c.name + '] AS nvarchar(4000)) AS bad_value, '
  + 'CAST(g.[' + c.name + '] AS nvarchar(4000)) AS good_value '
  + 'FROM oe_hdr b CROSS JOIN oe_hdr g WHERE b.order_no = @bad AND g.order_no = @good '
  + 'AND ISNULL(CAST(b.[' + c.name + '] AS nvarchar(4000)), N''<NULL>'') '
  + '<> ISNULL(CAST(g.[' + c.name + '] AS nvarchar(4000)), N''<NULL>'')'
    AS nvarchar(max)), N' UNION ALL ')
FROM sys.columns c
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.oe_hdr')
  AND t.name NOT IN ('image', 'timestamp', 'varbinary', 'binary')
  AND c.name NOT IN ('order_no');

SET @sql = N'SELECT * FROM (' + @sql + N') d ORDER BY column_name;';
EXEC sp_executesql @sql, N'@bad int, @good int', @bad = @bad, @good = @good;*/

------------------------------------------------------------------------------------------
-- Part 2: oe_line summary per order
------------------------------------------------------------------------------------------
SELECT l.order_no,
       COUNT(*)                                                    AS line_count,
       SUM(CASE WHEN l.disposition = 'T' THEN 1 ELSE 0 END)        AS disp_T_lines,
       SUM(CASE WHEN l.disposition IS NULL THEN 1 ELSE 0 END)      AS disp_null_lines,
       SUM(CASE WHEN l.complete = 'Y' THEN 1 ELSE 0 END)           AS complete_Y_lines,
       SUM(CASE WHEN l.delete_flag = 'Y' THEN 1 ELSE 0 END)        AS deleted_lines,
       SUM(CASE WHEN l.cancel_flag = 'Y' THEN 1 ELSE 0 END)        AS cancelled_lines,
       MAX(l.last_maintained_by)                                   AS last_maintained_by,
       MAX(l.date_last_modified)                                   AS last_modified
FROM oe_line l
WHERE l.order_no IN (@bad, @good)
GROUP BY l.order_no;

SELECT l.order_no, l.line_no, l.disposition, l.complete, l.delete_flag, l.cancel_flag,
       l.qty_ordered, l.qty_allocated, l.last_maintained_by, l.date_last_modified
FROM oe_line l
WHERE l.order_no IN (@bad, @good)
ORDER BY l.order_no, l.line_no;

------------------------------------------------------------------------------------------
-- Part 3 (optional): which tables have rows for each order
------------------------------------------------------------------------------------------
IF @scan_all_tables = 1
BEGIN
    DECLARE @scan nvarchar(max);

    SELECT @scan = STRING_AGG(CAST(
        'SELECT ''' + s.name + '.' + t.name + ''' AS table_name, '
      + '(SELECT COUNT(*) FROM [' + s.name + '].[' + t.name + '] WHERE [' + c.name + '] = @bad)  AS bad_rows, '
      + '(SELECT COUNT(*) FROM [' + s.name + '].[' + t.name + '] WHERE [' + c.name + '] = @good) AS good_rows'
        AS nvarchar(max)), N' UNION ALL ')
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.columns c ON c.object_id = t.object_id AND c.name IN ('order_no', 'order_number')
    JOIN sys.types ty  ON ty.user_type_id = c.user_type_id AND ty.name IN ('int', 'bigint', 'decimal', 'numeric')
    WHERE t.name NOT LIKE 'zz[_]%';

    SET @scan = N'SELECT * FROM (' + @scan + N') x WHERE bad_rows <> good_rows OR bad_rows > 0 ORDER BY table_name;';
    EXEC sp_executesql @scan, N'@bad int, @good int', @bad = @bad, @good = @good;
END

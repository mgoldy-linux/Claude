/* ============================================================================
   Pick 10 test items where ALL THREE updates would actually change a value.
     - non-deleted item + non-deleted inv_loc rows
     - each item from a different default product group
     - >=1 location row needs the replenishment_method change  AND
       >=1 needs the inv_min change                            AND
       >=1 needs the safety_stock_type change
   Run in: P21Dev.  READ-ONLY.
   If <10 rows come back, remove the "min_would_change > 0" line (inv_min is the
   rare one) and accept inv_min as a no-op test.
   ============================================================================ */
USE P21Dev;
GO

;WITH cand AS (
    SELECT  im.inv_mast_uid, im.item_id,
            im.default_product_group,
            COUNT(*) AS loc_rows,
            SUM(CASE WHEN il.replenishment_method <> 'Up To' OR il.replenishment_method IS NULL
                     THEN 1 ELSE 0 END) AS rm_would_change,
            SUM(CASE WHEN il.inv_min <> 0 OR il.inv_min IS NULL
                     THEN 1 ELSE 0 END) AS min_would_change,
            SUM(CASE WHEN il.safety_stock_type <> 0 OR il.safety_stock_type IS NULL
                     THEN 1 ELSE 0 END) AS sst_would_change
    FROM    dbo.inv_mast im
    JOIN    dbo.inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
    WHERE   im.delete_flag = 'N'
      AND   NULLIF(LTRIM(RTRIM(im.default_product_group)), '') IS NOT NULL
    GROUP BY im.inv_mast_uid, im.item_id, im.default_product_group
), ranked AS (
    SELECT  c.*,
            ROW_NUMBER() OVER (PARTITION BY c.default_product_group
                               ORDER BY c.loc_rows, c.item_id) AS rn,
            (SELECT COUNT(*) FROM dbo.assembly_line al
              WHERE al.component_inv_mast_uid = c.inv_mast_uid AND al.delete_flag = 'N') AS used_as_component,
            (SELECT COUNT(*) FROM dbo.assembly_line al
              WHERE al.inv_mast_uid = c.inv_mast_uid AND al.delete_flag = 'N')           AS is_assembly_parent
    FROM cand c
)
SELECT TOP (10)
       item_id, default_product_group, loc_rows,
       rm_would_change, min_would_change, sst_would_change,
       used_as_component, is_assembly_parent
FROM   ranked
WHERE  rn = 1
  AND  rm_would_change  > 0
  AND  min_would_change > 0
  AND  sst_would_change > 0
ORDER BY NEWID();
GO

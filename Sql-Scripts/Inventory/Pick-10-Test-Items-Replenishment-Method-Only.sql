/* ============================================================================
   Pick 10 items where replenishment_method is NOT already 'Up To' -- a clean,
   single-purpose set to isolate testing the replenishment_method import.
   One item per distinct default_product_group, fewest locations first.
   Run in: P21Dev.  READ-ONLY.
   ============================================================================ */
USE P21Dev;
GO

;WITH cand AS (
    SELECT  im.inv_mast_uid, im.item_id, im.default_product_group,
            COUNT(*) AS loc_rows,
            SUM(CASE WHEN il.replenishment_method <> 'Up To' OR il.replenishment_method IS NULL
                     THEN 1 ELSE 0 END) AS rm_would_change
    FROM    dbo.inv_mast im
    JOIN    dbo.inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
    WHERE   im.delete_flag = 'N'
      AND   NULLIF(LTRIM(RTRIM(im.default_product_group)), '') IS NOT NULL
    GROUP BY im.inv_mast_uid, im.item_id, im.default_product_group
    HAVING  SUM(CASE WHEN il.replenishment_method <> 'Up To' OR il.replenishment_method IS NULL
                     THEN 1 ELSE 0 END) > 0
), ranked AS (
    SELECT c.*,
           ROW_NUMBER() OVER (PARTITION BY c.default_product_group ORDER BY c.loc_rows, c.item_id) AS rn
    FROM cand c
)
SELECT TOP (10) item_id, default_product_group, loc_rows, rm_would_change
FROM   ranked
WHERE  rn = 1
ORDER BY NEWID();
GO

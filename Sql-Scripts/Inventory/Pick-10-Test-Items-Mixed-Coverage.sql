/* ============================================================================
   Pick 10 test items with MIXED coverage across the three updates, since no
   single item needs all three (Min/Max items already sit at safety_stock_type
   = 0; items needing the safety_stock_type fix are already on 'Up To' -- see
   the cross-tab check run alongside this).

   3 items focused on inv_min (the rare one -- grab what exists)
   4 items focused on replenishment_method
   3 items focused on safety_stock_type
   No item repeated across buckets.

   Run in: P21Dev.  READ-ONLY.
   ============================================================================ */
USE P21Dev;
GO

;WITH loc_flags AS (
    SELECT  il.inv_mast_uid,
            MAX(CASE WHEN il.replenishment_method <> 'Up To' OR il.replenishment_method IS NULL
                     THEN 1 ELSE 0 END) AS rm_change,
            MAX(CASE WHEN il.inv_min <> 0 OR il.inv_min IS NULL
                     THEN 1 ELSE 0 END) AS min_change,
            MAX(CASE WHEN il.safety_stock_type <> 0 OR il.safety_stock_type IS NULL
                     THEN 1 ELSE 0 END) AS sst_change
    FROM    dbo.inv_loc il
    WHERE   il.delete_flag = 'N'
    GROUP BY il.inv_mast_uid
), cand AS (
    SELECT  im.inv_mast_uid, im.item_id, im.default_product_group,
            f.rm_change, f.min_change, f.sst_change
    FROM    dbo.inv_mast im
    JOIN    loc_flags f ON f.inv_mast_uid = im.inv_mast_uid
    WHERE   im.delete_flag = 'N'
      AND   NULLIF(LTRIM(RTRIM(im.default_product_group)), '') IS NOT NULL
), min_picks AS (
    SELECT TOP (3) *, 'inv_min' AS test_focus
    FROM   cand WHERE min_change = 1
    ORDER BY NEWID()
), rm_picks AS (
    SELECT TOP (4) *, 'replenishment_method' AS test_focus
    FROM   cand
    WHERE  rm_change = 1
      AND  item_id NOT IN (SELECT item_id FROM min_picks)
    ORDER BY NEWID()
), sst_picks AS (
    SELECT TOP (3) *, 'safety_stock_type' AS test_focus
    FROM   cand
    WHERE  sst_change = 1
      AND  item_id NOT IN (SELECT item_id FROM min_picks)
      AND  item_id NOT IN (SELECT item_id FROM rm_picks)
    ORDER BY NEWID()
)
SELECT item_id, default_product_group, test_focus,
       rm_change, min_change, sst_change
FROM   min_picks
UNION ALL
SELECT item_id, default_product_group, test_focus,
       rm_change, min_change, sst_change
FROM   rm_picks
UNION ALL
SELECT item_id, default_product_group, test_focus,
       rm_change, min_change, sst_change
FROM   sst_picks
ORDER BY test_focus, item_id;
GO

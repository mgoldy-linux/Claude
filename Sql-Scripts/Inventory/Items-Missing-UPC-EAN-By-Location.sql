/*  Items-Missing-UPC-EAN-By-Location.sql
    --------------------------------------------------------------------------
    Find items with no item-level barcode, broken out by branch/location.

    Barcode field:  inv_mast.upc_or_ean_id  (varchar 15)  <- the actual number
                    inv_mast.upc_or_ean      (varchar 3)   <- "UPC"/"EAN" tag,
                                                              BLANK on every row
                                                              in P21 Prod, ignore it.

    Reality check (P21 Prod, 2026-09-01):
        upc_or_ean_id is empty on 130,061 of 138,505 active items (~94%).
        An unfiltered item x location list is essentially the whole catalog
        times every branch. Run the ROLLUP first, then decide how tight to
        make the detail extract with the filter block.

    Tables are all stock P21 (inv_mast / inv_loc / location) - no kb_/js_.
    inv_loc links to inv_mast by inv_mast_uid (+ location_id), not item_id.
    --------------------------------------------------------------------------  */

------------------------------------------------------------------------------
-- 1. ROLLUP -- missing-barcode item count by location, at four filter tiers
------------------------------------------------------------------------------
SELECT  l.location_id,
        l.location_name,
        COUNT(*)                                                        AS missing_all_loc_recs,
        SUM(CASE WHEN il.stockable = 'Y'          THEN 1 ELSE 0 END)    AS missing_stockable,
        SUM(CASE WHEN il.qty_on_hand <> 0         THEN 1 ELSE 0 END)    AS missing_with_qoh,
        SUM(CASE WHEN il.last_sale_date >= DATEADD(month, -12, GETDATE())
                 THEN 1 ELSE 0 END)                                     AS missing_sold_12mo
FROM    inv_mast im
JOIN    inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
JOIN    location l  ON l.location_id    = il.location_id  AND l.delete_flag  = 'N'
WHERE   im.delete_flag = 'N'
  AND   NULLIF(LTRIM(RTRIM(im.upc_or_ean_id)), '') IS NULL
GROUP BY l.location_id, l.location_name
ORDER BY missing_with_qoh DESC;


------------------------------------------------------------------------------
-- 2. DETAIL -- items and locations missing a barcode
--    Adjust the marked filter block for how strict a list you want.
------------------------------------------------------------------------------
SELECT  l.location_id,
        l.location_name,
        im.item_id,
        im.item_desc,
        im.class_id1,
        im.class_id2,
        il.qty_on_hand,
        il.stockable,
        il.sellable,
        il.discontinued,
        il.last_sale_date,
        il.last_purchase_date
FROM    inv_mast im
JOIN    inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
JOIN    location l  ON l.location_id    = il.location_id  AND l.delete_flag  = 'N'
WHERE   im.delete_flag = 'N'
  AND   NULLIF(LTRIM(RTRIM(im.upc_or_ean_id)), '') IS NULL
  /* -------- tighten as needed (remove lines for a fuller list) -------- */
  AND   il.stockable = 'Y'            -- item is stocked at this branch
  AND   il.qty_on_hand <> 0           -- only where there is stock on the shelf
  -- AND il.last_sale_date >= DATEADD(month, -12, GETDATE())   -- recently sold
  -- AND il.discontinued = 'N'
  /* ------------------------------------------------------------------- */
ORDER BY l.location_name, im.item_id;


------------------------------------------------------------------------------
-- 3. OPTIONAL -- "no barcode anywhere": also exclude items that at least have
--    a supplier-level UPC/EAN on inventory_supplier. Uncomment the NOT EXISTS.
------------------------------------------------------------------------------
-- SELECT l.location_name, im.item_id, im.item_desc, il.qty_on_hand
-- FROM   inv_mast im
-- JOIN   inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
-- JOIN   location l  ON l.location_id    = il.location_id  AND l.delete_flag  = 'N'
-- WHERE  im.delete_flag = 'N'
--   AND  NULLIF(LTRIM(RTRIM(im.upc_or_ean_id)), '') IS NULL
--   AND  NOT EXISTS (SELECT 1 FROM inventory_supplier isup
--                    WHERE isup.inv_mast_uid = im.inv_mast_uid
--                      AND (NULLIF(LTRIM(RTRIM(isup.upc_code)), '') IS NOT NULL
--                        OR NULLIF(LTRIM(RTRIM(isup.ean_code)), '') IS NOT NULL))
--   AND  il.stockable = 'Y' AND il.qty_on_hand <> 0
-- ORDER BY l.location_name, im.item_id;

/*  Perf note: the NULLIF(LTRIM(RTRIM())) test is not SARGable but only scans
    inv_mast (~150k rows) once; row volume comes from the inv_loc join, so the
    stockable / qty_on_hand / last_sale_date predicates are what keep it fast.
    No plan hints needed for an ad-hoc run.                                    */

/* ============================================================================
   Spot-check the safety_stock_type test list (CSV-In\Replenishment-Test\
   safety_stock_type.txt, built 2026-09-11) -- confirm these 10 items are
   still NOT already at safety_stock_type = 0 ("ABC Class") before using them
   as the native-import trace test set. List built two days ago; user flagged
   they're currently on "Days" -- this confirms the current DB state matches
   that expectation and the list is still a valid (non-no-op) test set.
   Run in: P21Dev.  READ-ONLY.
   ============================================================================ */
USE P21Dev;
GO

IF OBJECT_ID('tempdb..#items') IS NOT NULL DROP TABLE #items;
CREATE TABLE #items (item_id varchar(40) PRIMARY KEY);
INSERT INTO #items (item_id) VALUES
 ('CBHPPO125GB'),('HBF15035290'),('SCHSNS1D3TSSG'),('INPIPPFHSSANO'),('IVCQRTI60070'),
 ('IVCU3510195C731'),('WIC695767'),('INPIPSEEN5'),('IVC630239100648VT'),('ROPK72953P191');

SELECT im.item_id, il.location_id, il.safety_stock_type,
       CASE WHEN il.safety_stock_type = 0 THEN 'ALREADY 0 -- no-op for this item/location'
            ELSE 'would change' END AS test_status
FROM   dbo.inv_mast im
JOIN   dbo.inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
JOIN   #items t ON t.item_id = im.item_id
WHERE  im.delete_flag = 'N'
ORDER  BY im.item_id, il.location_id;
GO

-- Summary: are any of these 10 items now fully at 0 (no locations left to change)?
SELECT im.item_id,
       COUNT(*)                                              AS loc_rows,
       SUM(CASE WHEN il.safety_stock_type = 0 THEN 1 ELSE 0 END) AS loc_rows_already_0,
       SUM(CASE WHEN il.safety_stock_type <> 0 THEN 1 ELSE 0 END) AS loc_rows_would_change
FROM   dbo.inv_mast im
JOIN   dbo.inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
JOIN   #items t ON t.item_id = im.item_id
WHERE  im.delete_flag = 'N'
GROUP  BY im.item_id
ORDER  BY im.item_id;
GO

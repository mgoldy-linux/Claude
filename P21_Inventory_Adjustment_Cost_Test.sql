-- ============================================================
-- P21 Inventory Adjustment Costing - Test Queries
-- Purpose: Validate what cost P21 records during inventory
--          adjustments when on-hand = 0 and no receipt history
-- Tested in: Dev 202606, June 2026
-- ============================================================


-- ============================================================
-- STEP 1: Run BEFORE performing the adjustment
--         Snapshot the current cost state at each location
-- ============================================================
SELECT
    il.location_id,
    im.item_id,
    il.qty_on_hand,
    il.moving_average_cost,
    il.standard_cost            AS loc_standard_cost,
    il.future_standard_cost
FROM inv_loc il
INNER JOIN inv_mast im ON il.inv_mast_uid = im.inv_mast_uid
WHERE il.location_id IN (141, 340, 126, 183, 162, 220)
  AND im.item_id IN (
      'SCHKERDIFIX100G',
      'FDTT07-7512D',
      'GUN20450',
      'GUNCB-158WS',
      'TRADFF-1828CGR',
      'TRATXF-1836CGR',
      'MARNT680'
  )
ORDER BY im.item_id, il.location_id;


-- ============================================================
-- STEP 2: Perform the inventory adjustment in P21
--         Note the adjustment number assigned
-- ============================================================


-- ============================================================
-- STEP 3: Run AFTER saving the adjustment
--         Confirm what cost P21 actually recorded
--         Compare unit_cost here against Step 1 snapshot
-- ============================================================
SELECT TOP 50
    adj_no,
    location_id,
    item_id,
    qty,
    unit_cost,
    date_created
FROM inv_tran
WHERE item_id IN (
      'SCHKERDIFIX100G',
      'FDTT07-7512D',
      'GUN20450',
      'GUNCB-158WS',
      'TRADFF-1828CGR',
      'TRATXF-1836CGR',
      'MARNT680'
  )
  AND location_id IN (141, 340, 126, 183, 162, 220)
ORDER BY date_created DESC;


-- ============================================================
-- OPTIONAL: Look up a specific adjustment number directly
-- ============================================================
-- SELECT * FROM inv_tran WHERE adj_no = 'YOUR_ADJ_NUMBER';

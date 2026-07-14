/*==============================================================================
  Low Margin Alert — cost divergence & trigger-volume analysis
  Target : P21Play (P21Dev.allsurfaces.com)      READ ONLY — no writes
  Author : Mark Goldyn / Claude              Date: 2026-07-14

  WHY
  ---
  (1) Does oe_line.commission_cost actually equal MAC, as the config implies
      (commission_cost_flag = 2 = Moving Average)?  Where it does NOT, why not?
      Suspects: a cost page overrides it; UOM conversion; location mismatch.

  (2) Volume delta.  Today's trigger (line_item_profit_percentage < 5) resolves
      to margin off MAC for ~94% of users.  Evan wants an explicit MAC trigger
      AND a new STANDARD COST trigger.  How many more lines fire?

  THE TRAP THIS AVOIDS
  --------------------
  inv_loc costs are per STOCKING (base) unit; oe_line costs and unit_price are
  per PRICING unit.  Compared raw, every mixed-UOM line looks broken.  Convert
  first — mirroring kb_fn_pricing_convert (amount / from_size * to_size), but
  SET-BASED off p21_view_item_uom instead of the kb_ scalar UDF.
==============================================================================*/

USE P21Play;
GO

SET NOCOUNT ON;

DECLARE @days INT = 90;   -- rolling window

IF OBJECT_ID('tempdb..#calc') IS NOT NULL DROP TABLE #calc;

SELECT
      l.order_no
    , l.line_no
    , im.item_id
    , im.base_unit
    , l.unit_of_measure                        AS pricing_unit
    , l.unit_price
    , l.pricing_unit_size
    , uom_base.unit_size                       AS base_unit_size
    , uom_price.unit_size                      AS price_unit_size
    , l.commission_cost
    , l.sales_cost
    , il.standard_cost                         AS std_cost_stocking
    , il.moving_average_cost                   AS mac_stocking
    , has_cost_page  = CASE WHEN COALESCE(l.cost_price_page_uid,0) <> 0 THEN 1 ELSE 0 END
    , has_price_page = CASE WHEN COALESCE(l.price_page_uid,0)      <> 0 THEN 1 ELSE 0 END
    , uom_differs    = CASE WHEN im.base_unit <> l.unit_of_measure      THEN 1 ELSE 0 END
    , loc_differs    = CASE WHEN h.location_id <> l.source_loc_id       THEN 1 ELSE 0 END
    , mac_zero       = CASE WHEN COALESCE(il.moving_average_cost,0) = 0 THEN 1 ELSE 0 END
    -- Costs converted from the base unit into the line's PRICING unit.
    -- NB: the target size is oe_line.pricing_unit_size, NOT the item_uom size of
    -- unit_of_measure.  P21's ORDER unit and PRICING unit are different things:
    -- e.g. KARVGW86T is ordered in PA (2100 SF) but priced per SF
    -- (pricing_unit_size = 1).  Using the order UOM inflates cost 2100x.
    , std_cost_conv  = CAST(il.standard_cost       / NULLIF(uom_base.unit_size,0) * l.pricing_unit_size AS DECIMAL(19,4))
    , mac_conv       = CAST(il.moving_average_cost / NULLIF(uom_base.unit_size,0) * l.pricing_unit_size AS DECIMAL(19,4))
    -- diagnostic: how often does the ORDER uom size differ from the PRICING size?
    , uom_lookup_mismatch = CASE WHEN ABS(COALESCE(uom_price.unit_size,0) - COALESCE(l.pricing_unit_size,0)) > 0.0001
                                 THEN 1 ELSE 0 END
    -- sanity: base unit should always have unit_size = 1
    , base_size_not_1 = CASE WHEN ABS(COALESCE(uom_base.unit_size,1) - 1) > 0.0001 THEN 1 ELSE 0 END
INTO #calc
FROM        oe_hdr  h
INNER JOIN  oe_line l   ON l.order_no      = h.order_no
INNER JOIN  inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
INNER JOIN  inv_loc  il ON il.inv_mast_uid = l.inv_mast_uid
                       AND il.location_id  = l.source_loc_id      -- use_sales_loc_for_source_costs = N
LEFT  JOIN  p21_view_item_uom uom_base
                        ON uom_base.inv_mast_uid    = im.inv_mast_uid
                       AND uom_base.unit_of_measure = im.base_unit
                       AND uom_base.delete_flag     = 'N'
LEFT  JOIN  p21_view_item_uom uom_price
                        ON uom_price.inv_mast_uid    = im.inv_mast_uid
                       AND uom_price.unit_of_measure = l.unit_of_measure
                       AND uom_price.delete_flag     = 'N'
WHERE   h.order_date  >= DATEADD(DAY, -@days, GETDATE())
  AND   h.delete_flag  = 'N'
  AND   l.delete_flag  = 'N'
  AND   l.product_group_id NOT IN ('OCHARGE','SAMPLES','PAD')   -- "supplies", per the live alert
  AND   COALESCE(h.taker,'') NOT LIKE '%ESTORE%'                -- per the live alert
  AND   l.unit_price > 0;                                       -- margin undefined at price 0

-- margins + the divergence measure
ALTER TABLE #calc ADD gm_existing DECIMAL(19,2), gm_mac DECIMAL(19,2), gm_std DECIMAL(19,2), mac_delta DECIMAL(19,4);
GO
UPDATE #calc
SET   gm_existing = CAST((unit_price - commission_cost) / NULLIF(unit_price,0) * 100 AS DECIMAL(19,2))
    , gm_mac      = CAST((unit_price - mac_conv)        / NULLIF(unit_price,0) * 100 AS DECIMAL(19,2))
    , gm_std      = CAST((unit_price - std_cost_conv)   / NULLIF(unit_price,0) * 100 AS DECIMAL(19,2))
    , mac_delta   = CAST(ABS(commission_cost - mac_conv) AS DECIMAL(19,4));
GO

SELECT '=== 0. population ===' AS report, COUNT(*) AS lines_in_scope FROM #calc;

/*--- 1. Does commission_cost == converted MAC?  With the suspected causes ---*/
SELECT '=== 1. commission_cost vs converted MAC ===' AS report;

SELECT
      bucket = CASE WHEN mac_delta IS NULL THEN '4. NULL (missing uom or cost)'
                    WHEN mac_delta = 0     THEN '1. exact match'
                    WHEN mac_delta <= 0.01 THEN '2. within a penny'
                    ELSE                        '3. MATERIALLY DIFFERENT'
               END
    , lines          = COUNT(*)
    , pct            = CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2))
    , w_cost_page    = SUM(has_cost_page)
    , w_price_page   = SUM(has_price_page)
    , w_uom_differs  = SUM(uom_differs)
    , w_loc_differs  = SUM(loc_differs)
    , w_mac_zero     = SUM(mac_zero)
    , w_uom_mismatch = SUM(uom_lookup_mismatch)
    , w_base_not_1   = SUM(base_size_not_1)
    , max_delta      = MAX(mac_delta)
FROM #calc
GROUP BY CASE WHEN mac_delta IS NULL THEN '4. NULL (missing uom or cost)'
              WHEN mac_delta = 0     THEN '1. exact match'
              WHEN mac_delta <= 0.01 THEN '2. within a penny'
              ELSE                        '3. MATERIALLY DIFFERENT'
         END
ORDER BY bucket;

/*--- 2. Trigger volume: how many lines fire under each rule? ---*/
SELECT '=== 2. trigger volume (< 5%) ===' AS report;

SELECT
      total_lines        = COUNT(*)
    , fire_existing      = SUM(CASE WHEN gm_existing < 5 THEN 1 ELSE 0 END)
    , fire_mac           = SUM(CASE WHEN gm_mac      < 5 THEN 1 ELSE 0 END)
    , fire_std           = SUM(CASE WHEN gm_std      < 5 THEN 1 ELSE 0 END)
    , fire_either_new    = SUM(CASE WHEN gm_mac < 5 OR gm_std < 5 THEN 1 ELSE 0 END)
    -- overlap between today's alert and each new one
    , existing_and_mac   = SUM(CASE WHEN gm_existing < 5 AND gm_mac < 5 THEN 1 ELSE 0 END)
    , existing_not_mac   = SUM(CASE WHEN gm_existing < 5 AND (gm_mac >= 5 OR gm_mac IS NULL) THEN 1 ELSE 0 END)
    , mac_not_existing   = SUM(CASE WHEN gm_mac < 5 AND (gm_existing >= 5 OR gm_existing IS NULL) THEN 1 ELSE 0 END)
    , std_not_existing   = SUM(CASE WHEN gm_std < 5 AND (gm_existing >= 5 OR gm_existing IS NULL) THEN 1 ELSE 0 END)
FROM #calc;

/*--- 3. Hand-pick candidates for the Sales Margins tab reconciliation ---*/
SELECT '=== 3. reconciliation candidates (mixed UOM, then loc-differs) ===' AS report;

SELECT TOP 20
      order_no, line_no, item_id
    , base_unit, pricing_unit, base_unit_size, price_unit_size, pricing_unit_size
    , unit_price, std_cost_stocking, std_cost_conv, mac_stocking, mac_conv
    , commission_cost, gm_existing, gm_mac, gm_std
    , has_cost_page, uom_differs, loc_differs, uom_lookup_mismatch
FROM #calc
WHERE uom_differs = 1
ORDER BY loc_differs DESC, has_cost_page DESC, ABS(mac_delta) DESC;

DROP TABLE #calc;
GO

/*==============================================================================
  Analyze-Price-Override-Detection.sql          READ-ONLY. Run in SSMS vs P21.

  Purpose: answer Evan Jenkins' 2026-09-04 ask on the Low Margin Alert --
           "show both where the original price calculated from AND whether
            that price was overridden on the order."

  Background: P21 already stores BOTH halves on oe_line. Nothing needs to be
  derived by re-running the pricing engine:

      oe_line.manual_price_overide    -- 'Y' when a user edited the price
                                      -- NOTE: P21's own misspelling (one 'r').
                                      --       Do NOT "correct" it.
      oe_line.system_calc_unit_price  -- what P21 calculated before the edit

  And manual_price_overide is ALREADY exposed in the live alert view
  dbo.p21_view_alert_oe_OrderEntry as the column 'price_edit' -- stock P21, it
  predates every change this project made (see ROLLBACK-...-BEFORE.sql line 82).

  Q1  Confirm the mechanism on Evan's actual order (6132881).
  Q2  Is 'price_edit' already a registered alert token? (decides the effort)
  Q3  Is the flag trustworthy? Measure it against the price comparison.
==============================================================================*/
USE P21;
GO
SET NOCOUNT ON;

/*------------------------------------------------------------------ Q1 -----
  Evan's order. Expect: manual_price_overide = 'Y', unit_price 2.54,
  system_calc_unit_price = whatever the price page produced, and a still-
  populated price_page_uid (which is why the description kept showing).
---------------------------------------------------------------------------*/
PRINT '=== Q1: order 6132881 ===';
SELECT  ol.order_no
      , ol.line_no
      , im.item_id
      , ol.unit_price
      , ol.system_calc_unit_price
      , ol.manual_price_overide
      , price_diff = CAST(ISNULL(ol.system_calc_unit_price,0) - ISNULL(ol.unit_price,0) AS DECIMAL(19,4))
      , ol.price_page_uid
      , price_page_desc = pp.description
      , ol.pricing_unit_size
      , ol.unit_of_measure
      , ol.pricing_unit
FROM        dbo.oe_line    ol
LEFT JOIN   dbo.inv_mast   im ON im.inv_mast_uid  = ol.inv_mast_uid
LEFT JOIN   dbo.price_page pp ON pp.price_page_uid = ol.price_page_uid
WHERE       ol.order_no = '6132881';
GO

/*------------------------------------------------------------------ Q2 -----
  If price_edit is already registered on alert_type_uid 12, adding
  "Price Overridden" to the email body is a body-text edit only -- no view
  change, no token registration, no deploy script.
---------------------------------------------------------------------------*/
PRINT '=== Q2: existing price-related tokens on the OE alert type (12) ===';
SELECT  t.token_uid
      , t.name
      , t.description
      , t.available_areas          -- 4 = line-item body (per this project's notes)
      , t.data_type_cd
FROM        dbo.token              t
JOIN        dbo.alert_type_x_token x ON x.token_uid = t.token_uid
WHERE       x.alert_type_uid = 12
  AND      (t.name LIKE '%price%' OR t.name LIKE '%edit%' OR t.name LIKE '%overid%')
ORDER BY    t.name;
GO

/*------------------------------------------------------------------ Q3 -----
  Reliability. The whole recommendation rests on the flag being set whenever a
  price is actually edited. Cross-tab the flag against the stored
  system-calculated price over 120 days.

  flagY_and_differs : flag set AND prices differ   -> flag working
  flagY_but_same    : flag set, prices match       -> edited then re-matched, or
                                                      flag set by other means
  flagN_but_differs : prices differ, flag NOT set  -> flag alone would MISS these
  syscalc_null/zero : comparison impossible on these rows
---------------------------------------------------------------------------*/
PRINT '=== Q3a: flag vs price comparison, all lines, 120 days ===';
SELECT  lines_total         = COUNT(*)
      , flag_Y              = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') = 'Y' THEN 1 ELSE 0 END)
      , price_differs       = SUM(CASE WHEN ROUND(ISNULL(ol.system_calc_unit_price,0),2) <> ROUND(ISNULL(ol.unit_price,0),2) THEN 1 ELSE 0 END)
      , flagY_and_differs   = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') = 'Y'
                                        AND ROUND(ISNULL(ol.system_calc_unit_price,0),2) <> ROUND(ISNULL(ol.unit_price,0),2) THEN 1 ELSE 0 END)
      , flagY_but_same      = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') = 'Y'
                                        AND ROUND(ISNULL(ol.system_calc_unit_price,0),2)  = ROUND(ISNULL(ol.unit_price,0),2) THEN 1 ELSE 0 END)
      , flagN_but_differs   = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') <> 'Y'
                                        AND ROUND(ISNULL(ol.system_calc_unit_price,0),2) <> ROUND(ISNULL(ol.unit_price,0),2) THEN 1 ELSE 0 END)
      , syscalc_null        = SUM(CASE WHEN ol.system_calc_unit_price IS NULL THEN 1 ELSE 0 END)
      , syscalc_zero        = SUM(CASE WHEN ol.system_calc_unit_price = 0     THEN 1 ELSE 0 END)
      , has_price_page      = SUM(CASE WHEN ISNULL(ol.price_page_uid,0) <> 0 THEN 1 ELSE 0 END)
      , flagY_AND_pricepage = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') = 'Y'
                                        AND ISNULL(ol.price_page_uid,0) <> 0 THEN 1 ELSE 0 END)  -- the 6132881 shape
FROM        dbo.oe_line ol
WHERE       ol.date_created >= DATEADD(DAY, -120, GETDATE());
GO

/*  Same measurement narrowed to the population the ALERT actually emails on
    (low margin), since that is the only place the new line would appear.     */
PRINT '=== Q3b: same, but only lines that would trip the low-margin alert ===';
SELECT  lines_total       = COUNT(*)
      , flag_Y            = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') = 'Y' THEN 1 ELSE 0 END)
      , flagY_and_differs = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') = 'Y'
                                      AND ROUND(ISNULL(ol.system_calc_unit_price,0),2) <> ROUND(ISNULL(ol.unit_price,0),2) THEN 1 ELSE 0 END)
      , flagN_but_differs = SUM(CASE WHEN COALESCE(ol.manual_price_overide,'N') <> 'Y'
                                      AND ROUND(ISNULL(ol.system_calc_unit_price,0),2) <> ROUND(ISNULL(ol.unit_price,0),2) THEN 1 ELSE 0 END)
FROM        dbo.oe_line ol
JOIN        dbo.inv_loc il ON il.inv_mast_uid = ol.inv_mast_uid
                          AND il.location_id  = ol.source_loc_id
WHERE       ol.date_created >= DATEADD(DAY, -120, GETDATE())
  AND       ISNULL(ol.unit_price,0) <> 0
  AND     ( (ol.unit_price - COALESCE(il.moving_average_cost * ol.pricing_unit_size,0)) / ol.unit_price * 100 < 5
         OR (ol.unit_price - COALESCE(il.standard_cost       * ol.pricing_unit_size,0)) / ol.unit_price * 100 < 5 );
GO

/*  Sample rows for eyeballing the flagN_but_differs bucket. If this bucket is
    large, the flag alone is not enough, and the email should carry BOTH the
    flag and the system-calculated price so a human can see the delta.        */
PRINT '=== Q3c: sample of prices that differ with the flag NOT set ===';
SELECT TOP (25)
        ol.order_no, ol.line_no, im.item_id
      , ol.unit_price, ol.system_calc_unit_price, ol.manual_price_overide
      , ol.price_page_uid, ol.date_created
FROM        dbo.oe_line  ol
LEFT JOIN   dbo.inv_mast im ON im.inv_mast_uid = ol.inv_mast_uid
WHERE       ol.date_created >= DATEADD(DAY, -120, GETDATE())
  AND       COALESCE(ol.manual_price_overide,'N') <> 'Y'
  AND       ROUND(ISNULL(ol.system_calc_unit_price,0),2) <> ROUND(ISNULL(ol.unit_price,0),2)
  AND       ISNULL(ol.system_calc_unit_price,0) <> 0
ORDER BY    ol.date_created DESC;

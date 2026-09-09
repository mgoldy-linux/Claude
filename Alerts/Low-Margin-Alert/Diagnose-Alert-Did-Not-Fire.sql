/*==============================================================================
  Diagnose-Alert-Did-Not-Fire.sql        READ-ONLY. Run in SSMS vs P21Play.

  Why: test order 6062439 did not produce a Low Margin alert. Rather than guess,
  this evaluates EVERY clause of the Team alert's where_clause against the order,
  reconstructed from the view's own expressions (script 07), plus the joins that
  can silently drop rows.

  The view CANNOT be queried directly for an already-processed order -- it is
  INNER JOINed to the transient `pending_alerts` queue, so it returns 0 rows.
  Everything below is rebuilt against base tables.

  Team alert where_clause:
     low_margin_flag = 'Y' AND new_order = 'Y' AND total_amount > 1000
     AND corp_address_id <> 1046538
     AND product_group_id NOT IN ('OCHARGE','SAMPLES','PAD')
     AND customer_id NOT IN (3021352,3023035,3023036)
     AND taker NOT LIKE '%ESTORE%' AND extended_standard_cost > '500'
     AND rma_flag <> 'Y'

  Change @order to reuse this on any future non-firing order.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;
DECLARE @order VARCHAR(20) = '6062439';

/*------------------------------------------------------------------ D1 -----
  HEADER-LEVEL clauses. Any FAIL here kills the whole order, every line.

  NOTE on new_order: the view computes it as
      date_last_modified = date_created  OR  ABS(DATEDIFF(s, date_last_modified, order_date)) < 2
  so an order that was SAVED and then EDITED AGAIN flips to 'N' and can never
  alert. This is the single most likely cause when a hand-built test order that
  "looks right" does not fire.
---------------------------------------------------------------------------*/
PRINT '=== D1: header-level clauses ===';
SELECT  h.order_no
      , h.customer_id
      , customer_name   = ac.name
      , corp_address_id = COALESCE(ac.corp_address_id, 0)
      , chk_corp_addr   = CASE WHEN COALESCE(ac.corp_address_id,0) <> 1046538 THEN 'pass' ELSE 'FAIL (Empire Today exclusion)' END
      , chk_customer    = CASE WHEN h.customer_id NOT IN (3021352,3023035,3023036) THEN 'pass' ELSE 'FAIL (excluded customer)' END
      , taker_name      = COALESCE(ut.name,'')
      , chk_taker       = CASE WHEN COALESCE(ut.name,'') NOT LIKE '%ESTORE%' THEN 'pass' ELSE 'FAIL (ESTORE taker)' END
      , h.rma_flag
      , chk_rma         = CASE WHEN ISNULL(h.rma_flag,'') <> 'Y' THEN 'pass' ELSE 'FAIL (RMA)' END
      , h.date_created, h.date_last_modified, h.order_date
      , new_order       = CASE WHEN (h.date_last_modified = h.date_created)
                                 OR (ABS(DATEDIFF(s, h.date_last_modified, h.order_date)) < 2)
                               THEN 'Y' ELSE 'N' END
      , chk_new_order   = CASE WHEN (h.date_last_modified = h.date_created)
                                 OR (ABS(DATEDIFF(s, h.date_last_modified, h.order_date)) < 2)
                               THEN 'pass' ELSE 'FAIL (order was edited after it was first saved)' END
      , total_amount    = (SELECT CAST(SUM(ROUND((l2.unit_price * (l2.qty_ordered - l2.qty_canceled))
                                                 / NULLIF(l2.pricing_unit_size,0), 2)) AS DECIMAL(19,2))
                           FROM dbo.oe_line l2 WHERE l2.order_no = h.order_no)
      , chk_total       = CASE WHEN (SELECT SUM(ROUND((l2.unit_price * (l2.qty_ordered - l2.qty_canceled))
                                                      / NULLIF(l2.pricing_unit_size,0), 2))
                                     FROM dbo.oe_line l2 WHERE l2.order_no = h.order_no) > 1000
                               THEN 'pass' ELSE 'FAIL (order total <= 1000)' END
      , primary_reps    = (SELECT COUNT(*) FROM dbo.oe_hdr_salesrep sr
                           WHERE sr.order_number = h.order_no AND sr.primary_salesrep = 'Y')
      , chk_primary_rep = CASE WHEN EXISTS (SELECT 1 FROM dbo.oe_hdr_salesrep sr
                                            WHERE sr.order_number = h.order_no AND sr.primary_salesrep = 'Y')
                               THEN 'pass' ELSE 'FAIL (no primary salesrep - INNER JOIN drops the whole order)' END
FROM        dbo.oe_hdr  h
LEFT JOIN   dbo.address ac ON ac.id = h.customer_id
LEFT JOIN   dbo.users   ut ON ut.id = h.taker
WHERE       h.order_no = @order;
GO

/*------------------------------------------------------------------ D2 -----
  LINE-LEVEL clauses. A line must pass ALL of these to appear in the email.
  extended_standard_cost is NOT simply qty * standard_cost -- the view uses
      standard_cost / pricing_unit_size * unit_quantity * unit_size
---------------------------------------------------------------------------*/
DECLARE @order2 VARCHAR(20) = '6062439';
PRINT '=== D2: line-level clauses ===';
SELECT  l.line_no
      , im.item_id
      , im.product_type
      , chk_product_type = CASE WHEN im.product_type <> 'B' THEN 'pass' ELSE 'FAIL (subtotal item, excluded)' END
      , l.product_group_id
      , chk_prod_group   = CASE WHEN ISNULL(l.product_group_id,'') NOT IN ('OCHARGE','SAMPLES','PAD') THEN 'pass' ELSE 'FAIL' END
      , l.supplier_id
      , chk_supplier     = CASE WHEN EXISTS (SELECT 1 FROM dbo.supplier s WHERE s.supplier_id = l.supplier_id)
                                THEN 'pass' ELSE 'FAIL (no supplier row - INNER JOIN drops this line)' END
      , l.source_loc_id
      , chk_inv_loc      = CASE WHEN il.inv_mast_uid IS NOT NULL THEN 'pass' ELSE 'FAIL (no inv_loc at source_loc_id)' END
      , l.unit_price
      , l.manual_price_overide
      , l.price_page_uid
      , il.moving_average_cost
      , il.standard_cost
      , l.pricing_unit_size, l.unit_quantity, l.unit_size
      , ext_std_cost     = CAST(COALESCE(il.standard_cost / NULLIF(l.pricing_unit_size,0)
                                         * l.unit_quantity * l.unit_size, 0) AS DECIMAL(19,2))
      , chk_ext_std      = CASE WHEN CAST(COALESCE(il.standard_cost / NULLIF(l.pricing_unit_size,0)
                                                   * l.unit_quantity * l.unit_size, 0) AS DECIMAL(19,2)) > 500
                                THEN 'pass' ELSE 'FAIL (extended_standard_cost <= 500)' END
      , pct_off_mac      = CAST(CASE WHEN ISNULL(l.unit_price,0) = 0 THEN 0
                                     ELSE (l.unit_price - COALESCE(il.moving_average_cost * l.pricing_unit_size,0))
                                          / l.unit_price * 100 END AS DECIMAL(19,2))
      , pct_off_std      = CAST(CASE WHEN ISNULL(l.unit_price,0) = 0 THEN 0
                                     ELSE (l.unit_price - COALESCE(il.standard_cost * l.pricing_unit_size,0))
                                          / l.unit_price * 100 END AS DECIMAL(19,2))
      , low_margin_flag  = CASE WHEN ISNULL(l.unit_price,0) = 0 THEN 'N'
                                WHEN (l.unit_price - COALESCE(il.moving_average_cost * l.pricing_unit_size,0)) / l.unit_price * 100 < 5
                                  OR (l.unit_price - COALESCE(il.standard_cost       * l.pricing_unit_size,0)) / l.unit_price * 100 < 5
                                THEN 'Y' ELSE 'N' END
FROM        dbo.oe_line  l
JOIN        dbo.inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
LEFT JOIN   dbo.inv_loc  il ON il.inv_mast_uid = l.inv_mast_uid
                           AND il.location_id  = l.source_loc_id
WHERE       l.order_no = @order2
ORDER BY    l.line_no;
GO

/*------------------------------------------------------------------ D3 -----
  Did the alert GENERATE but fail to deliver? A row stuck at row_status_flag
  1063 ("Email Pending") reads exactly like "never fired" from the inbox.
---------------------------------------------------------------------------*/
PRINT '=== D3: alert_queued_mail (should normally be empty) ===';
SELECT * FROM dbo.alert_queued_mail;
GO

/*------------------------------------------------------------------ D4 -----
  Has the LIVE where_clause drifted from what the deploy script built -- e.g.
  did a "Price Edit equals Yes" filter row get added in the client? That would
  restrict the alert to overridden lines only.
---------------------------------------------------------------------------*/
PRINT '=== D4: live where_clause + filter rows on the four alerts ===';
SELECT  ai.alert_implementation_uid
      , ai.alert_implementation_name
      , ai.row_status_flag
      , ai.execution_mode_cd
      , ai.last_execution_error
      , ai.where_clause
      , filter_rows = (SELECT COUNT(*) FROM dbo.Alert_implementation_query q
                       WHERE q.alert_implementation_uid = ai.alert_implementation_uid)
FROM    dbo.alert_implementation ai
WHERE   ai.alert_implementation_name LIKE '%Margin%'
ORDER BY ai.alert_implementation_name;
GO

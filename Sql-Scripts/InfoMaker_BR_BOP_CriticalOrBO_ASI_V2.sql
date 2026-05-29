-- ============================================================
-- Portal: Purchasing BOP Supplier Summary (InfoMaker)
-- SA 45138: Added bo_orders and critical_orders columns; ABOEVE/PDUNDAS see all buyers (V2)
-- ============================================================

DECLARE @user_id  AS VARCHAR(20) = '<user_id>'
DECLARE @buyer_id AS INTEGER
SET @buyer_id = (SELECT contact_id FROM p21_view_users WHERE id = @user_id)


; WITH item_req_cte (location_id, inv_mast_uid, item_id, product_group_id, price_family_id, buyer_id, buyer, stockable, qty_on_hand, qty_allocated, qty_bo, qty_reserved, qty_quarantined, qty_pending, qty_transfer_in, po_qty, net_avail, inv_min, forecast_usage, daily_usage, upto, review_cycle, lead_time, safety_stock, supplier_id, supplier_name, purchase_unit, purchase_unit_size, weight, bo_count)

AS
 (
        SELECT
            l.location_id
            , l.inv_mast_uid
            , l.item_id
            , l.product_group_id
            , m.default_price_family_uid
            , c.id buyer_id
            , c.contact_name buyer
            , l.stockable
            , l.qty_on_hand
            , l.qty_allocated
            , l.qty_backordered
            , l.qty_reserved_due_in
            , ISNULL(s.qty_quarantined,0) qty_quarantined
            , pending.qty_pending
            , l.qty_in_transit
            , l.order_quantity
            , l.qty_on_hand - l.qty_allocated - qty_backordered - qty_reserved_due_in - ISNULL(s.qty_quarantined,0) + ISNULL(qty_pending, 0) + l.qty_in_transit + l.order_quantity net_avail
            , l.inv_min
            , ISNULL(f.forecast_usage,0) forecast_usage
            , ISNULL(f.forecast_usage,0) / DAY(EOMONTH(GETDATE())) daily_usage
            , ISNULL(f.forecast_usage,0) / DAY(EOMONTH(GETDATE())) * (COALESCE(ls.review_cycle, supplier.review_cycle,0) + COALESCE(manual_lead_time, sl.average_lead_time, supplier.average_lead_time, 0) + COALESCE(l.safety_stock, supplier.safety_stock_days,0)) UpTo
            , supplier.review_cycle
            , sl.manual_lead_time
            , l.safety_stock
            , sup.supplier_id
            , supplier.supplier_name
            , uom.unit_of_measure purchase_unit
            , uom.unit_size purchase_unit_size
            , m.net_weight
            , CASE
                WHEN qty_backordered > 0 THEN 1
                ELSE 0
              END AS bo_count
        FROM p21_view_inv_loc l
            LEFT JOIN p21_view_inv_loc_stock_status s
                ON l.location_id = s.location_id
                    and l.inv_mast_uid = s.inv_mast_uid
            INNER JOIN p21_view_inv_mast m
                ON l.inv_mast_uid = m.inv_mast_uid
                    and m.delete_flag = 'n'
            INNER JOIN p21_view_inventory_supplier sup
                ON sup.inv_mast_uid = l.inv_mast_uid
            INNER JOIN p21_view_inventory_supplier_x_loc sl
                ON sl.inventory_supplier_uid = sup.inventory_supplier_uid
                    and sl.location_id = l.location_id
                    and sl.primary_supplier = 'y'
            INNER JOIN p21_view_supplier supplier
                ON sup.supplier_id = supplier.supplier_id
               LEFT JOIN p21_view_location_supplier ls
                ON l.location_id = ls.location_id
                    and l.primary_supplier_id = ls.supplier_id
                    and ls.delete_flag = 'N'
            LEFT JOIN (
                        SELECT
                            u.demand_period_uid
                            , u.inv_mast_uid
                            , u.location_id
                            , d.year_for_period
                            , d.period
                            , u.forecast_usage
                        FROM p21_view_inv_period_usage u
                            LEFT JOIN p21_view_demand_period d
                                ON d.demand_period_uid = u.demand_period_uid
                        WHERE
                            d.year_for_period = YEAR(GETDATE())
                            and d.period = MONTH(GETDATE())
                        ) f
                ON l.inv_mast_uid = f.inv_mast_uid
                    and l.location_id = f.location_id
            LEFT JOIN p21_view_contacts c
                ON supplier.buyer_id = c.id
            INNER JOIN p21_view_item_uom uom
                ON m.default_purchasing_unit = uom.unit_of_measure
                    AND m.inv_mast_uid = uom.inv_mast_uid
            LEFT JOIN (
                        SELECT
                            l.source_loc_id loc_id
                            , l.inv_mast_uid
                            , l.item_id
                            , SUM(l.qty_ordered - l.qty_allocated - l.qty_on_pick_tickets - l.qty_invoiced - l.qty_canceled) qty_pending
                        FROM p21_view_oe_line l
                            INNER JOIN p21_view_oe_hdr h
                                ON l.order_No = h.order_no
                            INNER JOIN p21_view_inv_loc loc
                                ON l.source_loc_id = loc.location_id
                                    and l.inv_mast_uid = loc.inv_mast_uid
                        WHERE
                            (    loc.stockable = 'n' AND h.validation_status = 'Hold' AND l.complete = 'n'
                                AND ISNULL(l.product_group_id,'') NOT IN ('ocharge','samples') AND l.disposition = 'B'
                            ) OR (
                                h.approved = 'n' AND l.delete_flag = 'n' AND l.complete = 'n'
                                AND ISNULL(l.product_group_id,'') NOT IN ('ocharge','samples') AND l.disposition = 'B'
                            )
                        GROUP BY
                            l.source_loc_id
                            , l.inv_mast_uid
                            , l.item_id
                        ) pending
                ON l.location_id = pending.loc_id
                    and l.inv_mast_uid = pending.inv_mast_uid

        WHERE
            l.discontinued = 'n'
            and ISNULL(l.location_id,0) not in (102,1047269,143,144)
            and (l.stockable = 'y' or (l.stockable = 'n' and qty_backordered > 0) or (l.stockable = 'n' and qty_on_hand = 0 and ((qty_backordered + qty_allocated)> 0)))
            and ISNULL(l.product_group_id,'') not in ('ocharge','samples')
            AND (@user_id IN ('ABOEVE','PDUNDAS') OR c.id = @buyer_id OR c.id IS NULL)

    )  ,


max_cte (location_id, supplier_id, supplier_name, inv_mast_uid, item_id, weight, product_group_id, price_family_id, buyer, bo_count, critical, max_op)

AS
(
        SELECT
            location_id
            , supplier_id
            , supplier_name
            , inv_mast_uid
            , item_id
            , weight
            , product_group_id
            , price_family_id
            , buyer
            , bo_count
            , CASE
                WHEN --qty_bo > (qty_on_hand + po_qty + qty_transfer_in + ISNULL(qty_pending,0) - qty_reserved - qty_allocated - qty_quarantined) THEN 1
                    net_avail < 0 THEN 1
                ELSE 0
              END AS critical
            , CASE
                WHEN UpTo >= inv_min THEN UpTo
                ELSE inv_min
             END AS max_op
        FROM item_req_cte
        WHERE
            net_avail < (SELECT MAX (OP) FROM (VALUES(inv_min), (upto)) AS MaxVal(OP))
            AND (((SELECT MAX (OP) FROM (VALUES(inv_min), (upto)) AS MaxVal(OP)) - net_avail) / purchase_unit_size) + .75 > 1
            OR (qty_bo > (qty_on_hand + po_qty + qty_transfer_in + ISNULL(qty_pending,0) - qty_reserved - qty_allocated - qty_quarantined))
    ) ,


-- SA 45138: bo_orders_cte — open BO sales order numbers for items with qty_backordered > 0
-- New column: bo_orders
bo_orders_cte (location_id, supplier_id, bo_orders)

AS
(
        SELECT
            location_id
            , supplier_id
            , STRING_AGG(CAST(order_no AS VARCHAR(20)), ', ')
                WITHIN GROUP (ORDER BY order_no) AS bo_orders
        FROM (
            SELECT DISTINCT
                i.location_id
                , i.supplier_id
                , ol.order_no
            FROM item_req_cte i
                INNER JOIN max_cte mx
                    ON i.inv_mast_uid = mx.inv_mast_uid
                        AND i.location_id = mx.location_id
                INNER JOIN p21_view_oe_line ol
                    ON ol.inv_mast_uid = i.inv_mast_uid
                        AND ol.source_loc_id = i.location_id
                INNER JOIN p21_view_oe_hdr oh
                    ON ol.order_no = oh.order_no
            WHERE
                i.qty_bo > 0
                AND (ol.disposition IN ('B', 'T') OR ol.disposition IS NULL)
                AND ol.complete = 'n'
                AND ol.delete_flag = 'n'
            ) deduped
        GROUP BY
            location_id
            , supplier_id
    ) ,


-- SA 45138: critical_orders_cte — open BO sales order numbers for items with net_avail < 0
-- New column: critical_orders
critical_orders_cte (location_id, supplier_id, critical_orders)

AS
(
        SELECT
            location_id
            , supplier_id
            , STRING_AGG(CAST(order_no AS VARCHAR(20)), ', ')
                WITHIN GROUP (ORDER BY order_no) AS critical_orders
        FROM (
            SELECT DISTINCT
                i.location_id
                , i.supplier_id
                , ol.order_no
            FROM item_req_cte i
                INNER JOIN max_cte mx
                    ON i.inv_mast_uid = mx.inv_mast_uid
                        AND i.location_id = mx.location_id
                INNER JOIN p21_view_oe_line ol
                    ON ol.inv_mast_uid = i.inv_mast_uid
                        AND ol.source_loc_id = i.location_id
                INNER JOIN p21_view_oe_hdr oh
                    ON ol.order_no = oh.order_no
            WHERE
                i.net_avail < 0
                AND (ol.disposition IN ('B', 'T') OR ol.disposition IS NULL)
                AND ol.complete = 'n'
                AND ol.delete_flag = 'n'
            ) deduped
        GROUP BY
            location_id
            , supplier_id
    ) ,


last_po_cte (location_id, location_name, supplier_id, last_po)

AS
(
        SELECT
            location_id
            , a.name location_name
            , supplier_id
            , MAX(h.date_created) last_po
        FROM p21_view_po_hdr h
            INNER JOIN p21_view_address a
                ON h.location_id = a.id
        WHERE
            po_type <> 'D'
            AND h.delete_flag = 'n'

        GROUP BY
            location_id
            , supplier_id
            , a.name
    )


SELECT
    m.location_id
    , m.supplier_id
    , m.supplier_name
    , m.buyer
    , COUNT(m.inv_mast_uid) num_of_items
    --, FORMAT(SUM(FLOOR((((max_op - net_avail) / purchase_unit_size) +.75)) * c.weight * purchase_unit_size), 'N0') total_weight
     , SUM(FLOOR((((max_op - net_avail) / purchase_unit_size) +.75)) * c.weight * purchase_unit_size) total_weight
    , SUM(c.bo_count) num_of_bo
    , bo.bo_orders          -- SA 45138: open BO order numbers (qty_backordered > 0)
    , SUM(m.critical) critical
    , co.critical_orders    -- SA 45138: open BO order numbers for critical items (net_avail < 0)
     , l.last_po
FROM item_req_cte c
    INNER JOIN max_cte m
        ON c.inv_mast_uid = m.inv_mast_uid
            and c.location_id = m.location_id
    LEFT JOIN bo_orders_cte bo                  -- SA 45138
        on m.location_id = bo.location_id
            and m.supplier_id = bo.supplier_id
    LEFT JOIN critical_orders_cte co            -- SA 45138
        on m.location_id = co.location_id
            and m.supplier_id = co.supplier_id
     LEFT JOIN last_po_cte l
        on m.location_id = l.location_id
            and m.supplier_id = l.supplier_id

GROUP BY
    m.location_id
    , m.supplier_id
    , m.supplier_name
    , m.buyer
    , bo.bo_orders
    , co.critical_orders
     , l.last_po

HAVING
    bo.bo_orders IS NOT NULL        -- SA 45138: suppress rows where bo_orders is stale (no active BO lines)
    OR co.critical_orders IS NOT NULL

ORDER BY
    COUNT(m.inv_mast_uid) DESC
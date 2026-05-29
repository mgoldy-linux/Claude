-- ============================================================
-- Portal: Purchasing BOP Order Detail (InfoMaker)
-- SA 45138: Drill-through from BOP Summary/Manager — one row per order line
-- Retrieval arguments: al_supplier_id (long), al_location_id (long)
-- order_no column is the clickable link to Order Entry
-- ============================================================

SELECT
    oh.order_no
    , CONVERT(DATE, oh.order_date)  AS order_date
    , oh.customer_id
    , cust.name                     AS customer_name
    , ol.item_id
    , im.item_desc
    , il.qty_backordered            AS qty_bo
    , (
          il.qty_on_hand
        - il.qty_allocated
        - il.qty_backordered
        - il.qty_reserved_due_in
        - ISNULL(ss.qty_quarantined, 0)
        + il.qty_in_transit
        + il.order_quantity
      )                             AS net_avail
    , CASE
        WHEN (
              il.qty_on_hand
            - il.qty_allocated
            - il.qty_backordered
            - il.qty_reserved_due_in
            - ISNULL(ss.qty_quarantined, 0)
            + il.qty_in_transit
            + il.order_quantity
        ) < 0 THEN 'Critical'
        ELSE 'Backordered'
      END                           AS status
    , ol.disposition
    , SUM(CASE WHEN (
              il.qty_on_hand
            - il.qty_allocated
            - il.qty_backordered
            - il.qty_reserved_due_in
            - ISNULL(ss.qty_quarantined, 0)
            + il.qty_in_transit
            + il.order_quantity
        ) < 0 THEN 1 ELSE 0 END) OVER ()   AS critical_count
FROM p21_view_oe_hdr oh
    INNER JOIN p21_view_oe_line ol
        ON ol.order_no = oh.order_no
    INNER JOIN p21_view_inv_mast im
        ON im.inv_mast_uid = ol.inv_mast_uid
            AND im.delete_flag = 'n'
    INNER JOIN p21_view_inv_loc il
        ON il.inv_mast_uid = ol.inv_mast_uid
            AND il.location_id = ol.source_loc_id
    LEFT JOIN p21_view_inv_loc_stock_status ss
        ON ss.inv_mast_uid = il.inv_mast_uid
            AND ss.location_id = il.location_id
    INNER JOIN p21_view_inventory_supplier sup
        ON sup.inv_mast_uid = ol.inv_mast_uid
            AND sup.supplier_id = :al_supplier_id
    INNER JOIN p21_view_inventory_supplier_x_loc sl
        ON sl.inventory_supplier_uid = sup.inventory_supplier_uid
            AND sl.location_id = ol.source_loc_id
            AND sl.primary_supplier = 'y'
    INNER JOIN p21_view_supplier s
        ON sup.supplier_id = s.supplier_id
    LEFT JOIN p21_view_contacts buyer_c
        ON s.buyer_id = buyer_c.id
    LEFT JOIN p21_view_address cust
        ON oh.customer_id = cust.id
WHERE
    ol.source_loc_id = :al_location_id
    AND ol.complete = 'n'
    AND ol.delete_flag = 'n'
    AND (ol.disposition IN ('B', 'T') OR ol.disposition IS NULL)
    AND (
        il.qty_backordered > 0
        OR (
              il.qty_on_hand
            - il.qty_allocated
            - il.qty_backordered
            - il.qty_reserved_due_in
            - ISNULL(ss.qty_quarantined, 0)
            + il.qty_in_transit
            + il.order_quantity
        ) < 0
    )
    AND (
        '<user_id>' IN ('ABOEVE', 'PDUNDAS')
        OR buyer_c.id = (SELECT contact_id FROM p21_view_users WHERE id = '<user_id>')
        OR buyer_c.id IS NULL
    )
ORDER BY
    oh.order_no
    , ol.item_id

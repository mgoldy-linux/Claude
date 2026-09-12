/* Primary supplier per manufacturer class, scoped to the report's manufacturer
   list (qryInventoryValuebyLocation: p21_view_inventory_value_report joined to
   inv_mast on item_id, product_group_id <> 'SAMPLES'). item_ct primary,
   trailing-12mo $ volume (scoped to that class's items) as tiebreak,
   supplier_id as final deterministic tiebreak. */
;WITH report_mfrs AS (
    SELECT DISTINCT im.class_id1 AS mfr_code
    FROM p21_view_inventory_value_report ivr
    LEFT JOIN p21_view_inv_mast im ON ivr.item_id = im.item_id
    WHERE ISNULL(ivr.product_group_id,'') NOT IN ('SAMPLES')
      AND im.class_id1 IS NOT NULL AND im.class_id1 <> ''
),
mfr_supplier AS (
    SELECT im.class_id1 AS mfr_code, mc.class_description AS mfr_name,
           isup.supplier_id, s.supplier_name,
           COUNT(DISTINCT im.inv_mast_uid) AS item_ct
    FROM inv_mast im
    JOIN report_mfrs rm ON rm.mfr_code = im.class_id1
    JOIN inventory_supplier isup
         ON isup.inv_mast_uid = im.inv_mast_uid
         AND isup.delete_flag = 'N'
    JOIN supplier s ON s.supplier_id = isup.supplier_id
    JOIN class mc ON mc.class_id = im.class_id1 AND mc.class_type='IV' AND mc.class_number=1
    WHERE im.delete_flag = 'N'
    GROUP BY im.class_id1, mc.class_description, isup.supplier_id, s.supplier_name
),
po_dollars AS (
    SELECT im.class_id1 AS mfr_code, h.supplier_id,
           SUM(l.qty_received * l.unit_price) AS received_dollars_12mo
    FROM po_hdr h
    JOIN po_line l ON l.po_no = h.po_no AND l.delete_flag = 'N'
    JOIN inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
    JOIN report_mfrs rm ON rm.mfr_code = im.class_id1
    WHERE h.order_date >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY im.class_id1, h.supplier_id
),
ranked AS (
    SELECT ms.*, ISNULL(pd.received_dollars_12mo, 0) AS received_dollars_12mo,
           ROW_NUMBER() OVER (
               PARTITION BY ms.mfr_code
               ORDER BY ms.item_ct DESC, ISNULL(pd.received_dollars_12mo,0) DESC, ms.supplier_id ASC
           ) AS rnk,
           COUNT(*) OVER (PARTITION BY ms.mfr_code) AS supplier_count
    FROM mfr_supplier ms
    LEFT JOIN po_dollars pd ON pd.mfr_code = ms.mfr_code AND pd.supplier_id = ms.supplier_id
)
SELECT mfr_code, mfr_name, supplier_id, supplier_name, item_ct, received_dollars_12mo, supplier_count
FROM ranked
WHERE rnk = 1
ORDER BY mfr_name;

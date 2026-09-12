/* =====================================================================
   Trailing-90-Day-qry -- ALL manufacturers, with primary_supplier added
   right after class_id1 (per Jerome/user decision: ADD, don't replace
   class_description - avoids repeating the column-identity break that
   caused the Mfr Target Turns #REF! regression fixed this session).

   Base: live query as currently deployed (see
   live-Trailing90Day-current.sql, scratchpad) - unaliased class_id1 /
   class_description, unchanged. Only addition: primary_supplier column
   + its LEFT JOIN + GROUP BY entry. Same primary-supplier derivation as
   Manufacturer-Primary-Supplier-analysis-source-query.sql, unfiltered
   (computed once for all manufacturers, not per-class - cheaper, see
   9/11 perf note in that file's history).
   ===================================================================== */

;WITH mfr_supplier AS (
    SELECT im.class_id1 AS mfr_code,
           isup.supplier_id, s.supplier_name,
           COUNT(DISTINCT im.inv_mast_uid) AS item_ct
    FROM inv_mast im
    JOIN inventory_supplier isup
         ON isup.inv_mast_uid = im.inv_mast_uid
         AND isup.delete_flag = 'N'
    JOIN supplier s ON s.supplier_id = isup.supplier_id
    WHERE im.delete_flag = 'N'
      AND im.class_id1 IS NOT NULL AND im.class_id1 <> ''
    GROUP BY im.class_id1, isup.supplier_id, s.supplier_name
),
max_ct AS (
    SELECT mfr_code, MAX(item_ct) AS max_ct FROM mfr_supplier GROUP BY mfr_code
),
po_dollars AS (
    SELECT im.class_id1 AS mfr_code, h.supplier_id,
           SUM(l.qty_received * l.unit_price) AS received_dollars_12mo
    FROM po_hdr h
    JOIN po_line l ON l.po_no = h.po_no AND l.delete_flag = 'N'
    JOIN inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
    WHERE h.order_date >= DATEADD(MONTH, -12, GETDATE())
      AND im.class_id1 IS NOT NULL AND im.class_id1 <> ''
    GROUP BY im.class_id1, h.supplier_id
),
primary_supplier AS (
    SELECT ms.mfr_code, ms.supplier_id, ms.supplier_name,
           ROW_NUMBER() OVER (
               PARTITION BY ms.mfr_code
               ORDER BY ms.item_ct DESC, ISNULL(pd.received_dollars_12mo,0) DESC, ms.supplier_id ASC
           ) AS rnk
    FROM mfr_supplier ms
    JOIN max_ct mx ON mx.mfr_code = ms.mfr_code
    LEFT JOIN po_dollars pd ON pd.mfr_code = ms.mfr_code AND pd.supplier_id = ms.supplier_id
)
SELECT
      u.brand
    , im.class_id1
    , ps.supplier_name              AS primary_supplier
    , mfr_class.class_description
    , CASE
        WHEN i.[Source Location ID] = 222 THEN 220
        WHEN i.[Source Location ID] = 185 THEN 180
        WHEN i.[Source Location ID] = 122 THEN 125
        WHEN i.[Source Location ID] = 181 THEN 183
        WHEN i.[Source Location ID] = 124 THEN 121
        WHEN i.[Source Location ID] = 107 THEN 100
        WHEN i.[Source Location ID] = 0   THEN 100
        ELSE i.[Source Location ID]
      END AS source_loc_id
    , l.location_name
    , SUM(sales)         AS sales
    , SUM(cost)          AS cost
    , SUM(sales - cost)  AS gp
    , SUM(sales - cost) / (NULLIF(SUM(sales),0)) AS [gm%]
FROM bi_view_invoice i
    INNER JOIN p21_view_inv_mast im
        ON im.inv_mast_uid = i.inv_mast_uid
    LEFT JOIN p21_view_class mfr_class
        ON im.class_id1 = mfr_class.class_id
        AND mfr_class.class_type   = 'IV'
        AND mfr_class.class_number = 1
    LEFT JOIN primary_supplier ps
        ON ps.mfr_code = im.class_id1
        AND ps.rnk = 1
    LEFT JOIN p21_view_location l
        ON  CASE
                WHEN i.[Source Location ID] = 222 THEN 220
                WHEN i.[Source Location ID] = 185 THEN 180
                WHEN i.[Source Location ID] = 122 THEN 125
                WHEN i.[Source Location ID] = 181 THEN 183
                WHEN i.[Source Location ID] = 124 THEN 121
                WHEN i.[Source Location ID] = 107 THEN 100
                WHEN i.[Source Location ID] = 0   THEN 100
                ELSE i.[Source Location ID]
            END = l.location_id
    LEFT JOIN location_ud u
        ON  CASE
                WHEN i.[Source Location ID] = 222 THEN 220
                WHEN i.[Source Location ID] = 185 THEN 180
                WHEN i.[Source Location ID] = 122 THEN 125
                WHEN i.[Source Location ID] = 181 THEN 183
                WHEN i.[Source Location ID] = 124 THEN 121
                WHEN i.[Source Location ID] = 107 THEN 100
                WHEN i.[Source Location ID] = 0   THEN 100
                ELSE i.[Source Location ID]
            END = u.location_id
    LEFT JOIN p21_view_oe_hdr o
        ON i.[Order Number] = o.order_no
WHERE
        i.[Invoice Date] > CAST(GETDATE() - 92 AS DATE)
    AND i.[Invoice Date] < CAST(GETDATE() AS DATE)
    AND i.product_group_id NOT IN ('SAMPLES')
    AND i.[Direct Shipment] = 'N'
    AND ISNULL(o.class_1id, 'N') NOT IN ('CLAIM')
GROUP BY
      u.brand
    , im.class_id1
    , ps.supplier_name
    , mfr_class.class_description
    , CASE
        WHEN i.[Source Location ID] = 222 THEN 220
        WHEN i.[Source Location ID] = 185 THEN 180
        WHEN i.[Source Location ID] = 122 THEN 125
        WHEN i.[Source Location ID] = 181 THEN 183
        WHEN i.[Source Location ID] = 124 THEN 121
        WHEN i.[Source Location ID] = 107 THEN 100
        WHEN i.[Source Location ID] = 0   THEN 100
        ELSE i.[Source Location ID]
      END
    , l.location_name
ORDER BY
      u.brand
    , CASE
        WHEN i.[Source Location ID] = 222 THEN 220
        WHEN i.[Source Location ID] = 185 THEN 180
        WHEN i.[Source Location ID] = 122 THEN 125
        WHEN i.[Source Location ID] = 181 THEN 183
        WHEN i.[Source Location ID] = 124 THEN 121
        WHEN i.[Source Location ID] = 107 THEN 100
        WHEN i.[Source Location ID] = 0   THEN 100
        ELSE i.[Source Location ID]
      END
    , SUM(sales) DESC
    , l.location_name

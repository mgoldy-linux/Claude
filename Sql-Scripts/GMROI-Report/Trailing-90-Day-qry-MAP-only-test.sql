/* =====================================================================
   Trailing-90-Day-qry -- MAP-only test slice
   Base: Trailing-90-Day-qry-REWRITTEN-no-kb.sql, unchanged except for the
   added im.class_id1 = 'MAP' filter. Used to prototype adding a primary-
   supplier column to the Sales-sheet query before rolling out to all
   manufacturers. See Manufacturer-Primary-Supplier-analysis-source-query.sql
   for the primary-supplier derivation this will be joined against.
   ===================================================================== */

SELECT
      u.brand
    , im.class_id1                AS manufacturer_id
    , mfr_class.class_description  AS manufacturer_name
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
    AND im.class_id1 = 'MAP'
GROUP BY
      u.brand
    , im.class_id1
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
source_loc_id
      /*u.brand
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
    , l.location_name*/

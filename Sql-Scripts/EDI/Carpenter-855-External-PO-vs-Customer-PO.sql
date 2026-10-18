-- Carpenter 855: is po_hdr.external_po_no really the sales order's customer PO? (Chad Skelton, 2026-10-12)
-- Chad says P21 copies the Order Entry customer PO into External PO on Ship Directs. Read-only, run on Prod (P21).
-- Link PO -> order is oe_line_po (po_no, order_number); oe_hdr.po_no holds the customer PO. Customer PO column is oe_hdr.po_no (verified).
USE P21
GO

-- 0) Verify columns, and see which connection_type values exist (do not assume 'D' = drop ship)
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (TABLE_NAME = 'oe_line_po' AND COLUMN_NAME IN ('po_no','order_number','connection_type','po_line_number'))
   OR (TABLE_NAME = 'oe_hdr'     AND COLUMN_NAME LIKE '%po_no%')
ORDER BY TABLE_NAME, COLUMN_NAME;

SELECT connection_type, COUNT(*) AS n FROM oe_line_po GROUP BY connection_type ORDER BY n DESC;
GO

-- 1) Per PO: header External PO vs the linked order's customer PO vs the latest 855. Last 90 days.
;WITH latest_ack AS (
    SELECT ah.po_number, ah.external_po_no,
           ROW_NUMBER() OVER (PARTITION BY ah.po_number ORDER BY ah.po_acknowledgement_hdr_uid DESC) AS rn
    FROM po_acknowledgement_hdr ah
),
po_order AS (          -- one row per PO; a PO can cover several orders
    SELECT lp.po_no,
           COUNT(DISTINCT lp.order_number)               AS orders_linked,
           MIN(lp.order_number)                          AS order_no,
           MIN(oh.po_no)                        AS customer_po_no,
           COUNT(DISTINCT oh.po_no)             AS distinct_cust_pos,
           MIN(lp.connection_type)                       AS connection_type
    FROM oe_line_po lp
    INNER JOIN oe_hdr oh ON oh.order_no = lp.order_number
    GROUP BY lp.po_no
)
SELECT
    po_hdr.supplier_id,
    po_hdr.po_no,
    po_hdr.date_created              AS po_date_created,
    po_hdr.created_by                AS po_created_by,
    po_hdr.external_po_no            AS po_hdr_external_po_no,
    ack.external_po_no               AS ack_external_po_no,
    po.order_no,
    po.orders_linked,
    po.connection_type,
    po.customer_po_no                AS order_customer_po_no,
    CASE
        WHEN po.po_no IS NULL                               THEN 'no linked order (not a Ship Direct?)'
        WHEN po_hdr.external_po_no IS NULL                  THEN 'hdr blank'
        WHEN po_hdr.external_po_no = po.customer_po_no      THEN 'hdr = customer PO'
        WHEN SUBSTRING(po_hdr.external_po_no, PATINDEX('%[^0]%', po_hdr.external_po_no + '.'), 40)
           = SUBSTRING(po.customer_po_no,     PATINDEX('%[^0]%', po.customer_po_no + '.'), 40) THEN 'hdr = customer PO (leading zeros differ)'
        ELSE 'hdr differs from customer PO'
    END AS vs_customer_po,
    CASE
        WHEN ack.external_po_no IS NULL                     THEN 'no 855'
        WHEN po_hdr.external_po_no = ack.external_po_no     THEN 'hdr = 855'
        ELSE 'hdr <> 855'
    END AS vs_855
FROM po_hdr
INNER JOIN supplier ON supplier.supplier_id = po_hdr.supplier_id
LEFT  JOIN latest_ack ack ON ack.po_number = po_hdr.po_no AND ack.rn = 1
LEFT  JOIN po_order   po  ON po.po_no      = po_hdr.po_no
WHERE supplier.supplier_name LIKE 'Carpenter Co%'
  AND po_hdr.date_created >= DATEADD(DAY, -90, GETDATE())
  AND po_hdr.delete_flag = 'N'
ORDER BY vs_customer_po, po_hdr.po_no DESC;
GO

-- 2) Summary: how many Carpenter POs have External PO = the order's customer PO, split by whether the 855 matched
;WITH latest_ack AS (
    SELECT ah.po_number, ah.external_po_no,
           ROW_NUMBER() OVER (PARTITION BY ah.po_number ORDER BY ah.po_acknowledgement_hdr_uid DESC) AS rn
    FROM po_acknowledgement_hdr ah
),
po_order AS (
    SELECT lp.po_no, MIN(oh.po_no) AS customer_po_no
    FROM oe_line_po lp
    INNER JOIN oe_hdr oh ON oh.order_no = lp.order_number
    GROUP BY lp.po_no
)
SELECT
    CASE
        WHEN po.po_no IS NULL                          THEN 'no linked order'
        WHEN po_hdr.external_po_no IS NULL             THEN 'hdr blank'
        WHEN po_hdr.external_po_no = po.customer_po_no THEN 'hdr = customer PO'
        WHEN SUBSTRING(po_hdr.external_po_no, PATINDEX('%[^0]%', po_hdr.external_po_no + '.'), 40)
           = SUBSTRING(po.customer_po_no,     PATINDEX('%[^0]%', po.customer_po_no + '.'), 40) THEN 'hdr = customer PO (leading zeros differ)'
        ELSE 'hdr differs from customer PO'
    END AS vs_customer_po,
    CASE
        WHEN ack.external_po_no IS NULL                 THEN 'no 855'
        WHEN po_hdr.external_po_no = ack.external_po_no THEN 'hdr = 855'
        ELSE 'hdr <> 855'
    END AS vs_855,
    COUNT(*) AS po_count
FROM po_hdr
INNER JOIN supplier ON supplier.supplier_id = po_hdr.supplier_id
LEFT  JOIN latest_ack ack ON ack.po_number = po_hdr.po_no AND ack.rn = 1
LEFT  JOIN po_order   po  ON po.po_no      = po_hdr.po_no
WHERE supplier.supplier_name LIKE 'Carpenter Co%'
  AND po_hdr.date_created >= DATEADD(DAY, -90, GETDATE())
  AND po_hdr.delete_flag = 'N'
GROUP BY
    CASE
        WHEN po.po_no IS NULL                          THEN 'no linked order'
        WHEN po_hdr.external_po_no IS NULL             THEN 'hdr blank'
        WHEN po_hdr.external_po_no = po.customer_po_no THEN 'hdr = customer PO'
        WHEN SUBSTRING(po_hdr.external_po_no, PATINDEX('%[^0]%', po_hdr.external_po_no + '.'), 40)
           = SUBSTRING(po.customer_po_no,     PATINDEX('%[^0]%', po.customer_po_no + '.'), 40) THEN 'hdr = customer PO (leading zeros differ)'
        ELSE 'hdr differs from customer PO'
    END,
    CASE
        WHEN ack.external_po_no IS NULL                 THEN 'no 855'
        WHEN po_hdr.external_po_no = ack.external_po_no THEN 'hdr = 855'
        ELSE 'hdr <> 855'
    END
ORDER BY vs_customer_po, vs_855;
GO

-- 3) What IS the header value when it is NOT the order's customer PO? Sample rows, newest first.
--    Shows the order's po_no and po_no_append next to the header value and the 855 value.
;WITH latest_ack AS (
    SELECT ah.po_number, ah.external_po_no,
           ROW_NUMBER() OVER (PARTITION BY ah.po_number ORDER BY ah.po_acknowledgement_hdr_uid DESC) AS rn
    FROM po_acknowledgement_hdr ah
)
SELECT TOP 60
    po_hdr.po_no, po_hdr.created_by, po_hdr.last_maintained_by,
    po_hdr.external_po_no AS hdr_external_po_no,
    ack.external_po_no    AS ack_external_po_no,
    lp.order_number, lp.connection_type,
    oh.po_no              AS order_po_no,
    oh.po_no_append       AS order_po_no_append
FROM po_hdr
INNER JOIN supplier ON supplier.supplier_id = po_hdr.supplier_id
LEFT  JOIN latest_ack ack ON ack.po_number = po_hdr.po_no AND ack.rn = 1
LEFT  JOIN oe_line_po lp  ON lp.po_no = po_hdr.po_no
LEFT  JOIN oe_hdr oh      ON oh.order_no = lp.order_number
WHERE supplier.supplier_name LIKE 'Carpenter Co%'
  AND po_hdr.date_created >= DATEADD(DAY, -90, GETDATE())
  AND po_hdr.delete_flag = 'N'
  AND po_hdr.external_po_no IS NOT NULL
  AND po_hdr.external_po_no <> ISNULL(oh.po_no, '')
  AND po_hdr.external_po_no <> ISNULL(ack.external_po_no, '')
ORDER BY po_hdr.po_no DESC;
GO

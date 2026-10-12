-- Carpenter (2000692) 855 not updating po_hdr.external_po_no -- read-only diagnostic (Chad Skelton, 2026-10-12)
-- Control suppliers: Roppe 3003400, Schluter 3012610. Run on Prod (P21). Nothing here writes.
USE P21
GO

-- 0) Verify columns exist first (po_hdr / po_acknowledgement_hdr)
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('po_hdr','po_acknowledgement_hdr')
  AND (COLUMN_NAME LIKE '%external_po%' OR COLUMN_NAME LIKE '%last_maint%'
       OR COLUMN_NAME LIKE '%date_last_mod%' OR COLUMN_NAME LIKE '%date_created%'
       OR COLUMN_NAME LIKE '%created_by%')
ORDER BY TABLE_NAME, COLUMN_NAME;
GO

-- 1) PO header vs latest 855 header, last 90 days of POs
;WITH latest_ack AS (
    SELECT ah.*,
           ROW_NUMBER() OVER (PARTITION BY ah.po_number ORDER BY ah.po_acknowledgement_hdr_uid DESC) AS rn
    FROM po_acknowledgement_hdr ah
)
SELECT
    po_hdr.supplier_id,
    supplier.supplier_name,
    po_hdr.po_no,
    po_hdr.date_created              AS po_date_created,
    po_hdr.created_by                AS po_created_by,
    po_hdr.external_po_no            AS po_hdr_external_po_no,
    po_hdr.date_last_modified        AS po_last_modified,
    po_hdr.last_maintained_by        AS po_last_maintained_by,
    ack.po_acknowledgement_hdr_uid,
    ack.external_po_no               AS ack_external_po_no,
    ack.date_last_modified           AS ack_last_modified,
    ack.last_maintained_by           AS ack_last_maintained_by,
    (SELECT COUNT(*) FROM po_acknowledgement_hdr x WHERE x.po_number = po_hdr.po_no) AS acks_received,
    CASE
        WHEN ack.po_acknowledgement_hdr_uid IS NULL THEN 'no 855'
        WHEN ack.external_po_no IS NULL             THEN 'ack has no ext PO'
        WHEN po_hdr.external_po_no IS NULL          THEN 'hdr blank'
        WHEN po_hdr.external_po_no = ack.external_po_no THEN 'match'
        WHEN SUBSTRING(po_hdr.external_po_no, PATINDEX('%[^0]%', po_hdr.external_po_no + '.'), 40)
           = SUBSTRING(ack.external_po_no,     PATINDEX('%[^0]%', ack.external_po_no + '.'), 40) THEN 'match (leading zeros differ)'
        ELSE 'HDR NOT UPDATED (differs from ack)'
    END AS result
FROM po_hdr
INNER JOIN supplier ON supplier.supplier_id = po_hdr.supplier_id
LEFT  JOIN latest_ack ack ON ack.po_number = po_hdr.po_no AND ack.rn = 1
WHERE (po_hdr.supplier_id IN (3003400, 3012610)
       OR po_hdr.supplier_id IN (SELECT supplier_id FROM supplier WHERE supplier_name LIKE 'Carpenter Co%'))   -- Carpenter, Roppe, Schluter
  AND po_hdr.date_created >= DATEADD(DAY, -90, GETDATE())
  AND po_hdr.delete_flag = 'N'
ORDER BY po_hdr.supplier_id, po_hdr.po_no DESC;
GO

-- 2) Summary by supplier and result
;WITH latest_ack AS (
    SELECT ah.*,
           ROW_NUMBER() OVER (PARTITION BY ah.po_number ORDER BY ah.po_acknowledgement_hdr_uid DESC) AS rn
    FROM po_acknowledgement_hdr ah
)
SELECT po_hdr.supplier_id,
       CASE
           WHEN ack.po_acknowledgement_hdr_uid IS NULL THEN 'no 855'
           WHEN ack.external_po_no IS NULL             THEN 'ack has no ext PO'
           WHEN po_hdr.external_po_no IS NULL          THEN 'hdr blank'
           WHEN po_hdr.external_po_no = ack.external_po_no THEN 'match'
        WHEN SUBSTRING(po_hdr.external_po_no, PATINDEX('%[^0]%', po_hdr.external_po_no + '.'), 40)
           = SUBSTRING(ack.external_po_no,     PATINDEX('%[^0]%', ack.external_po_no + '.'), 40) THEN 'match (leading zeros differ)'
           ELSE 'HDR NOT UPDATED (differs from ack)'
       END AS result,
       COUNT(*) AS po_count
FROM po_hdr
LEFT JOIN latest_ack ack ON ack.po_number = po_hdr.po_no AND ack.rn = 1
WHERE (po_hdr.supplier_id IN (3003400, 3012610)
       OR po_hdr.supplier_id IN (SELECT supplier_id FROM supplier WHERE supplier_name LIKE 'Carpenter Co%'))
  AND po_hdr.date_created >= DATEADD(DAY, -90, GETDATE())
  AND po_hdr.delete_flag = 'N'
GROUP BY po_hdr.supplier_id,
       CASE
           WHEN ack.po_acknowledgement_hdr_uid IS NULL THEN 'no 855'
           WHEN ack.external_po_no IS NULL             THEN 'ack has no ext PO'
           WHEN po_hdr.external_po_no IS NULL          THEN 'hdr blank'
           WHEN po_hdr.external_po_no = ack.external_po_no THEN 'match'
        WHEN SUBSTRING(po_hdr.external_po_no, PATINDEX('%[^0]%', po_hdr.external_po_no + '.'), 40)
           = SUBSTRING(ack.external_po_no,     PATINDEX('%[^0]%', ack.external_po_no + '.'), 40) THEN 'match (leading zeros differ)'
           ELSE 'HDR NOT UPDATED (differs from ack)'
       END
ORDER BY po_hdr.supplier_id, result;
GO

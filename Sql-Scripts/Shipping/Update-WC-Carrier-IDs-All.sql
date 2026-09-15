-- Update open orders and transfers from all legacy WC carriers to consolidated carrier 10002
-- Scope: open (not deleted, not completed) records only; carriers identified dynamically by name LIKE '%-WC%'
-- Tables: oe_hdr, transfer_hdr
use P21; --P21BusinessRules;

-- Distinct WC carriers currently on open orders or transfers
; WITH wc_carriers AS (
    SELECT DISTINCT a.id AS carrier_id, a.name AS carrier_name
    FROM dbo.p21_view_address a
    WHERE ISNULL(a.delete_flag,  'N') <> 'Y'
      AND ISNULL(a.carrier_flag, 'N') = 'Y'
      AND a.name LIKE '%-WC%'
      AND (
          EXISTS (
              SELECT 1 FROM dbo.oe_hdr oh
              WHERE oh.carrier_id = a.id
                AND ISNULL(oh.delete_flag, 'N') <> 'Y'
                AND ISNULL(oh.completed,   'N') <> 'Y'
          )
          OR
          EXISTS (
              SELECT 1 FROM dbo.transfer_hdr th
              WHERE th.carrier_id = a.id
                AND ISNULL(th.delete_flag,   'N') <> 'Y'
                AND ISNULL(th.complete_flag, 'N') <> 'Y'
          )
      )
)
SELECT carrier_id, carrier_name FROM wc_carriers ORDER BY carrier_name;

-- Preview counts before running
; WITH wc_carriers AS (
    SELECT DISTINCT a.id AS carrier_id
    FROM dbo.p21_view_address a
    WHERE ISNULL(a.delete_flag,  'N') <> 'Y'
      AND ISNULL(a.carrier_flag, 'N') = 'Y'
      AND a.name LIKE '%-WC%'
)
SELECT 'oe_hdr'       AS tbl, COUNT(*) AS rows_affected FROM dbo.oe_hdr      WHERE carrier_id IN (SELECT carrier_id FROM wc_carriers) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(completed,    'N') <> 'Y'
UNION ALL
SELECT 'transfer_hdr' AS tbl, COUNT(*) AS rows_affected FROM dbo.transfer_hdr WHERE carrier_id IN (SELECT carrier_id FROM wc_carriers) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(complete_flag, 'N') <> 'Y';

-- Update oe_hdr
UPDATE dbo.oe_hdr
SET carrier_id         = 10002,
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE carrier_id IN (
    SELECT a.id FROM dbo.p21_view_address a
    WHERE ISNULL(a.delete_flag,  'N') <> 'Y'
      AND ISNULL(a.carrier_flag, 'N') = 'Y'
      AND a.name LIKE '%-WC%'
)
  AND ISNULL(delete_flag, 'N') <> 'Y'
  AND ISNULL(completed,   'N') <> 'Y';

-- Update transfer_hdr
UPDATE dbo.transfer_hdr
SET carrier_id         = 10002,
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE carrier_id IN (
    SELECT a.id FROM dbo.p21_view_address a
    WHERE ISNULL(a.delete_flag,  'N') <> 'Y'
      AND ISNULL(a.carrier_flag, 'N') = 'Y'
      AND a.name LIKE '%-WC%'
)
  AND ISNULL(delete_flag,   'N') <> 'Y'
  AND ISNULL(complete_flag, 'N') <> 'Y';

-- Counts after running (should both be 0)
; WITH wc_carriers AS (
    SELECT DISTINCT a.id AS carrier_id
    FROM dbo.p21_view_address a
    WHERE ISNULL(a.delete_flag,  'N') <> 'Y'
      AND ISNULL(a.carrier_flag, 'N') = 'Y'
      AND a.name LIKE '%-WC%'
)
SELECT 'oe_hdr'       AS tbl, COUNT(*) AS rows_affected FROM dbo.oe_hdr      WHERE carrier_id IN (SELECT carrier_id FROM wc_carriers) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(completed,    'N') <> 'Y'
UNION ALL
SELECT 'transfer_hdr' AS tbl, COUNT(*) AS rows_affected FROM dbo.transfer_hdr WHERE carrier_id IN (SELECT carrier_id FROM wc_carriers) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(complete_flag, 'N') <> 'Y';

-- Check ship_to default carrier against all WC carriers
SELECT
    st.ship_to_id,
    st.name,
    st.customer_id,
    st.default_carrier_id,
    a.name AS carrier_name
FROM dbo.ship_to st
INNER JOIN dbo.p21_view_address a
    ON st.default_carrier_id = a.id
WHERE ISNULL(st.delete_flag, 'N') <> 'Y'
  AND ISNULL(a.delete_flag,  'N') <> 'Y'
  AND ISNULL(a.carrier_flag, 'N') = 'Y'
  AND a.name LIKE '%-WC%'
ORDER BY a.name, st.customer_id, st.ship_to_id;

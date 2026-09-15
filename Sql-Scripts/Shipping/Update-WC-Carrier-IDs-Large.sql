-- Update open orders and transfers from legacy WC carrier IDs to consolidated carrier 10002
-- Scope: open (not deleted, not completed) records only
-- Tables: oe_hdr, transfer_hdr
-- Carriers: Brookfield, Cincinnati, Columbus, Davenport, Eagan, Fort Wayne, Indianapolis,
--           Lexington, Livonia, Louisville, North Kansas City, St Louis, Urbandale, Wyoming
use P21; --P21BusinessRules; --P21Play; -- 

-- Preview counts before running
SELECT 'oe_hdr'       AS tbl, COUNT(*) AS rows_affected FROM dbo.oe_hdr      WHERE carrier_id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(completed,    'N') <> 'Y'
UNION ALL
SELECT 'transfer_hdr' AS tbl, COUNT(*) AS rows_affected FROM dbo.transfer_hdr WHERE carrier_id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(complete_flag, 'N') <> 'Y';

UPDATE dbo.oe_hdr
SET carrier_id         = 10002,
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE carrier_id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533)
  AND ISNULL(delete_flag, 'N') <> 'Y'
  AND ISNULL(completed,   'N') <> 'Y';

UPDATE dbo.transfer_hdr
SET carrier_id         = 10002,
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE carrier_id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533)
  AND ISNULL(delete_flag,   'N') <> 'Y'
  AND ISNULL(complete_flag, 'N') <> 'Y';

-- Counts after running (should both be 0)
SELECT 'oe_hdr'       AS tbl, COUNT(*) AS rows_affected FROM dbo.oe_hdr      WHERE carrier_id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(completed,    'N') <> 'Y'
UNION ALL
SELECT 'transfer_hdr' AS tbl, COUNT(*) AS rows_affected FROM dbo.transfer_hdr WHERE carrier_id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(complete_flag, 'N') <> 'Y';

-- Check ship_to default carrier against all WC carriers
SELECT
    st.ship_to_id,
    addr.name        AS ship_to_name,
    st.customer_id,
    st.default_carrier_id,
    a.name           AS carrier_name
FROM dbo.ship_to st
INNER JOIN dbo.p21_view_address addr
    ON st.ship_to_id = addr.id
INNER JOIN dbo.p21_view_address a
    ON st.default_carrier_id = a.id
WHERE ISNULL(st.delete_flag,   'N') <> 'Y'
  AND ISNULL(addr.delete_flag, 'N') <> 'Y'
  AND ISNULL(a.delete_flag,    'N') <> 'Y'
  AND ISNULL(a.carrier_flag,   'N') = 'Y'
  AND a.name LIKE '%-WC%'
ORDER BY a.name, st.customer_id, st.ship_to_id;
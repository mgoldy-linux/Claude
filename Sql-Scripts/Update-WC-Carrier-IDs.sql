-- Update open orders and transfers from legacy WC carrier IDs to consolidated carrier 10002
-- Scope: open (not deleted, not completed) records only
-- Tables: oe_hdr, transfer_hdr
use P21; --P21BusinessRules;
-- Preview counts before running
SELECT 'oe_hdr'       AS tbl, COUNT(*) AS rows_affected FROM dbo.oe_hdr      WHERE carrier_id IN (3025340,3000656,3020718,3025590,3020719,3024800,3024818) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(completed,   'N') <> 'Y'
UNION ALL
SELECT 'transfer_hdr' AS tbl, COUNT(*) AS rows_affected FROM dbo.transfer_hdr WHERE carrier_id IN (3025340,3000656,3020718,3025590,3020719,3024800,3024818) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(complete_flag,'N') <> 'Y';

UPDATE dbo.oe_hdr
SET carrier_id         = 10002,
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE carrier_id IN (3025340,3000656,3020718,3025590,3020719,3024800,3024818)
  AND ISNULL(delete_flag, 'N') <> 'Y'
  AND ISNULL(completed,   'N') <> 'Y';

UPDATE dbo.transfer_hdr
SET carrier_id         = 10002,
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE carrier_id IN (3025340,3000656,3020718,3025590,3020719,3024800,3024818)
  AND ISNULL(delete_flag,   'N') <> 'Y'
  AND ISNULL(complete_flag, 'N') <> 'Y';

-- counts after running
SELECT 'oe_hdr'       AS tbl, COUNT(*) AS rows_affected FROM dbo.oe_hdr      WHERE carrier_id IN (3025340,3000656,3020718,3025590,3020719,3024800,3024818) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(completed,   'N') <> 'Y'
UNION ALL
SELECT 'transfer_hdr' AS tbl, COUNT(*) AS rows_affected FROM dbo.transfer_hdr WHERE carrier_id IN (3025340,3000656,3020718,3025590,3020719,3024800,3024818) AND ISNULL(delete_flag, 'N') <> 'Y' AND ISNULL(complete_flag,'N') <> 'Y';

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
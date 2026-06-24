-- =============================================================================
-- asi_view_inv_mast
-- Copy of p21_view_inv_mast (SELECT * FROM inv_mast) extended with:
--   * division, manufacturer  -- from inv_mast_ud
--   * supplier_name           -- primary supplier per item
--
-- Supplier resolution: inv_mast has no supplier column. The primary supplier
-- is stored per location on inv_loc.primary_supplier_id. To keep one row per
-- item, we collapse to a single primary per item via MIN(primary_supplier_id)
-- (deterministic tiebreak for the ~1.2% of items whose primary differs by
-- location), then join supplier for the name. View row count == inv_mast.
--
-- SA 48237
-- Tested in P21Dev (2026-06-18 div/mfr; supplier_name added 2026-06-24).
-- Run on P21 Prod AFTER acceptance testing.
-- Connect to the active P21 database (DB context, not master) before running.
-- =============================================================================

CREATE OR ALTER VIEW dbo.asi_view_inv_mast
AS
SELECT  inv_mast.*,
        imud.division,
        imud.manufacturer,
        s.supplier_name
FROM    inv_mast (NOLOCK)
LEFT JOIN inv_mast_ud imud (NOLOCK)
        ON imud.inv_mast_uid = inv_mast.inv_mast_uid
LEFT JOIN (
        SELECT  il.inv_mast_uid,
                MIN(il.primary_supplier_id) AS primary_supplier_id
        FROM    inv_loc il (NOLOCK)
        WHERE   il.primary_supplier_id IS NOT NULL
          AND   il.primary_supplier_id <> 0
        GROUP BY il.inv_mast_uid
) ps ON ps.inv_mast_uid = inv_mast.inv_mast_uid
LEFT JOIN supplier s (NOLOCK)
        ON s.supplier_id = ps.primary_supplier_id;
GO

-- Grant permissions
GRANT SELECT ON dbo.asi_view_inv_mast TO PxxiUser;
GRANT SELECT ON dbo.asi_view_inv_mast TO p21_application_role;
GO

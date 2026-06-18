-- =============================================================================
-- asi_view_inv_mast
-- Copy of p21_view_inv_mast (SELECT * FROM inv_mast) extended with the
-- division and manufacturer fields from inv_mast_ud.
--
-- SA 48237
-- Tested in P21Dev 2026-06-18. Run on P21 Prod AFTER acceptance testing.
-- Connect to the active P21 database (DB context, not master) before running.
-- =============================================================================

CREATE OR ALTER VIEW dbo.asi_view_inv_mast
AS
SELECT  inv_mast.*,
        imud.division,
        imud.manufacturer
FROM    inv_mast (NOLOCK)
LEFT JOIN inv_mast_ud imud (NOLOCK)
        ON imud.inv_mast_uid = inv_mast.inv_mast_uid;
GO

-- Grant permissions
GRANT SELECT ON dbo.asi_view_inv_mast TO PxxiUser;
GRANT SELECT ON dbo.asi_view_inv_mast TO p21_application_role;
GO

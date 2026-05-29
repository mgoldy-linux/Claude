-- ============================================================
-- SA 45138 — BOP JTIEHEN Test Data Setup  (P21Play only)
-- Assigns 25 random BOP-qualifying suppliers to JTIEHEN
-- PART 1: Apply  — assign 25 suppliers to JTIEHEN
-- PART 2: Verify — confirm JTIEHEN supplier count
-- PART 3: Undo   — restore original suppliers when testing is complete
-- PART 4: Login  — assign JTIEHEN contact_id to ISLAND2 so you can log in as ISLAND2
-- PART 5: Logout — reset ISLAND2 contact_id back to NULL when done
-- ============================================================

USE P21Play;
GO

-- ============================================================
-- PART 1: Apply
-- ============================================================

DECLARE @jtiehen_contact_id INT;
SELECT @jtiehen_contact_id = contact_id FROM p21_view_users WHERE id = 'JTIEHEN';

IF @jtiehen_contact_id IS NULL
BEGIN RAISERROR('JTIEHEN not found in users table', 16, 1); RETURN; END
PRINT 'JTIEHEN contact_id = ' + CAST(@jtiehen_contact_id AS VARCHAR(10));

-- Save original buyer_ids before making any changes (for undo)
IF OBJECT_ID('dbo.bop_jtiehen_test_undo') IS NOT NULL
    DROP TABLE dbo.bop_jtiehen_test_undo;

CREATE TABLE dbo.bop_jtiehen_test_undo (
    supplier_id       INT NOT NULL PRIMARY KEY,
    original_buyer_id INT NULL
);

-- Pick 25 random BOP-qualifying suppliers not already assigned to JTIEHEN
INSERT INTO dbo.bop_jtiehen_test_undo (supplier_id, original_buyer_id)
SELECT TOP 25
    s.supplier_id
    , s.buyer_id
FROM (
    SELECT DISTINCT sup.supplier_id
    FROM p21_view_inv_loc l
        INNER JOIN p21_view_inv_mast m
            ON l.inv_mast_uid = m.inv_mast_uid AND m.delete_flag = 'n'
        INNER JOIN p21_view_inventory_supplier sup
            ON sup.inv_mast_uid = l.inv_mast_uid
        INNER JOIN p21_view_inventory_supplier_x_loc sl
            ON sl.inventory_supplier_uid = sup.inventory_supplier_uid
               AND sl.location_id = l.location_id
               AND sl.primary_supplier = 'y'
    WHERE
        l.discontinued = 'n'
        AND ISNULL(l.location_id, 0) NOT IN (102, 1047269, 143, 144)
        AND (l.stockable = 'y' OR (l.stockable = 'n' AND l.qty_backordered > 0))
        AND ISNULL(l.product_group_id, '') NOT IN ('ocharge', 'samples')
) pool
    INNER JOIN supplier s ON pool.supplier_id = s.supplier_id
WHERE s.buyer_id != @jtiehen_contact_id OR s.buyer_id IS NULL
ORDER BY NEWID();

-- Show the 25 that will be changed
SELECT
    s.supplier_id
    , s.supplier_name
    , u.original_buyer_id
    , c.contact_name    AS original_buyer
FROM dbo.bop_jtiehen_test_undo u
    INNER JOIN supplier s ON u.supplier_id = s.supplier_id
    LEFT JOIN p21_view_contacts c ON u.original_buyer_id = c.id
ORDER BY s.supplier_id;

-- Apply the change
UPDATE s
SET    s.buyer_id = @jtiehen_contact_id
FROM supplier s
    INNER JOIN dbo.bop_jtiehen_test_undo u ON s.supplier_id = u.supplier_id;

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' supplier(s) assigned to JTIEHEN.';
GO

-- ============================================================
-- PART 2: Verify
-- ============================================================

DECLARE @jtiehen_contact_id INT;
SELECT @jtiehen_contact_id = contact_id FROM p21_view_users WHERE id = 'JTIEHEN';

SELECT COUNT(*) AS jtiehen_supplier_count
FROM supplier
WHERE buyer_id = @jtiehen_contact_id;
GO

-- ============================================================
-- PART 3: Undo — run this when testing is complete
-- ============================================================

UPDATE s
SET    s.buyer_id = u.original_buyer_id
FROM supplier s
    INNER JOIN dbo.bop_jtiehen_test_undo u ON s.supplier_id = u.supplier_id;

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' supplier(s) restored to original buyer.';

DROP TABLE dbo.bop_jtiehen_test_undo;
PRINT 'Undo table dropped.';
GO

-- ============================================================
-- PART 4: Login — assign JTIEHEN contact_id to ISLAND2
-- Run this so you can log in as ISLAND2 and see JTIEHEN's suppliers
-- ============================================================

UPDATE users SET contact_id = 29998 WHERE id = 'ISLAND2';
PRINT 'ISLAND2 contact_id set to 29998 (JTIEHEN).';

SELECT id, contact_id FROM p21_view_users WHERE id IN ('ISLAND2', 'JTIEHEN');
GO

-- ============================================================
-- PART 5: Logout — reset ISLAND2 contact_id back to NULL
-- Run this when testing is complete
-- ============================================================

UPDATE users SET contact_id = NULL WHERE id = 'ISLAND2';
PRINT 'ISLAND2 contact_id reset to NULL.';

SELECT id, contact_id FROM p21_view_users WHERE id IN ('ISLAND2', 'JTIEHEN');
GO

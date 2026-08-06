-- =============================================================================
-- asi_table_po_header_required_date_frozen / asi_table_po_line_required_date_frozen
-- Part of SA-46321 (PO Required Date -- line + header)
--
-- Minimal "already computed" markers. P21 auto-populates po_hdr.date_due and
-- po_line.required_date to order_date on creation (confirmed empirically,
-- 2026-08-06) -- neither column is ever NULL, so an IS NULL guard can't be
-- used to implement "compute once, freeze forever." These satellite tables
-- track that state ourselves instead, without altering po_hdr/po_line.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'asi_table_po_header_required_date_frozen')
BEGIN
    CREATE TABLE dbo.asi_table_po_header_required_date_frozen (
        po_no       DECIMAL(19,0) NOT NULL,
        date_frozen DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_asi_table_po_header_required_date_frozen PRIMARY KEY (po_no)
    )
END

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'asi_table_po_line_required_date_frozen')
BEGIN
    CREATE TABLE dbo.asi_table_po_line_required_date_frozen (
        po_line_uid INT      NOT NULL,
        date_frozen DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_asi_table_po_line_required_date_frozen PRIMARY KEY (po_line_uid)
    )
END

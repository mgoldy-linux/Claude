-- =============================================================================
-- dbo.asi_proc_po_required_date
-- Part of SA-46321 (PO Required Date -- line + header)
--
-- Called from the asi_po_required_date business rule on every pohdrpostupdate
-- fire for a PO. Idempotent by design via the asi_table_po_*_required_date_frozen
-- marker tables (see CREATE-TABLES-asi_table_po_required_date_frozen.sql) --
-- safe to call repeatedly for the same @PONo.
--
-- 1. Any line on this PO not yet frozen gets its Required Date computed:
--    order_date + Published Lead Time (fallback Average Lead Time, else 0),
--    slid forward to the next business day (dbo.asi_fn_po_next_business_day).
-- 2. If the header isn't yet frozen and at least one line exists, header
--    Required Date (date_due) is set once to MAX(line required_date).
--    Never touched again after that -- a line added later still gets its own
--    Required Date (step 1) but does not reopen the header freeze.
--
-- Testable directly, no need to save a PO through the P21 client:
--   EXEC dbo.asi_proc_po_required_date @PONo = 4319393
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.asi_proc_po_required_date
    @PONo DECIMAL(19,0)
AS
BEGIN
    SET NOCOUNT ON

    -- 1. Compute Required Date for any not-yet-frozen line on this PO,
    --    freezing it in the same statement via OUTPUT ... INTO
    UPDATE pl
    SET required_date = dbo.asi_fn_po_next_business_day(
          DATEADD(DAY, ISNULL(NULLIF(isxl.manual_lead_time, 0), ISNULL(isxl.average_lead_time, 0)), ph.order_date))
    OUTPUT inserted.po_line_uid INTO asi_table_po_line_required_date_frozen (po_line_uid)
    FROM po_line pl
    JOIN po_hdr ph ON ph.po_no = pl.po_no
    JOIN inventory_supplier ins ON ins.inv_mast_uid = pl.inv_mast_uid AND ins.supplier_id = ph.vendor_id
    JOIN inventory_supplier_x_loc isxl ON isxl.inventory_supplier_uid = ins.inventory_supplier_uid AND isxl.location_id = ph.location_id
    WHERE pl.po_no = @PONo
      AND NOT EXISTS (
            SELECT 1 FROM asi_table_po_line_required_date_frozen f
            WHERE f.po_line_uid = pl.po_line_uid
          )

    -- 2. Freeze the header once, from whatever line dates exist right now
    IF NOT EXISTS (SELECT 1 FROM asi_table_po_header_required_date_frozen WHERE po_no = @PONo)
       AND EXISTS (SELECT 1 FROM po_line WHERE po_no = @PONo)
    BEGIN
        UPDATE po_hdr
        SET date_due = (SELECT MAX(required_date) FROM po_line WHERE po_no = @PONo)
        WHERE po_no = @PONo

        INSERT INTO asi_table_po_header_required_date_frozen (po_no)
        VALUES (@PONo)
    END
END

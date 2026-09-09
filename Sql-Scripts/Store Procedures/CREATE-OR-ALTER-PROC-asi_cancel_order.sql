-- =====================================================
-- Description : Cancel a P21 sales order (oe_hdr + all open oe_line rows).
--               Mirrors the sequence executed by the P21 OE Cancel Order action:
--                 1. Mark oe_hdr cancel_flag='Y', completed='T'  (begin cancel)
--                 2. Cancel open oe_line rows (disposition='C', qty reallocated)
--                 3. Finalize oe_hdr completed='Y', profit_percent=0
--                 4. Mark cancelled lines complete='Y'
--               P21 triggers on oe_hdr and oe_line handle audit_trail,
--               inv_loc_stock_status, and customer_order_history side-effects.
-- Source      : SQL Profiler trace – Cancel Order on order 5923021 (2026-07-22)
-- CHANGE LOG
-- ----------
-- 2026-07-22  Bus App Team  Initial creation
-- =====================================================
CREATE OR ALTER PROCEDURE dbo.asi_cancel_order
    @order_no   VARCHAR(20),
    @user_id    VARCHAR(50) = NULL   -- defaults to SYSTEM_USER when omitted
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @now    DATETIME    = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL);
    DECLARE @user   VARCHAR(50) = COALESCE(NULLIF(@user_id, ''), SYSTEM_USER);

    -- -------------------------------------------------------
    -- Validate
    -- -------------------------------------------------------
    IF @order_no IS NULL OR @order_no = ''
    BEGIN
        RAISERROR('Order number is required.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM   oe_hdr
        WHERE  order_no    = @order_no
          AND  delete_flag = 'N'
          AND  cancel_flag = 'N'
          AND  completed   = 'N'
          AND  rma_flag    = 'N'
    )
    BEGIN
        RAISERROR(
            'Order %s cannot be cancelled: not found, already cancelled/completed, deleted, or is an RMA.',
            16, 1, @order_no
        );
        RETURN;
    END

    -- -------------------------------------------------------
    -- Cancel
    -- -------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Phase 1: begin cancel on header.
        -- completed='T' is the P21 intermediate processing state; triggers fire here
        -- and handle audit_trail + customer_order_history updates.
        UPDATE oe_hdr
        SET    cancel_flag        = 'Y',
               completed          = 'T',
               date_last_modified = @now,
               last_maintained_by = @user
        WHERE  order_no    = @order_no
          AND  cancel_flag = 'N'
          AND  completed   = 'N';

        -- Phase 2: cancel all open lines.
        -- Eligible: not deleted, not already complete, open (NULL) or backordered (B)
        -- disposition, and no quantity yet cancelled.
        -- oe_line trigger adjusts inv_loc_stock_status automatically on this update.
        UPDATE oe_line
        SET    disposition        = 'C',
               qty_canceled       = qty_ordered,
               qty_allocated      = 0,
               delete_flag        = 'N',
               date_last_modified = @now,
               last_maintained_by = @user
        WHERE  order_no    = @order_no
          AND  delete_flag = 'N'
          AND  complete    = 'N'
          AND  (disposition IS NULL OR disposition = 'B')
          AND  qty_canceled = 0;

        -- Phase 3: finalize header.
        -- Setting completed='Y' causes the oe_hdr trigger to stamp date_order_completed.
        UPDATE oe_hdr
        SET    completed                  = 'Y',
               profit_percent             = 0,
               apply_builder_allowance_flag = 'N',
               date_last_modified         = @now,
               last_maintained_by         = @user
        WHERE  order_no  = @order_no
          AND  completed = 'T';

        -- Phase 4: mark cancelled lines complete.
        -- Done after all lines have disposition='C', mirroring P21 post-line-loop step.
        UPDATE oe_line
        SET    complete            = 'Y',
               date_last_modified  = @now,
               last_maintained_by  = @user
        WHERE  order_no    = @order_no
          AND  disposition = 'C'
          AND  complete    = 'N';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

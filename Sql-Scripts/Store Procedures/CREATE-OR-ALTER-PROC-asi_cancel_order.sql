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
-- 2026-09-09  MG/Claude     Phase 5: write dbo.lost_sales_transaction. The client
--                           does this in its APPLICATION layer -- there is no
--                           trigger (verified) -- so replaying the traced UPDATEs
--                           alone never produced it. Verified against a client
--                           cancel of order 6062441.
-- =====================================================
CREATE OR ALTER PROCEDURE dbo.asi_cancel_order
    @order_no          VARCHAR(20),
    @user_id           VARCHAR(50) = NULL,  -- defaults to SYSTEM_USER when omitted
    @lost_sales_uid    INT         = 16,    -- reason code; 16 = 'OTHER'. NOT a constant in
                                            -- real data (uid 31 'Doesn''t Need' is the most
                                            -- common), so it is a parameter, not a literal.
    @write_lost_sales  CHAR(1)     = 'Y'    -- 'N' skips Phase 5. These rows feed usage/demand
                                            -- history; for pure test-order cleanup you may
                                            -- prefer not to inject fake lost demand.
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @now    DATETIME    = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL);
    DECLARE @user   VARCHAR(50) = COALESCE(NULLIF(@user_id, ''), SYSTEM_USER);

    -- Lines cancelled by THIS execution (populated by Phase 2's OUTPUT clause)
    DECLARE @cancelled_lines TABLE (line_no INT NOT NULL, qty_ordered DECIMAL(19,9) NULL);

    -- affect_usage on the transaction MIRRORS the chosen reason's own flag.
    -- Verified: reasons with lost_sales.affect_usage='N' (4 Lead Time, 10 No Stock,
    -- 7 Wrong Customer Billed) produce 'N' transaction rows.
    DECLARE @affect_usage CHAR(1);

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

    IF @write_lost_sales = 'Y'
    BEGIN
        SELECT @affect_usage = ls.affect_usage
        FROM   dbo.lost_sales ls
        WHERE  ls.lost_sales_uid  = @lost_sales_uid
          AND  ls.row_status_flag = 704;          -- active reasons only

        IF @affect_usage IS NULL
        BEGIN
            RAISERROR('lost_sales_uid %d is not an active reason code.', 16, 1, @lost_sales_uid);
            RETURN;
        END
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
        -- OUTPUT captures exactly the lines THIS call cancelled, so Phase 5 cannot
        -- pick up lines that were already 'C' before we started.
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
        OUTPUT inserted.line_no, inserted.qty_ordered INTO @cancelled_lines (line_no, qty_ordered)
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

        -- Phase 5: lost sales transactions.
        -- NOT trigger-driven -- P21's client writes these itself, which is why a proc
        -- rebuilt from a SQL trace of the UPDATEs alone produced none. Shape verified
        -- against the client's cancel of order 6062441 and 20 further orders:
        --   * one row per cancelled line, sku_qty_change = that line's qty_ordered
        --   * plus exactly ONE trailer row (line_no NULL, sku_qty_change NULL)
        --   * transaction_code_no 2143 = 'Order - Cancel Order' (2142 is Cancel Quantity)
        --   * usage_processed_flag 'Y', matching what the client writes for 2143
        -- lost_sales_transaction_uid is an IDENTITY column (verified), so it is omitted
        -- here; there is no P21 counter for this table and therefore no drift risk.
        IF @write_lost_sales = 'Y'
        BEGIN
            INSERT dbo.lost_sales_transaction
                  (lost_sales_uid, affect_usage, transaction_code_no, transaction_no,
                   line_no, sub_line_no, sku_qty_change, usage_processed_flag,
                   date_created, created_by, date_last_modified, last_maintained_by)
            SELECT @lost_sales_uid, @affect_usage, 2143, CAST(@order_no AS INT),
                   cl.line_no, NULL, cl.qty_ordered, 'Y',
                   @now, @user, @now, @user
            FROM   @cancelled_lines cl
            ORDER BY cl.line_no;

            -- Trailer row: one per cancelled order, no line, no quantity.
            IF EXISTS (SELECT 1 FROM @cancelled_lines)
                INSERT dbo.lost_sales_transaction
                      (lost_sales_uid, affect_usage, transaction_code_no, transaction_no,
                       line_no, sub_line_no, sku_qty_change, usage_processed_flag,
                       date_created, created_by, date_last_modified, last_maintained_by)
                VALUES (@lost_sales_uid, @affect_usage, 2143, CAST(@order_no AS INT),
                        NULL, NULL, NULL, 'Y',
                        @now, @user, @now, @user);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*==============================  KNOWN LIMITATION  ===========================
  Partially shipped lines. Phase 2 sets qty_canceled = qty_ordered outright, and
  Phase 5 reports sku_qty_change = qty_ordered to match. Every sample used to
  verify this had qty_invoiced = 0, so the behaviour of P21's own client on a
  partially shipped line is UNVERIFIED -- it may cancel and report only the open
  remainder. If this proc is ever pointed at orders with shipments against them,
  confirm that first; as written it would over-state both the cancelled quantity
  and the lost demand.

  Also note dbo.p21_view_alert_oe_OrderEntry references lost_sales_transaction,
  so rows written here are visible to the order-entry alert family.
===========================================================================*/

-- =====================================================
-- Description : Cancel all open sales orders for a given taker (user_id).
--               Iterates eligible oe_hdr rows and delegates each to
--               dbo.asi_cancel_order, collecting per-order results.
--               A failure on one order does not stop the others.
-- Depends on  : dbo.asi_cancel_order
-- CHANGE LOG
-- ----------
-- 2026-07-22  Bus App Team  Initial creation
-- =====================================================
CREATE OR ALTER PROCEDURE dbo.asi_cancel_open_orders_by_user
    @user_id        VARCHAR(50),            -- oe_hdr.taker value to match
    @cancelled_by   VARCHAR(50) = NULL,     -- last_maintained_by on the updates; defaults to @user_id
    @preview_only   CHAR(1)     = 'N'       -- 'Y' = list eligible orders, make no changes
AS
BEGIN
    SET NOCOUNT ON;

    IF @user_id IS NULL OR @user_id = ''
    BEGIN
        RAISERROR('user_id is required.', 16, 1);
        RETURN;
    END

    DECLARE @cancelled_by_resolved VARCHAR(50) = COALESCE(NULLIF(@cancelled_by, ''), @user_id);

    -- Collect eligible orders up front so the cursor is stable
    DECLARE @orders TABLE (order_no VARCHAR(20) NOT NULL);

    INSERT INTO @orders (order_no)
    SELECT order_no
    FROM   oe_hdr
    WHERE  taker       = @user_id
      AND  delete_flag = 'N'
      AND  cancel_flag = 'N'
      AND  completed   = 'N'
      AND  rma_flag    = 'N';

    -- Results table returned at the end
    DECLARE @results TABLE (
        order_no    VARCHAR(20)  NOT NULL,
        status      VARCHAR(10)  NOT NULL,   -- 'CANCELLED' | 'SKIPPED' | 'ERROR'
        message     VARCHAR(500) NULL
    );

    IF @preview_only = 'Y'
    BEGIN
        INSERT INTO @results (order_no, status, message)
        SELECT order_no, 'PREVIEW', 'Eligible for cancellation'
        FROM   @orders
        ORDER BY order_no;

        SELECT order_no, status, message FROM @results ORDER BY order_no;
        RETURN;
    END

    -- -------------------------------------------------------
    -- Cancel each order; catch per-order errors individually
    -- -------------------------------------------------------
    DECLARE @current_order VARCHAR(20);

    DECLARE order_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT order_no FROM @orders ORDER BY order_no;

    OPEN order_cursor;
    FETCH NEXT FROM order_cursor INTO @current_order;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.asi_cancel_order
                @order_no = @current_order,
                @user_id  = @cancelled_by_resolved;

            INSERT INTO @results (order_no, status, message)
            VALUES (@current_order, 'CANCELLED', NULL);
        END TRY
        BEGIN CATCH
            INSERT INTO @results (order_no, status, message)
            VALUES (@current_order, 'ERROR', ERROR_MESSAGE());
        END CATCH;

        FETCH NEXT FROM order_cursor INTO @current_order;
    END

    CLOSE order_cursor;
    DEALLOCATE order_cursor;

    -- Summary result set
    SELECT
        order_no,
        status,
        message
    FROM   @results
    ORDER BY
        CASE status WHEN 'ERROR' THEN 0 WHEN 'CANCELLED' THEN 1 ELSE 2 END,
        order_no;

    -- Print totals to messages pane
    DECLARE @cancelled INT = (SELECT COUNT(*) FROM @results WHERE status = 'CANCELLED');
    DECLARE @errors    INT = (SELECT COUNT(*) FROM @results WHERE status = 'ERROR');

    RAISERROR(
        'Done. Cancelled: %d  |  Errors: %d  |  User: %s',
        0, 1, @cancelled, @errors, @user_id
    ) WITH NOWAIT;
END;
GO

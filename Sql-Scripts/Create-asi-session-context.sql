-- ============================================================
-- Create-asi-session-context.sql
-- ============================================================
-- Purpose : Stores the most recently loaded order_no per user in
--           Order Entry. Populated by asi_oe_qto_session ValidateField
--           rule when user tabs off order_no. Read by
--           asi_oe_rmb_qto_taker Message Box Opening rule to identify
--           the correct quote being converted via RMB.
-- Run on  : P21Play first for testing, then P21 (Prod)
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'asi_session_context'
)
BEGIN
    CREATE TABLE asi_session_context (
        user_id    VARCHAR(30)  NOT NULL,
        order_no   VARCHAR(50)  NULL,
        updated_at DATETIME     NOT NULL CONSTRAINT DF_asi_session_context_updated_at DEFAULT GETDATE(),
        CONSTRAINT PK_asi_session_context PRIMARY KEY (user_id)
    )
    PRINT 'asi_session_context created.'
END
ELSE
    PRINT 'asi_session_context already exists — skipped.'

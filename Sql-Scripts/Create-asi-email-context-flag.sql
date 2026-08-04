-- ============================================================
-- Create-asi-email-context-flag.sql
-- ============================================================
-- Purpose : Stores, per user, whether the email window they are about to
--           see is for an Order Acknowledgment. Populated by
--           asi_email_context_flag (Form Printing Pre-Email Response
--           Window / FormPreEmail) on EVERY emailed form, not just Order
--           Ack -- always upserted so a stale "true" can't leak into a
--           later, unrelated email for the same user. Read by
--           asi_oe_email_close_diag (OK button on w_email_response) to
--           gate its memo append, since w_email_response has no
--           form_type/document_nos field exposed to a cb_ok-attached rule
--           (confirmed 2026-08-03 -- that window is shared by Order Ack,
--           Packing List Transfer, and other document emails).
-- Run on  : P21 Business Rules first for testing, then Play, then Prod
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'asi_email_context_flag'
)
BEGIN
    CREATE TABLE asi_email_context_flag (
        user_id      VARCHAR(30)   NOT NULL,
        is_order_ack BIT           NOT NULL,
        form_type    VARCHAR(255)  NULL,
        updated_at   DATETIME      NOT NULL CONSTRAINT DF_asi_email_context_flag_updated_at DEFAULT GETDATE(),
        CONSTRAINT PK_asi_email_context_flag PRIMARY KEY (user_id)
    )
    PRINT 'asi_email_context_flag created.'
END
ELSE
    PRINT 'asi_email_context_flag already exists — skipped.'

-- Permissions (MERGE requires SELECT + INSERT + UPDATE)
GRANT SELECT, INSERT, UPDATE ON dbo.asi_email_context_flag TO PxxiUser;
GRANT SELECT, INSERT, UPDATE ON dbo.asi_email_context_flag TO p21_application_role;
PRINT 'Permissions granted to PxxiUser and p21_application_role.'

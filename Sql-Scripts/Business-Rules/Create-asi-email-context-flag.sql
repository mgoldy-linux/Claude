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
-- SCHEMA TRAP (hit on Prod, 2026-09-03): in Play/BusinessRules the login
-- maps to dbo (db_owner), so an unqualified CREATE TABLE lands in dbo. In
-- Prod it maps to AHI\mgoldyn with a matching default schema, so the same
-- unqualified statement silently created [AHI\mgoldyn].asi_email_context_flag
-- and the dbo-qualified GRANTs then failed with "does not exist or you do
-- not have permission." Everything below is dbo-qualified, and the
-- existence check is OBJECT_ID (schema-aware) rather than
-- INFORMATION_SCHEMA.TABLES filtered on TABLE_NAME alone (which matches any
-- schema and would wrongly skip creation). Both rules query the table
-- unqualified, so it MUST live in dbo.
-- ============================================================

SET NOCOUNT ON;

-- Warn about a stray copy in some other schema (e.g. a prior run under a
-- non-dbo default schema). Not dropped automatically -- inspect and remove
-- it by hand so nothing with real rows is destroyed silently.
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.name = 'asi_email_context_flag'
      AND s.name <> 'dbo'
)
BEGIN
    SELECT
        'STRAY COPY -- not in dbo, drop it by hand' AS warning,
        QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS stray_object,
        t.create_date,
        (SELECT COUNT_BIG(*) FROM sys.partitions p
         WHERE p.object_id = t.object_id AND p.index_id IN (0, 1)) AS approx_rows
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.name = 'asi_email_context_flag'
      AND s.name <> 'dbo';
END

IF OBJECT_ID('dbo.asi_email_context_flag', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.asi_email_context_flag (
        user_id      VARCHAR(30)   NOT NULL,
        is_order_ack BIT           NOT NULL,
        form_type    VARCHAR(255)  NULL,
        updated_at   DATETIME      NOT NULL CONSTRAINT DF_asi_email_context_flag_updated_at DEFAULT GETDATE(),
        CONSTRAINT PK_asi_email_context_flag PRIMARY KEY (user_id)
    )
    PRINT 'dbo.asi_email_context_flag created.'
END
ELSE
    PRINT 'dbo.asi_email_context_flag already exists — skipped.'

-- Permissions (MERGE requires SELECT + INSERT + UPDATE)
GRANT SELECT, INSERT, UPDATE ON dbo.asi_email_context_flag TO PxxiUser;
GRANT SELECT, INSERT, UPDATE ON dbo.asi_email_context_flag TO p21_application_role;
PRINT 'Permissions granted to PxxiUser and p21_application_role.'

-- Verify what actually landed
SELECT
    s.name  AS schema_name,
    t.name  AS table_name,
    t.create_date
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name = 'asi_email_context_flag';

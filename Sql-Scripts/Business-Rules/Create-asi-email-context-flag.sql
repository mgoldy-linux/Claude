-- ============================================================
-- Create-asi-email-context-flag.sql
-- ============================================================
-- Purpose : Stores, per user, the context of the email window they are
--           about to see: whether it is an Order Acknowledgment, and which
--           document (order) it is for. Populated by
--           asi_email_context_flag (Form Printing Pre-Email Response
--           Window / FormPreEmail) on EVERY emailed form, not just Order
--           Ack -- always upserted so a stale "true" can't leak into a
--           later, unrelated email for the same user. Read by:
--             * asi_oe_email_close_diag (OK button on w_email_response) --
--               gates its memo append.
--             * asi_oe_order_ack_email_subject (same OK button) -- gates
--               its subject stamp AND takes the order number from
--               document_nos.
--           Both readers need this table because w_email_response exposes
--           no form_type/document_nos field to a cb_ok-attached rule
--           (confirmed 2026-08-03 -- that window is shared by Order Ack,
--           Packing List Transfer, and other document emails).
-- Run on  : P21 Business Rules first for testing, then Play, then Prod
-- ============================================================
-- 2026-09-06 : added document_nos. The 2026-09-06 BRR test proved
--   d_dw_email_info.subject at cb_ok is NOT the delivered subject line --
--   it is the rep's free-text portion (empty on window open, char(60)),
--   which P21 appends to its own generated
--   "All Surfaces - Acknowledgement# <order>" prefix at send time. So
--   asi_oe_order_ack_email_subject cannot parse the order number out of
--   the subject the way it was written; it now reads document_nos from
--   here instead. Existing deployments are ALTERed below -- the column is
--   NULLable so a pre-1.0.0.2 asi_email_context_flag DLL keeps working
--   (readers treat NULL as "no order number, leave the subject alone").
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
        (SELECT ISNULL(SUM(p.rows), 0) FROM sys.partitions p
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
        document_nos VARCHAR(255)  NULL,
        updated_at   DATETIME      NOT NULL CONSTRAINT DF_asi_email_context_flag_updated_at DEFAULT GETDATE(),
        CONSTRAINT PK_asi_email_context_flag PRIMARY KEY (user_id)
    )
    PRINT 'dbo.asi_email_context_flag created.'
END
ELSE
    PRINT 'dbo.asi_email_context_flag already exists — skipped creation.'

-- Bring an existing table (BRR / Play / Prod all predate document_nos) up to
-- the current shape. NULLable on purpose: an older asi_email_context_flag DLL
-- that does not write it must keep working, and readers treat NULL as "order
-- number unknown -- change nothing."
IF OBJECT_ID('dbo.asi_email_context_flag', 'U') IS NOT NULL
   AND COL_LENGTH('dbo.asi_email_context_flag', 'document_nos') IS NULL
BEGIN
    ALTER TABLE dbo.asi_email_context_flag ADD document_nos VARCHAR(255) NULL;
    PRINT 'dbo.asi_email_context_flag.document_nos added.'
END
ELSE
    PRINT 'dbo.asi_email_context_flag.document_nos already present — skipped.'

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

SELECT
    c.name          AS column_name,
    ty.name         AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.types   ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.asi_email_context_flag')
ORDER BY c.column_id;

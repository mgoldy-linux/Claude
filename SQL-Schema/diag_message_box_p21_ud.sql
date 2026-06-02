-- =============================================================================
-- diag_message_box_p21_ud
-- Diagnostic log table: captures all DataSet fields when a P21 message box fires
-- Populated by asi_diag_message_box_data business rule
-- =============================================================================

USE P21BusinessRules;
GO

CREATE TABLE dbo.diag_message_box_p21_ud (
    id              INT             IDENTITY(1,1)   NOT NULL,
    session_id      UNIQUEIDENTIFIER                NOT NULL,   -- groups all rows from one rule firing
    captured_date   DATETIME        DEFAULT GETDATE() NOT NULL,
    dataset_table   VARCHAR(100)                    NULL,
    row_no          INT                             NULL,
    column_name     VARCHAR(100)                    NULL,
    column_value    NVARCHAR(MAX)                   NULL,
    CONSTRAINT PK_diag_message_box_p21_ud PRIMARY KEY (id)
);
GO

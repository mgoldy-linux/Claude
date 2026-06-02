-- =============================================================================
-- message_log_p21_ud
-- Logs unrecognized P21 message box events for end-of-day review.
-- Populated by asi_oe_suppress_oe_msgs business rule.
-- Reviewed daily to determine suppress/allow/ignore per message.
-- =============================================================================

USE P21BusinessRules;
GO

CREATE TABLE dbo.message_log_p21_ud (
    id              INT             IDENTITY(1,1)   NOT NULL,
    message_no      INT                             NOT NULL,
    message_title   VARCHAR(100)                    NULL,
    method_name     VARCHAR(255)                    NULL,
    user_text       NVARCHAR(MAX)                   NULL,
    first_seen      DATETIME        DEFAULT GETDATE() NOT NULL,
    last_seen       DATETIME        DEFAULT GETDATE() NOT NULL,
    seen_count      INT             DEFAULT 1        NOT NULL,
    reviewed        CHAR(1)         DEFAULT 'N'      NOT NULL,
    action_taken    VARCHAR(10)                      NULL,
    CONSTRAINT PK_message_log_p21_ud        PRIMARY KEY (id),
    CONSTRAINT UQ_message_log_p21_ud        UNIQUE (message_no),
    CONSTRAINT CK_message_log_reviewed      CHECK (reviewed     IN ('Y', 'N')),
    CONSTRAINT CK_message_log_action_taken  CHECK (action_taken IN ('SUPPRESS', 'ALLOW', 'IGNORE'))
);
GO

-- Grant permissions
GRANT INSERT, UPDATE, SELECT ON dbo.message_log_p21_ud TO p21_application_role;
GRANT INSERT, UPDATE, SELECT ON dbo.message_log_p21_ud TO PxxiUser;
GO

--AddScript
-- Generated 2026-05-03 from message_log_p21_ud
GO
USE [P21BusinessRules];
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 1,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Update was not successful. | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 318,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | A valid inventory bin must be entered. | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 678,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Mandatory Note: Note: Windwalker, landed cost driver, $4,800.00 freight. | seen 6x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4003,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Modify statement failed in DataWindow. .Height= ! DataObject: d_dw_rf_container_receipts_line. | seen 3x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4132,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | The received quantity entered exceeds the remaining quantity. Do you want to continue? | seen 2x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4201,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Order may currently be edited by another user. Do you want to continue to retrieve? | seen 3x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4215,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Vessel Receipt Number does not pass validation. | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4234,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | The corporation has exceeded its credit limit. Do you want to continue? | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4326,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Changes to this user''s settings will not take effect until the next time the user logs in. Do you want to continue? | seen 2x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4916,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Order must be paid in full for a cod customer. Continue? | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 4978,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Do you want to clear the record? | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 8254,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Invalid Vessel Receipt Number for Container Name. | seen 1x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 10470,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | There are no incomplete line items on this Container. | seen 2x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 10800,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Unapproved receipts exist against this Vessel. Select from these receipts? | seen 5x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 12401,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | \\asp21fs1\BusinessRules\Portals\purch_open_po_edi_ack_exceptions_v3.srd | seen 5x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 13774,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | The specified portal element has already been installed. | seen 3x';
GO
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = 13775,
    @message_title      = '',
    @message_action     = 'ALLOW',  -- review: SUPPRESS / ALLOW
    @last_maintained_by = 'mgoldyn',
    @suppression_reason = ' | Browser elements require both a Portal Element Name and a URL. | seen 2x';
GO

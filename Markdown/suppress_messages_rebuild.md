# Suppress Messages System - Rebuild Steps
# P21BusinessRules Database

## Overview
Business rule `asi_oe_suppress_oe_msgs` fires on Order Entry message box events.
Checks a suppression table to decide whether to suppress, allow, or log the message.
P21 business rules run under the logged-in user's Windows account (confirmed via XE trace).

---

## Step 1 - Alter suppress_messages_p21_ud table
File: C:\Claude\step3a_alter_suppress_messages_p21_ud.sql

Adds message_action column (VARCHAR(10), DEFAULT 'SUPPRESS', CHECK: SUPPRESS or ALLOW).
Existing rows default to SUPPRESS automatically.

---

## Step 2 - Create message_log_p21_ud table
File: C:\Claude\step2_create_message_log_p21_ud.sql

Logs unrecognized messages for end-of-day review.
Columns: message_no, message_title, method_name, user_text,
         first_seen, last_seen, seen_count, reviewed, action_taken

Also drops diag_message_box_p21_ud (diagnostic table, no longer needed).

---

## Step 3 - Create usp_suppress_messages_p21_ud procedure
File: C:\Claude\step3_usp_suppress_messages_p21_ud.sql

Actions:
  ADD     - insert or update a message in suppress_messages_p21_ud
  REMOVE  - delete a message from suppress_messages_p21_ud
  LIST    - return all suppressed messages
  CHECK   - returns 'SUPPRESS', 'ALLOW', or 'ALERT' (no longer returns BIT)
  LOG     - insert or update message_log_p21_ud for end-of-day review

Grants EXECUTE to p21_application_role and PxxiUser.

---

## Step 4 - Grant permissions on tables

USE P21BusinessRules;
GRANT INSERT, UPDATE, SELECT ON dbo.message_log_p21_ud       TO p21_application_role;
GRANT INSERT, UPDATE, SELECT ON dbo.message_log_p21_ud       TO PxxiUser;
GRANT INSERT, UPDATE, SELECT ON dbo.suppress_messages_p21_ud TO p21_application_role;
GRANT INSERT, UPDATE, SELECT ON dbo.suppress_messages_p21_ud TO PxxiUser;
GRANT EXECUTE ON dbo.usp_suppress_messages_p21_ud            TO p21_application_role;
GRANT EXECUTE ON dbo.usp_suppress_messages_p21_ud            TO PxxiUser;

---

## Step 5 - Deploy business rule t9
File: C:\Claude\CSharp\asi_oe_suppress_oe_msgs_t9.cs

Logic:
  CHECK returns SUPPRESS  - set suppress_message = Y, hide popup
  CHECK returns ALLOW     - let popup through, no action
  CHECK returns ALERT     - let popup through, call LOG action to record in message_log_p21_ud

---

## Step 6 - End of day review query

USE P21BusinessRules;
SELECT message_no, message_title, method_name, user_text,
       first_seen, last_seen, seen_count, reviewed, action_taken
FROM   dbo.message_log_p21_ud
WHERE  reviewed = 'N'
ORDER  BY seen_count DESC, first_seen ASC;

-- After review, mark actioned and add to suppression table if needed:
-- SUPPRESS or ALLOW:
EXEC dbo.usp_suppress_messages_p21_ud
    @action             = 'ADD',
    @message_no         = <message_no>,
    @message_title      = '<message_title>',
    @suppression_reason = '<reason>';

UPDATE dbo.message_log_p21_ud
SET    reviewed     = 'Y',
       action_taken = 'SUPPRESS'  -- or ALLOW or IGNORE
WHERE  message_no   = <message_no>;

---

## Key Findings
- P21 runs business rules under the logged-in user's Windows account (NOT admin or service account)
- Confirmed via XE trace capturing error 229 on INSERT attempt - user was AHI\mgoldyn
- p21_application_role and PxxiUser are the correct accounts to grant permissions to
- DB mail route abandoned - permission complexity not worth it
- Use message_log_p21_ud table for end-of-day review instead of email alerts
- diag_message_box_p21_ud was a temporary diagnostic table - dropped after use
- Available MessageBoxData fields: rowID, button, default_button, icon, message_no,
  message_title, method_name, suppress_message, technical_text, user_text

---

## Still Open
- Test t9 business rule end-to-end in DEV
- Add all steps to backup/restore script for prod rollout

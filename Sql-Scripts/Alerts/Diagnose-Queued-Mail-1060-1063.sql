-- Diagnose alert_queued_mail rows stuck at reason_cd 1060 / row_status_flag 1063
-- (session: "Alert email queue failures", 2026-09-16)
-- Run in SSMS against the same DB the pasted query results came from.

-- 1) Confirm what these codes actually mean (authoritative source: code_p21)
SELECT code_no, code_description, code_sub_description, row_status_flag
FROM code_p21
WHERE code_no IN (1060, 1063);

-- 2) Trap 1 check: is alert_message.sender_email_address '' instead of NULL
--    for the alerts that produced these three queued rows?
--    (Low PAD Margin - Team / Low PAD Margin vs MAC (Purchasing) / Low Margin vs MAC (Purchasing))
SELECT ai.alert_implementation_uid, ai.alert_implementation_name, ai.row_status_flag AS alert_active_flag,
       am.alert_message_uid, am.subject,
       am.sender_email_address,
       CASE
           WHEN am.sender_email_address IS NULL THEN 'NULL (correct - falls back to system_setting)'
           WHEN am.sender_email_address = '' THEN '''''  <-- BUG: empty string blocks fallback, causes reason_cd 1060'
           ELSE am.sender_email_address
       END AS sender_diagnosis
FROM alert_implementation ai
JOIN alert_message am ON am.alert_implementation_uid = ai.alert_implementation_uid
WHERE am.subject LIKE 'Low%Margin%';

-- 3) Trap 2 check: any recipient rows that resolve to a blank/NULL address
--    for these same alerts (dynamic tokens with no data on the order, e.g. no primary salesrep)
SELECT ar.alert_recipient_uid, am.subject, ar.alert_email_address, ar.recipient_type_cd, ar.row_status_flag
FROM alert_recipient ar
JOIN alert_message am ON am.alert_message_uid = ar.alert_message_uid
WHERE am.subject LIKE 'Low%Margin%'
ORDER BY am.subject;

-- 4) The specific stuck rows from the pasted results, for reference
SELECT alert_queued_mail_uid, subject, email_to, reason_cd, row_status_flag, date_created
FROM alert_queued_mail
WHERE alert_queued_mail_uid IN (235, 236, 237);

-- 5) Fix, once (2) confirms an empty-string sender:
-- UPDATE alert_message SET sender_email_address = NULL
-- WHERE alert_message_uid = <uid> AND sender_email_address = '';

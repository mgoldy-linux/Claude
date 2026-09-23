-- Follow-up on Diagnose-Queued-Mail-1060-1063.sql: rows 235/236 (order 6149016) are stuck
-- with a valid NULL sender and no blank recipient in email_to -- the one outlier is the
-- external-domain Sales Rep address kisken@alltileccs.com. Check whether it's the culprit.

-- 1) Is this address current/active anywhere in P21's own contact data?
SELECT * FROM contacts WHERE email_address = 'kisken@alltileccs.com';
SELECT * FROM users WHERE email_address = 'kisken@alltileccs.com';

-- 2) Has any other alert_queued_mail row (any alert, any time) stalled with this
--    same domain in the recipient list? If alltileccs.com shows up repeatedly, that's
--    a relay/deliverability pattern, not a one-off.
SELECT alert_queued_mail_uid, subject, email_to, reason_cd, row_status_flag, date_created
FROM alert_queued_mail
WHERE email_to LIKE '%alltileccs.com%';

-- 3) For comparison: any stuck rows where every recipient IS @allsurfaces.com
--    (rules out a generic "all mail from this alert stalls" explanation)
SELECT alert_queued_mail_uid, subject, email_to, reason_cd, row_status_flag, date_created
FROM alert_queued_mail
WHERE row_status_flag = 1063
  AND email_to NOT LIKE '%alltileccs.com%'
  AND email_to NOT LIKE '%<>%';

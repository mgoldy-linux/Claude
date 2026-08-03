-- Tags every P21Play alert_message row (subject + footer) as belonging to the Play environment,
-- so a test-fired alert can never be mistaken for the real Prod alert.
-- Idempotent: safe to re-run after future P21Play refreshes from Prod.
-- Run against P21Play only -- never against P21 Prod.

USE [P21Play];
GO

-- ============================================================================
-- PREVIEW (read-only) -- run this block first and review before the UPDATEs below.
-- Shows old vs. new subject/footer for every row the script would actually touch;
-- rows where nothing would change are omitted.
-- ============================================================================
WITH replaced AS (
    SELECT
        alert_message_uid,
        subject AS old_subject,
        CAST(footer AS varchar(max)) AS old_footer,
        REPLACE(REPLACE(subject, 'P21 Prod', 'P21Play'), 'P21Prod', 'P21Play') AS subject_r,
        REPLACE(REPLACE(CAST(ISNULL(footer,'') AS varchar(max)), 'P21 Prod', 'P21Play'), 'P21Prod', 'P21Play') AS footer_r
    FROM dbo.alert_message
),
tagged AS (
    SELECT
        alert_message_uid, old_subject, old_footer, subject_r, footer_r,
        CASE WHEN subject_r NOT LIKE '%P21Play%' AND subject_r NOT LIKE '%P21 Play%'
              AND footer_r  NOT LIKE '%P21Play%' AND footer_r  NOT LIKE '%P21 Play%'
             THEN '[P21Play] ' + subject_r ELSE subject_r END AS new_subject,
        CASE WHEN subject_r NOT LIKE '%P21Play%' AND subject_r NOT LIKE '%P21 Play%'
              AND footer_r  NOT LIKE '%P21Play%' AND footer_r  NOT LIKE '%P21 Play%'
             THEN footer_r + CASE WHEN LEN(footer_r) > 0 THEN CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10) ELSE '' END + '(Sent from P21Play)'
             ELSE footer_r END AS new_footer
    FROM replaced
)
SELECT
    alert_message_uid,
    old_subject,
    new_subject,
    CAST(old_footer AS varchar(400))  AS old_footer_preview,
    CAST(new_footer AS varchar(400))  AS new_footer_preview
FROM tagged
WHERE old_subject <> new_subject OR old_footer <> new_footer
ORDER BY alert_message_uid;
GO
-- ============================================================================
-- END PREVIEW -- the statements below are the actual updates.
-- ============================================================================

-- Step 1: normalize any 'P21 Prod' / 'P21Prod' wording inherited from Prod's copy -> 'P21Play'
UPDATE dbo.alert_message
SET subject = REPLACE(REPLACE(subject, 'P21 Prod', 'P21Play'), 'P21Prod', 'P21Play'),
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE subject LIKE '%P21 Prod%' OR subject LIKE '%P21Prod%';
GO

UPDATE dbo.alert_message
SET footer = CAST(REPLACE(REPLACE(CAST(footer AS varchar(max)), 'P21 Prod', 'P21Play'), 'P21Prod', 'P21Play') AS text),
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE CAST(footer AS varchar(max)) LIKE '%P21 Prod%' OR CAST(footer AS varchar(max)) LIKE '%P21Prod%';
GO

-- Step 2: for any alert where neither subject nor footer already references Play
-- (accepts existing 'P21Play' or 'P21 Play' spellings so already-tagged test alerts aren't double-tagged),
-- prefix the subject and append a footer note.
UPDATE dbo.alert_message
SET subject = '[P21Play] ' + subject,
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE subject NOT LIKE '%P21Play%' AND subject NOT LIKE '%P21 Play%'
  AND CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21Play%'
  AND CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21 Play%';
GO

UPDATE dbo.alert_message
SET footer = CAST(
                 CAST(ISNULL(footer,'') AS varchar(max))
                 + CASE WHEN LEN(CAST(ISNULL(footer,'') AS varchar(max))) > 0
                        THEN CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10) ELSE '' END
                 + '(Sent from P21Play)'
             AS text),
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21Play%'
  AND CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21 Play%';
GO

-- Verify
SELECT alert_message_uid, subject, CAST(footer AS varchar(500)) AS footer_preview
FROM dbo.alert_message
ORDER BY alert_message_uid;
GO

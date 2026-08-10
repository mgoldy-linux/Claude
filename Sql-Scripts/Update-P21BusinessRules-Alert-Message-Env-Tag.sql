-- Tags every P21BusinessRules alert_message row (subject + footer) as belonging to the BRR environment,
-- so a test-fired alert can never be mistaken for the real Prod alert.
-- Idempotent: safe to re-run after future P21BusinessRules refreshes from Prod.
-- Run against P21BusinessRules only -- never against P21 Prod.
-- BRR variant of Update-P21Play-Alert-Message-Env-Tag.sql / Update-P21Training-Alert-Message-Env-Tag.sql (same pattern).
-- Tag uses 'P21BRR' (not 'P21BusinessRules') to match the shorthand already established for this env
-- (location names get a ' Test BRR' suffix -- see Sync-LocationNames-LowerEnvs.ps1).

USE [P21BusinessRules];
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
        REPLACE(REPLACE(subject, 'P21 Prod', 'P21BRR'), 'P21Prod', 'P21BRR') AS subject_r,
        REPLACE(REPLACE(CAST(ISNULL(footer,'') AS varchar(max)), 'P21 Prod', 'P21BRR'), 'P21Prod', 'P21BRR') AS footer_r
    FROM dbo.alert_message
),
tagged AS (
    SELECT
        alert_message_uid, old_subject, old_footer, subject_r, footer_r,
        CASE WHEN subject_r NOT LIKE '%P21BRR%' AND subject_r NOT LIKE '%P21 BRR%'
              AND footer_r  NOT LIKE '%P21BRR%' AND footer_r  NOT LIKE '%P21 BRR%'
             THEN '[P21BRR] ' + subject_r ELSE subject_r END AS new_subject,
        CASE WHEN subject_r NOT LIKE '%P21BRR%' AND subject_r NOT LIKE '%P21 BRR%'
              AND footer_r  NOT LIKE '%P21BRR%' AND footer_r  NOT LIKE '%P21 BRR%'
             THEN footer_r + CASE WHEN LEN(footer_r) > 0 THEN CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10) ELSE '' END + '(Sent from P21BRR)'
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

-- Step 1: normalize any 'P21 Prod' / 'P21Prod' wording inherited from Prod's copy -> 'P21BRR'
UPDATE dbo.alert_message
SET subject = REPLACE(REPLACE(subject, 'P21 Prod', 'P21BRR'), 'P21Prod', 'P21BRR'),
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE subject LIKE '%P21 Prod%' OR subject LIKE '%P21Prod%';
GO

UPDATE dbo.alert_message
SET footer = CAST(REPLACE(REPLACE(CAST(footer AS varchar(max)), 'P21 Prod', 'P21BRR'), 'P21Prod', 'P21BRR') AS text),
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE CAST(footer AS varchar(max)) LIKE '%P21 Prod%' OR CAST(footer AS varchar(max)) LIKE '%P21Prod%';
GO

-- Step 2: for any alert where neither subject nor footer already references BRR
-- (accepts existing 'P21BRR' or 'P21 BRR' spellings so already-tagged test alerts aren't double-tagged),
-- prefix the subject and append a footer note.
UPDATE dbo.alert_message
SET subject = '[P21BRR] ' + subject,
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE subject NOT LIKE '%P21BRR%' AND subject NOT LIKE '%P21 BRR%'
  AND CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21BRR%'
  AND CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21 BRR%';
GO

UPDATE dbo.alert_message
SET footer = CAST(
                 CAST(ISNULL(footer,'') AS varchar(max))
                 + CASE WHEN LEN(CAST(ISNULL(footer,'') AS varchar(max))) > 0
                        THEN CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10) ELSE '' END
                 + '(Sent from P21BRR)'
             AS text),
    date_last_modified = GetDate(),
    last_maintained_by = 'mgoldyn_job_sql'
WHERE CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21BRR%'
  AND CAST(ISNULL(footer,'') AS varchar(max)) NOT LIKE '%P21 BRR%';
GO

-- Verify
SELECT alert_message_uid, subject, CAST(footer AS varchar(500)) AS footer_preview
FROM dbo.alert_message
ORDER BY alert_message_uid;
GO

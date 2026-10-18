-- =============================================================================
-- Classify-Popup-Source.sql
-- Answers the actual ask (Todo-BusApps #9): for each OE popup, is the source
-- a Business Rule, DynaChange (Pre-SQL rule), or a native P21 setting?
--
-- Method: for a shortlist of message_no values (pulled from the highest-
-- frequency rows in Order-Popup-Audit-1Yr.sql), sample recent occurrences and
-- look for a business_rule_log entry from the SAME user within a tight time
-- window of each popup. A DynaChange Pre-SQL rule still registers in
-- business_rule_log like any other rule -- it's distinguished by P21 stamping
-- its output "--SQL has been modified via Dynachange Rule", not by a separate
-- rule type. No correlated business_rule_log row at all -> native P21
-- (system_setting / hardcoded validation), since there's no custom rule to log.
--
-- This narrows hundreds of message_no down to "go read this specific rule"
-- vs "this is native, check DynaChange/system_setting instead" -- it doesn't
-- replace actually reading the matched rule once you have its name.
--
-- KNOWN CONFOUND (confirmed 2026-09-22): asi_oe_suppress_oe_msgs is a
-- listener rule that fires on every OE message box regardless of what
-- caused it (see Markdown\suppress_messages_rebuild.md) -- excluded below
-- so it doesn't get counted as "the" source. If any OTHER rule shows this
-- same listener-style pattern (matches constantly, unrelated to the specific
-- message), exclude it the same way rather than trusting the correlation.
-- Since this rule is confirmed live, also check P21BusinessRules.dbo.
-- message_log_p21_ud.method_name for these message_no's directly.
--
-- CUSTOM vs NATIVE RULE (confirmed 2026-09-22): a business_rule_log match
-- doesn't automatically mean "your company's custom code." rule_assembly_name
-- distinguishes them -- Epicor's own shipped rule library runs as
-- "P21.Rules, Version=..." (e.g. rule_name "LibraryExport"), while custom
-- company rules run out of company-named assemblies like
-- "asi_oe_suppress_oe_msgs, Version=...". A P21.Rules match is still native
-- P21 functionality for classification purposes -- Epicor just implemented
-- that check via the rule engine instead of hardcoding it in PowerBuilder.
-- =============================================================================

DECLARE @MessageNos TABLE (message_no INT);
INSERT INTO @MessageNos (message_no) VALUES
    (93), (451), (1000), (12842);   -- <-- paste your OE-relevant shortlist here

-- Sample only the most recent N occurrences per message_no -- high-frequency
-- ones (300K+ rows for message_no 1001) don't need a full-year join to show
-- the correlation pattern, and a full join would be needless scan cost.
;WITH sampled AS (
    SELECT l.message_no, l.user_text, l.message_date, l.user_id,
           ROW_NUMBER() OVER (PARTITION BY l.message_no ORDER BY l.message_date DESC) AS rn
    FROM   message_log l
    WHERE  l.message_no IN (SELECT message_no FROM @MessageNos)
      AND  l.message_date >= DATEADD(YEAR, -1, GETDATE())
)
SELECT
    s.message_no,
    s.user_text,       -- generic message_no's (1000, 93, 4243, ...) cover unrelated
                        -- text -- always check this before comparing likely_source
                        -- across rows of the same message_no
    s.message_date,
    s.user_id,
    b.rule_name,
    b.rule_assembly_name,
    b.log_action,
    CASE WHEN b.xml LIKE '%Dynachange Rule%' OR b.return_message LIKE '%Dynachange Rule%'
              THEN 'DynaChange (Pre-SQL)'
         WHEN b.rule_assembly_name LIKE 'P21.%'
              THEN 'Native P21 rule (Epicor-shipped, via rule engine)'
         WHEN b.business_rule_log_uid IS NOT NULL
              THEN 'Custom Business Rule'
         ELSE 'No BR/DynaChange match -- likely native P21 (hardcoded, no rule)'
    END AS likely_source
FROM   sampled s
LEFT JOIN business_rule_log b
       ON b.user_id = s.user_id
      AND b.rule_name <> 'asi_oe_suppress_oe_msgs'   -- listener/observer rule, fires on
                                                       -- every OE message box regardless
                                                       -- of source -- not evidence of a
                                                       -- BR-driven popup, would otherwise
                                                       -- misclassify nearly everything
      AND b.date_created BETWEEN DATEADD(SECOND, -2, s.message_date)
                              AND DATEADD(SECOND,  2, s.message_date)
WHERE  s.rn <= 25
ORDER BY s.message_no, s.message_date DESC;

-- Roll up once you've eyeballed the detail above:
-- (wrap the SELECT block above as a derived table `x` and run)
-- SELECT message_no, likely_source, COUNT(*) AS sample_hits
-- FROM x
-- GROUP BY message_no, likely_source
-- ORDER BY message_no, sample_hits DESC;

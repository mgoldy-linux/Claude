-- ============================================================
-- Analyze-OrderAck-Subject-RepText-2026.sql
-- ============================================================
-- Purpose : SA 54321. Two open questions, one query:
--
--           Q1. Do reps actually type anything into the Order Ack email
--               subject box? If most leave it blank, the char(60) budget
--               is a non-issue. If they type sentences, our PO/Sidemark
--               segment competes with them for the same 60 characters.
--
--           Q2. What would the PO / Sidemark segment actually produce on
--               real orders, under each SegmentPolicy? (guide concern #2:
--               IdentifierOnly drops legitimate project names, ScrubAndCap
--               would pass internal notes like "Replacement for Leyza")
--
-- How     : email_log holds the DELIVERED subject line for document email
--           (per the Low Margin Alert research: email_log covers document
--           email only, never alerts -- an Order Ack is document email).
--           P21 builds the prefix itself and appends the rep's free text,
--           so everything AFTER the order number IS the rep's portion.
--
--           The prefix is NOT a fixed character count -- it varies by
--           environment banner and by use_branch_name_in_subject_flag
--           ("All Surfaces - Acknowledgement# 6136269" vs
--            "** BusinessRules 20260825 ** - Acknowledgement# 6109021").
--           So we locate transaction_number inside the subject with
--           CHARINDEX and cut after it, rather than trusting a fixed
--           offset. CHARINDEX not LIKE -- see
--           feedback_sql_like_charindex_mismatch.
--
-- Run on  : asdwdb01 (nightly 2:05 restore from Prod) -- NOT Prod.
--           This scans a full year of email_log; there is no useful index
--           on transaction_type, so it is a scan either way. Run it where
--           a scan costs nothing. Read-only regardless.
--           Sandbox blocks TDS from the workspace; run this in SSMS.
--
-- Author  : 2026-09-08
-- ============================================================

SET NOCOUNT ON;

DECLARE @YearStart date = '2026-01-01';
DECLARE @YearEnd   date = '2027-01-01';

-- The rule's own limits, mirrored from asi_oe_order_ack_email_subject.cs
-- so the "would it fit" math below matches what the rule actually does.
DECLARE @SubjectCap    int = 60;   -- char(60); P21's prefix does NOT count
DECLARE @MaxSegmentLen int = 30;   -- per-value cap in both policies

-- ------------------------------------------------------------
-- 1. Extract once into a temp table.
--    Everything downstream reads the temp, so email_log is scanned
--    exactly once instead of once per question.
-- ------------------------------------------------------------
IF OBJECT_ID('tempdb..#ack') IS NOT NULL DROP TABLE #ack;

CREATE TABLE #ack (
    order_no      varchar(20)   NULL,   -- varchar so the oe_hdr join can seek
    sender_name   varchar(255)  NULL,
    date_created  datetime      NULL,
    full_subject  varchar(1000) NULL,
    rep_text      varchar(1000) NULL,
    rep_len       int           NULL
);

INSERT INTO #ack (order_no, sender_name, date_created, full_subject, rep_text)
SELECT
    order_no     = LTRIM(RTRIM(CONVERT(varchar(20), e.transaction_number))),
    e.sender_name,
    e.date_created,
    full_subject = LTRIM(RTRIM(e.subject)),
    -- Everything after the order number, with a leading separator
    -- ("|", "-", ":") and surrounding whitespace stripped. When the rep
    -- types nothing the observed subject ends "...Acknowledgement# 6136269|",
    -- so that bare trailing pipe must read as EMPTY, not as one character.
    rep_text =
        LTRIM(RTRIM(
            SUBSTRING(
                LTRIM(RTRIM(e.subject)),
                CHARINDEX(LTRIM(RTRIM(CONVERT(varchar(20), e.transaction_number))),
                          LTRIM(RTRIM(e.subject)))
                    + LEN(LTRIM(RTRIM(CONVERT(varchar(20), e.transaction_number)))),
                1000)
        ))
FROM   email_log e
WHERE  e.transaction_type = 'ORDER ACKNOWLEDGEMENT'
  AND  e.date_created >= @YearStart
  AND  e.date_created <  @YearEnd
  AND  e.subject IS NOT NULL
  -- only rows where the order number really appears in the subject, so a
  -- differently-formatted subject cannot silently produce garbage rep_text
  AND  CHARINDEX(LTRIM(RTRIM(CONVERT(varchar(20), e.transaction_number))),
                 LTRIM(RTRIM(e.subject))) > 0;

-- Strip one leading separator character, then re-trim.
UPDATE #ack
SET    rep_text = LTRIM(RTRIM(SUBSTRING(rep_text, 2, 1000)))
WHERE  LEFT(rep_text, 1) IN ('|', '-', ':');

UPDATE #ack SET rep_len = LEN(rep_text);

-- ------------------------------------------------------------
-- 2. SANITY CHECK -- read this FIRST.
--    If the parse is wrong every number below is wrong. Eyeball that
--    full_subject really does split into prefix + rep_text as expected.
-- ------------------------------------------------------------
SELECT TOP 25
       '2. PARSE SANITY CHECK' AS section,
       order_no, full_subject, rep_text, rep_len
FROM   #ack
ORDER BY NEWID();

-- ------------------------------------------------------------
-- 3. Q1 ANSWER -- how often does a rep type anything at all?
-- ------------------------------------------------------------
SELECT
    '3. DOES ANYONE TYPE?'  AS section,
    total_acks              = COUNT(*),
    left_blank              = SUM(CASE WHEN rep_len = 0 THEN 1 ELSE 0 END),
    pct_blank               = CONVERT(decimal(5,1),
                                100.0 * SUM(CASE WHEN rep_len = 0 THEN 1 ELSE 0 END)
                                / NULLIF(COUNT(*), 0)),
    typed_something         = SUM(CASE WHEN rep_len > 0 THEN 1 ELSE 0 END),
    avg_len_when_typed      = AVG(CASE WHEN rep_len > 0 THEN rep_len END),
    max_len_when_typed      = MAX(rep_len),
    distinct_senders        = COUNT(DISTINCT sender_name)
FROM   #ack;

-- ------------------------------------------------------------
-- 4. How much room does the rep's text actually consume?
--    Buckets are drawn against the 60-char cap and against the two
--    real segment sizes measured in BRR on 2026-09-08:
--      "| PO 111-6053217-3210625 | Sidemark x"  = 38 chars
--      "| PO 57354"                             = 10 chars
-- ------------------------------------------------------------
SELECT
    '4. REP TEXT LENGTH'    AS section,
    bucket = CASE
                WHEN rep_len = 0            THEN 'a. blank'
                WHEN rep_len <= 10          THEN 'b. 1-10'
                WHEN rep_len <= 22          THEN 'c. 11-22  (fits beside a 38-char segment)'
                WHEN rep_len <= 36          THEN 'd. 23-36  (fits beside a 24-char PO-only segment)'
                WHEN rep_len <= 50          THEN 'e. 37-50  (fits beside a 10-char short PO)'
                WHEN rep_len <= 60          THEN 'f. 51-60  (fills the field on its own)'
                ELSE                             'g. 60+    (already over -- investigate)'
             END,
    orders  = COUNT(*),
    pct     = CONVERT(decimal(5,1), 100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())
FROM   #ack
GROUP BY CASE
                WHEN rep_len = 0            THEN 'a. blank'
                WHEN rep_len <= 10          THEN 'b. 1-10'
                WHEN rep_len <= 22          THEN 'c. 11-22  (fits beside a 38-char segment)'
                WHEN rep_len <= 36          THEN 'd. 23-36  (fits beside a 24-char PO-only segment)'
                WHEN rep_len <= 50          THEN 'e. 37-50  (fits beside a 10-char short PO)'
                WHEN rep_len <= 60          THEN 'f. 51-60  (fills the field on its own)'
                ELSE                             'g. 60+    (already over -- investigate)'
         END
ORDER BY bucket;

-- ------------------------------------------------------------
-- 5. What reps actually write, most common first.
--    This is the qualitative half of Q1 -- a list of "Rush", "per Bob",
--    "REVISED" reads very differently from a list of full sentences.
-- ------------------------------------------------------------
SELECT TOP 60
       '5. WHAT THEY TYPE'  AS section,
       rep_text,
       rep_len,
       times_used = COUNT(*),
       senders    = COUNT(DISTINCT sender_name)
FROM   #ack
WHERE  rep_len > 0
GROUP BY rep_text, rep_len
ORDER BY COUNT(*) DESC, rep_len DESC;

-- ------------------------------------------------------------
-- 6. Q2 ANSWER -- what the PO / Sidemark segment would do on these
--    same orders, under each policy.
--
--    IdentifierOnly (live today): no spaces, <= @MaxSegmentLen, and only
--    characters you'd expect in a code. Approximated here as "no space and
--    within length" -- the C# also restricts the character set, so the
--    real rule is slightly STRICTER than this estimate. Treat the
--    IdentifierOnly counts as an upper bound.
--
--    Join note: #ack.order_no is varchar(20) and oe_hdr.order_no is left
--    unwrapped, so the optimizer can still seek. Do not wrap it in a
--    function here.
-- ------------------------------------------------------------
SELECT
    '6. SEGMENT POLICY'         AS section,
    orders_matched              = COUNT(*),

    po_present                  = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.po_no,'')))) > 0 THEN 1 ELSE 0 END),
    po_renders_today            = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.po_no,'')))) BETWEEN 1 AND @MaxSegmentLen
                                            AND CHARINDEX(' ', LTRIM(RTRIM(h.po_no))) = 0
                                       THEN 1 ELSE 0 END),
    po_dropped_for_space        = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.po_no,'')))) > 0
                                            AND CHARINDEX(' ', LTRIM(RTRIM(h.po_no))) > 0
                                       THEN 1 ELSE 0 END),
    po_dropped_for_length       = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.po_no,'')))) > @MaxSegmentLen
                                       THEN 1 ELSE 0 END),

    sidemark_present            = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) > 0 THEN 1 ELSE 0 END),
    sidemark_renders_today      = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) BETWEEN 1 AND @MaxSegmentLen
                                            AND CHARINDEX(' ', LTRIM(RTRIM(h.job_name))) = 0
                                       THEN 1 ELSE 0 END),
    -- THE decision number: how many orders would GAIN a sidemark by
    -- allowing spaces -- and therefore how many internal notes would
    -- also start reaching customers.
    sidemark_gained_if_spaces_ok = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) BETWEEN 1 AND @MaxSegmentLen
                                             AND CHARINDEX(' ', LTRIM(RTRIM(h.job_name))) > 0
                                        THEN 1 ELSE 0 END),
    sidemark_dropped_for_length  = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) > @MaxSegmentLen
                                        THEN 1 ELSE 0 END),
    -- guide concern #5: one customer uses 'x' as every job_name, and a
    -- single character passes IdentifierOnly today
    sidemark_1_or_2_chars        = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) BETWEEN 1 AND 2
                                        THEN 1 ELSE 0 END),

    po_equals_sidemark_deduped   = SUM(CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.po_no,'')))) > 0
                                             AND LTRIM(RTRIM(ISNULL(h.po_no,'')))
                                               = LTRIM(RTRIM(ISNULL(h.job_name,'')))
                                        THEN 1 ELSE 0 END)
FROM   #ack a
JOIN   oe_hdr h ON h.order_no = a.order_no;

-- ------------------------------------------------------------
-- 7. THE RISK LIST -- the values that would newly reach customers if
--    spaces were allowed. Review this before changing SegmentPolicy.
--    Anything here that reads like an internal note is a reason not to.
-- ------------------------------------------------------------
SELECT TOP 100
       '7. WOULD BE EXPOSED'    AS section,
       sidemark   = LTRIM(RTRIM(h.job_name)),
       chars      = LEN(LTRIM(RTRIM(h.job_name))),
       orders     = COUNT(*)
FROM   #ack a
JOIN   oe_hdr h ON h.order_no = a.order_no
WHERE  LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) BETWEEN 1 AND @MaxSegmentLen
  AND  CHARINDEX(' ', LTRIM(RTRIM(h.job_name))) > 0
GROUP BY LTRIM(RTRIM(h.job_name))
ORDER BY COUNT(*) DESC;

-- ------------------------------------------------------------
-- 8. THE COLLISION -- orders where the rep's own text plus the segment
--    the rule would build together exceed 60 characters. These are the
--    orders where the rep loses their text (Sidemark is dropped first,
--    then the whole thing is left alone).
--    Segment length modelled as: "| PO " + po  [+ " | Sidemark " + job]
--    using only values that render under the CURRENT policy.
-- ------------------------------------------------------------
;WITH seg AS (
    SELECT
        a.order_no,
        a.rep_len,
        po_seg = CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.po_no,'')))) BETWEEN 1 AND @MaxSegmentLen
                       AND CHARINDEX(' ', LTRIM(RTRIM(h.po_no))) = 0
                      THEN 5 + LEN(LTRIM(RTRIM(h.po_no)))          -- "| PO "
                      ELSE 0 END,
        sm_seg = CASE WHEN LEN(LTRIM(RTRIM(ISNULL(h.job_name,'')))) BETWEEN 1 AND @MaxSegmentLen
                       AND CHARINDEX(' ', LTRIM(RTRIM(h.job_name))) = 0
                       AND LTRIM(RTRIM(ISNULL(h.job_name,''))) <> LTRIM(RTRIM(ISNULL(h.po_no,'')))
                      THEN 12 + LEN(LTRIM(RTRIM(h.job_name)))      -- " | Sidemark "
                      ELSE 0 END
    FROM   #ack a
    JOIN   oe_hdr h ON h.order_no = a.order_no
)
SELECT
    '8. 60-CHAR COLLISION'  AS section,
    orders                  = COUNT(*),
    fits_untouched          = SUM(CASE WHEN po_seg + sm_seg + rep_len <= @SubjectCap THEN 1 ELSE 0 END),
    needs_sidemark_dropped  = SUM(CASE WHEN po_seg + sm_seg + rep_len >  @SubjectCap
                                        AND po_seg + rep_len <= @SubjectCap THEN 1 ELSE 0 END),
    no_room_at_all          = SUM(CASE WHEN po_seg + rep_len > @SubjectCap THEN 1 ELSE 0 END),
    pct_degraded            = CONVERT(decimal(5,1),
                                100.0 * SUM(CASE WHEN po_seg + sm_seg + rep_len > @SubjectCap THEN 1 ELSE 0 END)
                                / NULLIF(COUNT(*), 0))
FROM   seg;

DROP TABLE #ack;

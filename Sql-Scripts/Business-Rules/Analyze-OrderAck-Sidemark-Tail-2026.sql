-- ============================================================
-- Analyze-OrderAck-Sidemark-Tail-2026.sql
-- ============================================================
-- Purpose : SA 54321, follow-up to Analyze-OrderAck-Subject-RepText-2026.sql.
--
--           That script's section 7 listed the 100 most FREQUENTLY USED
--           spaced job_name values, and they looked reassuring -- builder
--           names and job sites. But ranking by frequency structurally
--           hides the thing we are actually worried about: note-style text
--           ("Replacement for Leyza", "put on wrong account", "wrong
--           material sent") is written once, on one order, and can never
--           appear in a top-N-by-count list.
--
--           89,675 orders would gain a Sidemark if spaces were allowed.
--           This script asks how many of those are in the long tail, what
--           the tail actually says, and how much of the risk a minimum
--           length plus a blocklist would remove.
--
-- Reads    : sections 2-3 quantify the tail; section 4 is the human review
--            list (random sample -- re-run for a different draw);
--            sections 5-6 test the two structural heuristics; section 7
--            scores the recommended middle policy.
--
-- Run on   : asdwdb01 (nightly 2:05 restore from Prod) -- NOT Prod.
--            Read-only. Sandbox blocks TDS from the workspace; use SSMS.
--
-- Author   : 2026-09-08
-- ============================================================

SET NOCOUNT ON;

DECLARE @YearStart date = '2026-01-01';
DECLARE @YearEnd   date = '2027-01-01';
DECLARE @MaxSegmentLen int = 30;   -- current per-value cap
DECLARE @MinSegmentLen int = 3;    -- the proposed minimum (guide concern #5)

-- ------------------------------------------------------------
-- 1. Population: every order that actually received an Order Ack email
--    in 2026, with the sidemark that WOULD newly render if spaces were
--    allowed (has a space, within the length cap).
--    Same population as the previous script, so the counts reconcile.
-- ------------------------------------------------------------
IF OBJECT_ID('tempdb..#tail') IS NOT NULL DROP TABLE #tail;

CREATE TABLE #tail (
    sidemark    varchar(255) NULL,
    chars       int          NULL,
    words       int          NULL,
    orders      int          NULL
);

INSERT INTO #tail (sidemark, chars, words, orders)
SELECT
    sidemark = LTRIM(RTRIM(h.job_name)),
    chars    = LEN(LTRIM(RTRIM(h.job_name))),
    -- word count = spaces + 1, after the trim above
    words    = LEN(LTRIM(RTRIM(h.job_name)))
             - LEN(REPLACE(LTRIM(RTRIM(h.job_name)), ' ', '')) + 1,
    orders   = COUNT(*)
FROM   (
        SELECT DISTINCT order_no = LTRIM(RTRIM(CONVERT(varchar(20), e.transaction_number)))
        FROM   email_log e
        WHERE  e.transaction_type = 'ORDER ACKNOWLEDGEMENT'
          AND  e.date_created >= @YearStart
          AND  e.date_created <  @YearEnd
       ) a
JOIN   oe_hdr h ON h.order_no = a.order_no
WHERE  LEN(LTRIM(RTRIM(ISNULL(h.job_name, '')))) BETWEEN 1 AND @MaxSegmentLen
  AND  CHARINDEX(' ', LTRIM(RTRIM(h.job_name))) > 0
GROUP BY LTRIM(RTRIM(h.job_name));

-- ------------------------------------------------------------
-- 2. How much of the 89,675 lives in the tail?
--    If most orders use a value that hundreds of other orders also use,
--    reviewing the top 100 was nearly sufficient. If most orders use a
--    value seen once or twice, it was nearly worthless.
-- ------------------------------------------------------------
SELECT
    '2. CONCENTRATION'  AS section,
    usage_band = CASE
                    WHEN orders = 1        THEN 'a. used on 1 order'
                    WHEN orders = 2        THEN 'b. used on 2'
                    WHEN orders BETWEEN 3 AND 5   THEN 'c. used on 3-5'
                    WHEN orders BETWEEN 6 AND 20  THEN 'd. used on 6-20'
                    ELSE                        'e. used on 21+'
                 END,
    distinct_values = COUNT(*),
    total_orders    = SUM(orders),
    pct_of_orders   = CONVERT(decimal(5,1),
                        100.0 * SUM(orders) / SUM(SUM(orders)) OVER ())
FROM   #tail
GROUP BY CASE
                    WHEN orders = 1        THEN 'a. used on 1 order'
                    WHEN orders = 2        THEN 'b. used on 2'
                    WHEN orders BETWEEN 3 AND 5   THEN 'c. used on 3-5'
                    WHEN orders BETWEEN 6 AND 20  THEN 'd. used on 6-20'
                    ELSE                        'e. used on 21+'
         END
ORDER BY usage_band;

-- ------------------------------------------------------------
-- 3. Totals, so section 2 has a denominator to check against.
-- ------------------------------------------------------------
SELECT
    '3. TOTALS'       AS section,
    distinct_values   = COUNT(*),
    total_orders      = SUM(orders),
    avg_chars         = AVG(chars),
    max_chars         = MAX(chars)
FROM   #tail;

-- ------------------------------------------------------------
-- 4. THE REVIEW LIST -- a random sample of rarely-used values.
--    This is the section to actually read. Frequency ranking cannot
--    surface these; a random draw can. Re-run for a fresh sample.
-- ------------------------------------------------------------
SELECT TOP 300
       '4. TAIL SAMPLE'  AS section,
       sidemark, chars, words, orders
FROM   #tail
WHERE  orders <= 2
ORDER BY NEWID();

-- ------------------------------------------------------------
-- 5. Structural heuristic: word count.
--    Independent of vocabulary -- "Bielinski Homes" is 2 words,
--    "put on wrong account" is 4. Sentences are not sidemarks.
-- ------------------------------------------------------------
SELECT
    '5. WORD COUNT'   AS section,
    words,
    distinct_values   = COUNT(*),
    total_orders      = SUM(orders),
    pct_of_orders     = CONVERT(decimal(5,1),
                          100.0 * SUM(orders) / SUM(SUM(orders)) OVER ())
FROM   #tail
GROUP BY words
ORDER BY words;

-- 5b. What the 4-plus-word values actually say -- judge the heuristic
--     by its false positives before trusting it.
SELECT TOP 150
       '5b. 4+ WORDS'  AS section,
       sidemark, chars, words, orders
FROM   #tail
WHERE  words >= 4
ORDER BY orders DESC, sidemark;

-- ------------------------------------------------------------
-- 6. Vocabulary heuristic: note-like terms.
--    Deliberately broad -- some of these WILL false-positive on
--    legitimate values ('test', 'short', 'free', 'hold', 'sample',
--    'return' can all appear in a real company or job name). Section 6b
--    shows the hits so the list can be tuned rather than trusted blind.
--    CHARINDEX not LIKE (feedback_sql_like_charindex_mismatch).
-- ------------------------------------------------------------
IF OBJECT_ID('tempdb..#terms') IS NOT NULL DROP TABLE #terms;
CREATE TABLE #terms (term varchar(50) PRIMARY KEY);
INSERT INTO #terms (term) VALUES
    ('wrong'),('replacement'),('replace'),('mistake'),('error'),
    ('cancel'),('void'),('credit'),('refund'),('return'),
    ('damage'),('defect'),('complaint'),('apolog'),
    ('do not'),('dont'),('please'),('will advise'),('advise'),
    ('picked up'),('pick up'),('p/u'),('personal'),
    ('per '),('call'),('email'),('spoke'),('told'),
    ('hold'),('issue'),('problem'),('fix'),('redo'),('recut'),('remake'),
    ('missing'),('short'),('lost'),('no charge'),('free'),
    ('reorder'),('re-order'),('warranty'),('account'),
    ('see note'),('tbd'),('unknown'),('test'),('?');

IF OBJECT_ID('tempdb..#flagged') IS NOT NULL DROP TABLE #flagged;
SELECT DISTINCT t.sidemark, t.chars, t.words, t.orders
INTO   #flagged
FROM   #tail t
JOIN   #terms x ON CHARINDEX(x.term, LOWER(t.sidemark)) > 0;

SELECT
    '6. NOTE-LIKE TERMS'  AS section,
    flagged_values        = (SELECT COUNT(*)  FROM #flagged),
    flagged_orders        = (SELECT ISNULL(SUM(orders),0) FROM #flagged),
    pct_of_orders         = CONVERT(decimal(5,1),
                              100.0 * (SELECT ISNULL(SUM(orders),0) FROM #flagged)
                              / NULLIF((SELECT SUM(orders) FROM #tail), 0));

-- 6b. Every flagged value, so false positives are visible.
SELECT TOP 200
       '6b. FLAGGED VALUES'  AS section,
       sidemark, chars, words, orders
FROM   #flagged
ORDER BY orders DESC, sidemark;

-- ------------------------------------------------------------
-- 7. Score the recommended middle policy:
--    allow spaces, require >= @MinSegmentLen chars, keep the 30-char cap,
--    and exclude anything matching the note-term blocklist.
--    "kept" is the real gain over today; "blocked" is what the guardrails
--    stop. Compare against the 89,675 an unguarded change would add.
-- ------------------------------------------------------------
SELECT
    '7. MIDDLE POLICY'   AS section,
    would_gain_unguarded = SUM(orders),
    kept_by_policy       = SUM(CASE WHEN t.chars >= @MinSegmentLen
                                     AND f.sidemark IS NULL
                                THEN t.orders ELSE 0 END),
    blocked_too_short    = SUM(CASE WHEN t.chars < @MinSegmentLen
                                THEN t.orders ELSE 0 END),
    blocked_by_terms     = SUM(CASE WHEN t.chars >= @MinSegmentLen
                                     AND f.sidemark IS NOT NULL
                                THEN t.orders ELSE 0 END)
FROM   #tail t
LEFT   JOIN #flagged f ON f.sidemark = t.sidemark;

DROP TABLE #tail;
DROP TABLE #terms;
DROP TABLE #flagged;

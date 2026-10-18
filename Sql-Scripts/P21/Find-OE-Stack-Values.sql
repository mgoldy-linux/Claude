-- =============================================================================
-- Find-OE-Stack-Values.sql
-- Builds the curated list of Order-Entry stack values before running the real
-- audit -- confirmed from a live sample (Sample-Message-Log-Stack.sql):
--   w_order_entry_sheet, n_cst_ordersrv, n_cst_oe_line_fx,
--   n_cst_vt_orderentry_tab2, n_cst_oelinedetailsrv,
--   n_cst_epf_orderprocessing_pubsub_handler
-- Candidate LIKE patterns below are a starting net, not a finished filter --
-- eyeball the output and add/remove message_no/stack pairs manually before
-- trusting it. Known gap: n_cst_customer.of_checkcreditstatusaction (message
-- 4706, credit hold) is OE-relevant but the object name is too generic to
-- pattern-match safely -- add it to the curated list by hand if you confirm it.
-- =============================================================================

SELECT DISTINCT
    message_no,
    stack,
    COUNT(*) OVER (PARTITION BY message_no, stack) AS occurrence_count
FROM   message_log
WHERE  message_date >= DATEADD(YEAR, -1, GETDATE())
  AND  stack IS NOT NULL
  AND (
        stack LIKE '%order_entry%'
     OR stack LIKE '%orderentry%'
     OR stack LIKE '%[_]oe[_]%'
     OR stack LIKE '%ordersrv%'
     OR stack LIKE '%oelinedetailsrv%'
     OR stack LIKE '%orderprocessing%'
      )
ORDER BY occurrence_count DESC, message_no;

-- Once curated, paste the confirmed stack values (or message_no list) into
-- Order-Popup-Audit-1Yr.sql's WHERE clause as an exact IN-list -- a leading-
-- wildcard LIKE over a year of message_log can't seek an index, so this
-- discovery pass is the only place that cost should be paid; the real
-- recurring audit should run against a fixed, confirmed list.

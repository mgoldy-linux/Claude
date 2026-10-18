-- =============================================================================
-- Sample-Message-Log-Stack.sql
-- Learn what message_log.stack actually looks like before building an
-- Order-Entry filter on it -- don't guess the object-naming pattern the way
-- window_flag got guessed wrong earlier in this audit.
--
-- Goal: find the PowerBuilder object/window naming convention Order Entry
-- popups use in stack (expect something built on oe_hdr/oe_line, e.g.
-- w_oe_order, n_cst_oe..., d_oe_... -- confirm from real data, don't assume).
-- =============================================================================

SELECT TOP 200
    message_no,
    user_text,
    message_date,
    user_id,
    stack
FROM   message_log
WHERE  message_date >= DATEADD(MONTH, -1, GETDATE())
  AND  stack IS NOT NULL
  AND  LTRIM(RTRIM(stack)) <> ''
ORDER BY message_date DESC;

-- =============================================================================
-- Order-Popup-Audit-1Yr.sql
-- Order-Entry-scoped popup audit, last 1 year. Confirmed against a live
-- sample of message_log.stack (see Sample-Message-Log-Stack.sql /
-- Find-OE-Stack-Values.sql history) -- not guessed.
--
-- message_no alone is NOT a reliable filter: several numbers (1, 93, 1000,
-- 3001, 4243, 6596, 9856, 12842) are generic wrapper codes reused across many
-- unrelated windows (Transfers, PO, Shipping, RMA, Inventory...). The real
-- predicate has to stay on `stack` (the calling PB object), plus a couple of
-- text-based rules for cases where the object itself is generic but the
-- embedded DataWindow name in user_text says OE.
--
-- Confirmed OE objects:
--   w_order_entry_sheet, n_cst_ordersrv, n_cst_oe_line_fx,
--   n_cst_vt_orderentry_tab2, n_cst_oelinedetailsrv,
--   n_cst_epf_orderprocessing_pubsub_handler, n_cst_srv_orderinfo,
--   n_cst_cmi_hdr_customer_br, n_ext_tax_srv_avalara
-- Confirmed OE special cases:
--   u_oc_ribbonuicontrol only when user_text references m_mymenu38 (the OE
--     ribbon specifically -- other ribbon tools are not OE)
--   n_tr (of_evaluatedbreturn) / n_cst_custom_objects::of_applymods only when
--     user_text embeds an oe_-prefixed DataWindow (d_dw_oe_.../d_ds_oe_...)
--     -- both objects are generic wrappers otherwise (seen firing for
--     Receipts, Item Inquiry, etc. with the same message_no)
-- Explicitly excluded: message_no 9856 ("insufficient Windows resources") --
-- confirmed firing from Transfers/Shipping/RMA/PO/Inventory/OE alike, a
-- system resource symptom, not an OE-sourceable popup.
-- =============================================================================

SELECT
    l.message_no,
    MAX(l.user_text)                       AS sample_user_text,
    COUNT(*)                               AS occurrence_count,
    COUNT(DISTINCT l.user_id)              AS distinct_users,
    MIN(l.message_date)                    AS first_seen,
    MAX(l.message_date)                    AS last_seen
FROM   message_log l
WHERE  l.message_date >= DATEADD(YEAR, -1, GETDATE())
  AND  l.message_no <> 9856
  AND (
        l.stack LIKE '%w_order_entry_sheet%'
     OR l.stack LIKE '%n_cst_ordersrv%'
     OR l.stack LIKE '%n_cst_oe_line_fx%'
     OR l.stack LIKE '%n_cst_vt_orderentry_tab2%'
     OR l.stack LIKE '%n_cst_oelinedetailsrv%'
     OR l.stack LIKE '%n_cst_epf_orderprocessing_pubsub_handler%'
     OR l.stack LIKE '%n_cst_srv_orderinfo%'
     OR l.stack LIKE '%n_cst_cmi_hdr_customer_br%'
     OR l.stack LIKE '%n_ext_tax_srv_avalara%'
     OR (l.stack LIKE '%u_oc_ribbonuicontrol%' AND l.user_text LIKE '%m_mymenu38%')
     OR (l.stack LIKE '%for n_tr%'                          AND (l.user_text LIKE '%d_dw_oe_%' OR l.user_text LIKE '%d_ds_oe_%'))
     OR (l.stack LIKE '%n_cst_custom_objects::of_applymods%' AND (l.user_text LIKE '%d_dw_oe_%' OR l.user_text LIKE '%d_ds_oe_%'))
      )
GROUP BY l.message_no
ORDER BY occurrence_count DESC;

-- Once you have a shortlist of message_no values above, check whether the
-- OE suppress rule already logged a method_name (= actual source) for them:
--
-- SELECT message_no, message_title, method_name, user_text, seen_count, first_seen, last_seen
-- FROM   P21BusinessRules.dbo.message_log_p21_ud
-- WHERE  message_no IN (<paste message_no list from above>);

-- Perf note: a year of message_log with leading-wildcard LIKE on stack can't
-- seek an index -- this is fine as a periodic audit, but if it's re-run
-- often, cache the confirmed message_no list from a run and switch to
-- `l.message_no IN (...)` (sargable) for routine re-checks instead of
-- re-evaluating the LIKE predicates every time.

-- ============================================================
-- Audit-OrderAck-Email-Rule-Registrations.sql
-- ============================================================
-- Purpose : Before touching either Order Ack email rule, establish (a) how
--           many live registrations each one has and (b) exactly which
--           data elements each registration carries.
--
--           Written after the 2026-09-06 BRR test, where:
--             * asi_oe_email_close_diag failed "d_dw_email_info missing memo
--               column" -- its element list held d_dw_email_info.subject and
--               NOT memo (Rule Manager replaced the list; see
--               feedback_p21_rule_manager_destroys_data_elements).
--             * business_rule_log showed rule_state.uid = 168 for that rule,
--               not the 164/165 recorded in the deploy guide, AND two firings
--               48s apart with different field ordering -> a duplicate
--               registration is likely live again (3rd recurrence).
--
-- Run on  : P21BusinessRules (BRR) first. Read-only -- no writes.
--           Sandbox blocks TDS from this workspace; run in SSMS.
-- ============================================================

SET NOCOUNT ON;

DECLARE @rules TABLE (rule_name varchar(255) PRIMARY KEY);
INSERT INTO @rules (rule_name) VALUES
    ('asi_oe_email_close_diag'),
    ('asi_oe_order_ack_email_subject'),
    ('asi_email_context_flag');

-- ------------------------------------------------------------
-- 1. Live registrations. Expect EXACTLY ONE row per rule_name.
--    More than one = the duplicate-registration bug; deregister the
--    extras in Rule Manager before any other repair.
--    row_status_flag 704 = active, 705 = inactive.
--    multirow_flag MUST be Y for all three (Data.Set access).
-- ------------------------------------------------------------
SELECT
    '1. REGISTRATIONS'      AS section,
    b.business_rule_uid,
    b.rule_name,
    b.row_status_flag,
    b.multirow_flag,
    b.run_type_cd,
    b.run_for_all_users_flag,
    b.date_created,
    b.date_last_modified,
    b.last_maintained_by,
    element_count = (SELECT COUNT(*) FROM business_rule_data_element e
                     WHERE e.business_rule_uid = b.business_rule_uid)
FROM   business_rule b
JOIN   @rules r ON r.rule_name = b.rule_name
ORDER BY b.rule_name, b.business_rule_uid;

-- ------------------------------------------------------------
-- 2. Every data element on every one of those registrations.
--    What each rule NEEDS:
--      asi_oe_email_close_diag        -> Buttons.cb_ok  +  d_dw_email_info.memo
--      asi_oe_order_ack_email_subject -> Buttons.cb_ok  +  d_dw_email_info.subject
--                                                       +  d_dw_email_info.company_id
--      asi_email_context_flag         -> EmailDataMisc.form_type
--    The two cb_ok rules must NOT share a column: one owns memo, the other
--    owns subject.
-- ------------------------------------------------------------
SELECT
    '2. DATA ELEMENTS'      AS section,
    b.rule_name,
    e.business_rule_uid,
    e.business_rule_data_element_uid,
    e.class_name,
    e.field_name,
    e.field_alias,
    e.date_created,
    e.created_by
FROM   business_rule_data_element e
JOIN   business_rule b ON b.business_rule_uid = e.business_rule_uid
JOIN   @rules r        ON r.rule_name = b.rule_name
ORDER BY b.rule_name, e.business_rule_uid, e.class_name, e.field_name;

-- ------------------------------------------------------------
-- 3. Straight verdict on the two elements that actually broke.
-- ------------------------------------------------------------
SELECT
    '3. VERDICT'            AS section,
    b.rule_name,
    b.business_rule_uid,
    has_cb_ok = CASE WHEN EXISTS (SELECT 1 FROM business_rule_data_element e
                                  WHERE e.business_rule_uid = b.business_rule_uid
                                    AND e.field_name = 'cb_ok')
                     THEN 'Y' ELSE 'N -- rule will never fire' END,
    has_memo  = CASE WHEN EXISTS (SELECT 1 FROM business_rule_data_element e
                                  WHERE e.business_rule_uid = b.business_rule_uid
                                    AND e.class_name = 'd_dw_email_info'
                                    AND e.field_name = 'memo')
                     THEN 'Y' ELSE 'N' END,
    has_subject = CASE WHEN EXISTS (SELECT 1 FROM business_rule_data_element e
                                    WHERE e.business_rule_uid = b.business_rule_uid
                                      AND e.class_name = 'd_dw_email_info'
                                      AND e.field_name = 'subject')
                       THEN 'Y' ELSE 'N' END,
    has_company_id = CASE WHEN EXISTS (SELECT 1 FROM business_rule_data_element e
                                       WHERE e.business_rule_uid = b.business_rule_uid
                                         AND e.class_name = 'd_dw_email_info'
                                         AND e.field_name = 'company_id')
                          THEN 'Y' ELSE 'N' END
FROM   business_rule b
JOIN   @rules r ON r.rule_name = b.rule_name
WHERE  b.rule_name IN ('asi_oe_email_close_diag', 'asi_oe_order_ack_email_subject')
ORDER BY b.rule_name, b.business_rule_uid;

-- ------------------------------------------------------------
-- 4. What the DLLs on this box actually are. business_rule_log
--    reported 1.0.0.7 (asi_oe_email_close_diag -- pre-SA-53475, still the
--    DIAG-MARKER build) and 1.0.0.1 (asi_oe_order_ack_email_subject).
--    Confirms whether a field-selector repair alone is enough.
-- ------------------------------------------------------------
SELECT TOP (40)
    '4. RECENT LOG'         AS section,
    l.business_rule_log_uid,
    l.date_created,
    l.rule_name,
    l.rule_assembly_name,
    l.log_action,
    l.return_value,
    l.return_message
FROM   business_rule_log l
JOIN   @rules r ON r.rule_name = l.rule_name
ORDER BY l.business_rule_log_uid DESC;

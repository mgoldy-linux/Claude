/*======================================================================================
  Repair-BRR-OrderValidator-DataElements.sql
  Restores kb_Order_Validator_v2 (business_rule_uid 133) in P21BusinessRules (BRR) to the
  field registration PROD has.

  WHY
    Saving a rule in P21 Rule Manager REPLACES its entire business_rule_data_element list,
    keeping only the DataWindows the UI had loaded. On 2026-09-01 14:22:46 a status flip
    rewrote BRR's list from 114 elements / 11 DataWindows down to 74 / 3 -- every surviving
    row has date_created = that timestamp and created_by = MGOLDYN, while PROD and Play
    still carry the original 114 rows from 2024-02-19, created_by kbenish.

    P21 populates a rule's DataSet with ONLY its registered elements, so the loss made
    d_front_counter (19 fields) and 7 other DataWindows vanish at runtime -- which is why
    kb_Order_Validator_v2 now NREs on d_front_counter in BRR, and why the asi_ rule
    registered from that damaged list inherited missing fields.

  SAFE TO RUN AS A PLAIN INSERT
    business_rule_data_element_uid IS AN IDENTITY column (verified: COLUMNPROPERTY
    IsIdentity = 1) and no row in counter owns it, so this does NOT risk the P21 counter
    drift that affects counter-managed tables. Do NOT supply the uid.

  SCOPE: BRR (P21BusinessRules) ONLY. Do not run against Prod -- Prod is the source of truth
  and is already correct.
======================================================================================*/

USE P21BusinessRules;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- Guard: only proceed if this really is the damaged rule in the expected state.
IF NOT EXISTS (SELECT 1 FROM business_rule WHERE business_rule_uid = 133
                                             AND rule_name = 'kb_Order_Validator_v2')
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('uid 133 is not kb_Order_Validator_v2 in this database -- WRONG DB or the uid moved. Aborted.', 16, 1);
    RETURN;
END

PRINT 'Before: ' + CAST((SELECT COUNT(*) FROM business_rule_data_element
                         WHERE business_rule_uid = 133) AS varchar(10)) + ' elements';

-- 40 rows PROD has that BRR does not.
INSERT INTO business_rule_data_element
    (business_rule_uid, field_name, class_name, field_alias,
     date_created, created_by, date_last_modified, last_maintained_by)
VALUES
    (133, 'delete_flag', 'd_dw_oe_hdr_notepad_dataentry', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'mandatory', 'd_dw_oe_hdr_notepad_dataentry', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'note', 'd_dw_oe_hdr_notepad_dataentry', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'notepad_class_id', 'd_dw_oe_hdr_notepad_dataentry', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'topic', 'd_dw_oe_hdr_notepad_dataentry', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'oe_hdr_carrier_id', 'd_dw_oe_hdr_shipinfo', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'ship_route', 'd_dw_oe_hdr_shipinfo', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'terms', 'd_dw_oe_hdr_terms', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'amount_tendered', 'd_dw_oe_hdr_totals_remit', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'cf_balance', 'd_dw_oe_hdr_totals_remit', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'cf_ship_total', 'd_dw_oe_hdr_totals_remit', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'cf_total_due', 'd_dw_oe_hdr_totals_remit', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'cf_total_sugg_amt', 'd_dw_oe_hdr_totals_remit', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'total_paid', 'd_dw_oe_hdr_totals_remit', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'email_downpayment', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'email_invoice', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'email_orderack', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'email_pack_list', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'email_tix', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'fax_downpayment', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'fax_invoice', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'fax_orderack', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'fax_pack_list', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'fax_tix', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'invoice_edi', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'print_downpayment', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'print_invoice', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'print_orderack', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'print_pack_list', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'print_tix', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'ship', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'signature_capture', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'will_call', 'd_front_counter', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'oe_hdr_class_1id', 'd_oe_hdr_class', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'invoice_batch_number', 'd_oe_hdr_ship_to', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'cc_swiped', 'd_oe_payment_details', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'delete_flag', 'd_oe_payment_details', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'payment_amount', 'd_oe_payment_details', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'payment_desc', 'd_oe_payment_details', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()),
    (133, 'payment_method_id', 'd_oe_payment_details', NULL, GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME());

PRINT 'After:  ' + CAST((SELECT COUNT(*) FROM business_rule_data_element
                         WHERE business_rule_uid = 133) AS varchar(10)) + ' elements  (expect 114)';

-- Verify against the expected shape before committing.
SELECT class_name, fields = COUNT(*)
FROM   business_rule_data_element WHERE business_rule_uid = 133
GROUP  BY class_name ORDER BY class_name;

IF (SELECT COUNT(*) FROM business_rule_data_element WHERE business_rule_uid = 133) <> 114
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Element count is not 114 after insert -- rolled back, nothing changed.', 16, 1);
    RETURN;
END

COMMIT TRANSACTION;
PRINT 'Committed. BRR now matches PROD at 114 elements / 11 DataWindows.';
GO

/*--------------------------------------------------------------------------------------
  EXPECTED RESULT (PROD shape):
    d_dw_oe_hdr_notepad_dataentry   5
    d_dw_oe_hdr_shipinfo            2
    d_dw_oe_hdr_terms               1
    d_dw_oe_hdr_totals_remit        6
    d_dw_oe_line_dataentry         41
    d_front_counter                19
    d_oe_hdr_class                  1
    d_oe_hdr_credit                 1
    d_oe_hdr_ship_to                1
    d_oe_header                    32
    d_oe_payment_details            5

  UNDO (removes only what this script added -- identified by created_by/date):
    DELETE FROM business_rule_data_element
    WHERE business_rule_uid = 133 AND created_by = SUSER_SNAME()
      AND date_created >= 'PUT-THE-RUN-DATE-HERE';

  AFTER RUNNING: recycle the API-P21BusinessRules - P21 SOA* pools on AHI-API1. The
  middleware caches rule metadata; the DataSet shape will not change until it reloads.

  DO NOT re-open this rule in Rule Manager afterwards unless you re-verify the count --
  saving it there is what destroyed the list in the first place.
--------------------------------------------------------------------------------------*/

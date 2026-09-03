/*======================================================================================
  Register-asi_Order_Validator_t2.sql
  BRR (P21BusinessRules) ONLY.

  Converts the existing rule row uid 166 (`asi_Order_Validator`, the _t1 iteration) into
  `asi_Order_Validator_t2` and repairs its field registration -- ENTIRELY BY SQL.

  WHY BY SQL, NOT RULE MANAGER
    Saving a rule in Rule Manager REPLACES its whole business_rule_data_element list,
    silently dropping every DataWindow the UI had not loaded. That is what damaged this
    rule's list in the first place (uid 133 went 114/11 -> 74/3 on 2026-09-01 14:22:46,
    and uid 166 was registered from that already-damaged list).
    See feedback_p21_rule_manager_destroys_data_elements.

  WHY REUSE uid 166 INSTEAD OF CREATING A NEW RULE
    P21 binds a rule to code by matching business_rule.rule_name to the value the Rule
    class returns from GetName(). asi_Order_Validator_t2.GetName() returns
    "asi_Order_Validator_t2" (nameof), so renaming the row is all the binding needs.
    Reusing the row also avoids inserting into business_rule, whose uid we would rather
    not hand-assign, and preserves the 21 role rows already attached (which match kb_'s
    scoping exactly).

  WHAT CHANGES
    1. rule_name        asi_Order_Validator -> asi_Order_Validator_t2   (binds to the DLL)
    2. field_name       freight_cd -> freight_code_uid                  (kb_ uses this)
    3. run_for_all_flag Y -> N                                          (match kb_ exactly)
    4. +5 data elements: the exact fields the adapter reads but was never given.

  THE 5 MISSING FIELDS AND WHAT EACH ONE BREAKS
    d_oe_header.freight_code_uid          precursor + checks 3,4,6 -- THE false block
    d_dw_oe_hdr_shipinfo.oe_hdr_carrier_id  carrier -> will-call lookup
    d_dw_oe_hdr_notepad_dataentry.delete_flag  note filter
    d_dw_oe_hdr_notepad_dataentry.topic        freight-quote + signature notes
    d_dw_oe_hdr_notepad_dataentry.mandatory    freight-quote note (6b)
    The three notepad fields are the dangerous ones: their absence does not throw and does
    not block -- it silently makes every note invisible, so a correctly-noted order is
    judged as if it had no notes at all. Wrong verdict, no error.

  SAFE AS A PLAIN INSERT
    business_rule_data_element_uid is a true IDENTITY (COLUMNPROPERTY IsIdentity = 1) with
    no row in `counter` owning it, so this does not risk P21 counter drift. Do not supply
    the uid. (cf. feedback_p21_counter_drift)

  This script does NOT activate the rule. Activation is the last step, deliberately
  separate -- see the ACTIVATE block at the bottom.
======================================================================================*/

USE P21BusinessRules;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

/*-- Guard 1: this must be the rule we think it is, in the state we think it is in. ----*/
IF NOT EXISTS (SELECT 1 FROM business_rule
               WHERE business_rule_uid = 166
                 AND rule_name IN ('asi_Order_Validator','asi_Order_Validator_t2'))
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('uid 166 is not the asi_Order_Validator row in this database -- WRONG DB, or the uid moved. Aborted.', 16, 1);
    RETURN;
END

/* Guard 1 is also the "not Prod" guard: no asi_Order_Validator row exists outside BRR.
   Deliberately NOT keyed on uid 133's element count -- that would make this script abort
   once Repair-BRR-OrderValidator-DataElements.sql has run, and the two are independent. */

DECLARE @n INT, @dw INT;   -- PRINT cannot take a subquery; collect counts into variables.
SELECT @n = COUNT(*), @dw = COUNT(DISTINCT class_name)
FROM   business_rule_data_element WHERE business_rule_uid = 166;
PRINT 'Before: ' + CAST(@n AS varchar(10)) + ' elements, '
                 + CAST(@dw AS varchar(10)) + ' DataWindows';

/*-- 1-3. Rule header: name (the DLL binding), trigger field, scoping. ----------------*/
UPDATE business_rule
SET    rule_name          = 'asi_Order_Validator_t2',
       field_name         = 'freight_code_uid',
       run_for_all_flag   = 'N',
       date_last_modified = GETDATE(),
       last_maintained_by = SUSER_SNAME()
WHERE  business_rule_uid = 166;

/*-- 4. The 5 fields the adapter reads but was never registered for. ------------------*/
INSERT INTO business_rule_data_element
    (business_rule_uid, field_name, class_name, field_alias,
     date_created, created_by, date_last_modified, last_maintained_by)
SELECT 166, v.field_name, v.class_name, NULL,
       GETDATE(), SUSER_SNAME(), GETDATE(), SUSER_SNAME()
FROM (VALUES
        ('freight_code_uid',   'd_oe_header'),
        ('oe_hdr_carrier_id',  'd_dw_oe_hdr_shipinfo'),
        ('delete_flag',        'd_dw_oe_hdr_notepad_dataentry'),
        ('topic',              'd_dw_oe_hdr_notepad_dataentry'),
        ('mandatory',          'd_dw_oe_hdr_notepad_dataentry')
     ) v(field_name, class_name)
WHERE NOT EXISTS (SELECT 1 FROM business_rule_data_element e
                  WHERE e.business_rule_uid = 166
                    AND e.field_name = v.field_name
                    AND e.class_name = v.class_name);

SELECT @n = COUNT(*), @dw = COUNT(DISTINCT class_name)
FROM   business_rule_data_element WHERE business_rule_uid = 166;
PRINT 'After:  ' + CAST(@n AS varchar(10)) + ' elements, '
                 + CAST(@dw AS varchar(10)) + ' DataWindows  (expect 76 / 5)';

/*-- Verify: every field the adapter reads must now resolve. Roll back if not. --------*/
DECLARE @unregistered INT;

;WITH required(dw, field) AS (
    SELECT * FROM (VALUES
      ('d_oe_header','order_no'),                    ('d_oe_header','date_created'),
      ('d_oe_header','requested_date'),              ('d_oe_header','freight_code_uid'),
      ('d_oe_header','ship_to_id'),                  ('d_oe_header','customer_id'),
      ('d_oe_header','packing_basis'),               ('d_oe_header','order_type'),
      ('d_oe_header','rma_flag'),                    ('d_oe_header','quote'),
      ('d_oe_header','cancel_flag'),                 ('d_oe_header','ufc_oe_hdr_ud_oe_surcharge'),
      ('d_dw_oe_line_dataentry','delete_flag'),      ('d_dw_oe_line_dataentry','oe_order_item_id'),
      ('d_dw_oe_line_dataentry','qty_ordered'),      ('d_dw_oe_line_dataentry','oe_line_complete'),
      ('d_dw_oe_line_dataentry','product_type'),     ('d_dw_oe_line_dataentry','extended_price'),
      ('d_dw_oe_hdr_shipinfo','oe_hdr_carrier_id'),  ('d_oe_hdr_credit','credit_status'),
      ('d_dw_oe_hdr_notepad_dataentry','delete_flag'),
      ('d_dw_oe_hdr_notepad_dataentry','topic'),
      ('d_dw_oe_hdr_notepad_dataentry','mandatory')
    ) v(dw, field)
)
SELECT @unregistered = COUNT(*)
FROM   required r
WHERE  NOT EXISTS (SELECT 1 FROM business_rule_data_element e
                   WHERE e.business_rule_uid = 166
                     AND e.field_name = r.field AND e.class_name = r.dw);

IF @unregistered <> 0
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('%d required field(s) still unregistered -- rolled back, nothing changed.', 16, 1, @unregistered);
    RETURN;
END

SELECT class_name, fields = COUNT(*)
FROM   business_rule_data_element WHERE business_rule_uid = 166
GROUP  BY class_name ORDER BY class_name;

COMMIT TRANSACTION;
PRINT 'Committed. asi_Order_Validator_t2 is registered with all 23 required fields.';
PRINT 'Rule is still INACTIVE (705). Recycle the SOA pools, then run the ACTIVATE block.';
GO

/*--------------------------------------------------------------------------------------
  EXPECTED SHAPE AFTER THIS SCRIPT (uid 166):
    d_dw_oe_hdr_notepad_dataentry    3
    d_dw_oe_hdr_shipinfo             1
    d_dw_oe_line_dataentry          38
    d_oe_hdr_credit                  1
    d_oe_header                     33
    ------------------------------- 76 elements / 5 DataWindows

  53 of those 76 are unread leftovers copied from the kb_ list. They are harmless -- they
  only make the DataSet bigger -- and trimming them is a PERFORMANCE item to do AFTER the
  equivalence diff is clean, not before. Count them with:
      -- second query in Testing\kb_Order_Validator_v2\verify-required-elements.sql

  NEXT, IN ORDER:
    1. Recycle "API-P21BusinessRules" + the P21 SOA* app pools on AHI-API1.
       The middleware caches rule metadata; the DataSet shape will NOT change until it
       reloads, so skipping this makes the fix look like it failed.
    2. Run the ACTIVATE block below.
    3. Re-save order 6108922 in BRR. Expect a clean save, no block, no NRE.
    4. Corpus re-save + STEP 4 diff vs the kb_ baseline.

  ACTIVATE (run only after the pool recycle):
      UPDATE business_rule
      SET    row_status_flag = 704, date_last_modified = GETDATE(),
             last_maintained_by = SUSER_SNAME()
      WHERE  rule_name = 'asi_Order_Validator_t2';

  ROLLBACK TO kb_ (if _t2 misbehaves) -- BY SQL, never Rule Manager:
      UPDATE business_rule SET row_status_flag = 705 WHERE rule_name = 'asi_Order_Validator_t2';
      UPDATE business_rule SET row_status_flag = 704 WHERE rule_name = 'kb_Order_Validator_v2';
      -- kb_ only works if Repair-BRR-OrderValidator-DataElements.sql has been run first;
      -- BRR's copy is still truncated to 74/3 and NREs on d_front_counter.

  UNDO THIS SCRIPT (removes only what it added):
      DELETE FROM business_rule_data_element
      WHERE business_rule_uid = 166 AND created_by = SUSER_SNAME()
        AND date_created >= 'PUT-THE-RUN-DATE-HERE';
      UPDATE business_rule SET rule_name='asi_Order_Validator', field_name='freight_cd',
             run_for_all_flag='Y' WHERE business_rule_uid = 166;

  DO NOT open this rule in Rule Manager afterwards without re-running
  verify-required-elements.sql -- saving it there is what destroyed the list originally.
--------------------------------------------------------------------------------------*/

/*======================================================================================
  Activate-asi_Order_Validator_t2.sql          BRR (P21BusinessRules) ONLY.

  The ACTIVATE step from Register-asi_Order_Validator_t2.sql, split into its own file so
  it can be run (and rolled back) independently of the registration repair.

  BY SQL, NOT RULE MANAGER. Flipping row_status_flag in the UI is what truncated these
  element lists in the first place. See feedback_p21_rule_manager_destroys_data_elements.

  RUN ORDER MATTERS: activate FIRST, then recycle the API-P21BusinessRules pools. The
  middleware caches rule metadata at pool start, so a flip made after a recycle may not
  be seen until the next one -- and a rule that never fires looks exactly like a rule
  that fired and approved the order. That is the most dangerous false signal available
  to us here, so we remove the ambiguity rather than test through it.
======================================================================================*/

USE P21BusinessRules;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

/* Guard: refuse unless the registration repair has actually been applied. Activating a
   rule that is still missing fields would reproduce the 2026-09-01 false block. */
DECLARE @unregistered INT, @uid INT;

SELECT @uid = business_rule_uid FROM business_rule WHERE rule_name = 'asi_Order_Validator_t2';

IF @uid IS NULL
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('asi_Order_Validator_t2 does not exist in this database. Run Register-asi_Order_Validator_t2.sql first. Aborted.', 16, 1);
    RETURN;
END

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
                   WHERE e.business_rule_uid = @uid
                     AND e.field_name = r.field AND e.class_name = r.dw);

IF @unregistered <> 0
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('%d required field(s) unregistered -- refusing to activate. Run the registration repair first.', 16, 1, @unregistered);
    RETURN;
END

/* Activate _t2. kb_Order_Validator_v2 is left at 705 -- it was turned off on 2026-09-03
   and its 114/11 list has been repaired, so it remains a working rollback target. */
UPDATE business_rule
SET    row_status_flag = 704, date_last_modified = GETDATE(), last_maintained_by = SUSER_SNAME()
WHERE  business_rule_uid = @uid;

COMMIT TRANSACTION;
PRINT 'asi_Order_Validator_t2 is ACTIVE (704). Recycle the API-P21BusinessRules pools now.';
GO

SELECT rule_name, business_rule_uid, row_status_flag, run_type_cd, run_for_all_flag, field_name,
       elements    = (SELECT COUNT(*) FROM business_rule_data_element e
                      WHERE e.business_rule_uid = b.business_rule_uid),
       datawindows = (SELECT COUNT(DISTINCT class_name) FROM business_rule_data_element e
                      WHERE e.business_rule_uid = b.business_rule_uid)
FROM   business_rule b
WHERE  rule_name IN ('asi_Order_Validator_t2','kb_Order_Validator_v2','kb_Order_Workflow_v2')
ORDER  BY rule_name;

/*--------------------------------------------------------------------------------------
  ROLLBACK (BY SQL, never Rule Manager):
      UPDATE business_rule SET row_status_flag = 705 WHERE rule_name = 'asi_Order_Validator_t2';
      UPDATE business_rule SET row_status_flag = 704 WHERE rule_name = 'kb_Order_Validator_v2';
      -- then recycle the pools again.
--------------------------------------------------------------------------------------*/

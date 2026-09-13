/* ============================================================================
   code_p21 structure confirmed: code_uid (PK), code_no (the value stored in
   other tables, e.g. inv_loc.safety_stock_type), code_description (label),
   code_sub_description, language_id, row_status_flag, dates.

   Pull the 4 known safety-stock-type labels directly and check code_no
   against the actual values seen in inv_loc.safety_stock_type on Training
   (0, 1261, 1716, plus NULL).

   Run in: P21Training.  READ-ONLY.
   ============================================================================ */
USE P21Training;
GO

SELECT code_uid, code_no, language_id, code_description, code_sub_description, row_status_flag
FROM   dbo.code_p21
WHERE  code_description IN ('By ABC Class','Days','Deviation Multiplier','Service Level')
ORDER  BY code_no;
GO

-- Broader net in case the exact label text differs slightly (case/spacing)
SELECT code_uid, code_no, language_id, code_description, code_sub_description, row_status_flag
FROM   dbo.code_p21
WHERE  code_description LIKE '%ABC Class%'
   OR  code_description LIKE '%Deviation Multiplier%'
   OR  code_description LIKE '%Service Level%'
   OR  code_no IN (0, 1261, 1716);
GO

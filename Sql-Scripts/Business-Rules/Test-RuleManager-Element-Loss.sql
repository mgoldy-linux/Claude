/*======================================================================================
  Test-RuleManager-Element-Loss.sql
  Isolation test: does saving a rule in P21 Rule Manager destroy its registered
  business_rule_data_element list?

  WHY THIS MATTERS
    On 2026-09-01 14:22:46, kb_Order_Validator_v2 in BRR went from 114 elements / 11
    DataWindows to 74 / 3. Every surviving row has date_created = that timestamp and
    created_by = MGOLDYN, while PROD and Play still hold the original 114 rows from
    2024-02-19 created_by kbenish. So the list was not edited -- it was DELETED AND
    REWRITTEN, keeping only the DataWindows the UI had loaded.

    P21 populates a rule's DataSet with ONLY its registered elements, so the loss made
    d_front_counter and 7 other DataWindows vanish at runtime. That is the root cause of
    both the old rule's NRE and the new rule's false "FREIGHT CODE is blank" block.

    The correlation is strong but UNPROVEN as cause. It matters because the Prod cutover
    requires flipping row_status_flag -- and if that flip is what does this, doing it in
    Rule Manager would silently cripple the rule that gates every order save in Prod.

  CHOOSING THE CANARY -- the rule must have ENOUGH DataWindows to show the failure.
    If the mechanism is "Rule Manager writes back only the DataWindows it had loaded", a
    rule with few DataWindows cannot reproduce it and would produce a FALSE NEGATIVE that
    wrongly clears the UI. kb_Order_Validator_v2 went 11 DataWindows -> 3, so a canary needs
    more than 3 to be meaningful.

    Every BRR rule with >= 5 DataWindows:
      uid  55  kb_Order_Validator     705 inactive   28 elements   5 DWs   <- STAGE 1
      uid  59  kb_Customer_Closed_r1  705 inactive   10 elements   5 DWs   <- STAGE 1 alt
      uid 100  kb_FrontCounter_CotF   704 ACTIVE     19 elements   5 DWs
      uid 103  kb_Order_Workflow_v2   704 ACTIVE    115 elements  11 DWs   <- STAGE 2

    STAGE 1 -- uid 55. Inactive since 2023, superseded by _v2, 28 elements matching PROD
    exactly (undamaged). Zero operational risk. 5 DataWindows is above the 3 that survived
    on the damaged rule, so a truncation WOULD be visible. If it reproduces, stop -- the
    mechanism is confirmed and nothing active was touched.

    STAGE 2 -- ONLY if stage 1 comes back clean. A clean 5-DW result does not prove the UI
    is safe for an 11-DW rule. uid 103 (kb_Order_Workflow_v2) is the ideal second canary:
    same assembly, same d_oe_header binding, and still intact at 115/11 -- i.e. the exact
    shape kb_Order_Validator_v2 had before it broke. It is ACTIVE, so first deactivate it
    BY SQL (never through the UI, which is the thing under test):
        UPDATE business_rule SET row_status_flag = 705, date_last_modified = GETDATE(),
               last_maintained_by = SUSER_SNAME()
        WHERE business_rule_uid = 103;
    run the variants, restore its elements via STEP 4 (set @uid = 103), then reactivate by
    SQL. This briefly stops the freight-quote note writer in BRR only.

    NOTE: uid 103 is in the SAME ASSEMBLY as the damaged validator and was NOT harmed
    yesterday -- so the damage was confined to the rule actually opened and saved, not the
    assembly or the Rule Manager session.

    STEP 4 restores whichever canary exactly, from the STEP 1 snapshot.

  RUN IN BRR (P21BusinessRules) ONLY. Never in Prod.
======================================================================================*/

USE P21BusinessRules;
GO

/*--------------------------------------------------------------------------------------
  STEP 0 -- confirm the canary is safe to poke, intact, and has enough DataWindows to
  actually show the failure. Stage 1 expects: kb_Order_Validator, 705, 28 elements, 5 DWs.
--------------------------------------------------------------------------------------*/
SELECT  b.business_rule_uid, b.rule_name, b.class_name, b.row_status_flag,
        elements = (SELECT COUNT(*) FROM business_rule_data_element d
                    WHERE d.business_rule_uid = b.business_rule_uid),
        dws      = (SELECT COUNT(DISTINCT d.class_name) FROM business_rule_data_element d
                    WHERE d.business_rule_uid = b.business_rule_uid),
        safe_to_test = CASE WHEN b.row_status_flag = 705 THEN 'YES - inactive'
                            ELSE '*** ACTIVE - deactivate BY SQL first (see header) ***' END,
        -- A canary with <= 3 DataWindows cannot reproduce a truncation to 3 and would give
        -- a false negative.
        test_is_meaningful = CASE
            WHEN (SELECT COUNT(DISTINCT d.class_name) FROM business_rule_data_element d
                  WHERE d.business_rule_uid = b.business_rule_uid) > 3
            THEN 'YES' ELSE '*** NO - too few DataWindows, pick another ***' END
FROM    business_rule b
WHERE   b.business_rule_uid IN (55, 59, 103);   -- stage 1 candidates + stage 2
GO


/*--------------------------------------------------------------------------------------
  STEP 1 -- SNAPSHOT BEFORE. This doubles as the restore source for STEP 4, so do not
  skip it and do not drop the table until the test is finished.
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.asi_rule_element_snapshot') IS NULL
    CREATE TABLE dbo.asi_rule_element_snapshot (
        label            VARCHAR(30)  NOT NULL,   -- 'BEFORE' | 'AFTER-<variant>'
        captured_at      DATETIME     NOT NULL CONSTRAINT DF_ares_cap DEFAULT (GETDATE()),
        business_rule_uid INT         NOT NULL,
        element_uid      INT          NULL,
        field_name       VARCHAR(255) NULL,
        class_name       VARCHAR(255) NULL,
        field_alias      VARCHAR(255) NULL,
        row_created      DATETIME     NULL,
        row_created_by   VARCHAR(255) NULL
    );

DECLARE @label VARCHAR(30) = 'BEFORE';          -- <<< set per capture
DECLARE @uid   INT         = 55;                -- the canary

DELETE FROM dbo.asi_rule_element_snapshot WHERE label = @label AND business_rule_uid = @uid;

INSERT dbo.asi_rule_element_snapshot
    (label, business_rule_uid, element_uid, field_name, class_name, field_alias,
     row_created, row_created_by)
SELECT @label, business_rule_uid, business_rule_data_element_uid, field_name, class_name,
       field_alias, date_created, created_by
FROM   business_rule_data_element
WHERE  business_rule_uid = @uid;

SELECT captured = @label, rows_captured = @@ROWCOUNT;
GO


/*--------------------------------------------------------------------------------------
  STEP 2 -- THE ACTION (do this in the P21 client, not here).

  Run ONE variant, then go to STEP 3. Work down the list -- the earliest variant that
  destroys the list tells you the trigger, and there is no point testing the rest.

    Variant A  "open-close"   : open kb_Order_Validator in Rule Manager, change NOTHING,
                                close WITHOUT saving.
    Variant B  "open-save"    : open it, change NOTHING, SAVE.
    Variant C  "status-flip"  : open it, set row_status_flag 705 -> 704, SAVE.
                                Then set it back 704 -> 705 and SAVE again.
                                (This is what was done to kb_Order_Validator_v2 and is
                                 exactly what the Prod cutover needs.)

  Variant C is the one that matters operationally. A and B narrow down WHY, and are worth
  running first because if plain "open-save" already destroys the list, the problem is far
  broader than status flips -- it would mean any Rule Manager visit is destructive.
--------------------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------------------
  STEP 3 -- SNAPSHOT AFTER + DIFF. Set @label to 'AFTER-A' / 'AFTER-B' / 'AFTER-C'.
--------------------------------------------------------------------------------------*/
DECLARE @label VARCHAR(30) = 'AFTER-C';         -- <<< match the variant you ran
DECLARE @uid   INT         = 55;

DELETE FROM dbo.asi_rule_element_snapshot WHERE label = @label AND business_rule_uid = @uid;

INSERT dbo.asi_rule_element_snapshot
    (label, business_rule_uid, element_uid, field_name, class_name, field_alias,
     row_created, row_created_by)
SELECT @label, business_rule_uid, business_rule_data_element_uid, field_name, class_name,
       field_alias, date_created, created_by
FROM   business_rule_data_element
WHERE  business_rule_uid = @uid;

-- 3a. Headline counts.
SELECT label, elements = COUNT(*), dws = COUNT(DISTINCT class_name),
       oldest_row = MIN(row_created), newest_row = MAX(row_created)
FROM   dbo.asi_rule_element_snapshot
WHERE  business_rule_uid = @uid
GROUP  BY label ORDER BY label;

-- 3b. THE DECISIVE TEST -- were the SURVIVING rows rewritten?
--     Same element_uid before and after  => rows were left alone.
--     New element_uids / new date_created => the list was DELETED AND REWRITTEN, which is
--     the fingerprint seen on kb_Order_Validator_v2.
SELECT verdict = CASE
         WHEN a.field_name IS NULL THEN '*** DESTROYED (row gone) ***'
         WHEN b.field_name IS NULL THEN 'added (not in BEFORE)'
         WHEN a.element_uid <> b.element_uid THEN '*** REWRITTEN (new uid) ***'
         WHEN a.row_created <> b.row_created THEN '*** REWRITTEN (new date_created) ***'
         ELSE 'untouched' END,
       field   = ISNULL(b.field_name, a.field_name),
       dw      = ISNULL(b.class_name, a.class_name),
       uid_before = b.element_uid, uid_after = a.element_uid,
       created_before = b.row_created, created_after = a.row_created
FROM       (SELECT * FROM dbo.asi_rule_element_snapshot
            WHERE label = 'BEFORE'  AND business_rule_uid = @uid) b
FULL JOIN  (SELECT * FROM dbo.asi_rule_element_snapshot
            WHERE label = @label    AND business_rule_uid = @uid) a
       ON  a.field_name = b.field_name AND ISNULL(a.class_name,'~') = ISNULL(b.class_name,'~')
ORDER BY CASE WHEN verdict LIKE '***%' THEN 0 ELSE 1 END, dw, field;

-- 3c. Which whole DataWindows disappeared?
SELECT dw = b.class_name, fields_before = COUNT(*),
       fields_after = ISNULL((SELECT COUNT(*) FROM dbo.asi_rule_element_snapshot a
                              WHERE a.label = @label AND a.business_rule_uid = @uid
                                AND a.class_name = b.class_name), 0)
FROM   dbo.asi_rule_element_snapshot b
WHERE  b.label = 'BEFORE' AND b.business_rule_uid = @uid
GROUP  BY b.class_name ORDER BY b.class_name;
GO


/*--------------------------------------------------------------------------------------
  STEP 4 -- RESTORE the canary if the test damaged it.
  Safe to run even if nothing was lost (it only inserts what is missing).
  business_rule_data_element_uid is an IDENTITY (verified) with no `counter` row owning it,
  so this is a plain INSERT and carries no P21 counter-drift risk.
--------------------------------------------------------------------------------------*/
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @uid INT = 55;
DECLARE @expected INT = (SELECT COUNT(*) FROM dbo.asi_rule_element_snapshot
                         WHERE label = 'BEFORE' AND business_rule_uid = @uid);

IF @expected = 0
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('No BEFORE snapshot for uid 55 -- cannot restore. Did STEP 1 run?', 16, 1);
    RETURN;
END

INSERT business_rule_data_element
    (business_rule_uid, field_name, class_name, field_alias,
     date_created, created_by, date_last_modified, last_maintained_by)
SELECT s.business_rule_uid, s.field_name, s.class_name, s.field_alias,
       s.row_created, s.row_created_by, GETDATE(), SUSER_SNAME()
FROM   dbo.asi_rule_element_snapshot s
WHERE  s.label = 'BEFORE' AND s.business_rule_uid = @uid
  AND  NOT EXISTS (SELECT 1 FROM business_rule_data_element e
                   WHERE e.business_rule_uid = s.business_rule_uid
                     AND e.field_name = s.field_name
                     AND ISNULL(e.class_name,'~') = ISNULL(s.class_name,'~'));

DECLARE @now INT = (SELECT COUNT(*) FROM business_rule_data_element WHERE business_rule_uid = @uid);
IF @now <> @expected
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Restore did not reach the BEFORE count -- rolled back, nothing changed.', 16, 1);
    RETURN;
END

COMMIT TRANSACTION;
SELECT restored_to = @now;
GO


/*--------------------------------------------------------------------------------------
  STEP 5 -- CLEANUP (only once the test is finished and the canary is restored)
--------------------------------------------------------------------------------------*/
-- DROP TABLE dbo.asi_rule_element_snapshot;

/*--------------------------------------------------------------------------------------
  WHAT THE RESULT MEANS

  If STEP 3b shows '*** REWRITTEN ***' or '*** DESTROYED ***':
    Rule Manager rewrites the element list on save. The Prod cutover must NOT flip
    row_status_flag through the UI. Update it by SQL instead:
        UPDATE business_rule SET row_status_flag = 705, date_last_modified = GETDATE(),
               last_maintained_by = SUSER_SNAME()
        WHERE rule_name = 'kb_Order_Validator_v2';
    and snapshot business_rule_data_element before AND after any registration work.

  If STEP 3b shows everything 'untouched':
    A plain status flip is safe, and something else caused the 2026-09-01 loss -- most
    likely the act of CREATING/registering the asi_ rule in the same Rule Manager session.
    Re-test by registering a throwaway rule while an existing one is open.

  Either way, record the answer in the deploy guide before touching Prod.
--------------------------------------------------------------------------------------*/

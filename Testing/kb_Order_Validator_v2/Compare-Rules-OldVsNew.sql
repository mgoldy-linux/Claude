/*======================================================================================
  Compare-Rules-OldVsNew.sql
  Equivalence harness for the kb_Order_Validator_v2 assembly (OLD DLL vs NEW DLL 1.0.1.0).

  WHY THIS WORKS
    Both rules are thin C# wrappers over SQL that the rebuild did NOT change:
      - kb_Order_Validator_v2  -> dbo.kb_fnt_br_order_validator_v2 (verdict + surcharge toggle)
      - kb_Order_Workflow_v2   -> dbo.kb_proc_br_oe_hdr_note       (freight-quote note)
    The only C# changes were connection source, error-log destination, and C# 7.3 syntax.
    So every DB-observable result MUST match between OLD and NEW. This harness captures the
    two persisted artifacts (surcharge flag + header notes) per run and diffs them.

  EXPECTED-MISMATCH (by design, NOT a regression):
    Error rows move OLD: kb_table_br_error_log  ->  NEW: business_rule_log. Don't compare those.

  THE NOTE PROC IS STATEFUL (not idempotent across runs): run 1 inserts the note, run 2 sees
  it already present and no-ops. So RESET (step 2) before EACH run to give both DLLs an
  identical clean starting state. Run in P21Play only.

  SEQUENCE
    1. (once)  Create the capture table.
    2. RESET the test order's freight note  -> deploy OLD DLL -> save order -> CAPTURE @label='OLD'
    3. RESET again                          -> deploy NEW DLL -> save order -> CAPTURE @label='NEW'
    4. DIFF.   5. CLEANUP.
  TIP: use @label='EXEC' with a direct  EXEC dbo.kb_proc_br_oe_hdr_note @order  as a
       DLL-free ground-truth baseline (the proc is version-independent).
======================================================================================*/

/*--------------------------------------------------------------------------------------
  STEP 1 -- one-time: capture table
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.asi_rule_compare_scratch') IS NULL
    CREATE TABLE dbo.asi_rule_compare_scratch (
        run_label   VARCHAR(20)   NOT NULL,   -- 'OLD' | 'NEW' | 'EXEC'
        captured_at DATETIME      NOT NULL CONSTRAINT DF_arcs_cap DEFAULT (GETDATE()),
        order_no    VARCHAR(8)    NOT NULL,
        artifact    VARCHAR(30)   NOT NULL,   -- 'surcharge_flag' | 'note'
        k           VARCHAR(200)  NULL,       -- key within artifact (topic|mandatory|delete)
        v           VARCHAR(MAX)  NULL        -- normalized value (note timestamp stripped)
    );
GO

/*--------------------------------------------------------------------------------------
  STEP 2 -- RESET: clear the auto freight-quote note so each DLL gets a clean trigger.
  Set @order. Soft-deletes the rule-managed note only (topic = 'Freight Quote Required').
  Comment this block out if you do NOT want the note removed between runs.
--------------------------------------------------------------------------------------*/
DECLARE @order VARCHAR(8) = '5838255';   -- <<< test order (from the B1 FINDER)

UPDATE oe_hdr_notepad
   SET delete_flag = 'Y'
 WHERE order_no = @order
   AND topic = 'Freight Quote Required'
   AND delete_flag = 'N';
GO

/*--------------------------------------------------------------------------------------
  STEP 3 -- CAPTURE: run AFTER the save (or after the direct EXEC). Set @label + @order.
  Re-run with @label='OLD' under the old DLL, then @label='NEW' under the new DLL.
--------------------------------------------------------------------------------------*/
DECLARE @label VARCHAR(20) = 'NEW';      -- <<< 'OLD' | 'NEW' | 'EXEC'
DECLARE @order VARCHAR(8)  = '5838255';  -- <<< same order as the RESET

DELETE FROM dbo.asi_rule_compare_scratch WHERE run_label = @label AND order_no = @order;

-- Artifact 1: validator's persisted surcharge toggle
INSERT dbo.asi_rule_compare_scratch (run_label, order_no, artifact, k, v)
SELECT @label, @order, 'surcharge_flag', NULL, oe_surcharge
FROM   oe_hdr_ud WHERE order_no = @order;   -- UD field lives in oe_hdr_ud, keyed by order_no

-- Artifact 2: workflow proc's notes. Key = topic|mandatory|delete; value = note text with
-- the trailing "- Karen B, <timestamp>" stripped (the timestamp differs every run and would
-- create false diffs; the meaningful carrier+message prefix is what we compare).
INSERT dbo.asi_rule_compare_scratch (run_label, order_no, artifact, k, v)
SELECT @label, @order, 'note',
       topic + '|mand=' + ISNULL(mandatory,'') + '|del=' + ISNULL(delete_flag,''),
       CASE WHEN CAST(note AS VARCHAR(MAX)) LIKE '%- Karen B%'
            THEN RTRIM(LEFT(CAST(note AS VARCHAR(MAX)), CHARINDEX('- Karen B', CAST(note AS VARCHAR(MAX))) - 1))
            ELSE CAST(note AS VARCHAR(MAX)) END
FROM   oe_hdr_notepad
WHERE  order_no = @order
  AND  topic = 'Freight Quote Required';
GO

/*--------------------------------------------------------------------------------------
  STEP 3b -- RESET-AND-EXEC WRAPPER (DLL-free ground-truth baseline).
  Self-contained: resets the note, calls the proc DIRECTLY (the same call the workflow
  rule makes -- version-independent), and captures as @label (default 'EXEC') in ONE run.
  No DLL swap or P21 save needed. Use the resulting 'EXEC' label as the expected baseline
  in STEP 4 (e.g. compare 'EXEC' vs 'NEW'). Set @order only.
  NOTE: this exercises only the WORKFLOW/note path. The validator's surcharge toggle and
  message come from kb_fnt_br_order_validator_v2 and are NOT reproduced here (the function
  needs the live TVP payload) -- so surcharge_flag is captured as the order's CURRENT value
  for reference, not as a proc result.
--------------------------------------------------------------------------------------*/
DECLARE @order VARCHAR(8) = '5838255';   -- <<< test order (from the B1 FINDER)
DECLARE @label VARCHAR(20) = 'EXEC';     -- baseline label

-- reset the rule-managed note so the proc hits a clean trigger state
UPDATE oe_hdr_notepad
   SET delete_flag = 'Y'
 WHERE order_no = @order AND topic = 'Freight Quote Required' AND delete_flag = 'N';

-- run the proc exactly as kb_Order_Workflow_v2.ExecuteAsync does
EXEC dbo.kb_proc_br_oe_hdr_note @ordernumber = @order;

-- capture the result under @label
DELETE FROM dbo.asi_rule_compare_scratch WHERE run_label = @label AND order_no = @order;

INSERT dbo.asi_rule_compare_scratch (run_label, order_no, artifact, k, v)
SELECT @label, @order, 'surcharge_flag', NULL, oe_surcharge
FROM   oe_hdr_ud WHERE order_no = @order;   -- UD field lives in oe_hdr_ud, keyed by order_no

INSERT dbo.asi_rule_compare_scratch (run_label, order_no, artifact, k, v)
SELECT @label, @order, 'note',
       topic + '|mand=' + ISNULL(mandatory,'') + '|del=' + ISNULL(delete_flag,''),
       CASE WHEN CAST(note AS VARCHAR(MAX)) LIKE '%- Karen B%'
            THEN RTRIM(LEFT(CAST(note AS VARCHAR(MAX)), CHARINDEX('- Karen B', CAST(note AS VARCHAR(MAX))) - 1))
            ELSE CAST(note AS VARCHAR(MAX)) END
FROM   oe_hdr_notepad
WHERE  order_no = @order AND topic = 'Freight Quote Required';
GO

/*--------------------------------------------------------------------------------------
  STEP 4 -- DIFF: after both labels captured. result column flags any divergence.
  EXPECT every row = 'MATCH'. Anything else (other than the error-log table, which this
  harness does not touch) is a real behavioral difference to investigate.
--------------------------------------------------------------------------------------*/
DECLARE @a VARCHAR(20) = 'OLD', @b VARCHAR(20) = 'NEW';   -- <<< labels to compare

SELECT ISNULL(o.order_no, n.order_no)  AS order_no,
       ISNULL(o.artifact, n.artifact)  AS artifact,
       ISNULL(o.k, n.k)                AS k,
       o.v                             AS old_value,
       n.v                             AS new_value,
       CASE WHEN o.v IS NULL AND n.v IS NULL THEN 'BOTH NULL'
            WHEN o.v IS NULL              THEN 'ONLY IN ' + @b
            WHEN n.v IS NULL              THEN 'ONLY IN ' + @a
            WHEN o.v <> n.v               THEN '*** DIFFERENT ***'
            ELSE 'MATCH' END            AS result
FROM       (SELECT * FROM dbo.asi_rule_compare_scratch WHERE run_label = @a) o
FULL JOIN  (SELECT * FROM dbo.asi_rule_compare_scratch WHERE run_label = @b) n
       ON  o.order_no = n.order_no AND o.artifact = n.artifact
       AND ISNULL(o.k,'~') = ISNULL(n.k,'~')
ORDER BY order_no, artifact, k;
GO

/*--------------------------------------------------------------------------------------
  STEP 5 -- CLEANUP (optional, when finished testing)
--------------------------------------------------------------------------------------*/
-- DROP TABLE dbo.asi_rule_compare_scratch;

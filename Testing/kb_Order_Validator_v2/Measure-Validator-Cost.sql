/*======================================================================================
  Measure-Validator-Cost.sql        BRR (P21BusinessRules). Read-only except its own table.

  Measures what the kb_ -> asi_ port actually cost or saved, on three layers.

  WHY NOT WALL-CLOCK
    Per the standing rule: wall-clock on these servers has reported the exact opposite of
    the truth. Every number here is logical reads / CPU from the plan-cache DMVs, or a byte
    count. No stopwatch.

  WHY THE NUMBERS WE ALREADY HAVE ARE NOT A BASELINE
    business_rule_log holds kb_Order_Validator_v2 payloads of ~52,972 bytes from 2026-09-01.
    Those were captured while kb_ was ITSELF on the truncated 74/3 registration, so they
    measure kb_ crippled, not kb_. Comparing them to _t2 would show the new rule losing, for
    a reason that has nothing to do with the rewrite. kb_ is now repaired to 114/11 and must
    be re-measured from scratch.

  THE THREE LAYERS
    1. DataSet payload  -- DATALENGTH(xml) in business_rule_log. What P21 builds and ships
                           to the rule on every save. kb_ asks for 114 fields / 11
                           DataWindows; _t2 asks for 76 / 5. Free, already logged.
    2. SQL cost         -- logical reads + worker time. kb_ calls one multi-statement TVF
                           (57 scalar params, 2 TVPs); _t2 issues 5 small native SELECTs.
    3. Rule wall time   -- deliberately NOT measured. See above.

  PROTOCOL -- both halves must save the SAME order, or the comparison is void.
    A. Run STEP 1 (snapshot).
    B. Set kb_ ON / _t2 OFF (by SQL -- Activate-asi_Order_Validator_t2.sql has the flips).
       Recycle pools. Save the test order. Note the order number.
    C. Run STEP 2 with @phase='kb'.
    D. Run STEP 1 again.
    E. Set _t2 ON / kb_ OFF. Recycle pools. Save the SAME order again.
    F. Run STEP 2 with @phase='t2'.
    G. Run STEP 3 to report.

  Recycling the pools between halves also clears the middleware's rule cache, which is what
  makes the two halves independent. Do not skip it to save time -- a warm cache on one side
  and a cold one on the other is a measurement of the cache, not of the rule.
======================================================================================*/

USE P21BusinessRules;
GO

/*-------------------------------------------------------------------------------------
  STEP 0 (once): result store. Kept as a real table so the two halves survive the pool
  recycle and the disconnect between them.
-------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.asi_validator_cost_snap') IS NULL
    CREATE TABLE dbo.asi_validator_cost_snap (
        snap_uid     int IDENTITY(1,1) PRIMARY KEY,
        phase        varchar(10)  NOT NULL,   -- 'kb' | 't2' | 'base'
        taken_at     datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
        sql_handle   varbinary(64) NULL,
        stmt_start   int NULL,
        obj_name     nvarchar(256) NULL,
        exec_count   bigint NULL,
        logical_rds  bigint NULL,
        worker_us    bigint NULL,
        stmt_text    nvarchar(max) NULL
    );
GO

/*-------------------------------------------------------------------------------------
  STEP 1 -- snapshot the plan cache BEFORE a save. Run immediately before each half.
-------------------------------------------------------------------------------------*/
DELETE FROM dbo.asi_validator_cost_snap WHERE phase = 'base';

INSERT INTO dbo.asi_validator_cost_snap
        (phase, sql_handle, stmt_start, obj_name, exec_count, logical_rds, worker_us, stmt_text)
SELECT  'base', qs.sql_handle, qs.statement_start_offset,
        OBJECT_NAME(st.objectid, st.dbid),
        qs.execution_count, qs.total_logical_reads, qs.total_worker_time,
        SUBSTRING(st.text, qs.statement_start_offset/2 + 1,
                  (CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
                        ELSE qs.statement_end_offset END - qs.statement_start_offset)/2 + 1)
FROM    sys.dm_exec_query_stats qs
CROSS   APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE   st.text LIKE '%kb_fnt_br_order_validator%'
   OR   st.text LIKE '%p21_view_freight_code%'
   OR   st.text LIKE '%carrier_flag%'
   OR   st.text LIKE '%p21_view_freight_charge_break%'
   OR   st.text LIKE '%default_product_group%'
   OR   OBJECT_NAME(st.objectid, st.dbid) LIKE 'kb_fnt_br_order_validator%';
GO

/*-------------------------------------------------------------------------------------
  STEP 2 -- snapshot AFTER the save, and store the delta. Set @phase first.
-------------------------------------------------------------------------------------*/
DECLARE @phase varchar(10) = 'kb';   -- <<< 'kb' for the first half, 't2' for the second

DELETE FROM dbo.asi_validator_cost_snap WHERE phase = @phase;

;WITH nowstats AS (
    SELECT  qs.sql_handle, qs.statement_start_offset AS stmt_start,
            obj = OBJECT_NAME(st.objectid, st.dbid),
            qs.execution_count, qs.total_logical_reads, qs.total_worker_time,
            txt = SUBSTRING(st.text, qs.statement_start_offset/2 + 1,
                      (CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
                            ELSE qs.statement_end_offset END - qs.statement_start_offset)/2 + 1)
    FROM    sys.dm_exec_query_stats qs
    CROSS   APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    WHERE   st.text LIKE '%kb_fnt_br_order_validator%'
       OR   st.text LIKE '%p21_view_freight_code%'
       OR   st.text LIKE '%carrier_flag%'
       OR   st.text LIKE '%p21_view_freight_charge_break%'
       OR   st.text LIKE '%default_product_group%'
       OR   OBJECT_NAME(st.objectid, st.dbid) LIKE 'kb_fnt_br_order_validator%'
)
INSERT INTO dbo.asi_validator_cost_snap
        (phase, sql_handle, stmt_start, obj_name, exec_count, logical_rds, worker_us, stmt_text)
SELECT  @phase, n.sql_handle, n.stmt_start, n.obj,
        n.execution_count  - ISNULL(b.exec_count,0),
        n.total_logical_reads - ISNULL(b.logical_rds,0),
        n.total_worker_time   - ISNULL(b.worker_us,0),
        n.txt
FROM    nowstats n
LEFT    JOIN dbo.asi_validator_cost_snap b
       ON   b.phase = 'base' AND b.sql_handle = n.sql_handle AND b.stmt_start = n.stmt_start
WHERE   n.execution_count - ISNULL(b.exec_count,0) > 0;   -- only what this save actually ran
GO

/*-------------------------------------------------------------------------------------
  STEP 3 -- report. Run after BOTH halves are captured.
-------------------------------------------------------------------------------------*/

-- Layer 2: SQL cost per save.
SELECT  phase,
        statements   = COUNT(*),
        executions   = SUM(exec_count),
        logical_reads= SUM(logical_rds),
        cpu_ms       = SUM(worker_us)/1000.0
FROM    dbo.asi_validator_cost_snap
WHERE   phase IN ('kb','t2')
GROUP   BY phase ORDER BY phase;

-- Per-statement breakdown, heaviest first. This is where a single bad native SELECT would
-- show up -- do not let the totals hide one.
SELECT  phase, obj_name, exec_count, logical_rds, cpu_ms = worker_us/1000.0,
        stmt = LEFT(REPLACE(REPLACE(stmt_text,CHAR(13),' '),CHAR(10),' '), 160)
FROM    dbo.asi_validator_cost_snap
WHERE   phase IN ('kb','t2')
ORDER   BY phase, logical_rds DESC;

-- Layer 1: DataSet payload P21 builds per save. Uses only Invoke rows (Return rows include
-- whatever the rule wrote back, so they are not comparable across rules).
SELECT  rule_name,
        saves      = COUNT(*),
        avg_bytes  = AVG(DATALENGTH(xml)),
        min_bytes  = MIN(DATALENGTH(xml)),
        max_bytes  = MAX(DATALENGTH(xml))
FROM    business_rule_log WITH (NOLOCK)
WHERE   log_action = 'Invoke'
  AND   rule_name IN ('kb_Order_Validator_v2','asi_Order_Validator_t2')
  AND   date_created >= CAST(GETDATE() AS date)   -- today's paired run only
GROUP   BY rule_name;

/*--------------------------------------------------------------------------------------
  READING THE RESULT HONESTLY

  * Layer 1 is the one the rewrite most directly controls: 114 fields / 11 DataWindows vs
    76 / 5. Expect _t2 lower. If it is not, the registration drifted -- check it before
    concluding anything about the code.
  * Layer 2 may well show _t2 issuing MORE statements (5 SELECTs vs 1 TVF call) while doing
    FEWER logical reads. Both facts are real; report both. More round trips is a genuine
    cost and should not be buried because the reads look good.
  * A single paired save is one sample. For a number worth quoting, repeat the protocol
    across the corpus, not one order.
  * If the rewrite is NOT faster, say so. That is a legitimate result -- the port's
    justification is retiring the kb_ objects and the custom stored procedure dependency,
    not speed.

  CLEANUP:  DROP TABLE dbo.asi_validator_cost_snap;
--------------------------------------------------------------------------------------*/

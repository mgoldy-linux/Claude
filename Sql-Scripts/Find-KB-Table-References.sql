-- Find-KB-Table-References.sql
-- For each kb_ table in P21, find what SQL objects and Agent jobs reference it.
-- Run on P21.allsurfaces.com / P21 (msdb cross-queries will run automatically).
-- ============================================================

-- -------------------------------------------------------
-- Section 1: Stored procs, functions, triggers, views
--            in P21 that reference any kb_ table
-- -------------------------------------------------------
SELECT
    kb.name            AS kb_table,
    o.type_desc        AS object_type,
    SCHEMA_NAME(o.schema_id) + '.' + o.name AS referencing_object,
    'P21 sql_modules'  AS source
FROM sys.tables kb
CROSS JOIN sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE kb.name LIKE 'kb_%'
  AND m.definition LIKE '%' + kb.name + '%'

UNION ALL

-- -------------------------------------------------------
-- Section 2: SQL Agent job steps (searched via msdb)
-- -------------------------------------------------------
SELECT
    kb.name             AS kb_table,
    'SQL_AGENT_JOB'     AS object_type,
    j.name + ' > ' + js.step_name AS referencing_object,
    'msdb sysjobsteps'  AS source
FROM sys.tables kb
CROSS JOIN msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps js ON js.job_id = j.job_id
WHERE kb.name LIKE 'kb_%'
  AND js.command LIKE '%' + kb.name + '%'

ORDER BY kb_table, source, object_type, referencing_object;

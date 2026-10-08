/* Find kb_ / js_ / ds_ references in SQL Agent jobs (P21 Prod).  Read-only.
   Part 1: tokens directly in a job step command.
   Part 2: stored procs/functions CALLED by a step (name appears in the step command)
           whose own definition references kb_/js_/ds_ objects (one level deep).  */
USE P21;
SET NOCOUNT ON;

-- Part 1: direct hits in step commands
SELECT 'direct' AS hit_type, j.name AS job_name, j.enabled, s.step_id, s.step_name, s.database_name,
       LEFT(REPLACE(REPLACE(s.command, CHAR(13), ' '), CHAR(10), ' '), 250) AS command
FROM   msdb.dbo.sysjobs j
JOIN   msdb.dbo.sysjobsteps s ON s.job_id = j.job_id
WHERE  s.command LIKE '%kb[_]%' OR s.command LIKE '%js[_]%' OR s.command LIKE '%ds[_]%'
ORDER  BY j.name, s.step_id;

-- Part 2: objects called by steps that themselves reference kb_/js_/ds_
SELECT 'via called object' AS hit_type, j.name AS job_name, j.enabled, s.step_id, s.step_name,
       o.name AS called_object, o.type_desc, o.modify_date,
       CASE WHEN m.definition LIKE '%kb[_]%' THEN 'kb_ ' ELSE '' END
     + CASE WHEN m.definition LIKE '%js[_]%' THEN 'js_ ' ELSE '' END
     + CASE WHEN m.definition LIKE '%ds[_]%' THEN 'ds_'  ELSE '' END AS prefixes_inside
FROM   msdb.dbo.sysjobs j
JOIN   msdb.dbo.sysjobsteps s ON s.job_id = j.job_id AND s.subsystem = 'TSQL'
JOIN   sys.objects o          ON o.type IN ('P','FN','IF','TF','V')
                             AND s.command LIKE '%' + o.name + '%'
JOIN   sys.sql_modules m      ON m.object_id = o.object_id
WHERE  m.definition LIKE '%kb[_]%' OR m.definition LIKE '%js[_]%' OR m.definition LIKE '%ds[_]%'
ORDER  BY j.name, s.step_id, o.name;

/*======================================================================================
  Check-Grants-asi-rules.sql
  Pre-deploy permission gate for asi_Order_Validator + asi_Order_Workflow.

  WHY THIS MATTERS
    kb_Order_Validator_v2 and kb_Order_Workflow_v2 touched most of these objects
    INDIRECTLY -- inside dbo.kb_fnt_br_order_validator_v2 / dbo.kb_proc_br_oe_hdr_note.
    SQL Server ownership chaining meant the FUNCTION/PROC owner's rights applied, so the
    caller never needed rights on the underlying tables.

    The asi_ rules query those tables DIRECTLY as the caller. Ownership chaining no longer
    covers them. A missing grant surfaces as a swallowed rule error (both rules log
    best-effort and never rethrow), i.e. silence -- not an obvious failure.

  DO NOT rely on HAS_PERMS_BY_NAME while connected as yourself: as db_owner/sysadmin it
  returns 1 for everything and proves nothing. Section 1 reads the actual grants.

  Run in the target DB (P21BusinessRules for the BRR deploy).
======================================================================================*/


/*--------------------------------------------------------------------------------------
  SECTION 1 -- THE REAL CHECK: what is actually granted, and to whom.
  Every object below must show a GRANT of the required permission to a principal the rule
  will be running under (normally p21_application_role; public also counts).
--------------------------------------------------------------------------------------*/
;WITH required AS (
    SELECT obj, perm, used_by FROM (VALUES
        -- asi_Order_Validator
        ('p21_view_freight_code',          'SELECT',  'validator'),
        ('p21_view_ship_to',               'SELECT',  'validator + workflow'),
        ('p21_view_freight_charge_break',  'SELECT',  'validator'),
        ('p21_view_address',               'SELECT',  'validator + workflow'),
        ('address_ud',                     'SELECT',  'validator + workflow'),
        ('inv_mast',                       'SELECT',  'validator + workflow'),
        ('product_group',                  'SELECT',  'validator'),
        -- asi_Order_Workflow
        ('oe_hdr',                         'SELECT',  'workflow'),
        ('oe_line',                        'SELECT',  'workflow'),
        ('customer',                       'SELECT',  'workflow'),
        ('address',                        'SELECT',  'workflow'),
        ('oe_hdr_notepad',                 'SELECT',  'workflow'),
        ('oe_hdr_notepad',                 'UPDATE',  'workflow (clears mandatory)'),
        ('p21_ecc_add_order_header_note',  'EXECUTE', 'workflow (native P21 proc)'),
        -- both
        ('business_rule_log',              'INSERT',  'validator + workflow logging')
    ) v(obj, perm, used_by)
)
, evaluated AS (
    SELECT r.obj,
           r.perm,
           r.used_by,
           object_exists = CASE WHEN OBJECT_ID('dbo.' + r.obj) IS NULL THEN 'MISSING' ELSE 'ok' END,
           granted_to    = ISNULL(STUFF((
                SELECT ', ' + dp.name
                FROM   sys.database_permissions perm2
                JOIN   sys.database_principals dp ON dp.principal_id = perm2.grantee_principal_id
                WHERE  perm2.major_id = OBJECT_ID('dbo.' + r.obj)
                  AND  perm2.minor_id = 0
                  AND  perm2.state = 'G'
                  AND  (perm2.permission_name = r.perm OR perm2.permission_name = 'CONTROL')
                ORDER BY dp.name
                FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, ''), '*** NONE ***'),
           verdict       = CASE
                WHEN OBJECT_ID('dbo.' + r.obj) IS NULL THEN '*** OBJECT MISSING ***'
                WHEN EXISTS (
                    SELECT 1 FROM sys.database_permissions perm2
                    WHERE perm2.major_id = OBJECT_ID('dbo.' + r.obj)
                      AND perm2.minor_id = 0 AND perm2.state = 'G'
                      AND (perm2.permission_name = r.perm OR perm2.permission_name = 'CONTROL')
                ) THEN 'ok'
                ELSE '*** NO GRANT -- see SECTION 3 ***' END
    FROM   required r
)
SELECT obj, perm, used_by, object_exists, granted_to, verdict
FROM   evaluated
ORDER  BY CASE WHEN verdict = 'ok' THEN 1 ELSE 0 END, obj, perm;
GO


/*--------------------------------------------------------------------------------------
  SECTION 2 -- Sanity: how does the CURRENT rule actually get its rights today?
  Confirms the ownership-chaining assumption above, and shows which principal P21 uses.
  If the kb_ objects are owned by dbo and the tables are too, chaining was doing the work.
--------------------------------------------------------------------------------------*/
SELECT o.name,
       o.type_desc,
       owner_principal = ISNULL(dp.name, '(schema owner)'),
       schema_name     = s.name
FROM   sys.objects o
JOIN   sys.schemas s ON s.schema_id = o.schema_id
LEFT   JOIN sys.database_principals dp ON dp.principal_id = o.principal_id
WHERE  o.name IN ('kb_fnt_br_order_validator_v2','kb_proc_br_oe_hdr_note',
                  'p21_ecc_add_order_header_note','oe_hdr','inv_mast','business_rule_log');

-- Which principals exist that P21 rules could be running as?
SELECT name, type_desc, is_fixed_role
FROM   sys.database_principals
WHERE  name LIKE 'p21%' OR name IN ('public')
ORDER  BY name;
GO


/*--------------------------------------------------------------------------------------
  SECTION 3 -- REMEDIATION. Generates the GRANT statements for anything Section 1 flagged.
  REVIEW THE OUTPUT BEFORE RUNNING IT. Grant to the application role, never to individuals.
  Adjust @principal if Section 2 shows P21 uses a different one.
--------------------------------------------------------------------------------------*/
DECLARE @principal SYSNAME = 'p21_application_role';

;WITH required AS (
    SELECT obj, perm FROM (VALUES
        ('p21_view_freight_code','SELECT'),      ('p21_view_ship_to','SELECT'),
        ('p21_view_freight_charge_break','SELECT'),('p21_view_address','SELECT'),
        ('address_ud','SELECT'),                 ('inv_mast','SELECT'),
        ('product_group','SELECT'),              ('oe_hdr','SELECT'),
        ('oe_line','SELECT'),                    ('customer','SELECT'),
        ('address','SELECT'),                    ('oe_hdr_notepad','SELECT'),
        ('oe_hdr_notepad','UPDATE'),             ('p21_ecc_add_order_header_note','EXECUTE'),
        ('business_rule_log','INSERT')
    ) v(obj, perm)
)
SELECT generated_grant =
       'GRANT ' + r.perm + ' ON dbo.' + r.obj + ' TO ' + QUOTENAME(@principal) + ';'
FROM   required r
WHERE  OBJECT_ID('dbo.' + r.obj) IS NOT NULL
  AND  NOT EXISTS (
        SELECT 1 FROM sys.database_permissions perm2
        WHERE perm2.major_id = OBJECT_ID('dbo.' + r.obj)
          AND perm2.minor_id = 0 AND perm2.state = 'G'
          AND (perm2.permission_name = r.perm OR perm2.permission_name = 'CONTROL')
      );
GO


/*--------------------------------------------------------------------------------------
  SECTION 4 -- Confirm p21_ecc_add_order_header_note really is a NATIVE P21 proc.
  asi_Order_Workflow calls it deliberately (it owns note_id assignment, so bypassing it
  with a raw INSERT into oe_hdr_notepad would drift the P21 counter). If this comes back
  looking custom, that decision has to be revisited.
--------------------------------------------------------------------------------------*/
SELECT name, type_desc, is_ms_shipped, create_date, modify_date
FROM   sys.objects
WHERE  name = 'p21_ecc_add_order_header_note';

-- Its parameter list -- asi_Order_Workflow calls it POSITIONALLY, so confirm the order is
-- (order_no, topic, note) and that there are no additional required parameters.
SELECT p.parameter_id, p.name, TYPE_NAME(p.user_type_id) AS data_type,
       p.max_length, p.is_output, p.has_default_value
FROM   sys.parameters p
WHERE  p.object_id = OBJECT_ID('dbo.p21_ecc_add_order_header_note')
ORDER  BY p.parameter_id;
GO

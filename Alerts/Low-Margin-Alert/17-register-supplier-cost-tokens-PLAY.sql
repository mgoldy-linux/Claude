/*==============================================================================
  17 — Register the two supplier-cost tokens  (Evan item #3, step 2 of 3) — PLAY
  Target : P21Play.  Prod twin not written yet (do Play first, then re-check
           Prod's own token uids -- they differ between environments).
  Author : Mark Goldyn / Claude          Date: 2026-10-07

  *** THIS FILE RUNS AS-IS. DO NOT UNCOMMENT ANYTHING. ***
  Commits only if it inserts exactly 2 token rows and 2 link rows.

  DEPENDS ON script 16 (the two columns must exist in the view first).

  WHY REGISTER THEM AT ALL
  The where_clause is plain SQL appended to a SELECT on the view, so raw column
  names would work today. But Alert Maintenance REGENERATES the entire
  where_clause from the Filter grid on save (trap 10), and the grid only knows
  REGISTERED tokens. An unregistered column would be silently dropped the first
  time anyone opens and saves the alert -- the filter would quietly stop
  filtering and the subset would go back to the whole Team. Registering them is
  what keeps uid 104 out of the never-open-in-the-client category that uid 106
  is already in.

  WHAT IS REGISTERED, AND WHY THESE EXACT VALUES
  Mirrored from the closest existing tokens rather than chosen:

    unit_supplier_cost              data_type_cd 853 (decimal), available_areas 4
      <- exactly matches unit_standard_cost (739) and unit_mac (738), its two
         siblings in the e-mail body. Area 4 = line-item body.
         The view CASTs it to DECIMAL(19,2), so decimal is right.

    std_cost_exceeds_supplier_cost  data_type_cd 851 (char), available_areas 32
      <- exactly matches low_margin_flag (742), the other Y/N trigger-only flag
         on this same alert. Area 32 = event/filter.

  Type codes verified from code_p21 on Play 2026-10-07: 850 varchar, 851 char,
  853 decimal. available_areas is a BITMASK (4 body, 32 filter, 11 subject/
  header, 16/64 recipient) -- see feedback_p21_alert_available_areas.

  The flag is filter-only (32), not 36, deliberately: low_margin_flag is the
  precedent, and the recipient can already see the numbers because
  unit_supplier_cost sits in the body next to Standard Cost. Widen to 36 later
  if Evan wants the Y/N printed too.

  ALERT TYPE: alert_type_uid = 12 (read from alert_implementation 104, not
  assumed). Both tokens are linked to that type via alert_type_x_token.

  *** UID ALLOCATION ***
  Both tables are sequence-backed, same as alert_recipient (see script 13):
    counter.token              counter_num -1, seq_name seq_token
    counter.alert_type_x_token counter_num -1, seq_name seq_alert_type_x_token
  Drawn with NEXT VALUE FOR, so nothing needs realigning afterwards. Verified
  aligned on Play 2026-10-07: seq_token 746 = MAX(token_uid) 746;
  seq_alert_type_x_token 1644 = MAX 1644.

  NOTE: token.name is NOT unique in this schema (price_edit exists twice,
  product_group_id three times, with different uids and areas). The guard below
  therefore checks "not already registered AND linked to alert type 12", not
  just the name.

  ROLLBACK at the bottom, commented on purpose.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '=============== BEFORE ===============';
SELECT t.token_uid, t.name, t.description, t.data_type_cd, t.available_areas,
       linked_to_type_12 = CASE WHEN EXISTS (SELECT 1 FROM dbo.alert_type_x_token x
                                             WHERE x.token_uid = t.token_uid AND x.alert_type_uid = 12)
                                THEN 'YES' ELSE 'no' END
FROM   dbo.token t
WHERE  t.name IN ('unit_supplier_cost','std_cost_exceeds_supplier_cost',
                  'unit_standard_cost','low_margin_flag')
ORDER BY t.name;
GO

/*------------------------------- APPLY ------------------------------------*/
BEGIN TRY
  BEGIN TRAN;

  DECLARE @type_uid int = (SELECT alert_type_uid FROM dbo.alert_implementation
                           WHERE alert_implementation_uid = 104);
  IF @type_uid IS NULL
    BEGIN RAISERROR('Could not resolve alert_type_uid from alert 104.',16,1); END

  DECLARE @new TABLE (token_uid int, name varchar(128));

  -- 1. the two token rows
  INSERT INTO dbo.token
        (token_uid, name, description, date_created, date_last_modified,
         last_maintained_by, data_type_cd, available_areas)
  OUTPUT inserted.token_uid, inserted.name INTO @new
  SELECT NEXT VALUE FOR dbo.seq_token, v.name, v.descr,
         GETDATE(), GETDATE(), 'MGOLDYN', v.dtype, v.areas
  FROM  (VALUES
           ('unit_supplier_cost',             'Supplier Cost',                  853,  4),
           ('std_cost_exceeds_supplier_cost', 'Std Cost Exceeds Supplier Cost', 851, 32)
        ) AS v(name, descr, dtype, areas)
  WHERE NOT EXISTS (
          SELECT 1 FROM dbo.token t
          JOIN dbo.alert_type_x_token x ON x.token_uid = t.token_uid AND x.alert_type_uid = @type_uid
          WHERE t.name = v.name);

  DECLARE @a int = @@ROWCOUNT;

  -- 2. link each to the OE alert type
  INSERT INTO dbo.alert_type_x_token
        (alert_type_x_token_uid, alert_type_uid, token_uid,
         date_created, date_last_modified, last_maintained_by)
  SELECT NEXT VALUE FOR dbo.seq_alert_type_x_token, @type_uid, n.token_uid,
         GETDATE(), GETDATE(), 'MGOLDYN'
  FROM   @new n;

  DECLARE @b int = @@ROWCOUNT;
  PRINT 'tokens inserted: ' + CAST(@a AS varchar(10)) + ' / links inserted: ' + CAST(@b AS varchar(10));

  IF @a = 2 AND @b = 2
    BEGIN COMMIT; PRINT 'COMMITTED - 2 tokens + 2 type links.'; END
  ELSE
    BEGIN ROLLBACK;
          PRINT 'ROLLED BACK - expected 2 and 2. If 0/0, already registered.'; END
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'ROLLED BACK ON ERROR - ' + ERROR_MESSAGE();
END CATCH;
GO

/*------------------------------ VERIFY ------------------------------------*/
PRINT '=============== AFTER ===============';
SELECT t.token_uid, t.name, t.description, t.data_type_cd, t.available_areas,
       linked_to_type_12 = CASE WHEN EXISTS (SELECT 1 FROM dbo.alert_type_x_token x
                                             WHERE x.token_uid = t.token_uid AND x.alert_type_uid = 12)
                                THEN 'YES' ELSE 'no' END
FROM   dbo.token t
WHERE  t.name IN ('unit_supplier_cost','std_cost_exceeds_supplier_cost')
ORDER BY t.name;

SELECT seq_token_now = (SELECT current_value FROM sys.sequences WHERE name='seq_token'),
       token_max     = (SELECT MAX(token_uid) FROM dbo.token),
       seq_axt_now   = (SELECT current_value FROM sys.sequences WHERE name='seq_alert_type_x_token'),
       axt_max       = (SELECT MAX(alert_type_x_token_uid) FROM dbo.alert_type_x_token);
GO
PRINT 'Expected: both tokens present, linked_to_type_12 = YES, sequences = maxes.';
GO

/*=============================== ROLLBACK ===================================
  COMMENTED ON PURPOSE.
=============================================================================
USE P21Play;
GO
DELETE x FROM dbo.alert_type_x_token x
JOIN dbo.token t ON t.token_uid = x.token_uid
WHERE t.name IN ('unit_supplier_cost','std_cost_exceeds_supplier_cost');
DELETE FROM dbo.token
WHERE name IN ('unit_supplier_cost','std_cost_exceeds_supplier_cost');
PRINT 'tokens and links removed.';
GO
=============================================================================*/

/*==============================================================================
  20 — Populate the Filter grid rows (Evan #3, step 3c) — PLAY
  Target : P21Play.  Prod twin not written yet.
  Author : Mark Goldyn / Claude          Date: 2026-10-07

  *** THIS FILE RUNS AS-IS. DO NOT UNCOMMENT ANYTHING. ***
  DEPENDS ON scripts 16-19.

  WHY THIS EXISTS -- a gap in script 19 that was caught in the client.
  Script 19 wrote the new alert's where_clause by SQL but never populated the
  rows behind the Alert Maintenance **Filter grid**, which live in a separate
  table, dbo.Alert_implementation_query. Opening uid 110 in the client showed
  "No items to display" and an "An error has occurred accessing alert
  information" banner. Saving from that screen would have REGENERATED the
  where_clause from an EMPTY grid and wiped it (trap 10). Nothing was lost --
  the screen was closed without saving and both clauses were verified intact at
  391 characters.

  WHAT THIS DOES
    - clones uid 104's 10 grid rows onto the new alert (uid 110 in Play)
    - adds route_pricing_only = 'Y' to the new alert's grid
    - adds route_pricing_only = 'N' to uid 104's grid
  Both grids then carry 11 rows and match their where_clauses.

  GRID ROW SHAPE (mirrored from 104, not invented):
    column_id   = token_uid        operator_cd 1049 is greater than
    column_value and column_value_description both hold the literal
                                   1050 equals
                                   1053 does not equal
                                   1094 is not one of
                                   1102 does not contain
  seq_alert_implementation_query is sequence-backed (counter_num -1), drawn
  with NEXT VALUE FOR, so nothing needs realigning.

  *** PRE-EXISTING DEFECT FOUND WHILE DOING THIS -- NOT CAUSED BY THIS WORK ***
  `rma_flag <> 'Y'` appears in the where_clause of ALL of 104, 105, 106 and 107
  but has NO grid row on ANY of them, because **rma_flag is not a registered
  token for alert_type_uid 12 at all**. It therefore cannot be represented in
  the Filter grid, and the first client save of any of those four alerts will
  silently drop the RMA exclusion -- RMAs would start generating low-margin
  alerts. Measured on Play 2026-10-07: grid rows 104=10, 105=10, 106=10,
  107=11, rma_flag rows = 0 everywhere.
  This is NOT fixed here. Fixing it means registering rma_flag as a token
  (char, available_areas 32) and adding one grid row to each of the five
  alerts. Small, but it touches all four live alerts, so it needs the user's
  go-ahead. Until then the family is still not safe to open-and-save in the
  client, and uid 106 remains unsafe for its own separate reason (its -5% OR
  trigger has no grid representation at all).

  ROLLBACK at the bottom, commented on purpose.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @new int = (SELECT alert_implementation_uid FROM dbo.alert_implementation
                    WHERE alert_implementation_name = 'Low Margin Alert - Pricing Review (Std > Supplier)');

BEGIN TRY
  BEGIN TRAN;

  IF @new IS NULL BEGIN RAISERROR('Pricing Review alert not found - run script 19 first.',16,1); END
  IF EXISTS (SELECT 1 FROM dbo.Alert_implementation_query WHERE alert_implementation_uid = @new)
    BEGIN RAISERROR('The new alert already has grid rows - nothing done.',16,1); END

  INSERT INTO dbo.Alert_implementation_query
        (alert_implementation_query_uid, alert_implementation_uid, column_id, operator_cd,
         column_value, date_created, date_last_modified, last_maintained_by,
         row_status_flag, column_value_description)
  SELECT NEXT VALUE FOR dbo.seq_alert_implementation_query, @new, q.column_id, q.operator_cd,
         q.column_value, GETDATE(), GETDATE(), 'MGOLDYN', 704, q.column_value_description
  FROM   dbo.Alert_implementation_query q
  WHERE  q.alert_implementation_uid = 104;
  DECLARE @a int = @@ROWCOUNT;

  INSERT INTO dbo.Alert_implementation_query
        (alert_implementation_query_uid, alert_implementation_uid, column_id, operator_cd,
         column_value, date_created, date_last_modified, last_maintained_by,
         row_status_flag, column_value_description)
  VALUES(NEXT VALUE FOR dbo.seq_alert_implementation_query, @new, 749, 1050,
         'Y', GETDATE(), GETDATE(), 'MGOLDYN', 704, 'Y');
  DECLARE @b int = @@ROWCOUNT;

  INSERT INTO dbo.Alert_implementation_query
        (alert_implementation_query_uid, alert_implementation_uid, column_id, operator_cd,
         column_value, date_created, date_last_modified, last_maintained_by,
         row_status_flag, column_value_description)
  VALUES(NEXT VALUE FOR dbo.seq_alert_implementation_query, 104, 749, 1050,
         'N', GETDATE(), GETDATE(), 'MGOLDYN', 704, 'N');
  DECLARE @c int = @@ROWCOUNT;

  IF @a = 10 AND @b = 1 AND @c = 1
    BEGIN COMMIT; PRINT 'COMMITTED - 10 cloned + route(Y) on new alert + route(N) on 104.'; END
  ELSE
    BEGIN ROLLBACK;
          PRINT 'ROLLED BACK - got ' + CAST(@a AS varchar(5)) + '/' + CAST(@b AS varchar(5))
              + '/' + CAST(@c AS varchar(5)) + ', expected 10/1/1.'; END
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'ROLLED BACK ON ERROR - ' + ERROR_MESSAGE();
END CATCH;
GO

/*------------------------------ VERIFY ------------------------------------
  Both alerts should show 11 rows, identical except route_pricing_only Y vs N.
  rma_flag will be absent from both - see the note in the header.
---------------------------------------------------------------------------*/
SELECT alert_uid = q.alert_implementation_uid, tok = t.name,
       op = (SELECT TOP 1 code_description FROM dbo.code_p21 WHERE code_no = q.operator_cd),
       q.column_value
FROM   dbo.Alert_implementation_query q
LEFT JOIN dbo.token t ON t.token_uid = q.column_id
WHERE  q.alert_implementation_uid = 104
   OR  q.alert_implementation_uid = (SELECT alert_implementation_uid FROM dbo.alert_implementation
                                     WHERE alert_implementation_name = 'Low Margin Alert - Pricing Review (Std > Supplier)')
ORDER BY q.alert_implementation_uid, q.alert_implementation_query_uid;
GO

/*=============================== ROLLBACK ===================================
  COMMENTED ON PURPOSE.
=============================================================================
USE P21Play;
GO
DECLARE @new int = (SELECT alert_implementation_uid FROM dbo.alert_implementation
                    WHERE alert_implementation_name = 'Low Margin Alert - Pricing Review (Std > Supplier)');
DELETE FROM dbo.Alert_implementation_query WHERE alert_implementation_uid = @new;
DELETE FROM dbo.Alert_implementation_query WHERE alert_implementation_uid = 104 AND column_id = 749;
PRINT 'grid rows removed.';
GO
=============================================================================*/

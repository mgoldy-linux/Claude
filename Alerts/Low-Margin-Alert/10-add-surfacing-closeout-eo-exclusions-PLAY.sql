/*==============================================================================
  10 — Suppress Surfacing / CLOSEOUT / E&O on the Low Margin alerts (PLAY)
  Target : P21Play. Run 2026-09-17, same rationale/measurements as
           10-add-surfacing-closeout-eo-exclusions-PROD.sql — see that file's
           header for the full Evan Jenkins background.

  Differs from the PROD script only in target database and in the "before"
  text for 106/107, which needed a separate parity-restore pass first (Play's
  PAD pair still carried the pre-9/14 threshold bug at the time — see
  fix-play-parity in the project memory / Deploy-Guides\low-margin-alert.md,
  2026-09-17 section). Guarded the same way: aborts if any alert's current
  where_clause doesn't match the exact post-parity-fix text asserted below.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;

DECLARE @expected104 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND low_margin_flag = ''Y'' AND rma_flag <> ''Y''';
DECLARE @expected105 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < 5 AND rma_flag <> ''Y''';
DECLARE @expected106 NVARCHAR(MAX) = '(percent_profit_off_mac < -5 OR percent_profit_off_standard_cost < -5) AND new_order = ''Y'' AND total_amount > 1000 AND corp_address_id <> 1046538 AND product_group_id = ''PAD'' AND customer_id NOT IN (3021352,3023035,3023036) AND taker NOT LIKE ''%ESTORE%'' AND extended_standard_cost > ''500'' AND rma_flag <> ''Y''';
DECLARE @expected107 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id = ''PAD'' AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < -5 AND rma_flag <> ''Y''';

IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=104 AND where_clause = @expected104)
BEGIN RAISERROR('uid 104 where_clause drifted -- STOP.',16,1); RETURN; END
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=105 AND where_clause = @expected105)
BEGIN RAISERROR('uid 105 where_clause drifted -- STOP.',16,1); RETURN; END
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=106 AND where_clause = @expected106)
BEGIN RAISERROR('uid 106 where_clause drifted -- STOP.',16,1); RETURN; END
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=107 AND where_clause = @expected107)
BEGIN RAISERROR('uid 107 where_clause drifted -- STOP.',16,1); RETURN; END

PRINT 'All four where_clause values match the expected post-parity-fix baseline -- proceeding.';

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'',''SURFACE'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND low_margin_flag = ''Y'' AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 104;

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'',''SURFACE'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < 5 AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 105;

UPDATE alert_implementation
SET where_clause = '(percent_profit_off_mac < -5 OR percent_profit_off_standard_cost < -5) AND new_order = ''Y'' AND total_amount > 1000 AND corp_address_id <> 1046538 AND product_group_id = ''PAD'' AND customer_id NOT IN (3021352,3023035,3023036) AND taker NOT LIKE ''%ESTORE%'' AND extended_standard_cost > ''500'' AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 106;

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id = ''PAD'' AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < -5 AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 107;

PRINT 'Updated 104, 105, 106, 107.';
GO

SELECT alert_implementation_uid AS uid, alert_implementation_name AS name,
       CONVERT(varchar(19),date_last_modified,120) AS modified, where_clause
FROM alert_implementation
WHERE alert_implementation_uid IN (104,105,106,107)
ORDER BY alert_implementation_uid;
GO

/*===============================  ROLLBACK  =================================
  Revert each alert's where_clause to the @expectedNNN text captured above.

  ⚠ 2026-09-18 FINDING: uid 107's where_clause was subsequently reverted by a
  client-side edit (Alert Maintenance's Filter grid regenerates the whole
  where_clause from its own rows on save — see feedback_p21_alerts.md trap
  10) and had to be re-applied by SQL. uid 106 has NO grid representation of
  its OR-based condition at all in either environment — never open its
  Filter tab in the client, or this same regression will happen there with
  no way to fix it through the UI.
===========================================================================*/

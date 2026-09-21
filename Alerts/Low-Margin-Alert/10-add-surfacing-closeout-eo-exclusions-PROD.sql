/*==============================================================================
  10 — Suppress Surfacing / CLOSEOUT / E&O on the Low Margin alerts (PROD)
  Target : P21 (Prod). Guarded UPDATEs -- each aborts if the alert's current
           where_clause doesn't match what was verified live on 2026-09-14
           (no drift check needed for a where_clause UPDATE the way a shared
           VIEW change needs one -- each alert's where_clause is its own row,
           not shared -- but the exact pre-text is still asserted below so a
           partial/out-of-band edit can't be silently overwritten).
  Author : Mark Goldyn / Claude          Date: 2026-09-17

  Ask (Evan Jenkins, 2026-09-14, confirmed 2026-09-16):
    1. Suppress "Surfacing" product-group items on the main (non-PAD) pair.
    2. Suppress any order whose Job field contains CLOSEOUT or E&O, on ALL
       FOUR alerts ("should apply to all four alerts please" -- 9/16).

  Investigated before building, not guessed:
    - "Surfacing" = real, existing product_group_id = 'SURFACE' (desc
      "Surfacing"). Doesn't touch the PAD pair -- 106/107 already scope to
      product_group_id = 'PAD' only, so SURFACE can never match there.
    - CLOSEOUT/E&O live in oe_hdr.job_name (the view's 'job_name', shown as
      "Job:" in the email). Real matches confirmed ("Closeout Quote",
      "E&O 2025", etc.); over 120 days, 44 low-margin lines mention CLOSEOUT,
      60 mention E&O out of 9,783 total (~1.1% combined). job_name is never
      NULL in the view (ISNULL(oe_hdr.job_name,'') already in script 01), so
      no NULL-token risk from this filter.

  kb_/js_ (standing rule): none involved -- plain where_clause text edits.
  Performance: no plan-cache angle -- a where_clause is interpreted per-row
  by p21_sp_alert_generation at fire time, not a query to tune.
==============================================================================*/
USE P21;
GO
SET NOCOUNT ON;

DECLARE @expected104 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND low_margin_flag = ''Y'' AND rma_flag <> ''Y''';
DECLARE @expected105 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < 5 AND rma_flag <> ''Y''';
DECLARE @expected106 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id = ''PAD'' AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND (percent_profit_off_mac < -5 OR percent_profit_off_standard_cost < -5) AND rma_flag <> ''Y''';
DECLARE @expected107 NVARCHAR(MAX) = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id = ''PAD'' AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < -5 AND rma_flag <> ''Y''';

-- where_clause is a legacy text column -- must CAST to nvarchar(max) before comparing
-- to an nvarchar(max) variable (text/nvarchar(max) '=' is not directly comparable).
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=104 AND CAST(where_clause AS NVARCHAR(MAX)) = @expected104)
BEGIN RAISERROR('uid 104 where_clause has drifted from the 9/14 baseline -- STOP, re-verify before editing.',16,1); RETURN; END
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=105 AND CAST(where_clause AS NVARCHAR(MAX)) = @expected105)
BEGIN RAISERROR('uid 105 where_clause has drifted from the 9/14 baseline -- STOP, re-verify before editing.',16,1); RETURN; END
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=106 AND CAST(where_clause AS NVARCHAR(MAX)) = @expected106)
BEGIN RAISERROR('uid 106 where_clause has drifted from the 9/14 baseline -- STOP, re-verify before editing.',16,1); RETURN; END
IF NOT EXISTS (SELECT 1 FROM alert_implementation WHERE alert_implementation_uid=107 AND CAST(where_clause AS NVARCHAR(MAX)) = @expected107)
BEGIN RAISERROR('uid 107 where_clause has drifted from the 9/14 baseline -- STOP, re-verify before editing.',16,1); RETURN; END

PRINT 'All four where_clause values match the expected baseline -- proceeding.';

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'',''SURFACE'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND low_margin_flag = ''Y'' AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 104;

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id NOT IN (''OCHARGE'',''SAMPLES'',''PAD'',''SURFACE'') AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < 5 AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 105;

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id = ''PAD'' AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND (percent_profit_off_mac < -5 OR percent_profit_off_standard_cost < -5) AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 106;

UPDATE alert_implementation
SET where_clause = 'total_amount > 1000 AND customer_id NOT IN (3021352,3023035,3023036) AND corp_address_id <> 1046538 AND taker NOT LIKE ''%ESTORE%''  AND product_group_id = ''PAD'' AND new_order = ''Y'' AND extended_standard_cost > ''500'' AND percent_profit_off_mac < -5 AND job_name NOT LIKE ''%CLOSEOUT%'' AND job_name NOT LIKE ''%E&O%'' AND rma_flag <> ''Y''',
    last_maintained_by = 'MGOLDYN', date_last_modified = GETDATE()
WHERE alert_implementation_uid = 107;

PRINT 'Updated 104, 105, 106, 107.';
GO

/*==============================  VERIFY  ==================================*/
SELECT alert_implementation_uid AS uid, alert_implementation_name AS name,
       CONVERT(varchar(19),date_last_modified,120) AS modified, where_clause
FROM alert_implementation
WHERE alert_implementation_uid IN (104,105,106,107)
ORDER BY alert_implementation_uid;
GO

/* Parse-check each new where_clause against the view (0 rows expected --
   pending_alerts is transient, this only proves the SQL is well-formed). */
DECLARE @wc104 NVARCHAR(MAX), @wc105 NVARCHAR(MAX), @wc106 NVARCHAR(MAX), @wc107 NVARCHAR(MAX);
SELECT @wc104 = where_clause FROM alert_implementation WHERE alert_implementation_uid=104;
SELECT @wc105 = where_clause FROM alert_implementation WHERE alert_implementation_uid=105;
SELECT @wc106 = where_clause FROM alert_implementation WHERE alert_implementation_uid=106;
SELECT @wc107 = where_clause FROM alert_implementation WHERE alert_implementation_uid=107;
EXEC('SELECT COUNT(*) AS n_104 FROM p21_view_alert_oe_OrderEntry WHERE ' + @wc104);
EXEC('SELECT COUNT(*) AS n_105 FROM p21_view_alert_oe_OrderEntry WHERE ' + @wc105);
EXEC('SELECT COUNT(*) AS n_106 FROM p21_view_alert_oe_OrderEntry WHERE ' + @wc106);
EXEC('SELECT COUNT(*) AS n_107 FROM p21_view_alert_oe_OrderEntry WHERE ' + @wc107);
GO

/* Real-data sanity check: how many of the last 120 days' low-margin lines
   would this newly-excluded scope have suppressed? (matches the numbers
   quoted to Evan) */
;WITH base AS (
    SELECT oe_hdr.job_name, oe_line.product_group_id,
        CASE WHEN ISNULL(oe_line.unit_price,0)=0 THEN 'N'
             WHEN (oe_line.unit_price - COALESCE(inv_loc.moving_average_cost*oe_line.pricing_unit_size,0))/oe_line.unit_price*100 < 5
               OR (oe_line.unit_price - COALESCE(inv_loc.standard_cost*oe_line.pricing_unit_size,0))/oe_line.unit_price*100 < 5
             THEN 'Y' ELSE 'N' END AS low_margin_flag
    FROM oe_hdr
    INNER JOIN oe_line ON oe_hdr.order_no = oe_line.order_no AND oe_line.delete_flag='N'
    INNER JOIN inv_mast ON inv_mast.inv_mast_uid = oe_line.inv_mast_uid AND inv_mast.product_type <> 'B'
    INNER JOIN inv_loc ON inv_loc.inv_mast_uid = inv_mast.inv_mast_uid AND inv_loc.location_id = oe_line.source_loc_id
    WHERE oe_hdr.delete_flag='N' AND oe_hdr.order_date >= DATEADD(day,-120,GETDATE())
)
SELECT
  SUM(CASE WHEN low_margin_flag='Y' THEN 1 ELSE 0 END) AS low_margin_lines_120d,
  SUM(CASE WHEN low_margin_flag='Y' AND product_group_id='SURFACE' THEN 1 ELSE 0 END) AS would_suppress_surfacing,
  SUM(CASE WHEN low_margin_flag='Y' AND (job_name LIKE '%CLOSEOUT%' OR job_name LIKE '%E&O%') THEN 1 ELSE 0 END) AS would_suppress_closeout_eo
FROM base;
GO

/*===============================  ROLLBACK  =================================
  Revert each alert's where_clause to the @expectedNNN text captured above
  (or restore from Deploy-Guides\low-margin-alert.md's recorded 9/4 text).
===========================================================================*/

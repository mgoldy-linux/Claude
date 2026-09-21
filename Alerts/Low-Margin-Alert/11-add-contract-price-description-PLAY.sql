/*==============================================================================
  11 — Surface job/contract pricing in Price Page Description (PLAY)
  Target : P21Play ONLY. Scoped and run 2026-09-21 to prove the design before
           the Prod copy (11-add-contract-price-description-PROD.sql, same
           script shape, not yet built).
  Author : Mark Goldyn / Claude          Date: 2026-09-21

  Ask (Evan Jenkins, order 6163019 for Tim's Construction Group, 2026-09-21):
  a line showed "Price Page Description: (no price page)" but Evan confirmed
  in the client the price actually came from a contract. Confirmed against
  the real order: oe_line.price_page_uid = 0 (correctly "no price page"),
  but oe_line.job_price_line_uid = 294787 -> job_price_line -> job_price_hdr
  (uid 4047, job_description "INTEGRATION GARTMAN", contract_no 3022961,
  approved='Y', cancelled='N') -- P21's separate Job/Contract Pricing
  mechanism, which the alert view never looked at.

  Measured (Prod, 120 days): of 228,898 lines showing "(no price page)",
  35,986 (~16%) have an active, approved job/contract price behind them and
  could show real contract detail instead of a blank-looking fallback.

  Change: price_page_description now falls back, in order:
    1) real price page description (unchanged)
    2) "Contract Price[: <job_description>][ (Contract #<contract_no>)]"
       when price_page_uid=0 but an approved, non-cancelled job price exists
    3) "(no price page)" (unchanged, when neither applies)
  Additive LEFT JOINs only (job_price_line, job_price_hdr) -- no new token,
  no body-template edit needed; price_page_description is already wired.

  Verified structurally against real Play data: job_price_hdr_uid 5787
  (contract #1023680, customer 1023680 "Efrain Reyes(ASI)", job_description
  blank) renders cleanly as "Contract Price (Contract #1023680)" -- no
  double-space artifact from the blank job_description (first-pass version
  of this script had that bug; fixed before this version).
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'));

IF @sql IS NULL
BEGIN
    RAISERROR('View p21_view_alert_oe_OrderEntry not found.', 16, 1);
    RETURN;
END

DECLARE @pos INT = CHARINDEX('CREATE', @sql);
IF @pos = 0 BEGIN RAISERROR('CREATE keyword not found.', 16, 1); RETURN; END
SET @sql = STUFF(@sql, @pos, 6, 'ALTER');

IF CHARINDEX('Contract Price', @sql) > 0
BEGIN
    PRINT 'SKIP: contract-price fallback already present.';
END
ELSE
BEGIN
    DECLARE @oldCol NVARCHAR(MAX) = N',COALESCE(NULLIF(price_page.description, ''''), ''(no price page)'') ''price_page_description''  -- (no price page) when line not priced from a price page (uid=0); Evan 2026-07-17';
    DECLARE @newCol NVARCHAR(MAX) = N',CASE
    WHEN NULLIF(price_page.description, '''') IS NOT NULL THEN price_page.description
    WHEN job_price_hdr.job_price_hdr_uid IS NOT NULL THEN ''Contract Price''
         + CASE WHEN NULLIF(job_price_hdr.job_description, '''') IS NOT NULL THEN '': '' + job_price_hdr.job_description ELSE '''' END
         + CASE WHEN NULLIF(job_price_hdr.contract_no, '''') IS NOT NULL THEN '' (Contract #'' + job_price_hdr.contract_no + '')'' ELSE '''' END
    ELSE ''(no price page)''
 END ''price_page_description''  -- mg add 2026-09-21: surface active job/contract pricing when no price page exists (Evan Jenkins ask); falls back to price page, then (no price page)';

    DECLARE @oldJoin NVARCHAR(MAX) = N'LEFT JOIN price_page ON price_page.price_page_uid = oe_line.price_page_uid';
    DECLARE @newJoin NVARCHAR(MAX) = N'LEFT JOIN price_page ON price_page.price_page_uid = oe_line.price_page_uid
-- mg add 2026-09-21: job/contract pricing lookup, for price_page_description fallback (Evan Jenkins ask)
LEFT JOIN job_price_line ON job_price_line.job_price_line_uid = oe_line.job_price_line_uid
LEFT JOIN job_price_hdr ON job_price_hdr.job_price_hdr_uid = job_price_line.job_price_hdr_uid
                        AND job_price_hdr.approved = ''Y'' AND job_price_hdr.cancelled = ''N''';

    IF CHARINDEX(@oldCol, @sql) = 0 OR CHARINDEX(@oldJoin, @sql) = 0
    BEGIN
        RAISERROR('Anchor text not found -- view has drifted since this script was cut. STOP and re-cut.', 16, 1);
        RETURN;
    END

    SET @sql = REPLACE(@sql, @oldCol, @newCol);
    SET @sql = REPLACE(@sql, @oldJoin, @newJoin);

    PRINT 'ADD: contract-price fallback queued.';
    EXEC sp_executesql @sql;
    PRINT 'DONE: view altered.';
END
GO

PRINT '=== compiles / returns 0 rows (expected -- pending_alerts is transient) ===';
SELECT COUNT(*) AS n FROM dbo.p21_view_alert_oe_OrderEntry;
GO

/*===============================  ROLLBACK  =================================
  Re-run the pre-change definition with CREATE OR ALTER (backup: capture
  OBJECT_DEFINITION before running this script), then no token/table cleanup
  is needed -- this script only edits an existing column expression and adds
  two LEFT JOINs, it does not register a new token or touch any other table.
===========================================================================*/

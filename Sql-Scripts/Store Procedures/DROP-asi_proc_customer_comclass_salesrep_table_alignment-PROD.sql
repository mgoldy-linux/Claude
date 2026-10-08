/*==============================================================================
  DROP asi_proc_customer_comclass_salesrep_table_alignment  —  P21 PROD
  Author : Mark Goldyn / Claude          Date: 2026-10-08

  *** THIS FILE RUNS AS-IS. DO NOT UNCOMMENT ANYTHING. ***
  It drops the proc only if it still exists, and prints what it did.
  The FULL original definition is preserved at the bottom of this file as the
  restore path — that is the only copy, so keep this file.

  WHY IT IS BEING DROPPED
  The proc copies dbo.kb_table_customer_comclass_salesrep ->
  dbo.asi_table_customer_comclass_salesrep: it UPDATEs asi_ rows whose rep
  differs from kb_, NULLs asi_ reps that kb_ has no row for, and INSERTs kb_
  rows asi_ is missing. It was written 2024-11-07 by Karen Benish and its own
  header calls it "a TEMPORARY thing that needs to be done quickly", explicitly
  ignoring row_status_flag.

  That direction is now backwards. Measured on Prod 2026-10-08:
    - the proc last wrote asi_ on 2025-01-04 (last_maintained_by =
      'kb_TableAlignmentProc'); it has not run in ~21 months;
    - 16,884 asi_ rows have been written by REAL USERS since, the most recent
      by AHI\cthompson at 10:48 that same morning;
    - 307 of the 134,750 customer+commission-class pairs the two tables share
      now disagree on the rep.
  So asi_ is the maintained table and kb_ is not. Running this proc today would
  overwrite those 307 hand-maintained assignments and insert from a table
  nobody edits — silently, because the only failure notification goes to
  kbenish@allsurfaces.com, who has left the company.

  SAFE TO DROP — verified on Prod 2026-10-08:
    - no SQL object references it (sys.sql_modules: zero callers)
    - no SQL Agent job step mentions it
    - sys.dm_exec_procedure_stats has no entry: never executed since the
      2026-09-20 10:40 restart
  It is a loaded gun with no trigger attached. Dropping removes the gun.

  NOT AFFECTED BY THIS
  The nightly ~03:39 refresh of kb_table_customer_comclass_salesrep is done by
  something else, still unidentified — see
  project_2026_10_08_kb_comclass_nightly_writer. Dropping this proc does not
  touch that, and does not change any data in either table.
==============================================================================*/
USE P21;
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.asi_proc_customer_comclass_salesrep_table_alignment', 'P') IS NULL
BEGIN
    PRINT 'Nothing to do - proc does not exist.';
END
ELSE
BEGIN
    DROP PROCEDURE dbo.asi_proc_customer_comclass_salesrep_table_alignment;
    PRINT 'DROPPED dbo.asi_proc_customer_comclass_salesrep_table_alignment.';
END
GO

/*------------------------------ VERIFY ------------------------------------*/
SELECT still_exists = CASE
         WHEN OBJECT_ID('dbo.asi_proc_customer_comclass_salesrep_table_alignment','P') IS NULL
         THEN 'NO - dropped' ELSE 'YES - still there' END;
GO

/*============================== RESTORE =====================================
  COMMENTED ON PURPOSE. This is the proc's exact definition as it stood on
  P21 Prod at 2026-10-08, captured with OBJECT_DEFINITION immediately before
  the drop. To put it back, uncomment from the line below down to the end and
  run it on its own.

  Before restoring, re-read the reasoning above: if asi_ is still the
  hand-maintained table, running this will overwrite real assignments.
=============================================================================

CREATE PROCEDURE asi_proc_customer_comclass_salesrep_table_alignment 
AS
BEGIN
----------------------- 
-- Created by Karen Benish
-- November 7, 2024
-- Procedure that evaluates the differences between the commission schedule/rule salesrep assignment table, which is refreshed nightly, and the IIS table used for DW Power BI reporting
--
-- NOTE: THIS IS IGNORING THE ROW STATUS FLAG, AS THE ALIGNMENT PROCEDURE IS A TEMPORARY THING THAT NEEDS TO BE DONE QUICKLY
--
-- There is a two day lag on updates to the salesrep assignments for when they actually reach the Data Warehouse Power BI reporting.  Here's an example:
-- Change to rep assignment  Monday afternoon
-- Old customer assignment table gets refreshed  Tuesday 3am
-- IIS table gets refreshed  Tuesday 3am
-- Change visible on P21 SSRS/Live Power BI  Tuesday morning
-- DW restores from midnight backup of live, looks at IIS table  Tuesday overnight
-- Change visible on DW Power BI  Wednesday morning
--
----------------------- 
DECLARE @error_code AS INT, @return_val AS INT = 0, @result_message AS VARCHAR(5000) 
DECLARE @change_ct AS DECIMAL(19,0), @update_ct AS DECIMAL(19,0), @insert_ct AS DECIMAL(19,0)
DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @sub VARCHAR(400), @bod VARCHAR(MAX), @rec VARCHAR(256), @example VARCHAR(256)
-- Set email recipient(s) for failed runs ONLY.  Separate multiple with a semicolon
SET @rec = 'kbenish@allsurfaces.com'

-- Find Updates
SELECT --iis_table.customer_id, iis_table.commission_class_id, iis_table.salesrep_id AS change_rep_from, 
	iis_table.customer_comclass_salesrep_uid
	,comrule_table.salesrep_id AS change_rep_to
	INTO #cccs_updates
FROM asi_table_customer_comclass_salesrep AS iis_table
INNER JOIN kb_table_customer_comclass_salesrep AS comrule_table
	ON iis_table.customer_id = comrule_table.customer_id
	AND iis_table.commission_class_id = comrule_table.commission_class_id
WHERE iis_table.salesrep_id <> comrule_table.salesrep_id
	AND iis_table.customer_id IS NOT NULL

SET @update_ct = ISNULL((SELECT COUNT(*) FROM #cccs_updates),0)


-- Find Reps to set to NULL
SELECT --iis_table.customer_id, iis_table.commission_class_id, iis_table.salesrep_id AS change_rep_from, 
	iis_table.customer_comclass_salesrep_uid
	,comrule_table.salesrep_id AS change_rep_to
	INTO #cccs_set_to_nulls
FROM asi_table_customer_comclass_salesrep AS iis_table
LEFT JOIN kb_table_customer_comclass_salesrep AS comrule_table
	ON iis_table.customer_id = comrule_table.customer_id
	AND iis_table.commission_class_id = comrule_table.commission_class_id
WHERE comrule_table.salesrep_id IS NULL
	AND iis_table.salesrep_id IS NOT NULL

SET @update_ct = ISNULL(@update_ct,0) + ISNULL((SELECT COUNT(*) FROM #cccs_set_to_nulls),0)

-- Find Inserts
SELECT comrule_table.customer_id, comrule_table.commission_class_id, iis_table.salesrep_id AS change_rep_from, comrule_table.salesrep_id AS change_rep_to
	INTO #cccs_inserts
FROM kb_table_customer_comclass_salesrep AS comrule_table
LEFT JOIN asi_table_customer_comclass_salesrep AS iis_table
	ON iis_table.customer_id = comrule_table.customer_id
	AND iis_table.commission_class_id = comrule_table.commission_class_id
WHERE iis_table.customer_id IS NULL

SET @insert_ct = ISNULL((SELECT COUNT(*) FROM #cccs_inserts),0)

SET @change_ct = @update_ct + @insert_ct

BEGIN TRY
	BEGIN TRANSACTION
		-- Perform updates 1/2
		UPDATE iis_table
		SET salesrep_id = upd.change_rep_to
			,row_status_flag = 704
			,date_last_modified = GetDate()
			,last_maintained_by = 'kb_TableAlignmentProc'
		FROM asi_table_customer_comclass_salesrep AS iis_table
		INNER JOIN #cccs_updates AS upd
			ON iis_table.customer_comclass_salesrep_uid = upd.customer_comclass_salesrep_uid

		-- Perform updates 2/2
		UPDATE iis_table
		SET salesrep_id = NULL
			,row_status_flag = 704
			,date_last_modified = GetDate()
			,last_maintained_by = 'kb_TableAlignmentProc'
		FROM asi_table_customer_comclass_salesrep AS iis_table
		INNER JOIN #cccs_set_to_nulls AS upd
			ON iis_table.customer_comclass_salesrep_uid = upd.customer_comclass_salesrep_uid

		-- Perform inserts
		INSERT INTO asi_table_customer_comclass_salesrep (company_id, customer_id, commission_class_id, salesrep_id, date_created, created_by, date_last_modified, last_maintained_by, row_status_flag)
		(
			SELECT '1'
				,customer_id
				,commission_class_id
				,change_rep_to
				,GetDate()
				,'kb_TableAlignmentProc'
				,GetDate()
				,'kb_TableAlignmentProc'
				,704
			FROM #cccs_inserts
		)


	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	-- Log the error in the output variables
	SELECT @error_code = @@ERROR,
		@ErrorMessage = ERROR_MESSAGE(),
		@ErrorSeverity = ERROR_SEVERITY(),
		@ErrorState = ERROR_STATE();
	SET @return_val = -4 
	SET @result_message = 'Error Code: ' + CONVERT(VARCHAR(20), @error_code)
		+ '; Message: ' + CONVERT(VARCHAR(4000), @ErrorMessage)
		+ '; Severity: ' + CONVERT(VARCHAR(20), @ErrorSeverity)
		+ '; State: ' + CONVERT(VARCHAR(20), @ErrorState);
	-- Pass along the error
	THROW;
	-- Rollback changes
	WHILE @@TRANCOUNT > 0 
	BEGIN
		ROLLBACK TRANSACTION;
	END
	
END CATCH


IF @return_val <> 0
BEGIN	
	-- Print problems
	PRINT CONVERT(VARCHAR(20), @return_val)
	PRINT @result_message

	-- Prep email of problems detail
	SET @sub = 'Procedure FAILURE: Customer ComClass Salesrep Table Alignment' 
	SET @bod = 'The asi_proc_customer_comclass_salesrep_table_alignment procedure failed to reassign salesreps. '
		+ 'This represented ' + FORMAT(@change_ct,'N0') + ' changes, comprised of ' + FORMAT(@insert_ct,'N0') + ' inserts and '
		+ FORMAT(@update_ct,'N0') + ' updates.  The error text was: ' + @result_message

	-- Email the problems
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name='P21 Alerts',
		@recipients=@rec,
		@subject=@sub, 
		@body=@bod	
END
ELSE 	
BEGIN
	-- Print number of changes made
	PRINT 'Success! Changes completed.  This represented ' + FORMAT(@change_ct,'N0') + ' changes, comprised of ' + FORMAT(@insert_ct,'N0') + ' inserts and '
		+ FORMAT(@update_ct,'N0') + ' updates.'
END
	
DROP TABLE #cccs_inserts
DROP TABLE #cccs_updates
DROP TABLE #cccs_set_to_nulls

RETURN @return_val

END

GO
===========================================================================*/

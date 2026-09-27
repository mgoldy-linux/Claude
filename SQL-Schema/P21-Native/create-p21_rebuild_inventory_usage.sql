USE [P21Training]
GO

/****** Object:  StoredProcedure [dbo].[p21_rebuild_inventory_usage]    Script Date: 9/27/2026 11:00:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[p21_rebuild_inventory_usage]
(@as_CompanyID							VARCHAR(255) = NULL
,@ai_StartComputedDate					INTEGER = NULL
,@ai_EndComputedDate					INTEGER = NULL
,@ai_StartInvMastUID					INTEGER = NULL
,@ai_EndInvMastUID						INTEGER = NULL
,@ai_StartLocationID					INTEGER = NULL
,@ai_EndLocationID						INTEGER = NULL
,@ai_StartSupplierID					INTEGER = NULL
,@ai_EndSupplierID						INTEGER = NULL
,@ai_DeleteUsage						CHAR(1) = 'Y'
,@ai_AffectAllUsage						CHAR(1) = 'N'
,@as_OverRideServiceLevelSettingCheck	CHAR(1) = 'N'
,@ai_SectiontoExecute					INTEGER = 15
,@ReportValues							CHAR(1) = 'N'  --N/No S/Short D/Details
,@ai_Debug								INTEGER = 1)
AS

--	@ai_SectiontoExecute
--	Bitwise math!
--	1 = Execute Usage
--	2 = Execute Number of Orders
--	4 = Execute Number of Hits
--	8 = Execute Lost Sales
--	16 = 
--	32 = 
--	64 = 
--	128 = 
--	256 = 
--	512 = 

--	@ai_Debug
--	Bitwise math!
--	1 = Execute main SQL statement
--	2 = Print main SQL statement
--	4 = Print arguments/variables
--	8 = Select tables
--	16 = 
--	32 = 
--	64 = 
--	128 = 
--	256 = 
--	512 = 

BEGIN

	DECLARE @Error    						INTEGER
	DECLARE @li_UsageLocation				INTEGER
	DECLARE @li_UsageCapturePoint			INTEGER
	DECLARE @li_AccumulateServiceLevelAt	INTEGER
	DECLARE @li_TrackConsignment			INTEGER
	DECLARE	@ldc_HitPct						DECIMAL(19, 4)
	-- JRL 05/20/14 - F57580 - Need to get system setting info for push_usage_to_replen_loc
	DECLARE @lc_push_usage_to_replen_loc    CHAR(1)
	DECLARE @lc_TrackComponent				CHAR(1)
	DECLARE @lc_TrackConsignment			CHAR(1)
	DECLARE @lc_TrackDirectShip				CHAR(1)
	DECLARE @lc_TrackRawItem				CHAR(1)
	DECLARE @lc_TrackRMA					CHAR(1)
	DECLARE @lc_TrackTransfer				CHAR(1)
	DECLARE @lc_UpdateServiceLevel			CHAR(1)
	DECLARE @lc_UseIdealLocation			CHAR(1)
	DECLARE @lc_UsePeriodTable				CHAR(1)
	DECLARE @lc_UseWhereLocation			CHAR(1)
	DECLARE @lc_TrackShipToDefaultLocation	CHAR(1)
	DECLARE @ls_DefaultUsagePercent			VARCHAR(255)
	DECLARE	@Msg							VARCHAR(2000)
	DECLARE @ls_SQL							NVARCHAR(MAX)
	DECLARE @ls_WhereClauseRegOrder			NVARCHAR(MAX) -- 12.12 JBH 02/26/13 - Scopus 1123013
	DECLARE @ls_WhereClauseCUO				NVARCHAR(MAX) -- 12.12 JBH 02/26/13 - Scopus 1123013
		-- 1/6/16 - J.Villanueva - 12.17 Feature: 61702 Duplicate item usage on referenced item by inv_mast.inv_mast_uid_dup_usage
	DECLARE @lc_push_usage_to_dup_item		CHAR(1)
	DECLARE @ld_current_timestamp			DATETIME

	--P21CD-14008 Modify Timezone feature to use @ld_current_timestamp variable
	SET @ld_current_timestamp = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL)

	SET @Msg = 'p21_rebuild_inventory_usage : '

	IF (@ai_Debug & 1 > 0)
		BEGIN TRANSACTION
		
	--sub_item_usg_to_orig_item		Never,0/Always,1/Prompt,2/
	--track_item_usage_at_cd		Sales Location,1186/Source Location,1187/
	--track_consignment_usage		Consignment Location,1894/Distributor Sales Location,1895/Contract Source Location,3155/
	--capture_usage_at				Order Entry,951/Invoice,995/
	--USAGE TYPE:					usage,1/number of orders,2/number of hits,3/lost sales,4/

	SELECT	@li_UsageLocation = CAST(usage_location.[value] AS INTEGER)
			,@li_UsageCapturePoint = CAST(capture_point.[value] AS INTEGER)
			,@lc_TrackComponent = COALESCE(track_component.[value], 'N')
			,@li_TrackConsignment = COALESCE(CAST(track_consignment.[value] AS INTEGER), 1895)
			,@lc_TrackDirectShip = COALESCE(track_direct_ship.[value], 'N')
			,@lc_TrackRawItem = COALESCE(track_raw_item.[value], 'N')
			,@lc_TrackRMA = COALESCE(track_rma.[value], 'N')
			,@ldc_HitPct = COALESCE(CAST(order_hit_percent.[value] AS DECIMAL(19, 4)), 0.0000)
			,@li_AccumulateServiceLevelAt = CAST(accumulate_service_level_at.[value] AS INTEGER)
	        ,@lc_push_usage_to_replen_loc = COALESCE(push_usage_to_replen_loc.[value], 'N')
	        ,@ls_DefaultUsagePercent = COALESCE(default_transfer_usage_percent.[value], '')
	        ,@lc_UseIdealLocation = COALESCE(use_ideal_location_in_usage_rebuild.[value], 'N')
		    ,@lc_push_usage_to_dup_item = COALESCE(push_usage_to_dup_item.[value], 'N')
		    ,@lc_TrackShipToDefaultLocation = COALESCE(track_usage_at_ship_to_default_location.[value], 'N')
	FROM	(SELECT 1 dummy) AS placeholder
	LEFT JOIN system_setting usage_location ON (usage_location.[name] = 'track_item_usage_at_cd')
	LEFT JOIN system_setting capture_point ON (capture_point.[name] = 'capture_usage_at')
	LEFT JOIN system_setting track_component ON (track_component.[name] = 'assembly_usage_accumulation')
	LEFT JOIN system_setting track_consignment ON (track_consignment.[name] = 'track_consignment_usage')
	LEFT JOIN system_setting track_direct_ship ON (track_direct_ship.[name] = 'track_usage_direct_ship')
	LEFT JOIN system_setting track_raw_item ON (track_raw_item.[name] = 'accumulate_usage_for_raw_items')
	LEFT JOIN system_setting track_rma ON (track_rma.[name] = 'track_usage_rma')
	LEFT JOIN system_setting order_hit_percent ON (order_hit_percent.[name] = 'order_hit_percent')
	LEFT JOIN system_setting accumulate_service_level_at ON (accumulate_service_level_at.[name] = 'accumulate_service_level_at')
	LEFT JOIN system_setting push_usage_to_replen_loc ON (push_usage_to_replen_loc.[name] = 'push_usage_to_replen_loc')
	LEFT JOIN system_setting default_transfer_usage_percent ON (default_transfer_usage_percent.[name] = 'default_transfer_usage_percent')
	LEFT JOIN system_setting use_ideal_location_in_usage_rebuild ON (use_ideal_location_in_usage_rebuild.[name] = 'use_ideal_location_in_usage_rebuild')
	LEFT JOIN system_setting push_usage_to_dup_item ON (push_usage_to_dup_item.[name] = 'push_usage_to_dup_item') -- 1/6/16 - J.Villanueva - 12.17 Feature: 61702 Duplicate item usage on referenced item by inv_mast.inv_mast_uid_dup_usage
	LEFT JOIN system_setting track_usage_at_ship_to_default_location ON (track_usage_at_ship_to_default_location.[name] = 'track_usage_at_ship_to_default_location')
	
	IF (@ls_DefaultUsagePercent <> '' OR EXISTS (SELECT 1 FROM inv_loc WHERE transfer_usage_percent IS NOT NULL))
		SET @lc_TrackTransfer = 'Y'
	ELSE
		SET @lc_TrackTransfer = 'N'

	-- Ser JBH 03/08/10 - Scopus 861159 - If tracking service level at OE time it is not possible to recalculate it.  So don't allow the user to proceed unless
	--		they pass in the override parm.
	IF (@li_AccumulateServiceLevelAt = 951 AND UPPER(@as_OverRideServiceLevelSettingCheck) <> 'Y')
		SET	@lc_UpdateServiceLevel = 'N'
	ELSE
		SET	@lc_UpdateServiceLevel = 'Y'

	IF EXISTS (SELECT 1 FROM oe_hdr WHERE company_id = @as_CompanyID AND order_type = 1344)
	BEGIN
		SET @lc_TrackConsignment = 'Y'
		IF (@li_UsageLocation = 1187 AND @li_TrackConsignment = 1894) OR
		   (@li_UsageLocation = 1186 AND @li_TrackConsignment = 1895)
			SET @lc_UseWhereLocation = 'N'
		ELSE
		BEGIN
			SET @lc_UseWhereLocation = 'Y'
			
			IF (@lc_UseIdealLocation = 'Y')
			BEGIN
				IF (@li_UsageLocation = 1186) --Sales Location
					SET @ls_WhereClauseRegOrder = N'COALESCE(oe_hdr.order_type, 0) <> 1344 AND COALESCE(drv_ideal_location.location_id, oe_hdr.location_id) = temp_inventory_rebuild_items.location_id'
			
				IF (@li_UsageLocation = 1187) --Source Location
					SET @ls_WhereClauseRegOrder = N'COALESCE(oe_hdr.order_type, 0) <> 1344 AND COALESCE(drv_ideal_location.location_id, oe_line.source_loc_id) = temp_inventory_rebuild_items.location_id'
			
				IF (@li_TrackConsignment = 1894) -- Consignment Location
					SET @ls_WhereClauseCUO = N'COALESCE(oe_hdr.order_type, 0) = 1344 AND COALESCE(drv_ideal_location.location_id, oe_line.source_loc_id) = temp_inventory_rebuild_items.location_id'

				IF (@li_TrackConsignment = 1895) -- Sales location
					SET @ls_WhereClauseCUO = N'COALESCE(oe_hdr.order_type, 0) = 1344 AND COALESCE(drv_ideal_location.location_id, oe_hdr.location_id) = temp_inventory_rebuild_items.location_id'

				IF (@li_TrackConsignment = 3155) -- Contract location
					SET @ls_WhereClauseCUO = N'COALESCE(oe_hdr.order_type, 0) = 1344 AND COALESCE(drv_ideal_location.location_id, job_price_line_consign.source_location_id, job_price_customer_shipto.preferred_location_id, oe_hdr.location_id) = temp_inventory_rebuild_items.location_id'
			END
			ELSE
			BEGIN
				-- 12.12 JBH 02/26/13 - Scopus 1123013 - Pieces used to build where clause later.
				IF (@li_UsageLocation = 1186) --Sales Location
					SET @ls_WhereClauseRegOrder = N'COALESCE(oe_hdr.order_type, 0) <> 1344 AND oe_hdr.location_id = temp_inventory_rebuild_items.location_id'
			
				IF (@li_UsageLocation = 1187) --Source Location
					SET @ls_WhereClauseRegOrder = N'COALESCE(oe_hdr.order_type, 0) <> 1344 AND oe_line.source_loc_id = temp_inventory_rebuild_items.location_id'
			
				IF (@li_TrackConsignment = 1894) -- Consignment Location
					SET @ls_WhereClauseCUO = N'COALESCE(oe_hdr.order_type, 0) = 1344 AND oe_line.source_loc_id = temp_inventory_rebuild_items.location_id'

				IF (@li_TrackConsignment = 1895) -- Sales location
					SET @ls_WhereClauseCUO = N'COALESCE(oe_hdr.order_type, 0) = 1344 AND oe_hdr.location_id = temp_inventory_rebuild_items.location_id'

				IF (@li_TrackConsignment = 3155) -- Contract location
					SET @ls_WhereClauseCUO = N'COALESCE(oe_hdr.order_type, 0) = 1344 AND COALESCE(job_price_line_consign.source_location_id, job_price_customer_shipto.preferred_location_id, oe_hdr.location_id) = temp_inventory_rebuild_items.location_id'
			END
		END
	END
	ELSE
	BEGIN
		SET @lc_TrackConsignment = 'N'
		SET @lc_UseWhereLocation = 'N'
	END
	
	IF (@ai_StartComputedDate IS NULL AND @ai_EndComputedDate IS NULL)
		SET	@lc_UsePeriodTable = 'N'
	ELSE
		SET	@lc_UsePeriodTable = 'Y'

	IF (@ai_Debug & 4 > 0)
	BEGIN
		PRINT '@as_CompanyID: ' + COALESCE(@as_CompanyID, 'NULL')
		PRINT '@ai_StartComputedDate: ' + COALESCE(CAST(@ai_StartComputedDate AS VARCHAR(255)), 'NULL')
		PRINT '@ai_EndComputedDate: ' + COALESCE(CAST(@ai_EndComputedDate AS VARCHAR(255)), 'NULL')
		PRINT '@ai_StartInvMastUID: ' + COALESCE(CAST(@ai_StartInvMastUID AS VARCHAR(255)), 'NULL')
		PRINT '@ai_EndInvMastUID: ' + COALESCE(CAST(@ai_EndInvMastUID AS VARCHAR(255)), 'NULL')
		PRINT '@ai_StartLocationID: ' + COALESCE(CAST(@ai_StartLocationID AS VARCHAR(255)), 'NULL')
		PRINT '@ai_EndLocationID: ' + COALESCE(CAST(@ai_EndLocationID AS VARCHAR(255)), 'NULL')
		PRINT '@ai_StartSupplierID: ' + COALESCE(CAST(@ai_StartSupplierID AS VARCHAR(255)), 'NULL')
		PRINT '@ai_EndSupplierID: ' + COALESCE(CAST(@ai_EndSupplierID AS VARCHAR(255)), 'NULL')
		PRINT '@ai_Debug: ' + COALESCE(CAST(@ai_Debug AS VARCHAR(255)), 'NULL')
		PRINT '@li_UsageLocation: ' + COALESCE(CAST(@li_UsageLocation AS VARCHAR(255)), 'NULL')
		PRINT '@li_UsageCapturePoint: ' + COALESCE(CAST(@li_UsageCapturePoint AS VARCHAR(255)), 'NULL')
		PRINT '@lc_TrackComponent: ' + COALESCE(@lc_TrackComponent, 'NULL')
		PRINT '@lc_TrackConsignment: ' +  COALESCE(@lc_TrackConsignment, 'NULL')
		PRINT '@li_TrackConsignment: ' +  CAST(@li_TrackConsignment AS VARCHAR(255))
		PRINT '@lc_TrackDirectShip: ' + COALESCE(@lc_TrackDirectShip, 'NULL')
		PRINT '@lc_TrackRawItem: ' + COALESCE(@lc_TrackRawItem, 'NULL')
		PRINT '@lc_TrackRMA: ' + COALESCE(@lc_TrackRMA, 'NULL')
		PRINT '@lc_TrackTransfer: ' + COALESCE(@lc_TrackTransfer, 'NULL')
		PRINT '@lc_UsePeriodTable: ' + COALESCE(@lc_UsePeriodTable, 'NULL')
		PRINT '@ldc_HitPct: ' + COALESCE(CAST(@ldc_HitPct AS VARCHAR(255)), 'NULL')
		PRINT '@lc_UpdateServiceLevel: ' + COALESCE(CAST(@lc_UpdateServiceLevel AS VARCHAR(255)), 'NULL')
		PRINT '@lc_UseWhereLocation: ' + COALESCE(CAST(@lc_UseWhereLocation AS VARCHAR(255)), 'NULL')
		PRINT '@li_AccumulateServiceLevelAt: ' + COALESCE(CAST(@li_AccumulateServiceLevelAt AS VARCHAR(255)), 'NULL')
		PRINT '@lc_push_usage_to_replen_loc: ' + COALESCE(CAST(@lc_push_usage_to_replen_loc AS VARCHAR(255)), 'NULL')
		PRINT '@ls_DefaultUsagePercent: ' + COALESCE(CAST(@ls_DefaultUsagePercent AS VARCHAR(255)), 'NULL')
		PRINT '@lc_UseIdealLocation: ' + COALESCE(CAST(@lc_UseIdealLocation AS VARCHAR(255)), 'NULL')
		PRINT '@lc_push_usage_to_dup_item: ' + COALESCE(CAST(@lc_push_usage_to_dup_item AS VARCHAR(255)), 'NULL')

	END

	SET @ls_SQL = N'
TRUNCATE TABLE temp_inventory_rebuild_items'

	IF (@ai_Debug & 2 > 0)
		SELECT @ls_SQL

	IF (@ai_Debug & 1 > 0)
		EXECUTE (@ls_SQL)

    SELECT @error = @@ERROR
    IF (@error <> 0)
    BEGIN
        SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing TRUNCATE of temp_inventory_rebuild_items'
        GOTO error_return
    END

	SET @ls_SQL = N'
INSERT INTO temp_inventory_rebuild_items
		(company_id
		,inv_mast_uid
		,location_id
		,duplicate_usage_inv_mast_uid
		,duplicate_usage_location)
	SELECT	inv_loc.company_id
			,inv_loc.inv_mast_uid
			,inv_loc.location_id
			,COALESCE(inv_loc.inv_mast_uid_dup_usage, inv_mast.inv_mast_uid_dup_usage)
			,CASE	WHEN inv_loc.replenishment_location <> inv_loc.location_id THEN
						inv_loc.replenishment_location
					ELSE
						NULL
			 END
	FROM	inv_loc
	INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = inv_loc.inv_mast_uid)
	WHERE	inv_loc.company_id = ''' + COALESCE(@as_CompanyID, 'NULL') + N''''

	IF (@ai_StartLocationID IS NOT NULL)
		SET @ls_SQL = @ls_SQL + N'
	  AND	inv_loc.location_id >= ' + CAST(@ai_StartLocationID AS VARCHAR(255))

	IF (@ai_EndLocationID IS NOT NULL)
		SET @ls_SQL = @ls_SQL + N'
	  AND	inv_loc.location_id <= ' + CAST(@ai_EndLocationID AS VARCHAR(255))

	IF (@ai_StartInvMastUID IS NOT NULL)
		SET @ls_SQL = @ls_SQL + N'
	  AND	inv_loc.inv_mast_uid >= ' + CAST(@ai_StartInvMastUID AS VARCHAR(255))

	IF (@ai_EndInvMastUID IS NOT NULL)
		SET @ls_SQL = @ls_SQL + N'
	  AND	inv_loc.inv_mast_uid <= ' + CAST(@ai_EndInvMastUID AS VARCHAR(255))

	IF (@ai_StartSupplierID IS NOT NULL)
		SET @ls_SQL = @ls_SQL + N'
	  AND	inv_loc.primary_supplier_id >= ' + CAST(@ai_StartSupplierID AS VARCHAR(255))

	IF (@ai_EndSupplierID IS NOT NULL)
		SET @ls_SQL = @ls_SQL + N'
	  AND	inv_loc.primary_supplier_id <= ' + CAST(@ai_EndSupplierID AS VARCHAR(255))

	IF (@ai_Debug & 2 > 0)
		SELECT @ls_SQL

	IF (@ai_Debug & 1 > 0)
		EXECUTE (@ls_SQL)

    SELECT @error = @@ERROR
    IF (@error <> 0)
    BEGIN
        SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_rebuild_items'
        GOTO error_return
    END

	IF (@ai_Debug & 8 > 0)
	BEGIN
		SELECT 'Initial SELECT into temp_inventory_rebuild_items'

		SELECT	*
		FROM	temp_inventory_rebuild_items
	END

    IF (@lc_push_usage_to_dup_item = 'Y')
	BEGIN
		SET @ls_SQL = N'
INSERT INTO temp_inventory_rebuild_items
		(company_id
		,inv_mast_uid
		,location_id
		,duplicate_usage_inv_mast_uid
		,duplicate_usage_location)
	--SELECT dup item records not already in the rebuild table
	SELECT	temp_inventory_rebuild_items.company_id
			,temp_inventory_rebuild_items.duplicate_usage_inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,NULL
			,NULL
	FROM	temp_inventory_rebuild_items
	INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = temp_inventory_rebuild_items.duplicate_usage_inv_mast_uid)
									AND (inv_loc.location_id = temp_inventory_rebuild_items.location_id)
	LEFT JOIN temp_inventory_rebuild_items tiri2 ON (tiri2.company_id = temp_inventory_rebuild_items.company_id)
												AND (tiri2.inv_mast_uid = temp_inventory_rebuild_items.duplicate_usage_inv_mast_uid)
												AND (tiri2.location_id = temp_inventory_rebuild_items.location_id)
	WHERE	temp_inventory_rebuild_items.duplicate_usage_inv_mast_uid IS NOT NULL
	  AND	tiri2.company_id IS NULL
	  
	UNION
	
	--SELECT items WITH inv_loc.inv_mast_uid_dup_usage records that are not in the rebuild table (inv_loc takes precedence over inv_mast)
	SELECT	temp_inventory_rebuild_items.company_id
			,inv_loc.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,temp_inventory_rebuild_items.inv_mast_uid
			,NULL
	FROM	temp_inventory_rebuild_items
	INNER JOIN inv_mast ON (inv_mast.inv_mast_uid_dup_usage = temp_inventory_rebuild_items.inv_mast_uid)
	INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid_dup_usage = inv_mast.inv_mast_uid)
									AND (inv_loc.location_id = temp_inventory_rebuild_items.location_id)
	LEFT JOIN temp_inventory_rebuild_items tiri2 ON (tiri2.company_id = temp_inventory_rebuild_items.company_id)
												AND (tiri2.inv_mast_uid = inv_mast.inv_mast_uid)
												AND (tiri2.location_id = temp_inventory_rebuild_items.location_id)
	WHERE	tiri2.company_id IS NULL
	  
	UNION
	
	--SELECT items WITH inv_mast.inv_mast_uid_dup_usage records and NULL inv_loc.inv_mast_uid_dup_usage records that are not in the rebuild table (inv_loc takes precedence over inv_mast)
	SELECT	temp_inventory_rebuild_items.company_id
			,inv_mast.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,temp_inventory_rebuild_items.inv_mast_uid
			,NULL
	FROM	temp_inventory_rebuild_items
	INNER JOIN inv_mast ON (inv_mast.inv_mast_uid_dup_usage = temp_inventory_rebuild_items.inv_mast_uid)
	INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = inv_mast.inv_mast_uid)
									AND (inv_loc.location_id = temp_inventory_rebuild_items.location_id)
	LEFT JOIN temp_inventory_rebuild_items tiri2 ON (tiri2.company_id = temp_inventory_rebuild_items.company_id)
												AND (tiri2.inv_mast_uid = inv_mast.inv_mast_uid)
												AND (tiri2.location_id = temp_inventory_rebuild_items.location_id)
	WHERE	inv_loc.inv_mast_uid_dup_usage IS NULL
	  AND	tiri2.company_id IS NULL'

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_rebuild_items'
			GOTO error_return
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'SELECT into temp_inventory_rebuild_items for @lc_push_usage_to_dup_item'

			SELECT	*
			FROM	temp_inventory_rebuild_items
		END
	END

    IF (@lc_push_usage_to_replen_loc = 'Y')
	BEGIN
		SET @ls_SQL = N'
INSERT INTO temp_inventory_rebuild_items
		(company_id
		,inv_mast_uid
		,location_id
		,duplicate_usage_inv_mast_uid
		,duplicate_usage_location)
	SELECT	inv_loc.company_id
			,temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.duplicate_usage_location
			,NULL
			,NULL
	FROM	temp_inventory_rebuild_items
	INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
									AND (inv_loc.location_id = temp_inventory_rebuild_items.duplicate_usage_location)
	LEFT JOIN temp_inventory_rebuild_items tiri2 ON (tiri2.company_id = inv_loc.company_id)
												AND (tiri2.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
												AND (tiri2.location_id = temp_inventory_rebuild_items.duplicate_usage_location)
	WHERE	tiri2.company_id IS NULL
	
	UNION

	SELECT	inv_loc.company_id
			,temp_inventory_rebuild_items.inv_mast_uid
			,inv_loc.location_id
			,NULL
			,inv_loc.replenishment_location
	FROM	temp_inventory_rebuild_items
	INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
									AND (inv_loc.replenishment_location = temp_inventory_rebuild_items.location_id)
									AND (inv_loc.location_id <> temp_inventory_rebuild_items.location_id)
	LEFT JOIN temp_inventory_rebuild_items tiri2 ON (tiri2.company_id = temp_inventory_rebuild_items.company_id)
												AND (tiri2.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
												AND (tiri2.location_id = inv_loc.location_id)
	WHERE	tiri2.company_id IS NULL'

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_rebuild_items'
			GOTO error_return
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'SELECT into temp_inventory_rebuild_items for @lc_push_usage_to_replen_loc'

			SELECT	*
			FROM	temp_inventory_rebuild_items
		END
	END

	IF (@lc_UsePeriodTable = 'Y')
	BEGIN
		SET @ls_SQL = N'
TRUNCATE TABLE temp_inventory_rebuild_periods'

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing TRUNCATE of temp_inventory_rebuild_periods'
			GOTO error_return
		END

		SET @ls_SQL = N'
INSERT INTO temp_inventory_rebuild_periods
		(inv_mast_uid
		,location_id
		,demand_period_uid)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
	FROM	temp_inventory_rebuild_items
	CROSS JOIN demand_period
	WHERE	demand_period.company_id = ''' + @as_CompanyID + N''''

		IF (@ai_StartComputedDate IS NOT NULL)
			SET @ls_SQL = @ls_SQL + N'
	  AND	demand_period.computed_year_period >= ' + CAST(@ai_StartComputedDate AS VARCHAR(255))

		IF (@ai_EndComputedDate IS NOT NULL)
			SET @ls_SQL = @ls_SQL + N'
	  AND	demand_period.computed_year_period <= ' + CAST(@ai_EndComputedDate AS VARCHAR(255))

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_rebuild_periods'
			GOTO error_return
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'Initial SELECT into temp_inventory_rebuild_periods'

			SELECT	*
			FROM	temp_inventory_rebuild_items
		END
	END
	
	SET @ls_SQL = '
TRUNCATE TABLE temp_inventory_usage_rebuild'

	IF (@ai_Debug & 2 > 0)
		SELECT @ls_SQL

	IF (@ai_Debug & 1 > 0)
		EXECUTE (@ls_SQL)

    SELECT @error = @@ERROR
    IF (@error <> 0)
    BEGIN
        SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing TRUNCATE of temp_inventory_usage_rebuild'
        GOTO error_return
    END

	IF (@ai_SectiontoExecute & 1 > 0)
	BEGIN
		SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid'

		IF (@li_UsageCapturePoint = 951) --OE
		BEGIN
			SET @ls_SQL = @ls_SQL + N'
			,CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''N'' THEN'
					
			IF (@lc_TrackDirectShip = 'N')
				SET @ls_SQL = @ls_SQL + N'
					CASE	WHEN oe_line.disposition = ''D'' THEN
								oe_line.qty_invoiced - COALESCE(drv_invoice.sum_direct_ship_invoice, 0)
							ELSE
								oe_line.qty_ordered - oe_line.qty_canceled - COALESCE(drv_invoice.sum_direct_ship_invoice, 0)
					END'

			ELSE
				SET @ls_SQL = @ls_SQL + N'
					oe_line.qty_ordered - oe_line.qty_canceled'
		
			SET @ls_SQL = @ls_SQL + N'
				ELSE
					0
			 END
			,CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''Y'' THEN'

			IF (@lc_TrackDirectShip = 'N')
				SET @ls_SQL = @ls_SQL + N'
					CASE	WHEN oe_line.disposition = ''D'' THEN
								oe_line.qty_invoiced - COALESCE(drv_invoice.sum_direct_ship_invoice, 0)
							ELSE
								oe_line.qty_ordered - oe_line.qty_canceled - COALESCE(drv_invoice.sum_direct_ship_invoice, 0)
					END'

			ELSE
				SET @ls_SQL = @ls_SQL + N'
					oe_line.qty_ordered - oe_line.qty_canceled'

			SET @ls_SQL = @ls_SQL + N'
				ELSE
					0
			 END
			,0
			,0
			,951
			,oe_line.oe_line_uid
			,1
			,oe_line.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN oe_line ON (oe_line.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)'

			IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseWhereLocation = 'N' AND @li_UsageLocation = 1187) --Source Location
				SET @ls_SQL = @ls_SQL + N'
					  AND (oe_line.source_loc_id = temp_inventory_rebuild_items.location_id)'

			SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN oe_line_service ON (oe_line_service.oe_line_uid = oe_line.oe_line_uid)
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)'

			IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseWhereLocation = 'N' AND @li_UsageLocation = 1186) --Sales Location
				SET @ls_SQL = @ls_SQL + N'
				     AND (oe_hdr.location_id = temp_inventory_rebuild_items.location_id)'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'

			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN demand_period ON (oe_line.date_created >= demand_period.beginning_date)
							AND (oe_line.date_created < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'
							
			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'
	
			IF (@lc_TrackDirectShip = 'N')
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN (SELECT	SUM(CASE	WHEN oe_pick_ticket.direct_shipment = ''Y'' THEN
										qty_shipped
									ELSE
										0
							END) sum_direct_ship_invoice
						,invoice_line.order_no
						,invoice_line.oe_line_number
			   FROM		invoice_line
			   INNER JOIN oe_pick_ticket ON (oe_pick_ticket.invoice_id_when_shipped = invoice_line.invoice_no)
			   GROUP BY invoice_line.order_no
						,invoice_line.oe_line_number) AS drv_invoice ON (drv_invoice.order_no = oe_line.order_no)
																	AND (drv_invoice.oe_line_number = oe_line.line_no)'
											 
			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Added join when tracking consignment usage by contract source location.  Note the
			--		we do not need to verify if the contract is still active -- if the UID is set on the CUO then we know it was used
			--		and was active at that point.
			IF (@li_TrackConsignment = 3155) 
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN job_price_line_consign ON (job_price_line_consign.job_price_line_uid = oe_line.job_price_line_uid)
	LEFT JOIN job_price_customer_shipto ON (job_price_customer_shipto.job_price_hdr_uid = oe_hdr.job_price_hdr_uid)
									   AND (job_price_customer_shipto.customer_id = oe_hdr.customer_id)
									   AND (job_price_customer_shipto.ship_to_id = oe_hdr.address_id)'

			SET @ls_SQL = @ls_SQL + N'
	WHERE	oe_line.delete_flag = ''N''
	  AND	COALESCE(oe_hdr.approved, ''Y'') = ''Y''
	  AND	COALESCE(oe_hdr.projected_order, ''N'') = ''N''
	  AND	oe_line.capture_usage = ''Y''
	  AND	oe_line.qty_ordered - oe_line.qty_canceled <> 0
	  AND	oe_line.other_charge = ''N''
	  AND	COALESCE(oe_hdr.order_type, 0) <> 1343
	  AND	oe_line_service.oe_line_service_uid IS NULL'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
			BEGIN
				IF (@li_UsageLocation = 1186)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

				IF (@li_UsageLocation = 1187)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
			END

			IF (@lc_TrackRMA = 'N')
				SET @ls_SQL = @ls_SQL + N'
	  AND	COALESCE(oe_hdr.rma_flag, ''N'') = ''N'''

			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Location limiting moved to where clause
			IF (@lc_UseWhereLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	  AND	((' + @ls_WhereClauseRegOrder + N')
	   OR	(' + @ls_WhereClauseCUO + N'))'

		END

		IF (@li_UsageCapturePoint = 995) --Invoice
		BEGIN
			SET @ls_SQL = @ls_SQL + N'
			,CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''N'' THEN
					qty_shipped
				ELSE
					0
			 END
			,CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''Y'' THEN
					qty_shipped
				ELSE
					0
			 END
			,0
			,0
			,995
			,invoice_line.invoice_line_uid
			,1
			,COALESCE(oe_pick_ticket.ship_date, invoice_line.date_created)
	FROM	temp_inventory_rebuild_items
	INNER JOIN invoice_line ON (invoice_line.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
	INNER JOIN invoice_hdr ON (invoice_hdr.invoice_no = invoice_line.invoice_no)
	LEFT JOIN oe_pick_ticket_detail ON (oe_pick_ticket_detail.invoice_line_uid = invoice_line.invoice_line_uid)
	LEFT JOIN oe_pick_ticket ON (oe_pick_ticket.pick_ticket_no = oe_pick_ticket_detail.pick_ticket_no)'

			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN demand_period ON (COALESCE(oe_pick_ticket.ship_date, invoice_line.date_created) >= demand_period.beginning_date)
							AND (COALESCE(oe_pick_ticket.ship_date, invoice_line.date_created) < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

			IF (@lc_UseIdealLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN (	SELECT	invoice_line.invoice_no
						,invoice_line.line_no
						,ideal_locations_by_zip.location_id
				FROM	ideal_locations_by_zip
				INNER JOIN invoice_hdr ON (invoice_hdr.ship2_postal_code BETWEEN ideal_locations_by_zip.start_zip_code AND ideal_locations_by_zip.end_zip_code)
				INNER JOIN invoice_line ON (invoice_line.invoice_no = invoice_hdr.invoice_no)
				INNER JOIN oe_line ON (oe_line.line_no = invoice_line.oe_line_number)
								  AND (oe_line.order_no = invoice_line.order_no)
				INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
				INNER JOIN customer ON (customer.company_id = invoice_hdr.company_no)
								   AND (customer.customer_id = invoice_hdr.customer_id)
				INNER JOIN ship_to ON (ship_to.company_id = invoice_hdr.company_no)
								  AND (ship_to.customer_id = invoice_hdr.customer_id)
								  AND (ship_to.ship_to_id = invoice_hdr.ship_to_id)
				INNER JOIN inventory_supplier ON (inventory_supplier.inv_mast_uid = invoice_line.inv_mast_uid)
											 AND (inventory_supplier.delete_flag = ''N'')
				INNER JOIN inventory_supplier_x_loc ON (inventory_supplier_x_loc.inventory_supplier_uid = inventory_supplier.inventory_supplier_uid)
												   AND (inventory_supplier_x_loc.location_id = oe_line.source_loc_id)
												   AND (inventory_supplier_x_loc.primary_supplier = ''Y'')
												   AND (inventory_supplier_x_loc.row_status_flag = 704)
				WHERE	COALESCE(customer.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(ship_to.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(inventory_supplier.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(oe_hdr.order_type, 706) <> 1344
				  AND	oe_line.delete_flag = ''N''
				  AND	COALESCE(oe_hdr.approved, ''Y'') = ''Y''
				  AND	COALESCE(oe_hdr.projected_order, ''N'') = ''N''
				  AND	oe_line.capture_usage = ''Y''
				  AND	invoice_line.qty_shipped <> 0
				  AND	oe_line.other_charge = ''N''
				GROUP BY invoice_line.invoice_no
						,invoice_line.line_no
						,ideal_locations_by_zip.location_id) AS drv_ideal_location ON (drv_ideal_location.invoice_no = invoice_hdr.invoice_no)
																				  AND (drv_ideal_location.line_no = invoice_line.line_no)'

			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'
											 
			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN oe_line ON (oe_line.line_no = invoice_line.oe_line_number)
					  AND (oe_line.order_no = invoice_line.order_no)'
					  
			IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseWhereLocation = 'N' AND @li_UsageLocation = 1187) --Source Location
	 			IF (@lc_UseIdealLocation = 'Y')
					SET @ls_SQL = @ls_SQL + N'
					  AND (COALESCE(drv_ideal_location.location_id, oe_line.source_loc_id) = temp_inventory_rebuild_items.location_id)'
				ELSE
					SET @ls_SQL = @ls_SQL + N'
					  AND (oe_line.source_loc_id = temp_inventory_rebuild_items.location_id)'
					  
			SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN oe_line_service ON (oe_line_service.oe_line_uid = oe_line.oe_line_uid)
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)'

			IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseWhereLocation = 'N' AND @li_UsageLocation = 1186) --Sales Location
	 			IF (@lc_UseIdealLocation = 'Y')
					SET @ls_SQL = @ls_SQL + N'
				     AND (COALESCE(drv_ideal_location.location_id, oe_hdr.location_id) = temp_inventory_rebuild_items.location_id)'
				ELSE
					SET @ls_SQL = @ls_SQL + N'
				     AND (oe_hdr.location_id = temp_inventory_rebuild_items.location_id)'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'

			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Added join when tracking consignment usage by contract source location.  Note the
			--		we do not need to verify if the contract is still active -- if the UID is set on the CUO then we know it was used
			--		and was active at that point.
			IF (@li_TrackConsignment = 3155) 
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN job_price_line_consign ON (job_price_line_consign.job_price_line_uid = oe_line.job_price_line_uid)
	LEFT JOIN job_price_customer_shipto ON (job_price_customer_shipto.job_price_hdr_uid = oe_hdr.job_price_hdr_uid)
									   AND (job_price_customer_shipto.customer_id = oe_hdr.customer_id)
									   AND (job_price_customer_shipto.ship_to_id = oe_hdr.address_id)'

			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Remove invalid exclusion for source_code_no of CUO. (order_type is set for CUOs, not source_code_no)
			--		But add exclusion for CRO which should not track usage.
			SET @ls_SQL = @ls_SQL + N'
	WHERE	oe_line.delete_flag = ''N''
	  AND	COALESCE(oe_hdr.approved, ''Y'') = ''Y''
	  AND	COALESCE(oe_hdr.projected_order, ''N'') = ''N''
	  AND	oe_line.capture_usage = ''Y''
	  AND	invoice_line.qty_shipped <> 0
	  AND	oe_line.other_charge = ''N''
	  AND	COALESCE(oe_hdr.order_type, 0) <> 1343
	  AND	oe_line_service.oe_line_service_uid IS NULL'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
			BEGIN
				IF (@li_UsageLocation = 1186)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

				IF (@li_UsageLocation = 1187)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
			END

			IF (@lc_TrackDirectShip = 'N')
				SET @ls_SQL = @ls_SQL + N'
	  AND	COALESCE(oe_pick_ticket.direct_shipment, ''N'') = ''N'''

			IF (@lc_TrackRMA = 'N')
				SET @ls_SQL = @ls_SQL + N'
	  AND	COALESCE(oe_hdr.rma_flag, ''N'') = ''N'''

			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Location limiting moved to where clause
			IF (@lc_UseWhereLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	  AND	((' + @ls_WhereClauseRegOrder + N')
	   OR	(' + @ls_WhereClauseCUO + N'))'

		END

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for order/invoice'
			GOTO error_return
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'SELECT into temp_inventory_usage_rebuild for order/invoice usage'

			SELECT	*
			FROM	temp_inventory_usage_rebuild
			WHERE	usage_type = 1
		END

		IF (@lc_TrackComponent IN ('B', 'C'))
		BEGIN
			SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,prod_order_line_component.qty_used
			,0
			,0
			,0
			,980
			,prod_order_line_component.prod_order_line_component_uid
			,1
			,prod_order_line_component.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN prod_order_line_component ON (prod_order_line_component.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
										AND (prod_order_line_component.source_location_id = temp_inventory_rebuild_items.location_id)
	INNER JOIN prod_order_hdr ON (prod_order_hdr.prod_order_number = prod_order_line_component.prod_order_number)
	--Scopus 1419809 Request ID 96428 Modify p21_rebiuld_inventory_usage to account for capture usage at the assembly or process transaction level -Jason Lieberman
	INNER JOIN prod_order_line ON (prod_order_line.prod_order_number = prod_order_hdr.prod_order_number)
							  AND (prod_order_line.line_number = prod_order_line_component.line_number)
	INNER JOIN assembly_hdr ON (assembly_hdr.inv_mast_uid = prod_order_line.inv_mast_uid)
						   AND (assembly_hdr.assembly_usage_accumulation IN (''B'',''C''))
	INNER JOIN demand_period ON (prod_order_hdr.date_created >= demand_period.beginning_date)
							AND (prod_order_hdr.date_created < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'
											 
			SET @ls_SQL = @ls_SQL + N'
	WHERE	prod_order_hdr.delete_flag = ''N''
	  AND	prod_order_hdr.approved = ''Y''
	  AND	prod_order_line_component.qty_used <> 0'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for prod order'
				GOTO error_return
			END
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'SELECT into temp_inventory_usage_rebuild for production order usage'

			SELECT	*
			FROM	temp_inventory_usage_rebuild
			WHERE	usage_type = 1
		END

		IF (@lc_TrackTransfer = 'Y')
		BEGIN
			SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,ROUND(inventory_receipts_line.qty_received * COALESCE(inv_loc.transfer_usage_percent, CAST(' + @ls_DefaultUsagePercent + N' AS DECIMAL(19, 9))) / 100, 4)
			,0
			,0
			,0
			,979
			,inventory_receipts_line.inventory_receipts_line_uid
			,1
			,inventory_receipts_line.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN transfer_line ON (transfer_line.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
	INNER JOIN transfer_hdr ON (transfer_hdr.transfer_no = transfer_line.transfer_no)
						   AND (transfer_hdr.from_location_id = temp_inventory_rebuild_items.location_id)
	INNER JOIN transfer_shipment_hdr ON (transfer_shipment_hdr.transfer_no = transfer_hdr.transfer_no)
	INNER JOIN transfer_shipment_line ON (transfer_shipment_line.transfer_shipment_hdr_uid = transfer_shipment_hdr.transfer_shipment_hdr_uid)
									 AND (transfer_shipment_line.transfer_line_no = transfer_line.line_no)
	INNER JOIN inventory_receipts_hdr ON (inventory_receipts_hdr.po_number = transfer_shipment_hdr.transfer_shipment_no)
	INNER JOIN inventory_receipts_line ON (inventory_receipts_line.receipt_number = inventory_receipts_hdr.receipt_number)
									  AND (inventory_receipts_line.po_line_number = transfer_shipment_line.ts_line_no)
	INNER JOIN inv_loc ON (inv_loc.inv_mast_uid = inventory_receipts_line.inv_mast_uid)
					  AND (inv_loc.location_id = transfer_hdr.to_location_id)
					  AND (inv_loc.replenishment_location = transfer_hdr.from_location_id)
	INNER JOIN demand_period ON (inventory_receipts_hdr.date_created >= demand_period.beginning_date)
							AND (inventory_receipts_hdr.date_created < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'

			SET @ls_SQL = @ls_SQL + N'
	WHERE	inventory_receipts_hdr.receipt_type = ''T''
	  AND	inventory_receipts_hdr.approved = ''Y''
	  AND	(inv_loc.transfer_usage_percent IS NULL
	   OR	inv_loc.transfer_usage_percent <> 0)
	  AND	COALESCE(transfer_hdr.omit_transfer_usage_flag, ''N'') = ''N''
	  AND	COALESCE(transfer_line.omit_transfer_usage_flag, ''N'') = ''N''
	  AND	ROUND(inventory_receipts_line.qty_received * COALESCE(inv_loc.transfer_usage_percent, CAST(' + @ls_DefaultUsagePercent + N' AS DECIMAL(19, 9))) / 100, 4) <> 0'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for transfer'
				GOTO error_return
			END

			IF (@ai_Debug & 8 > 0)
			BEGIN
				SELECT 'SELECT into temp_inventory_usage_rebuild for transfer usage'

				SELECT	*
				FROM	temp_inventory_usage_rebuild
				WHERE	usage_type = 1
			END
		END

		IF (@lc_TrackRawItem = 'Y')
		BEGIN
			SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,process_x_transaction.qty_completed
			,0
			,0
			,0
			,814
			,process_x_transaction.process_x_transaction_uid
			,1
			,process_x_transaction.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN process_x_transaction ON (process_x_transaction.raw_inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
									AND (process_x_transaction.location_id = temp_inventory_rebuild_items.location_id)
									AND (process_x_transaction.capture_usage_flag = ''Y'')					--Scopus 1419809 Request ID 96428 Modify p21_rebiuld_inventory_usage to account for capture usage at the assembly or process transaction level -Jason Lieberman
	INNER JOIN location ON (location.location_id = process_x_transaction.location_id)
	INNER JOIN demand_period ON (process_x_transaction.date_created >= demand_period.beginning_date)
							AND (process_x_transaction.date_created < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'

			SET @ls_SQL = @ls_SQL + N'
	WHERE	process_x_transaction.row_status_flag IN (701, 703)
	  AND	process_x_transaction.qty_completed <> 0'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for process'
				GOTO error_return
			END

			IF (@ai_Debug & 8 > 0)
			BEGIN
				SELECT 'SELECT into temp_inventory_usage_rebuild for secondary process usage'

				SELECT	*
				FROM	temp_inventory_usage_rebuild
				WHERE	usage_type = 1
			END
		END
	END
	
	IF (@lc_UpdateServiceLevel = 'Y')
	BEGIN
		IF (@ai_SectiontoExecute & 2 > 0)
		BEGIN
			SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,0
			,0
			,1
			,0
			,951
			,oe_line.oe_line_uid
			,2
			,oe_line.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN oe_line ON (oe_line.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)'

			IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseIdealLocation <> 'Y')
				SET @ls_SQL = @ls_SQL + N'
					  AND (oe_line.source_loc_id = temp_inventory_rebuild_items.location_id)'

			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'

			IF (@li_AccumulateServiceLevelAt = 995)
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN (SELECT	invoice_line.inv_mast_uid inv_mast_uid
						,invoice_hdr.order_no
						,MIN(invoice_hdr.invoice_date) invoice_date
				FROM	invoice_line
				INNER JOIN invoice_hdr ON (invoice_hdr.invoice_no = invoice_line.invoice_no)
				GROUP BY invoice_line.inv_mast_uid
						,invoice_hdr.order_no) AS drv_first_invoice ON (drv_first_invoice.order_no = oe_line.order_no)
																   AND (drv_first_invoice.inv_mast_uid = oe_line.inv_mast_uid)
	INNER JOIN demand_period ON (drv_first_invoice.invoice_date >= demand_period.beginning_date)
							AND (drv_first_invoice.invoice_date < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'
			ELSE
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN demand_period ON (oe_hdr.order_date >= demand_period.beginning_date)
							AND (oe_hdr.order_date < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

			IF (@lc_UseIdealLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN (	SELECT	oe_line.order_no
						,oe_line.line_no
						,ideal_locations_by_zip.location_id
				FROM	ideal_locations_by_zip
				INNER JOIN invoice_hdr ON (invoice_hdr.ship2_postal_code BETWEEN ideal_locations_by_zip.start_zip_code AND ideal_locations_by_zip.end_zip_code)
				INNER JOIN invoice_line ON (invoice_line.invoice_no = invoice_hdr.invoice_no)
				INNER JOIN oe_line ON (oe_line.line_no = invoice_line.oe_line_number)
								  AND (oe_line.order_no = invoice_line.order_no)
				INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
				INNER JOIN customer ON (customer.company_id = invoice_hdr.company_no)
								   AND (customer.customer_id = invoice_hdr.customer_id)
				INNER JOIN ship_to ON (ship_to.company_id = invoice_hdr.company_no)
								  AND (ship_to.customer_id = invoice_hdr.customer_id)
								  AND (ship_to.ship_to_id = invoice_hdr.ship_to_id)
				INNER JOIN inventory_supplier ON (inventory_supplier.inv_mast_uid = invoice_line.inv_mast_uid)
											 AND (inventory_supplier.delete_flag = ''N'')
				INNER JOIN inventory_supplier_x_loc ON (inventory_supplier_x_loc.inventory_supplier_uid = inventory_supplier.inventory_supplier_uid)
												   AND (inventory_supplier_x_loc.location_id = oe_line.source_loc_id)
												   AND (inventory_supplier_x_loc.primary_supplier = ''Y'')
												   AND (inventory_supplier_x_loc.row_status_flag = 704)
				WHERE	COALESCE(customer.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(ship_to.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(inventory_supplier.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(oe_hdr.order_type, 706) <> 1344
				  AND	oe_line.delete_flag = ''N''
				  AND	COALESCE(oe_hdr.approved, ''Y'') = ''Y''
				  AND	COALESCE(oe_hdr.projected_order, ''N'') = ''N''
				  AND	oe_line.capture_usage = ''Y''
				  AND	invoice_line.qty_shipped <> 0
				  AND	oe_line.other_charge = ''N''
				GROUP BY oe_line.order_no
						,oe_line.line_no
						,ideal_locations_by_zip.location_id) AS drv_ideal_location ON (drv_ideal_location.order_no = oe_line.order_no)
																				  AND (drv_ideal_location.line_no = oe_line.line_no)'

			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'

			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Remove invalid exclusion for source_code_no of CUO. (order_type is set for CUOs, not source_code_no)
			--		But add exclusion for CRO which should not track usage.
			SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN oe_line_service ON (oe_line_service.oe_line_uid = oe_line.oe_line_uid)
	WHERE	oe_line.delete_flag = ''N''
	  AND	oe_hdr.approved = ''Y''
	  AND	oe_hdr.projected_order = ''N''
	  AND	oe_line.capture_usage = ''Y''
	  AND	oe_line.qty_ordered - oe_line.qty_canceled <> 0
	  AND	oe_line.other_charge = ''N''
	  AND   oe_line.scheduled = ''N''
	  AND	COALESCE(oe_hdr.order_type, 0) <> 1343
	  AND	oe_line_service.oe_line_service_uid IS NULL'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
			BEGIN
				IF (@li_UsageLocation = 1186)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

				IF (@li_UsageLocation = 1187)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
			END

			IF (@lc_UseIdealLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	  AND	(COALESCE(drv_ideal_location.location_id, oe_line.source_loc_id) = temp_inventory_rebuild_items.location_id)'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for number of orders'
				GOTO error_return
			END

			IF (@ai_Debug & 8 > 0)
			BEGIN
				SELECT 'SELECT into temp_inventory_usage_rebuild for order/invoice number of orders'

				SELECT	*
				FROM	temp_inventory_usage_rebuild
				WHERE	usage_type = 2
			END
		END

		IF (@ai_SectiontoExecute & 4 > 0)
		BEGIN
			SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,0
			,0
			,0
			,1
			,951
			,oe_line.oe_line_uid
			,3
			,oe_line.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN oe_line ON (oe_line.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)'

			IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseIdealLocation <> 'Y')
				SET @ls_SQL = @ls_SQL + N'
					  AND (oe_line.source_loc_id = temp_inventory_rebuild_items.location_id)'

			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
	INNER JOIN (SELECT	invoice_line.inv_mast_uid inv_mast_uid
						,invoice_hdr.order_no
						,MIN(invoice_hdr.invoice_date) invoice_date
				FROM	invoice_line
				INNER JOIN invoice_hdr ON (invoice_hdr.invoice_no = invoice_line.invoice_no)
				GROUP BY invoice_line.inv_mast_uid
						,invoice_hdr.order_no) AS drv_first_invoice ON (drv_first_invoice.order_no = oe_line.order_no)
																   AND (drv_first_invoice.inv_mast_uid = oe_line.inv_mast_uid)
	INNER JOIN demand_period ON (drv_first_invoice.invoice_date >= demand_period.beginning_date)
							AND (drv_first_invoice.invoice_date < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'

			IF (@lc_UseIdealLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN (	SELECT	oe_line.order_no
						,oe_line.line_no
						,ideal_locations_by_zip.location_id
				FROM	ideal_locations_by_zip
				INNER JOIN invoice_hdr ON (invoice_hdr.ship2_postal_code BETWEEN ideal_locations_by_zip.start_zip_code AND ideal_locations_by_zip.end_zip_code)
				INNER JOIN invoice_line ON (invoice_line.invoice_no = invoice_hdr.invoice_no)
				INNER JOIN oe_line ON (oe_line.line_no = invoice_line.oe_line_number)
								  AND (oe_line.order_no = invoice_line.order_no)
				INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
				INNER JOIN customer ON (customer.company_id = invoice_hdr.company_no)
								   AND (customer.customer_id = invoice_hdr.customer_id)
				INNER JOIN ship_to ON (ship_to.company_id = invoice_hdr.company_no)
								  AND (ship_to.customer_id = invoice_hdr.customer_id)
								  AND (ship_to.ship_to_id = invoice_hdr.ship_to_id)
				INNER JOIN inventory_supplier ON (inventory_supplier.inv_mast_uid = invoice_line.inv_mast_uid)
											 AND (inventory_supplier.delete_flag = ''N'')
				INNER JOIN inventory_supplier_x_loc ON (inventory_supplier_x_loc.inventory_supplier_uid = inventory_supplier.inventory_supplier_uid)
												   AND (inventory_supplier_x_loc.location_id = oe_line.source_loc_id)
												   AND (inventory_supplier_x_loc.primary_supplier = ''Y'')
												   AND (inventory_supplier_x_loc.row_status_flag = 704)
				WHERE	COALESCE(customer.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(ship_to.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(inventory_supplier.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(oe_hdr.order_type, 706) <> 1344
				  AND	oe_line.delete_flag = ''N''
				  AND	COALESCE(oe_hdr.approved, ''Y'') = ''Y''
				  AND	COALESCE(oe_hdr.projected_order, ''N'') = ''N''
				  AND	oe_line.capture_usage = ''Y''
				  AND	invoice_line.qty_shipped <> 0
				  AND	oe_line.other_charge = ''N''
				GROUP BY oe_line.order_no
						,oe_line.line_no
						,ideal_locations_by_zip.location_id) AS drv_ideal_location ON (drv_ideal_location.order_no = oe_line.order_no)
																				  AND (drv_ideal_location.line_no = oe_line.line_no)'

			IF (@lc_UsePeriodTable = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'

			-- 12.12 JBH 02/26/13 - Scopus 1123013 - Remove invalid exclusion for source_code_no of CUO. (order_type is set for CUOs, not source_code_no)
			--		But add exclusion for CRO which should not track usage.
			SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN oe_line_service ON (oe_line_service.oe_line_uid = oe_line.oe_line_uid)
	WHERE	oe_line.qty_ordered <> oe_line.qty_canceled
	  AND	oe_line.delete_flag = ''N''
	  AND	oe_hdr.approved = ''Y''
	  AND	oe_hdr.projected_order = ''N''
	  AND	oe_line.capture_usage = ''Y''
	  AND	COALESCE(oe_hdr.order_type, 0) <> 1343
	  AND	oe_line_service.oe_line_service_uid IS NULL
	  AND	EXISTS
			(SELECT	invoice_hdr.order_no
					,invoice_line.oe_line_number
			 FROM	invoice_hdr
			 INNER JOIN invoice_line ON (invoice_line.invoice_no = invoice_hdr.invoice_no)
			 WHERE	invoice_hdr.order_no = oe_line.order_no
			   AND	invoice_line.oe_line_number = oe_line.line_no
			   AND	DATEDIFF(DAY, invoice_hdr.ship_date, COALESCE(oe_line.required_date, oe_hdr.requested_date)) >= 0
			   GROUP BY invoice_hdr.order_no
						,invoice_line.oe_line_number
			   HAVING (oe_line.qty_ordered * ' + CAST(@ldc_HitPct AS VARCHAR(255)) + N' / 100) <= SUM(invoice_line.qty_shipped))'

			IF (@li_AccumulateServiceLevelAt = 951)
				SET @ls_SQL = @ls_SQL + N'
	  AND	EXISTS
			(SELECT	1
			 FROM	audit_trail
			 WHERE	audit_trail.source_area_cd = 1319
			   AND	audit_trail.table_changed = ''oe_line''
			   AND	audit_trail.column_changed = ''disposition''
			   AND	audit_trail.new_value IS NOT NULL
			   AND	audit_trail.key1_value = oe_line.order_no
			   AND	audit_trail.line_no = oe_line.line_no)'

			IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
			BEGIN
				IF (@li_UsageLocation = 1186)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

				IF (@li_UsageLocation = 1187)
					SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
			END

			IF (@lc_UseIdealLocation = 'Y')
				SET @ls_SQL = @ls_SQL + N'
	  AND	(COALESCE(drv_ideal_location.location_id, oe_line.source_loc_id) = temp_inventory_rebuild_items.location_id)'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for orders with invoices number of hits'
				GOTO error_return
			END

			IF (@ai_Debug & 8 > 0)
			BEGIN
				SELECT 'SELECT into temp_inventory_usage_rebuild for orders with invoices number of hits'

				SELECT	*
				FROM	temp_inventory_usage_rebuild
				WHERE	usage_type = 3
			END

			IF (@li_AccumulateServiceLevelAt = 951)
			BEGIN
				SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,0
			,0
			,0
			,1
			,951
			,oe_line.oe_line_uid
			,3
			,oe_line.date_created
	FROM	temp_inventory_rebuild_items
	INNER JOIN oe_line ON (oe_line.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)'

				IF (@lc_TrackShipToDefaultLocation = 'N' AND @lc_UseIdealLocation <> 'Y')
					SET @ls_SQL = @ls_SQL + N'
					  AND (oe_line.source_loc_id = temp_inventory_rebuild_items.location_id)'

				SET @ls_SQL = @ls_SQL + N'
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
	INNER JOIN demand_period ON (oe_hdr.order_date >= demand_period.beginning_date)
							AND (oe_hdr.order_date < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

				IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
					SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'

				IF (@lc_UseIdealLocation = 'Y')
					SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN (	SELECT	oe_line.order_no
						,oe_line.line_no
						,ideal_locations_by_zip.location_id
				FROM	ideal_locations_by_zip
				INNER JOIN invoice_hdr ON (invoice_hdr.ship2_postal_code BETWEEN ideal_locations_by_zip.start_zip_code AND ideal_locations_by_zip.end_zip_code)
				INNER JOIN invoice_line ON (invoice_line.invoice_no = invoice_hdr.invoice_no)
				INNER JOIN oe_line ON (oe_line.line_no = invoice_line.oe_line_number)
								  AND (oe_line.order_no = invoice_line.order_no)
				INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
				INNER JOIN customer ON (customer.company_id = invoice_hdr.company_no)
								   AND (customer.customer_id = invoice_hdr.customer_id)
				INNER JOIN ship_to ON (ship_to.company_id = invoice_hdr.company_no)
								  AND (ship_to.customer_id = invoice_hdr.customer_id)
								  AND (ship_to.ship_to_id = invoice_hdr.ship_to_id)
				INNER JOIN inventory_supplier ON (inventory_supplier.inv_mast_uid = invoice_line.inv_mast_uid)
											 AND (inventory_supplier.delete_flag = ''N'')
				INNER JOIN inventory_supplier_x_loc ON (inventory_supplier_x_loc.inventory_supplier_uid = inventory_supplier.inventory_supplier_uid)
												   AND (inventory_supplier_x_loc.location_id = oe_line.source_loc_id)
												   AND (inventory_supplier_x_loc.primary_supplier = ''Y'')
												   AND (inventory_supplier_x_loc.row_status_flag = 704)
				WHERE	COALESCE(customer.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(ship_to.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(inventory_supplier.record_usage_actual_loc_flag, ''N'') = ''N''
				  AND	COALESCE(oe_hdr.order_type, 706) <> 1344
				  AND	oe_line.delete_flag = ''N''
				  AND	COALESCE(oe_hdr.approved, ''Y'') = ''Y''
				  AND	COALESCE(oe_hdr.projected_order, ''N'') = ''N''
				  AND	oe_line.capture_usage = ''Y''
				  AND	invoice_line.qty_shipped <> 0
				  AND	oe_line.other_charge = ''N''
				GROUP BY oe_line.order_no
						,oe_line.line_no
						,ideal_locations_by_zip.location_id) AS drv_ideal_location ON (drv_ideal_location.order_no = oe_line.order_no)
																				  AND (drv_ideal_location.line_no = oe_line.line_no)'

				IF (@lc_UsePeriodTable = 'Y')
					SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'

				-- 12.12 JBH 02/26/13 - Scopus 1123013 - Remove invalid exclusion for source_code_no of CUO. (order_type is set for CUOs, not source_code_no)
				--		But add exclusion for CRO which should not track usage.
				SET @ls_SQL = @ls_SQL + N'
	LEFT JOIN oe_line_service ON (oe_line_service.oe_line_uid = oe_line.oe_line_uid)
	WHERE	oe_line.qty_ordered <> oe_line.qty_canceled
	  AND	oe_line.delete_flag = ''N''
	  AND	oe_hdr.approved = ''Y''
	  AND	oe_hdr.projected_order = ''N''
	  AND	oe_line.capture_usage = ''Y''
	  AND	COALESCE(oe_hdr.order_type, 0) <> 1343
	  AND	oe_line_service.oe_line_service_uid IS NULL
	  AND	NOT EXISTS
			(SELECT	1
			 FROM	audit_trail
			 WHERE	audit_trail.source_area_cd = 1319
			   AND	audit_trail.table_changed = ''oe_line''
			   AND	audit_trail.column_changed = ''disposition''
			   AND	audit_trail.new_value IS NOT NULL
			   AND	audit_trail.key1_value = oe_line.order_no
			   AND	audit_trail.line_no = oe_line.line_no)'

				IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
				BEGIN
					IF (@li_UsageLocation = 1186)
						SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

					IF (@li_UsageLocation = 1187)
						SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
				END

				IF (@lc_UseIdealLocation = 'Y')
					SET @ls_SQL = @ls_SQL + N'
	  AND	(COALESCE(drv_ideal_location.location_id, oe_line.source_loc_id) = temp_inventory_rebuild_items.location_id)'

				IF (@ai_Debug & 2 > 0)
					SELECT @ls_SQL

				IF (@ai_Debug & 1 > 0)
					EXECUTE (@ls_SQL)

				SELECT @error = @@ERROR
				IF (@error <> 0)
				BEGIN
					SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for number of hits'
					GOTO error_return
				END

				IF (@ai_Debug & 8 > 0)
				BEGIN
					SELECT 'SELECT into temp_inventory_usage_rebuild for order number of hits'

					SELECT	*
					FROM	temp_inventory_usage_rebuild
					WHERE	usage_type = 3
				END
			END
		END
	END

	IF (@ai_SectiontoExecute & 8 > 0)
	BEGIN
		SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	inv_mast_uid
			,location_id
			,demand_period_uid
			,SUM(inv_period_usage)
			,SUM(scheduled_usage)
			,0
			,0
			,951
			,oe_line_uid
			,4
			,date_created
	FROM	(
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,SUM(CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''N'' THEN
					lost_sales_transaction.sku_qty_change
				ELSE
					0
			 END) inv_period_usage'

		IF (@li_UsageCapturePoint = 951) --OE
			SET @ls_SQL = @ls_SQL + N'
			,0 AS scheduled_usage'
		ELSE
			SET @ls_SQL = @ls_SQL + N'
			,SUM(CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''Y'' THEN
					lost_sales_transaction.sku_qty_change
				ELSE
					0
			 END) scheduled_usage'

		SET @ls_SQL = @ls_SQL + N'
			,oe_line.oe_line_uid
			,oe_line.date_created
	FROM	lost_sales_transaction
	INNER JOIN lost_sales ON (lost_sales.lost_sales_uid = lost_sales_transaction.lost_sales_uid)
	INNER JOIN oe_line ON (oe_line.order_no = CAST(lost_sales_transaction.transaction_no AS VARCHAR(255)))
					  AND (oe_line.line_no = lost_sales_transaction.line_no)
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
	INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = oe_line.inv_mast_uid)'
	
		IF (@lc_TrackShipToDefaultLocation = 'N' AND @li_UsageLocation = 1187) --Source Location
			SET @ls_SQL = @ls_SQL + N'
										   AND (temp_inventory_rebuild_items.location_id = oe_line.source_loc_id)'

		IF (@lc_TrackShipToDefaultLocation = 'N' AND @li_UsageLocation = 1186) --Sales Location
			SET @ls_SQL = @ls_SQL + N'
										   AND (temp_inventory_rebuild_items.location_id = oe_hdr.location_id)'

		IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'
										   
		SET @ls_SQL = @ls_SQL + N'
	INNER JOIN demand_period ON (oe_line.date_created >= demand_period.beginning_date)
							AND (oe_line.date_created < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

		IF (@lc_UsePeriodTable = 'Y')
			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'
											 
		SET @ls_SQL = @ls_SQL + N'
	WHERE	lost_sales.affect_usage = ''Y''
	  AND	lost_sales_transaction.affect_usage = ''Y''
	  AND	lost_sales_transaction.usage_processed_flag = ''Y''
	  AND	lost_sales_transaction.transaction_code_no IN (2142, 2143, 2144, 2145, 2148, 2707, 2846, 2847)
	  AND	COALESCE(lost_sales_transaction.sku_qty_change, 0) <> 0'

		IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
		BEGIN
			IF (@li_UsageLocation = 1186)
				SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

			IF (@li_UsageLocation = 1187)
				SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
		END

		SET @ls_SQL = @ls_SQL + N'
	GROUP BY temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,oe_line.oe_line_uid	  
			,oe_line.date_created

	UNION
	
	SELECT	temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,SUM(CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''N'' THEN
					lost_sales_transaction.sku_qty_change
				ELSE
					0
			 END) inv_period_usage'

		IF (@li_UsageCapturePoint = 951) --OE
			SET @ls_SQL = @ls_SQL + N'
			,0 AS scheduled_usage'
		ELSE
			SET @ls_SQL = @ls_SQL + N'
			,SUM(CASE COALESCE(oe_line.scheduled, ''N'')
				WHEN ''Y'' THEN
					lost_sales_transaction.sku_qty_change
				ELSE
					0
			 END) scheduled_usage'

		SET @ls_SQL = @ls_SQL + N'
			,oe_line.oe_line_uid
			,oe_line.date_created
	FROM	lost_sales_transaction
	INNER JOIN lost_sales ON (lost_sales.lost_sales_uid = lost_sales_transaction.lost_sales_uid)
	INNER JOIN oe_pick_ticket_detail ON (oe_pick_ticket_detail.pick_ticket_no = CAST(lost_sales_transaction.transaction_no AS VARCHAR(255)))
									AND (oe_pick_ticket_detail.line_number = lost_sales_transaction.line_no)
	INNER JOIN oe_pick_ticket ON (oe_pick_ticket.pick_ticket_no = oe_pick_ticket_detail.pick_ticket_no)
	INNER JOIN oe_line ON (oe_line.order_no = oe_pick_ticket.order_no)
					  AND (oe_line.line_no = oe_pick_ticket_detail.oe_line_no)
	INNER JOIN oe_hdr ON (oe_hdr.order_no = oe_line.order_no)
	INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = oe_line.inv_mast_uid)'
	
		IF (@lc_TrackShipToDefaultLocation = 'N' AND @li_UsageLocation = 1187) --Source Location
			SET @ls_SQL = @ls_SQL + N'
										   AND (temp_inventory_rebuild_items.location_id = oe_line.source_loc_id)'

		IF (@lc_TrackShipToDefaultLocation = 'N' AND @li_UsageLocation = 1186) --Sales Location
			SET @ls_SQL = @ls_SQL + N'
										   AND (temp_inventory_rebuild_items.location_id = oe_hdr.location_id)'

		IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN ship_to ON (ship_to.company_id = oe_hdr.company_id)
					  AND (ship_to.customer_id = oe_hdr.customer_id)
					  AND (ship_to.ship_to_id = oe_hdr.address_id)'
										   
		SET @ls_SQL = @ls_SQL + N'
	INNER JOIN demand_period ON (oe_line.date_created >= demand_period.beginning_date)
							AND (oe_line.date_created < DATEADD(DAY, 1, demand_period.ending_date))
							AND (temp_inventory_rebuild_items.company_id = demand_period.company_id)'

		IF (@lc_UsePeriodTable = 'Y')
			SET @ls_SQL = @ls_SQL + N'
	INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
											 AND (temp_inventory_rebuild_periods.location_id = temp_inventory_rebuild_items.location_id)
											 AND (temp_inventory_rebuild_periods.demand_period_uid = demand_period.demand_period_uid)'

		SET @ls_SQL = @ls_SQL + N'
	WHERE	lost_sales.affect_usage = ''Y''
	  AND	lost_sales_transaction.affect_usage = ''Y''
	  AND	lost_sales_transaction.usage_processed_flag = ''Y''
	  AND	lost_sales_transaction.transaction_code_no IN (2146, 2147, 2149)
	  AND	COALESCE(lost_sales_transaction.sku_qty_change, 0) <> 0'

		IF (@lc_TrackShipToDefaultLocation = 'Y' AND @lc_UseIdealLocation = 'N')
		BEGIN
			IF (@li_UsageLocation = 1186)
				SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_hdr.location_id)'

			IF (@li_UsageLocation = 1187)
				SET @ls_SQL = @ls_SQL + N'
	  AND	temp_inventory_rebuild_items.location_id = COALESCE(ship_to.preferred_location_id, oe_line.source_loc_id)'
		END

		SET @ls_SQL = @ls_SQL + N'
	GROUP BY temp_inventory_rebuild_items.inv_mast_uid
			,temp_inventory_rebuild_items.location_id
			,demand_period.demand_period_uid
			,oe_line.oe_line_uid
			,oe_line.date_created) AS drv_lost_sales
	GROUP BY drv_lost_sales.inv_mast_uid
			,drv_lost_sales.location_id
			,drv_lost_sales.demand_period_uid
			,drv_lost_sales.oe_line_uid
			,drv_lost_sales.date_created'

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild for lost sales'
			GOTO error_return
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'SELECT into temp_inventory_usage_rebuild for lost sales'

			SELECT	*
			FROM	temp_inventory_usage_rebuild
			WHERE	usage_type = 4
		END
	END

	IF (@ai_SectiontoExecute BETWEEN 1 AND 15 AND @ReportValues = 'N')
	BEGIN
		IF (@ai_DeleteUsage = 'Y')
		BEGIN
			IF (@ai_AffectAllUsage = 'Y')
				SET @ls_SQL = N'
DELETE	demand_review_adjustment
FROM	demand_review_adjustment
INNER JOIN inv_period_usage ON (inv_period_usage.inv_period_usage_uid = demand_review_adjustment.inv_period_usage_uid)
INNER JOIN location ON (location.location_id = inv_period_usage.location_id)
WHERE	location.company_id = ''' + @as_CompanyID + N'''
  AND	COALESCE(inv_period_usage.imported, ''N'') <> ''Y''

DELETE	inv_period_usage
FROM	inv_period_usage
INNER JOIN location ON (location.location_id = inv_period_usage.location_id)
WHERE	location.company_id = ''' + @as_CompanyID + N'''
  AND	COALESCE(inv_period_usage.imported, ''N'') <> ''Y'''
			ELSE
				IF  (@lc_UsePeriodTable = 'N')
					SET @ls_SQL = N'
DELETE	demand_review_adjustment
FROM	demand_review_adjustment
INNER JOIN inv_period_usage ON (inv_period_usage.inv_period_usage_uid = demand_review_adjustment.inv_period_usage_uid)
INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = inv_period_usage.inv_mast_uid)
									   AND (temp_inventory_rebuild_items.location_id = inv_period_usage.location_id)
WHERE	COALESCE(inv_period_usage.imported, ''N'') <> ''Y''

DELETE	inv_period_usage
FROM	inv_period_usage
INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = inv_period_usage.inv_mast_uid)
									   AND (temp_inventory_rebuild_items.location_id = inv_period_usage.location_id)
WHERE	COALESCE(inv_period_usage.imported, ''N'') <> ''Y'''
				ELSE
					SET @ls_SQL = N'
DELETE	demand_review_adjustment
FROM	demand_review_adjustment
INNER JOIN inv_period_usage ON (inv_period_usage.inv_period_usage_uid = demand_review_adjustment.inv_period_usage_uid)
INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = inv_period_usage.inv_mast_uid)
										 AND (temp_inventory_rebuild_periods.location_id = inv_period_usage.location_id)
										 AND (temp_inventory_rebuild_periods.demand_period_uid = inv_period_usage.demand_period_uid)
WHERE	COALESCE(inv_period_usage.imported, ''N'') <> ''Y''

DELETE	inv_period_usage
FROM	inv_period_usage
INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = inv_period_usage.inv_mast_uid)
										 AND (temp_inventory_rebuild_periods.location_id = inv_period_usage.location_id)
										 AND (temp_inventory_rebuild_periods.demand_period_uid = inv_period_usage.demand_period_uid)
WHERE	COALESCE(inv_period_usage.imported, ''N'') <> ''Y'''
		END
		ELSE
		BEGIN
			SET @ls_SQL = N'
UPDATE	inv_period_usage'

			IF (@ai_SectiontoExecute & 1 > 0)
			BEGIN
				SET @ls_SQL = @ls_SQL + N'
SET		inv_period_usage = 0
		,inv_period_usage_this_location = 0
		,scheduled_usage = 0'

				IF (@lc_UpdateServiceLevel = 'Y')
				BEGIN
					IF (@ai_SectiontoExecute & 2 > 0)
						SET @ls_SQL = @ls_SQL + N'
		,number_of_orders = 0'
				
					IF (@ai_SectiontoExecute & 4 > 0)
						SET @ls_SQL = @ls_SQL + N'
		,number_of_hits = 0'

				END
			END
			ELSE
			BEGIN
				IF (@lc_UpdateServiceLevel = 'Y')
				BEGIN
					IF (@ai_SectiontoExecute & 2 > 0)
					BEGIN
						SET @ls_SQL = @ls_SQL + N'
SET		number_of_orders = 0'
			
						IF (@ai_SectiontoExecute & 4 > 0)
							SET @ls_SQL = @ls_SQL + N'
		,number_of_hits = 0'
					END
					ELSE
					BEGIN
						IF (@ai_SectiontoExecute & 4 > 0)
							SET @ls_SQL = @ls_SQL + N'
SET		number_of_hits = 0'

					END	
				END
				ELSE
				BEGIN
					SELECT @error = @@ERROR
					IF (@error <> 0)
					BEGIN
						SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' no work to perform.'
						GOTO error_return
					END
				END
			END
			
			IF (@ai_AffectAllUsage = 'Y')
				SET @ls_SQL = @ls_SQL + N'
FROM	inv_period_usage
INNER JOIN location ON (location.location_id = inv_period_usage.location_id)
WHERE	location.company_id = ''' + @as_CompanyID + N'''
  AND	COALESCE(inv_period_usage.imported, ''N'') <> ''Y'''
			ELSE
				IF (@lc_UsePeriodTable = 'N')
					SET @ls_SQL = @ls_SQL + N'
FROM	inv_period_usage
INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = inv_period_usage.inv_mast_uid)
									   AND (temp_inventory_rebuild_items.location_id = inv_period_usage.location_id)
WHERE	COALESCE(inv_period_usage.imported, ''N'') <> ''Y'''
				ELSE				
					SET @ls_SQL = @ls_SQL + N'
FROM	inv_period_usage
INNER JOIN temp_inventory_rebuild_periods ON (temp_inventory_rebuild_periods.inv_mast_uid = inv_period_usage.inv_mast_uid)
										 AND (temp_inventory_rebuild_periods.location_id = inv_period_usage.location_id)
										 AND (temp_inventory_rebuild_periods.demand_period_uid = inv_period_usage.demand_period_uid)
WHERE	COALESCE(inv_period_usage.imported, ''N'') <> ''Y'''
		END

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing DELETE\UPDATE of inv_period_usage to clear'
			GOTO error_return
		END

--The trigger should handle this
/*
		IF (@lc_push_usage_to_dup_item = 'Z')
		BEGIN
			SET @ls_SQL = '
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	dup_inv_loc.inv_mast_uid
			,temp_inventory_usage_rebuild.location_id
			,demand_period.demand_period_uid
			,temp_inventory_usage_rebuild.inv_period_usage
			,temp_inventory_usage_rebuild.scheduled_usage
			,temp_inventory_usage_rebuild.number_of_orders
			,temp_inventory_usage_rebuild.number_of_hits
			,temp_inventory_usage_rebuild.source
			,temp_inventory_usage_rebuild.document_no
			,temp_inventory_usage_rebuild.usage_type
			,temp_inventory_usage_rebuild.trans_date
	FROM	temp_inventory_usage_rebuild
	INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = temp_inventory_usage_rebuild.inv_mast_uid)
										   AND (temp_inventory_rebuild_items.location_id = temp_inventory_usage_rebuild.location_id)
	INNER JOIN inv_loc dup_inv_loc WITH (NOLOCK) ON (dup_inv_loc.inv_mast_uid = temp_inventory_rebuild_items.duplicate_usage_inv_mast_uid)
												AND (dup_inv_loc.location_id = temp_inventory_usage_rebuild.location_id)
	INNER JOIN demand_period ON (temp_inventory_usage_rebuild.trans_date >= demand_period.beginning_date)
							AND (temp_inventory_usage_rebuild.trans_date < DATEADD(DAY, 1, demand_period.ending_date))
							AND (dup_inv_loc.company_id = demand_period.company_id)
	LEFT JOIN temp_inventory_usage_rebuild temp_rebuild_dup ON (temp_rebuild_dup.inv_mast_uid = dup_inv_loc.inv_mast_uid)
														   AND (temp_rebuild_dup.location_id = dup_inv_loc.location_id)
														   AND (temp_rebuild_dup.source = temp_inventory_usage_rebuild.source)
														   AND (temp_rebuild_dup.document_no = temp_inventory_usage_rebuild.document_no)
														   AND (temp_rebuild_dup.usage_type = temp_inventory_usage_rebuild.usage_type)
	WHERE	temp_rebuild_dup.inv_mast_uid IS NULL'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild_history for push_usage_to_dup_item'
				GOTO error_return
			END
		END

		IF (@lc_push_usage_to_replen_loc = 'Z')
		BEGIN
			SET @ls_SQL = '
INSERT INTO temp_inventory_usage_rebuild
		(inv_mast_uid
		,location_id
		,demand_period_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,usage_type
		,trans_date)
	SELECT	temp_inventory_usage_rebuild.inv_mast_uid
			,dup_inv_loc.location_id
			,demand_period.demand_period_uid
			,temp_inventory_usage_rebuild.inv_period_usage
			,temp_inventory_usage_rebuild.scheduled_usage
			,temp_inventory_usage_rebuild.number_of_orders
			,temp_inventory_usage_rebuild.number_of_hits
			,temp_inventory_usage_rebuild.source
			,temp_inventory_usage_rebuild.document_no
			,temp_inventory_usage_rebuild.usage_type
			,temp_inventory_usage_rebuild.trans_date
	FROM	temp_inventory_usage_rebuild
	INNER JOIN temp_inventory_rebuild_items ON (temp_inventory_rebuild_items.inv_mast_uid = temp_inventory_usage_rebuild.inv_mast_uid)
										   AND (temp_inventory_rebuild_items.location_id = temp_inventory_usage_rebuild.location_id)
	INNER JOIN inv_loc dup_inv_loc WITH (NOLOCK) ON (dup_inv_loc.inv_mast_uid = temp_inventory_rebuild_items.inv_mast_uid)
												AND (dup_inv_loc.location_id = temp_inventory_rebuild_items.duplicate_usage_location)
	INNER JOIN demand_period ON (temp_inventory_usage_rebuild.trans_date >= demand_period.beginning_date)
							AND (temp_inventory_usage_rebuild.trans_date < DATEADD(DAY, 1, demand_period.ending_date))
							AND (dup_inv_loc.company_id = demand_period.company_id)
	LEFT JOIN temp_inventory_usage_rebuild temp_rebuild_dup ON (temp_rebuild_dup.inv_mast_uid = dup_inv_loc.inv_mast_uid)
														   AND (temp_rebuild_dup.location_id = dup_inv_loc.location_id)
														   AND (temp_rebuild_dup.source = temp_inventory_usage_rebuild.source)
														   AND (temp_rebuild_dup.document_no = temp_inventory_usage_rebuild.document_no)
														   AND (temp_rebuild_dup.usage_type = temp_inventory_usage_rebuild.usage_type)
	WHERE	temp_rebuild_dup.inv_mast_uid IS NULL'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild_history for push_usage_to_replen_loc'
				GOTO error_return
			END
		END
*/

		SET @ls_SQL = N'
INSERT INTO inv_period_usage_temp
		(location_id
		,demand_period_uid
		,inv_mast_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,date_created
		,last_maintained_by)
   SELECT 	temp_inventory_usage_rebuild.location_id
			,temp_inventory_usage_rebuild.demand_period_uid
			,temp_inventory_usage_rebuild.inv_mast_uid
			,temp_inventory_usage_rebuild.inv_period_usage
			,temp_inventory_usage_rebuild.scheduled_usage'

		IF (@lc_UpdateServiceLevel = 'Y')
			SET @ls_SQL = @ls_SQL + N'
			,temp_inventory_usage_rebuild.number_of_orders
			,temp_inventory_usage_rebuild.number_of_hits'

		ELSE
			SET @ls_SQL = @ls_SQL + N'
			,0
			,0'

		SET @ls_SQL = @ls_SQL + N'
			,''' + CAST(@ld_current_timestamp AS NVARCHAR(MAX)) + N'''
			,''p21_rebuild_inventory_usage''
	FROM	temp_inventory_usage_rebuild
	LEFT JOIN inv_period_usage WITH (NOLOCK) ON (inv_period_usage.demand_period_uid = temp_inventory_usage_rebuild.demand_period_uid)
											AND (inv_period_usage.inv_mast_uid = temp_inventory_usage_rebuild.inv_mast_uid)
											AND (inv_period_usage.location_id = temp_inventory_usage_rebuild.location_id)
											AND (COALESCE(inv_period_usage.imported, ''N'') = ''Y'')
	WHERE	inv_period_usage.inv_period_usage_uid IS NULL'

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into inv_period_usage_temp'
			GOTO error_return
		END

		IF (@ai_Debug & 8 > 0)
		BEGIN
			SELECT 'SELECT into inv_period_usage_temp'

			SELECT	*
			FROM	temp_inventory_usage_rebuild
		END

		SET @ls_SQL = N'
INSERT INTO temp_inventory_usage_rebuild_history
		(location_id
		,demand_period_uid
		,inv_mast_uid
		,inv_period_usage
		,scheduled_usage
		,number_of_orders
		,number_of_hits
		,source
		,document_no
		,date_created
		,last_maintained_by)
   SELECT 	temp_inventory_usage_rebuild.location_id
			,temp_inventory_usage_rebuild.demand_period_uid
			,temp_inventory_usage_rebuild.inv_mast_uid
			,temp_inventory_usage_rebuild.inv_period_usage
			,temp_inventory_usage_rebuild.scheduled_usage'

		IF (@lc_UpdateServiceLevel = 'Y')
			SET @ls_SQL = @ls_SQL + N'
			,temp_inventory_usage_rebuild.number_of_orders
			,temp_inventory_usage_rebuild.number_of_hits'

		ELSE
			SET @ls_SQL = @ls_SQL + N'
			,0
			,0'

		SET @ls_SQL = @ls_SQL + N'
			,temp_inventory_usage_rebuild.source
			,temp_inventory_usage_rebuild.document_no
			,''' + CAST(@ld_current_timestamp AS NVARCHAR(MAX)) + N'''
			,CURRENT_USER
	FROM	temp_inventory_usage_rebuild
	LEFT JOIN inv_period_usage WITH (NOLOCK) ON (inv_period_usage.demand_period_uid = temp_inventory_usage_rebuild.demand_period_uid)
											AND (inv_period_usage.inv_mast_uid = temp_inventory_usage_rebuild.inv_mast_uid)
											AND (inv_period_usage.location_id = temp_inventory_usage_rebuild.location_id)
											AND (COALESCE(inv_period_usage.imported, ''N'') = ''Y'')
	WHERE	inv_period_usage.inv_period_usage_uid IS NULL'

		IF (@ai_Debug & 2 > 0)
			SELECT @ls_SQL

		IF (@ai_Debug & 1 > 0)
			EXECUTE (@ls_SQL)

		SELECT @error = @@ERROR
		IF (@error <> 0)
		BEGIN
			SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing INSERT into temp_inventory_usage_rebuild_history'
			GOTO error_return
		END
	END
	
	IF (@ai_Debug & 1 > 0)
		COMMIT TRANSACTION

	IF (@ReportValues <> 'Y' AND (@ai_SectiontoExecute & 1 > 0 OR @ai_SectiontoExecute & 2 > 0 OR @ai_SectiontoExecute & 4 > 0))
	BEGIN
		IF (@ReportValues = 'S')
		BEGIN
			SET @ls_SQL = N'
WITH CTE_usage (inv_mast_uid, location_id, demand_period_uid, inv_period_usage, scheduled_usage, number_of_orders, number_of_hits)
AS
(
SELECT	inv_mast_uid
		,location_id
		,demand_period_uid
		,SUM(COALESCE(inv_period_usage, 0)) inv_period_usage
		,SUM(COALESCE(scheduled_usage, 0)) scheduled_usage
		,SUM(COALESCE(number_of_orders, 0)) number_of_orders
		,SUM(COALESCE(number_of_hits, 0)) number_of_hits
FROM	temp_inventory_usage_rebuild
GROUP BY inv_mast_uid
		,location_id
		,demand_period_uid
)
	SELECT	inv_mast.item_id
			,CTE_usage.location_id
			,demand_period.year_for_period
			,demand_period.period'

			IF (@ai_SectiontoExecute & 1 > 0)
				SET @ls_SQL = @ls_SQL + N'
			,inv_period_usage.inv_period_usage current_usage
			,CTE_usage.inv_period_usage new_usage
			,inv_period_usage.scheduled_usage current_scheduled_usage
			,CTE_usage.scheduled_usage new_scheduled_usage'

			IF (@lc_UpdateServiceLevel = 'Y')
			BEGIN
				IF (@ai_SectiontoExecute & 2 > 0)
					SET @ls_SQL = @ls_SQL + N'
			,inv_period_usage.number_of_orders current_number_of_orders
			,CTE_usage.number_of_orders new_number_of_orders'

				IF (@ai_SectiontoExecute & 4 > 0)
					SET @ls_SQL = @ls_SQL + N'
			,inv_period_usage.number_of_hits current_number_of_hits
			,CTE_usage.number_of_hits new_number_of_hits'
			END

			SET @ls_SQL = @ls_SQL + N'
	FROM	CTE_usage
	INNER JOIN inv_mast WITH (NOLOCK) ON (inv_mast.inv_mast_uid = CTE_usage.inv_mast_uid)
	INNER JOIN demand_period WITH (NOLOCK) ON (demand_period.demand_period_uid = CTE_usage.demand_period_uid)
	LEFT JOIN inv_period_usage WITH (NOLOCK) ON (inv_period_usage.demand_period_uid = CTE_usage.demand_period_uid)
											AND (inv_period_usage.inv_mast_uid = CTE_usage.inv_mast_uid)
											AND (inv_period_usage.location_id = CTE_usage.location_id)
	WHERE	(CTE_usage.inv_period_usage <> inv_period_usage.inv_period_usage
	   OR	CTE_usage.scheduled_usage <> inv_period_usage.scheduled_usage
	   OR	CTE_usage.number_of_orders <> inv_period_usage.number_of_orders
	   OR	CTE_usage.number_of_hits <> inv_period_usage.number_of_hits)

	ORDER BY inv_mast.item_id
			,CTE_usage.location_id
			,demand_period.year_for_period
			,demand_period.period'

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing SELECT from temp_inventory_usage_rebuild'
				GOTO error_return
			END
		END

		IF (@ReportValues = 'D')
		BEGIN
			IF (@ai_SectiontoExecute & 1 > 0)
			BEGIN
				SET @ls_SQL = N'
WITH CTE_usage (inv_mast_uid, location_id, demand_period_uid, inv_period_usage, scheduled_usage)
AS
(
SELECT	inv_mast_uid
		,location_id
		,demand_period_uid
		,SUM(COALESCE(inv_period_usage, 0)) inv_period_usage
		,SUM(COALESCE(scheduled_usage, 0)) scheduled_usage
FROM	temp_inventory_usage_rebuild
GROUP BY inv_mast_uid
		,location_id
		,demand_period_uid
)
	SELECT	inv_mast.item_id
			,CTE_usage.location_id
			,demand_period.year_for_period
			,demand_period.period
			,inv_period_usage.inv_period_usage current_usage
			,CTE_usage.inv_period_usage new_total_usage
			,temp_inventory_usage_rebuild.inv_period_usage new_transaction_usage
			,inv_period_usage.scheduled_usage current_scheduled_usage
			,CTE_usage.scheduled_usage new_total_scheduled_usage
			,temp_inventory_usage_rebuild.scheduled_usage new_transaction_scheduled_usage
			,CASE temp_inventory_usage_rebuild.[source]
				WHEN 951 THEN
					oe_line.order_no
				WHEN 995 THEN
					invoice_line.invoice_no
				WHEN 980 THEN
					CAST(prod_order_line_component.prod_order_number AS VARCHAR(255))
				WHEN 979 THEN
					CAST(inventory_receipts_line.receipt_number AS VARCHAR(255))
				WHEN 814 THEN
					CAST(process_x_transaction.transaction_no AS VARCHAR(255))
				ELSE
					''Other''
			 END transaction_number
			,CASE temp_inventory_usage_rebuild.[source]
				WHEN 951 THEN
					oe_line.line_no
				WHEN 995 THEN
					invoice_line.line_no
				WHEN 980 THEN
					prod_order_line_component.line_number
				WHEN 979 THEN
					inventory_receipts_line.line_number
				WHEN 814 THEN
					process_x_transaction.transaction_line_no
				ELSE
					0
			 END transaction_line_number
			,CASE temp_inventory_usage_rebuild.[source]
				WHEN 951 THEN
					''Order''
				WHEN 995 THEN
					''Invoice''
				WHEN 980 THEN
					''Production Order''
				WHEN 979 THEN
					''Transfer Receipt''
				WHEN 814 THEN
					''Secondary Process''
				ELSE
					''Other''
			 END transaction_type
	FROM	CTE_usage
	INNER JOIN temp_inventory_usage_rebuild ON (temp_inventory_usage_rebuild.demand_period_uid = CTE_usage.demand_period_uid)
										   AND (temp_inventory_usage_rebuild.inv_mast_uid = CTE_usage.inv_mast_uid)
										   AND (temp_inventory_usage_rebuild.location_id = CTE_usage.location_id)
										   AND (temp_inventory_usage_rebuild.usage_type = 1)
	INNER JOIN inv_mast WITH (NOLOCK) ON (inv_mast.inv_mast_uid = CTE_usage.inv_mast_uid)
	INNER JOIN demand_period WITH (NOLOCK) ON (demand_period.demand_period_uid = CTE_usage.demand_period_uid)
	LEFT JOIN inv_period_usage WITH (NOLOCK) ON (inv_period_usage.demand_period_uid = CTE_usage.demand_period_uid)
											AND (inv_period_usage.inv_mast_uid = CTE_usage.inv_mast_uid)
											AND (inv_period_usage.location_id = CTE_usage.location_id)
	LEFT JOIN oe_line WITH (NOLOCK) ON (oe_line.oe_line_uid = temp_inventory_usage_rebuild.document_no)
	LEFT JOIN invoice_line WITH (NOLOCK) ON (invoice_line.invoice_line_uid = temp_inventory_usage_rebuild.document_no)
	LEFT JOIN prod_order_line_component WITH (NOLOCK) ON (prod_order_line_component_uid = temp_inventory_usage_rebuild.document_no)
	LEFT JOIN inventory_receipts_line WITH (NOLOCK) ON (inventory_receipts_line.inventory_receipts_line_uid = temp_inventory_usage_rebuild.document_no)
	LEFT JOIN process_x_transaction WITH (NOLOCK) ON (process_x_transaction.process_x_transaction_uid = temp_inventory_usage_rebuild.document_no)
	WHERE	(CTE_usage.inv_period_usage <> inv_period_usage.inv_period_usage
	   OR	CTE_usage.scheduled_usage <> inv_period_usage.scheduled_usage)
	ORDER BY inv_mast.item_id
			,CTE_usage.location_id
			,demand_period.year_for_period
			,demand_period.period'

				IF (@ai_Debug & 2 > 0)
					SELECT @ls_SQL

				IF (@ai_Debug & 1 > 0)
					EXECUTE (@ls_SQL)

				SELECT @error = @@ERROR
				IF (@error <> 0)
				BEGIN
					SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing SELECT from temp_inventory_usage_rebuild'
					GOTO error_return
				END
			END

			IF (@ai_SectiontoExecute & 2 > 0 OR @ai_SectiontoExecute & 4 > 0)
			BEGIN
				SET @ls_SQL = N'
WITH CTE_usage (inv_mast_uid, location_id, demand_period_uid'

				IF (@ai_SectiontoExecute & 2 > 0) 
					SET @ls_SQL = @ls_SQL + N', number_of_orders'

				IF (@ai_SectiontoExecute & 4 > 0) 
					SET @ls_SQL = @ls_SQL + N', number_of_hits'

				SET @ls_SQL = @ls_SQL + N')
AS
(
SELECT	inv_mast_uid
		,location_id
		,demand_period_uid'

				IF (@ai_SectiontoExecute & 2 > 0) 
					SET @ls_SQL = @ls_SQL + N'
		,SUM(COALESCE(number_of_orders, 0)) number_of_orders'

				IF (@ai_SectiontoExecute & 4 > 0) 
					SET @ls_SQL = @ls_SQL + N'
		,SUM(COALESCE(number_of_hits, 0)) number_of_hits'

				SET @ls_SQL = @ls_SQL + N'
FROM	temp_inventory_usage_rebuild
GROUP BY inv_mast_uid
		,location_id
		,demand_period_uid
)
	SELECT	inv_mast.item_id
			,CTE_usage.location_id
			,demand_period.year_for_period
			,demand_period.period'

				IF (@ai_SectiontoExecute & 2 > 0) 
					SET @ls_SQL = @ls_SQL + N'
			,inv_period_usage.number_of_orders current_number_of_orders
			,CTE_usage.number_of_orders new_number_of_orders
			,temp_inventory_usage_rebuild.number_of_orders new_number_of_orders'

				IF (@ai_SectiontoExecute & 4 > 0) 
					SET @ls_SQL = @ls_SQL + N'
			,inv_period_usage.number_of_hits current_number_of_hits
			,CTE_usage.number_of_hits new_number_of_hits
			,temp_inventory_usage_rebuild.number_of_hits new_number_of_hits'

				SET @ls_SQL = @ls_SQL + N'
			,oe_line.order_no transaction_number
			,oe_line.line_no transaction_line_number
			,''Order'' transaction_type
	FROM	CTE_usage
	INNER JOIN temp_inventory_usage_rebuild ON (temp_inventory_usage_rebuild.demand_period_uid = CTE_usage.demand_period_uid)
										   AND (temp_inventory_usage_rebuild.inv_mast_uid = CTE_usage.inv_mast_uid)
										   AND (temp_inventory_usage_rebuild.location_id = CTE_usage.location_id)
										   AND (temp_inventory_usage_rebuild.usage_type IN (2, 3))
	INNER JOIN inv_mast WITH (NOLOCK) ON (inv_mast.inv_mast_uid = CTE_usage.inv_mast_uid)
	INNER JOIN demand_period WITH (NOLOCK) ON (demand_period.demand_period_uid = CTE_usage.demand_period_uid)
	LEFT JOIN inv_period_usage WITH (NOLOCK) ON (inv_period_usage.demand_period_uid = CTE_usage.demand_period_uid)
											AND (inv_period_usage.inv_mast_uid = CTE_usage.inv_mast_uid)
											AND (inv_period_usage.location_id = CTE_usage.location_id)
	LEFT JOIN oe_line WITH (NOLOCK) ON (oe_line.oe_line_uid = temp_inventory_usage_rebuild.document_no)
	WHERE	(CTE_usage.number_of_orders <> inv_period_usage.number_of_orders
	   OR	CTE_usage.number_of_hits <> inv_period_usage.number_of_hits)
	ORDER BY inv_mast.item_id
			,CTE_usage.location_id
			,demand_period.year_for_period
			,demand_period.period'
					
			END

			IF (@ai_Debug & 2 > 0)
				SELECT @ls_SQL

			IF (@ai_Debug & 1 > 0)
				EXECUTE (@ls_SQL)

			SELECT @error = @@ERROR
			IF (@error <> 0)
			BEGIN
				SELECT @msg = @msg + 'Error ' + LTRIM(STR(@error)) + ' when performing SELECT from temp_inventory_usage_rebuild'
				GOTO error_return
			END
		END
	END

    RETURN 0

	error_return:
		IF (@ai_Debug & 1 > 0)
			ROLLBACK TRANSACTION

   		RAISERROR (@msg,16,1)
		RETURN 1

END

--$Author: Bernie.pomidor $
--$Date: 6/18/21 3:01p $
--$Revision: 55 $
--$Log: /Server/CommerceCenter/Z_Polecat (20.2)/Stored Procedures/p21_rebuild_inventory_usage.sql $
-- 
-- 55    6/18/21 3:01p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix prod order join
-- b020_002_056295
-- 
-- 54    1/21/21 4:52p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- add missing join
-- b020_002_055573
-- 
-- 52    8/18/20 6:29p Bernie.pomidor
-- DBA: BGP
-- DEV: IHS
-- add ship to location
-- b020_001_054657
-- 
-- 51    7/28/20 3:21p Jesus.lopez
-- DEV: JLB
-- DBA: JEL
-- Scopus 1419809: Modify p21_rebiuld_inventory_usage to account for
-- capture usage at the assembly or process transaction level
-- b019_002_054532.sql
-- 
-- 49    7/17/19 11:47a Bernie.pomidor
-- DBA: BGP
-- DEV: IHS
-- add inv_loc dup_item
-- b019_001_052117b
-- 
-- 48    6/26/19 2:52p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix direct ship restriction
-- b019_001_052027
-- 
-- 47    5/15/19 11:15a Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- add imported usage flag
-- b019_001_051770b
-- 
-- 45    3/31/19 6:24p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix timezone
-- b018_002_051346cw
-- 
-- 44    8/09/18 4:18p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- add report option
-- b018_001_050027
-- 
-- 42    3/31/17 5:22p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix multi company
-- b012_017_046192c
-- 
-- 41    2/08/17 10:21a Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- add multi company for usage push
-- b012_017_046192b
-- 
-- 39    1/11/16 9:14a Jorge.villanueva
-- DBA: J.Villanueva
-- Feature 61702: Modify stored procedure to handle pushing usage to
-- another item
-- B012_016_043868
-- 
-- 37    11/23/15 2:39p Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- add location usage column
-- b012_016_043680d
-- 
-- 36    11/10/15 2:53p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix duplicate transfer rows
-- b012_015_043562b
-- 
-- 35    8/31/15 9:51a Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix supplier join
-- b012_015_043082c
-- 
-- 34    8/27/15 4:38p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- move record_usage_actual_loc_flag to inventory_supplier
-- b012_015_043082b
-- 
-- 33    8/07/15 5:35p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix use_ideal_location_in_usage_rebuild logic
-- b012_015_043082a
-- 
-- 32    7/30/15 5:34p Bernie.pomidor
-- DBA: BGP
-- DEV: JCL
-- add ideal_location
-- b012_015_043010
-- 
-- 31    9/08/14 4:11p Bernie.pomidor
-- same
-- 
-- 30    9/08/14 10:55a Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- retag script for 12.14
-- b012_014_040633
-- 
-- 29    9/08/14 10:48a Bernie.pomidor
-- DBA: BGP
-- DEV: LC
-- add transfer usage rebuild
-- b012_014_036641
-- 
-- 28    8/20/14 4:28p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- skip scheduled usage for lost sales at OE
-- b012_014_040497
-- 
-- 27    5/21/14 4:57p Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- add check for push_usage_to_replen_loc
-- b012_013_039791b
-- 
-- 25    3/05/13 3:09p Bernie.pomidor
-- DBA: BGP
-- DEV: JBH
-- add consignment logic
-- b012_011_036551
-- 
-- 23    8/21/12 4:58p Bridgitte.hoganperry
-- Update objects to 2012 syntax of RAISERROR
-- dev:bhp
-- b012_010_035290 family
-- 
-- 21    3/07/12 3:15p Bernie.pomidor
-- same
-- 
-- 20    3/06/12 10:53a Bernie.pomidor
-- same
-- 
-- 19    2/27/12 2:49p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- add lost sales
-- b012_007_034056
-- 
-- 18    2/06/12 4:59p Bernie.pomidor
-- same
-- 
-- 17    11/16/11 2:09p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix scheduled
-- b012_007_033348
-- 
-- 15    12/08/10 3:27p Bernie.pomidor
-- same
-- 
-- 14    11/18/10 10:52a Bernie.pomidor
-- same
-- 
-- 13    11/11/10 2:08p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix direct ship at order
-- ara030917
-- 
-- 12    3/24/10 11:30a Bernie.pomidor
-- same
-- 
-- 11    3/22/10 3:52p Bernie.pomidor
-- same
-- 
-- 10    3/18/10 3:20p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- fix service level
-- ara029159
-- 
-- 7     6/16/09 4:48p Bridgitte.hoganperry
-- aoa026874f
-- 
-- 6     4/22/09 4:42p Bernie.pomidor
-- same
-- 
-- 5     4/22/09 3:25p Bernie.pomidor
-- same
-- 
-- 4     4/22/09 3:04p Bernie.pomidor
-- same
-- 
-- 3     4/15/09 4:01p Bernie.pomidor
-- same
-- 
-- 2     4/15/09 3:31p Bernie.pomidor
-- same
-- 
-- 1     4/08/09 2:36p Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- rebuild usage proc
-- aoa026874
-- 
GO



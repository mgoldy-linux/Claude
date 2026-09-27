USE [P21Training]
GO

/****** Object:  Trigger [dbo].[t_inv_period_usage_temp_i]    Script Date: 9/27/2026 11:00:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE TRIGGER [dbo].[t_inv_period_usage_temp_i] ON [dbo].[inv_period_usage_temp] FOR INSERT
AS

BEGIN  
	 IF (@@rowcount = 0)     
		RETURN
		
	SET NOCOUNT ON

	DECLARE @temp						INTEGER
	DECLARE @CombineScheduledUsage		CHAR(1)
	DECLARE @push_usage_to_replen_loc	CHAR(1)
	-- 12/21/15 - J.Villanueva - 12.17 Feature: 61702 Duplicate item usage on referenced item by inv_mast.inv_mast_uid_dup_usage
	DECLARE @push_usage_to_dup_item		CHAR(1)

	-- 4/1/19 - P21CD-14008 Modify Triggers for Timezone feature to use @current_timestamp variable
	DECLARE @ld_current_timestamp datetime 

	SET @ld_current_timestamp = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP,NULL,NULL)
		
	DECLARE @holding TABLE
	(location_id			DECIMAL(19,0)
	,inv_mast_uid			INTEGER
	,demand_period_uid		INTEGER
	,date_last_modified		DATETIME
	,last_maintained_by 	VARCHAR(30)
	,inv_period_usage		DECIMAL(19,9)
	,scheduled_usage		DECIMAL(19,9)
	,number_of_hits			DECIMAL(19,9)
	,number_of_orders		DECIMAL(19,0)
	,replenishment_location	INTEGER
    ,inv_mast_uid_dup_usage	INTEGER)

	-- JRL 09/14/12 - Retrieve system setting info for push_usage_to_replen_loc
	SELECT	@CombineScheduledUsage = COALESCE(track_scheduled_usage_with_usage.value, 'N')
			,@push_usage_to_replen_loc = COALESCE(push_usage_to_replen_loc.value, 'N')
			,@push_usage_to_dup_item = COALESCE(push_usage_to_dup_item.value, 'N')
	FROM	(SELECT 1 dummy) AS dummy	
	LEFT JOIN system_setting track_scheduled_usage_with_usage  WITH (NOLOCK) ON (track_scheduled_usage_with_usage.name = 'track_scheduled_usage_with_usage')
	LEFT JOIN system_setting push_usage_to_replen_loc  WITH (NOLOCK) ON (push_usage_to_replen_loc.name = 'push_usage_to_replen_loc')
	LEFT JOIN system_setting push_usage_to_dup_item WITH (NOLOCK) ON (push_usage_to_dup_item.name = 'push_usage_to_dup_item')

	IF (@push_usage_to_replen_loc = 'Y')
	BEGIN
		INSERT INTO @holding
				(location_id
				,inv_mast_uid
				,demand_period_uid
				,date_last_modified
				,last_maintained_by
				,inv_period_usage
				,scheduled_usage
				,number_of_hits
				,number_of_orders
				,replenishment_location)  
			SELECT	inserted.location_id
					,inserted.inv_mast_uid
					,inserted.demand_period_uid
					,MAX(inserted.date_created)
					,MAX(inserted.last_maintained_by)
					,SUM(inserted.inv_period_usage)
					,SUM(inserted.scheduled_usage)
					,SUM(inserted.number_of_hits)
					,SUM(inserted.number_of_orders)
					,MIN(COALESCE(replen_location.location_id, inserted.location_id))  
			FROM	inserted
			INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = inserted.inv_mast_uid)
											AND (inv_loc.location_id = inserted.location_id)
			LEFT JOIN inv_loc replen_location  WITH (NOLOCK) ON (replen_location.location_id = inv_loc.replenishment_location)
															AND (replen_location.inv_mast_uid = inv_loc.inv_mast_uid)
			GROUP BY inserted.location_id
					,inserted.inv_mast_uid
					,inserted.demand_period_uid
	END
	ELSE
	BEGIN
		INSERT INTO @holding
				(location_id
				,inv_mast_uid
				,demand_period_uid
				,date_last_modified
				,last_maintained_by
				,inv_period_usage
				,scheduled_usage
				,number_of_hits 
				,number_of_orders
				,replenishment_location)  
			SELECT	inserted.location_id
					,inserted.inv_mast_uid
					,inserted.demand_period_uid
					,MAX(inserted.date_created)
					,MAX(inserted.last_maintained_by)
					,SUM(inserted.inv_period_usage)
					,SUM(inserted.scheduled_usage)
					,SUM(inserted.number_of_hits)
					,SUM(inserted.number_of_orders)
					,inserted.location_id
			FROM	inserted
			GROUP BY inserted.location_id
					,inserted.inv_mast_uid
					,inserted.demand_period_uid  
	END
 
	--
	-- If it's new, insert it
	-- 
		
	INSERT INTO inv_period_usage
		(inv_mast_uid
		,location_id
		,forecast_usage
		,forecast_deviation_percentage
		,mad_percentage
		,filtered_usage
		,inv_period_usage
		,edited
		,scheduled_usage
		,date_created
		,date_last_modified
		,last_maintained_by
		,number_of_orders
		,number_of_hits
		,demand_period_uid
	-- 11/23/15 - JRL - F62441 - Add inv_period_usage_this_location
		,inv_period_usage_this_location)
	SELECT	h.inv_mast_uid
			,h.location_id
			,0 forecast_usage
			,0 forecast_deviation_percentage
			,0 mad_percentage
			,0 filtered_usage
			,0
			,'N' edited
			,0
			,0
			,h.date_last_modified
			,0
			,0
			,0
			,h.demand_period_uid
			,0
	FROM	
		@holding h
		left outer join inv_period_usage ON 
			(h.location_id = inv_period_usage.location_id)
			AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)
			AND (h.demand_period_uid = inv_period_usage.demand_period_uid)
	where
		inv_period_usage.location_id is null

	--
	-- Update the info from the table.
	--

	UPDATE	
		inv_period_usage
	SET

		date_last_modified = h.date_last_modified
		,last_maintained_by = h.last_maintained_by
		,inv_period_usage = CASE	WHEN @CombineScheduledUsage = 'Y' THEN
										inv_period_usage.inv_period_usage + h.inv_period_usage + h.scheduled_usage
									ELSE
										inv_period_usage.inv_period_usage + h.inv_period_usage
							END
		,scheduled_usage = CASE	WHEN @CombineScheduledUsage = 'Y' THEN
									inv_period_usage.scheduled_usage
								ELSE
									inv_period_usage.scheduled_usage + h.scheduled_usage
							END
		,number_of_hits = inv_period_usage.number_of_hits + h.number_of_hits
		,number_of_orders = inv_period_usage.number_of_orders + h.number_of_orders
		-- 11/23/15 - JRL - F62441 - Add inv_period_usage_this_location
		,inv_period_usage_this_location = CASE	WHEN @CombineScheduledUsage = 'Y' THEN
														Coalesce(inv_period_usage.inv_period_usage_this_location,0) + h.inv_period_usage + h.scheduled_usage
													ELSE
														Coalesce(inv_period_usage.inv_period_usage_this_location,0) + h.inv_period_usage
											END
	FROM
		@holding h
		INNER JOIN inv_period_usage ON (h.location_id = inv_period_usage.location_id)
								AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)
								AND (h.demand_period_uid = inv_period_usage.demand_period_uid)

 	-- 01/16/17 - JRL - SCOPUS #1400824  - 12.17 0 - If push_usage_to_replen_loc or push_usage_to_dup_item is enabled, use the demand_period_uid of the target location 
	-- b/c it may be from another company. 
	IF (@push_usage_to_replen_loc = 'Y')
	BEGIN
		UPDATE	h
		SET		h.demand_period_uid = demand_period_new_company.demand_period_uid
		FROM	@holding h
		INNER JOIN location source_loc WITH (NOLOCK) ON	(source_loc.location_id = h.location_id)
		INNER JOIN location target_loc WITH (NOLOCK) ON	(target_loc.location_id = h.replenishment_location)
													AND (target_loc.company_id <> source_loc.company_id)
		LEFT JOIN demand_period demand_period_new_company WITH (NOLOCK) ON (demand_period_new_company.company_id = target_loc.company_id)
																		AND (@ld_current_timestamp  >= demand_period_new_company.beginning_date)
																		AND (@ld_current_timestamp  < DATEADD(DAY, 1, demand_period_new_company.ending_date))
		WHERE	h.location_id <> h.replenishment_location
	
		DELETE
		FROM	@holding
		WHERE	demand_period_uid IS NULL

		INSERT INTO inv_period_usage  
				(inv_mast_uid  
				,location_id  
				,forecast_usage  
				,forecast_deviation_percentage  
				,mad_percentage  
				,filtered_usage  
				,inv_period_usage  
				,edited  
				,scheduled_usage  
				,date_created  
				,date_last_modified  
				,last_maintained_by  
				,number_of_orders  
				,number_of_hits  
				,demand_period_uid
				-- 11/23/15 - JRL - F62441 - Add inv_period_usage_this_location
				,inv_period_usage_this_location) 
			SELECT	DISTINCT h.inv_mast_uid  
					,h.replenishment_location 
					,0 forecast_usage  
					,0 forecast_deviation_percentage  
					,0 mad_percentage  
					,0 filtered_usage  
					,0  
					,'N' edited  
					,0  
					,0  
					,h.date_last_modified  
					,0  
					,0  
					,0  
					,h.demand_period_uid  
					,0
			FROM	@holding h  
			left outer join inv_period_usage ON   
			(h.replenishment_location = inv_period_usage.location_id)  
			AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)  
			AND (h.demand_period_uid = inv_period_usage.demand_period_uid)  
			where	inv_period_usage.location_id is null
			and h.replenishment_location <> h.location_id  
			-- 11/12/12 - JRL - F52506 / SC 1095106 - We should ONLY be updating the hub location when inv_period_usage or scheduled_usage <> 0
			-- 11/12/12 - JRL - F52506 / SC 1095106 - We should NOT be pushing number_of_hits or number_of_orders to the hub location
			and (h.inv_period_usage <> 0 or h.scheduled_usage <> 0)

		--  
		-- Update the info from the table.  
		--  

		-- 10/21/16 - JRL - SCOPUS #1399681 / SN#CS0000093492 - Need to account for multiple inserts for the same inv_mast_uid, location_id, 
		-- replenishment_location, and demand_period_uid
		UPDATE inv_period_usage
		SET		inv_period_usage = inv_period_usage.inv_period_usage + drv_usage.inv_period_usage
     			,scheduled_usage = inv_period_usage.scheduled_usage + drv_usage.scheduled_usage
     			,date_last_modified = drv_usage.date_last_modified
     			,last_maintained_by = drv_usage.last_maintained_by
		FROM	inv_period_usage
		INNER JOIN (SELECT 	SUM(CASE	WHEN @CombineScheduledUsage = 'Y' THEN
											h.inv_period_usage + h.scheduled_usage      
										ELSE
											h.inv_period_usage      
								END) inv_period_usage
	   						,SUM(CASE	WHEN @CombineScheduledUsage = 'Y' THEN
											0 
										ELSE
											h.scheduled_usage      
								END) scheduled_usage
	  						,h.replenishment_location
	  						,h.inv_mast_uid
	  						,h.demand_period_uid
	  						,MAX(h.last_maintained_by) last_maintained_by
	  						,MAX(h.date_last_modified) date_last_modified
  					FROM	@holding h      
  					INNER JOIN inv_period_usage ON (h.replenishment_location = inv_period_usage.location_id)      
  						AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)      
  						AND (h.demand_period_uid = inv_period_usage.demand_period_uid)     
  					WHERE (h.replenishment_location <> h.location_id)   
  					GROUP BY h.replenishment_location, h.inv_mast_uid,h.demand_period_uid) drv_usage ON drv_usage.inv_mast_uid = inv_period_usage.inv_mast_uid 
																									AND drv_usage.replenishment_location = inv_period_usage.location_id
																									AND drv_usage.demand_period_uid = inv_period_usage.demand_period_uid
	END

	-- 12/21/15 - J.Villanueva - 12.17 Feature: 61702 Duplicate item usage on referenced item by inv_mast.inv_mast_uid_dup_usage
	IF (@push_usage_to_dup_item = 'Y')
	BEGIN
		
		UPDATE	holding
		SET		inv_mast_uid_dup_usage = COALESCE(inv_loc.inv_mast_uid_dup_usage, inv_mast.inv_mast_uid_dup_usage)
		FROM	@holding AS holding
		INNER JOIN inv_mast WITH (NOLOCK) ON (inv_mast.inv_mast_uid = holding.inv_mast_uid)
		INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = holding.inv_mast_uid)
									    AND (inv_loc.location_id = holding.location_id)
		WHERE	COALESCE(inv_loc.inv_mast_uid_dup_usage, inv_mast.inv_mast_uid_dup_usage) IS NOT NULL

		--
		-- If it's new, insert it
		-- 
		
		INSERT INTO inv_period_usage
			(inv_mast_uid
			,location_id
			,forecast_usage
			,forecast_deviation_percentage
			,mad_percentage
			,filtered_usage
			,inv_period_usage
			,edited
			,scheduled_usage
			,date_created
			,date_last_modified
			,last_maintained_by
			,number_of_orders
			,number_of_hits
			,demand_period_uid) 
		SELECT	h.inv_mast_uid_dup_usage
				,h.location_id
				,0 forecast_usage
				,0 forecast_deviation_percentage
				,0 mad_percentage
				,0 filtered_usage
				,0
				,'N' edited
				,0
				,0
				,h.date_last_modified
				,0
				,0
				,0
				,h.demand_period_uid
		FROM	
			@holding h
			left outer join inv_period_usage ON 
				(h.location_id = inv_period_usage.location_id)
				AND (h.inv_mast_uid_dup_usage = inv_period_usage.inv_mast_uid)
				AND (h.demand_period_uid = inv_period_usage.demand_period_uid)
		WHERE
			inv_period_usage.location_id is NULL
			AND h.inv_mast_uid_dup_usage IS NOT NULL
			AND (h.inv_period_usage <> 0 or h.scheduled_usage <> 0)

		--
		-- Update the info from the table.
		--

		UPDATE	
			inv_period_usage
		SET

			date_last_modified = h.date_last_modified
			,last_maintained_by = h.last_maintained_by
			,inv_period_usage = CASE	WHEN @CombineScheduledUsage = 'Y' THEN
											inv_period_usage.inv_period_usage + h.inv_period_usage + h.scheduled_usage
										ELSE
											inv_period_usage.inv_period_usage + h.inv_period_usage
								END
			,scheduled_usage = CASE	WHEN @CombineScheduledUsage = 'Y' THEN
										inv_period_usage.scheduled_usage
									ELSE
										inv_period_usage.scheduled_usage + h.scheduled_usage
							   END
		FROM
			@holding h
			INNER JOIN inv_period_usage ON (h.location_id = inv_period_usage.location_id)
								   AND (h.inv_mast_uid_dup_usage = inv_period_usage.inv_mast_uid)
								   AND (h.demand_period_uid = inv_period_usage.demand_period_uid)


	END
END


--$Author: Bernie.pomidor $
--$Revision: 31 $
--$Date: 7/17/19 11:45a $
--$Log: /Server/CommerceCenter/Z_Narwhal (19.2)/Triggers/t_inv_period_usage_temp_i .sql $
-- 
-- 31    7/17/19 11:45a Bernie.pomidor
-- DBA: BGP
-- DEV: IHS
-- Add inv_loc dup_item
-- b019_001_052117a
-- 
-- 30    4/01/19 10:15p Bridgitte.hoganperry
-- Feature P21CD-14008: Modify Triggers for Timezone feature to use
-- @current_timestamp variable
-- dev:bhp
-- b018_002_051345.sql
-- 
-- 29    8/26/18 11:42p Bridgitte.hoganperry
-- Feature 69545: Modify trigger for new timezone funtionality
-- dev:syunus
-- b018_002_050037.sql (family)
-- 
-- 27    2/08/17 9:56a Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- add multi company for usage push
-- b012_017_046192a
-- 
-- 26    11/30/16 10:58a Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- fix replenishment update
-- b012_017_045730a
-- 
-- 25    10/24/16 9:54a Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- fix multi row insert
-- b012_017_045730
-- 
-- 24    1/04/16 10:26p Jorge.villanueva
-- DBA: J.Villanueva
-- Feature 61702: Modify t_inv_period_usage_temp_i to push usage to
-- another item when push_usage_to_dup_item setting is enabled
-- B012_017_043820
-- 
-- 21    11/23/15 2:38p Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- add location usage column
-- b012_016_043680b
-- 
-- 19    7/11/13 10:47a Chad.dinerman
-- DBA: CMD
-- Fixed Deprecated NOLOCK Syntax
-- 
-- 18    11/12/12 2:38p Bernie.pomidor
-- same
-- 
-- 17    10/03/12 5:16p Bernie.pomidor
-- same
-- 
-- 16    10/03/12 5:12p Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- new system setting logic
-- b012_009_035585
-- 
-- 14    11/15/11 11:21a Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- add system setting for scheduled usage
-- b012_007_033348
-- 
-- 11    4/08/09 11:41a Bernie.pomidor
-- DBA: BGP
-- DEV: BGP
-- remove instead of
-- aoa026874
-- 
-- 9     8/06/04 5:25p Chad_dinerman
-- 
-- 8     8/06/04 5:20p Chad_dinerman
-- ama009068a 
-- dev:chad_dinerman
-- Performance / Concurrancy improvement
-- 
-- 7     4/01/04 12:15p Bernie_pomidor
-- DBA: BGP
-- DEV: BGP
-- fix identity issues
-- ala008085
-- 
-- 6     3/31/04 4:47p Bernie_pomidor
-- DBA: BGP
-- DEV: BGP
-- remove counter script
-- ala008085.sql
-- 
-- 5     10/31/03 10:34 Kevin_gottschalk
-- DBA: KEG
-- DEV: KEG
-- Remove DELETE at the end of the trigger and change to an INSTEAD OF
-- trigger, so that the row doesn't actually ever get inserted into the
-- table.
-- Script: ala007053a
-- 
-- 3     3/07/03 3:10p Bernie_pomidor
-- DBA: BGP
-- Add missing comment block
GO

ALTER TABLE [dbo].[inv_period_usage_temp] ENABLE TRIGGER [t_inv_period_usage_temp_i]
GO


CREATE PROCEDURE [ssb].[inv_period_usage_temp_process_i]
@trig_uid	UNIQUEIDENTIFIER
AS
SET NOCOUNT ON 
BEGIN
	DECLARE @ld_current_timestamp DATETIME 

	SET @ld_current_timestamp = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL)
	DECLARE @CombineScheduledUsage		CHAR(1)
	DECLARE @push_usage_to_replen_loc	CHAR(1)
	-- 12/21/15 - J.Villanueva - 12.17 Feature: 61702 Duplicate item usage on referenced item by inv_mast.inv_mast_uid_dup_usage
	DECLARE @push_usage_to_dup_item		CHAR(1)

	-- JRL 09/14/12 - Retrieve system setting info for push_usage_to_replen_loc
	SELECT	@CombineScheduledUsage = COALESCE(track_scheduled_usage_with_usage.[value], 'N')
			,@push_usage_to_replen_loc = COALESCE(push_usage_to_replen_loc.[value], 'N')
			,@push_usage_to_dup_item = COALESCE(push_usage_to_dup_item.[value], 'N')
	FROM	(SELECT 1 dummy) AS dummy	
	LEFT JOIN system_setting track_scheduled_usage_with_usage  WITH (NOLOCK) ON (track_scheduled_usage_with_usage.[name] = 'track_scheduled_usage_with_usage')
	LEFT JOIN system_setting push_usage_to_replen_loc  WITH (NOLOCK) ON (push_usage_to_replen_loc.[name] = 'push_usage_to_replen_loc')
	LEFT JOIN system_setting push_usage_to_dup_item WITH (NOLOCK) ON (push_usage_to_dup_item.[name] = 'push_usage_to_dup_item')

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
			,h.date_last_modified  -- date_created
			,h.date_last_modified
			,h.last_maintained_by
			,0
			,0
			,h.demand_period_uid
			,0
	FROM	[ssb].[trig_inv_period_usage_temp] h
	INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = h.inv_mast_uid)
									AND (inv_loc.location_id = h.location_id)
	LEFT JOIN inv_period_usage ON (h.location_id = inv_period_usage.location_id)
								AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)
								AND (h.demand_period_uid = inv_period_usage.demand_period_uid)
	WHERE	h.trig_uid = @trig_uid
	  AND	inv_period_usage.location_id IS NULL

	--
	-- Update the info from the table.
	--

	UPDATE	inv_period_usage
	SET		date_last_modified = h.date_last_modified
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
															COALESCE(inv_period_usage.inv_period_usage_this_location,0) + h.inv_period_usage + h.scheduled_usage
														ELSE
															COALESCE(inv_period_usage.inv_period_usage_this_location,0) + h.inv_period_usage
												END
	FROM	[ssb].[trig_inv_period_usage_temp] h
	INNER JOIN inv_period_usage ON (h.location_id = inv_period_usage.location_id)
								AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)
								AND (h.demand_period_uid = inv_period_usage.demand_period_uid)
	WHERE	h.trig_uid = @trig_uid

 	-- 01/16/17 - JRL - SCOPUS #1400824  - 12.17 0 - If push_usage_to_replen_loc or push_usage_to_dup_item is enabled, use the demand_period_uid of the target location 
	-- b/c it may be from another company. 
	IF (@push_usage_to_replen_loc = 'Y')
	BEGIN
		UPDATE	h
		SET		replenishment_location = inv_loc.replenishment_location
		FROM	[ssb].[trig_inv_period_usage_temp] h
		INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = h.inv_mast_uid)
										AND (inv_loc.location_id = h.location_id)
		WHERE	h.trig_uid = @trig_uid
		  AND	h.location_id <> inv_loc.replenishment_location

		UPDATE	h
		SET		demand_period_uid = demand_period_new_company.demand_period_uid
		FROM	[ssb].[trig_inv_period_usage_temp] h
		INNER JOIN [location] source_loc WITH (NOLOCK) ON (source_loc.location_id = h.location_id)
		INNER JOIN [location] target_loc WITH (NOLOCK) ON (target_loc.location_id = h.replenishment_location)
													  AND (target_loc.company_id <> source_loc.company_id)
		LEFT JOIN demand_period demand_period_new_company WITH (NOLOCK) ON (demand_period_new_company.company_id = target_loc.company_id)
																	   AND (@ld_current_timestamp  >= demand_period_new_company.beginning_date)
																	   AND (@ld_current_timestamp  < DATEADD(DAY, 1, demand_period_new_company.ending_date))
		WHERE	h.trig_uid = @trig_uid
		  AND	h.location_id <> h.replenishment_location
	
		DELETE	h
		FROM	[ssb].[trig_inv_period_usage_temp] h
		WHERE	h.trig_uid = @trig_uid
		  AND	h.demand_period_uid IS NULL

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
					,h.date_last_modified  -- date_created
					,h.date_last_modified  
					,h.last_maintained_by
					,0  
					,0  
					,h.demand_period_uid  
					,0
			FROM	[ssb].[trig_inv_period_usage_temp] h  
			INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = h.inv_mast_uid)
											AND (inv_loc.location_id = h.location_id)
			INNER JOIN inv_loc rep_loc WITH (NOLOCK) ON (rep_loc.inv_mast_uid = h.inv_mast_uid)
													AND (rep_loc.location_id = h.replenishment_location)
			LEFT JOIN inv_period_usage WITH (NOLOCK) ON (h.replenishment_location = inv_period_usage.location_id)  
													AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)  
													AND (h.demand_period_uid = inv_period_usage.demand_period_uid)  
			WHERE	h.trig_uid = @trig_uid
			  AND	inv_period_usage.location_id IS NULL
			  AND	h.replenishment_location <> h.location_id  
			  AND	(h.inv_period_usage <> 0 or h.scheduled_usage <> 0)

		--  
		-- Update the info from the table.  
		--  

		-- 10/21/16 - JRL - SCOPUS #1399681 / SN#CS0000093492 - Need to account for multiple inserts for the same inv_mast_uid, location_id, 
		-- replenishment_location, and demand_period_uid
		UPDATE	inv_period_usage
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
  					FROM	[ssb].[trig_inv_period_usage_temp] h      
  					INNER JOIN inv_period_usage ON (h.replenishment_location = inv_period_usage.location_id)      
  												AND (h.inv_mast_uid = inv_period_usage.inv_mast_uid)      
  												AND (h.demand_period_uid = inv_period_usage.demand_period_uid)     
  					WHERE	h.trig_uid = @trig_uid
					  AND	(h.replenishment_location <> h.location_id)   
  					GROUP BY h.replenishment_location, h.inv_mast_uid,h.demand_period_uid) drv_usage ON drv_usage.inv_mast_uid = inv_period_usage.inv_mast_uid 
																									AND drv_usage.replenishment_location = inv_period_usage.location_id
																									AND drv_usage.demand_period_uid = inv_period_usage.demand_period_uid
	END

	-- 12/21/15 - J.Villanueva - 12.17 Feature: 61702 Duplicate item usage on referenced item by inv_mast.inv_mast_uid_dup_usage
	IF (@push_usage_to_dup_item = 'Y')
	BEGIN
		
		UPDATE	h
		SET		inv_mast_uid_dup_usage = COALESCE(inv_loc.inv_mast_uid_dup_usage, inv_mast.inv_mast_uid_dup_usage)
		FROM	[ssb].[trig_inv_period_usage_temp] AS h
		INNER JOIN inv_mast WITH (NOLOCK) ON (inv_mast.inv_mast_uid = h.inv_mast_uid)
		INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = h.inv_mast_uid)
									    AND (inv_loc.location_id = h.location_id)
		WHERE	h.trig_uid = @trig_uid
		  AND	COALESCE(inv_loc.inv_mast_uid_dup_usage, inv_mast.inv_mast_uid_dup_usage) IS NOT NULL

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
				,h.date_last_modified  -- date_created
				,h.date_last_modified
				,h.last_maintained_by
				,0
				,0
				,h.demand_period_uid
		FROM	[ssb].[trig_inv_period_usage_temp] h
		INNER JOIN inv_loc WITH (NOLOCK) ON (inv_loc.inv_mast_uid = h.inv_mast_uid)
										AND (inv_loc.location_id = h.location_id)
		INNER JOIN inv_loc dup_loc WITH (NOLOCK) ON (dup_loc.inv_mast_uid = h.inv_mast_uid_dup_usage)
												AND (dup_loc.location_id = h.location_id)
		LEFT JOIN inv_period_usage WITH (NOLOCK) ON (h.location_id = inv_period_usage.location_id)
												AND (h.inv_mast_uid_dup_usage = inv_period_usage.inv_mast_uid)
												AND (h.demand_period_uid = inv_period_usage.demand_period_uid)
		WHERE	h.trig_uid = @trig_uid
		  AND	inv_period_usage.location_id is NULL
		  AND	h.inv_mast_uid_dup_usage IS NOT NULL
		  AND	(h.inv_period_usage <> 0 OR h.scheduled_usage <> 0)

		--
		-- Update the info from the table.
		--

		UPDATE	inv_period_usage
		SET		date_last_modified = h.date_last_modified
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
		FROM	[ssb].[trig_inv_period_usage_temp] h
		INNER JOIN inv_period_usage ON (h.location_id = inv_period_usage.location_id)
								   AND (h.inv_mast_uid_dup_usage = inv_period_usage.inv_mast_uid)
								   AND (h.demand_period_uid = inv_period_usage.demand_period_uid)
		WHERE	h.trig_uid = @trig_uid

	END
END
;




------------------------------------------------------------
-- 05/20/25 12:54 Author: Bernie Pomidor
-- Commit id: 9bd53a5dc1becc5aadbdaf66da2423bd1871486b
-- Merged PR 157188: Updated ssb.inv_period_usage_temp_process_i.sql
--DBA: BGP
--DEV: BGP
--verify rep loc
--b025_001_065459
--
------------------------------------------------------------
-- 12/06/24 18:00 Author: Pomidor, Bernie
-- Commit id: b61a123ec3a9f1a6836da0e038e2d66e8ca3d157
-- Merged PR 132340: Updated ssb.inv_period_usage_temp_process_i.sql
--DBA: BGP
--DEV: BGP
--verify inv_loc
--b024_002_064248
--
------------------------------------------------------------
-- 08/05/24 12:54 Author: Pomidor, Bernie
-- Commit id: 663bbdd29511ed007a878c98fc04259427031d2f
-- Merged PR 114631: inv_period_usage SB changes
--DBA: BGP
--DEV: BGP
--SB changes
--b024_001_063379
--
--$Author: Claudia.gonzalez $
--$Date: 4/03/23 12:41p $
--$Revision: 1 $
--$Log: /Server/CommerceCenter/Z_Turtle (22.2)/Stored Procedures/ssb.inv_period_usage_temp_process_i.sql $
-- 
-- 1     4/03/23 12:41p Claudia.gonzalez
-- DEV: CEG
-- DBA: CEG
-- JIRA P21S-8000: Convert period usage trigger to Service Broker
-- b022_002_060110family.sql
; 


Completion time: 2026-09-27T13:28:58.6132955-04:00

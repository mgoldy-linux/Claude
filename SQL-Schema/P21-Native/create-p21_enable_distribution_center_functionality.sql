USE [P21Training]
GO

/****** Object:  StoredProcedure [dbo].[p21_enable_distribution_center_functionality]    Script Date: 9/27/2026 10:55:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[p21_enable_distribution_center_functionality](@push_usage_to_replen_loc				char(1) = ''
                                                            , @trg_exclude_tbo_stock_requirements	char(1) = ''
                                                            , @oveerride_trg_periods_to_supply		char(1) = ''
                                                            , @trg_periods_to_supply_factor			int = 0
)
AS
BEGIN

	DECLARE @ld_current_timestamp datetime
	
	SET @ld_current_timestamp = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP,NULL,NULL)

	IF (@trg_exclude_tbo_stock_requirements <> '')
	BEGIN
		UPDATE system_setting 
		SET system_setting.date_last_modified = @ld_current_timestamp
			,system_setting.last_maintained_by = 'enable_dc_functionality'
			,system_setting.value = @trg_exclude_tbo_stock_requirements
		WHERE system_setting.name = 'trg_exclude_tbo_stock_requirements'
		AND system_setting.value <> @trg_exclude_tbo_stock_requirements
	END	
	
	IF (@oveerride_trg_periods_to_supply <> '')
	BEGIN
		UPDATE system_setting 
		SET system_setting.date_last_modified = @ld_current_timestamp
			,system_setting.last_maintained_by = 'enable_dc_functionality'
			,system_setting.value = @oveerride_trg_periods_to_supply
		WHERE system_setting.name = 'oveerride_trg_periods_to_supply'
		  AND system_setting.value <> @oveerride_trg_periods_to_supply
		  
	END
	
	IF (@trg_periods_to_supply_factor <> 0)
	BEGIN
		UPDATE system_setting 
		SET system_setting.date_last_modified = @ld_current_timestamp
			,system_setting.last_maintained_by = 'enable_dc_functionality'
			,system_setting.value = CONVERT(varchar(255),@trg_periods_to_supply_factor)
		WHERE	system_setting.name = 'trg_periods_to_supply_factor'
			AND system_setting.value <> Convert(varchar(255),@trg_periods_to_supply_factor)
	END	
	
	DECLARE @system_setting_push_usage_to_replen_loc CHAR(255)
	SET @system_setting_push_usage_to_replen_loc = (SELECT value  
													FROM  system_setting  
													WHERE name = 'push_usage_to_replen_loc')
    
    -- JRL 05/20/14 - Turn on the feature and push the usage to the spokes
               
	IF (@push_usage_to_replen_loc = 'Y' and @system_setting_push_usage_to_replen_loc = 'N')
	BEGIN
		UPDATE system_setting 
		set system_setting.date_last_modified = @ld_current_timestamp
			,system_setting.last_maintained_by = 'enable_dc_functionality'
			,system_setting.value = 'Y'
		WHERE system_setting.name = 'push_usage_to_replen_loc'

   		-- JRL 11/23/15 - F62441 - Need to update inv_period_usage_this_location
		UPDATE inv_period_usage
		set inv_period_usage.inv_period_usage_this_location = inv_period_usage.inv_period_usage

		INSERT INTO inv_period_usage_temp
		(location_id, demand_period_uid, inv_mast_uid, inv_period_usage, scheduled_usage,number_of_orders,number_of_hits,date_created,
		last_maintained_by)
	
		SELECT inv_loc.replenishment_location
			, inv_period_usage.demand_period_uid
			, inv_period_usage.inv_mast_uid
			, sum(inv_period_usage.inv_period_usage)
			, sum(inv_period_usage.scheduled_usage)
			, 0 --sum(inv_period_usage.number_of_orders) -- JRL 05/20/14 - We are only pushing usage, not service levels
			, 0 --sum(inv_period_usage.number_of_hits)   -- JRL 05/20/14 - We are only pushing usage, not service levels
			, @ld_current_timestamp
			, 'enable_dc_functionality'
		FROM inv_period_usage (NOLOCK) 
		INNER JOIN inv_loc (NOLOCK) on	inv_loc.location_id = inv_period_usage.location_id 
									and inv_loc.inv_mast_uid = inv_period_usage.inv_mast_uid
									and inv_loc.location_id <> inv_loc.replenishment_location
		WHERE EXISTS(SELECT 1 FROM inv_loc replen_loc (NOLOCK) 
					 WHERE replen_loc.location_id = inv_loc.replenishment_location 
					   and replen_loc.inv_mast_uid = inv_loc.inv_mast_uid)
		GROUP BY
		inv_loc.replenishment_location
		, inv_period_usage.demand_period_uid
		, inv_period_usage.inv_mast_uid

	END
	
	-- JRL 05/20/14 - Turn off the feature and erase the usage that were copied to the spokes
	
	IF (@push_usage_to_replen_loc = 'N' and @system_setting_push_usage_to_replen_loc = 'Y')
	BEGIN
		UPDATE system_setting 
		set system_setting.date_last_modified = @ld_current_timestamp
			,system_setting.last_maintained_by = 'enable_dc_functionality'
			,system_setting.value = 'N'
		WHERE system_setting.name = 'push_usage_to_replen_loc'

		INSERT INTO inv_period_usage_temp
		(location_id, demand_period_uid, inv_mast_uid, inv_period_usage, scheduled_usage,number_of_orders,number_of_hits,date_created,
		last_maintained_by)
	
		SELECT inv_loc.replenishment_location
			, inv_period_usage.demand_period_uid
			, inv_period_usage.inv_mast_uid
			, -1 * sum(inv_period_usage.inv_period_usage)
			, -1 * sum(inv_period_usage.scheduled_usage)
			, 0 --sum(inv_period_usage.number_of_orders) -- JRL 05/20/14 - We are only pushing usage, not service levels
			, 0 --sum(inv_period_usage.number_of_hits)   -- JRL 05/20/14 - We are only pushing usage, not service levels
			, @ld_current_timestamp
			, 'enable_dc_functionality'
		FROM inv_period_usage (NOLOCK) 
		INNER JOIN inv_loc (NOLOCK) on	inv_loc.location_id = inv_period_usage.location_id 
									and inv_loc.inv_mast_uid = inv_period_usage.inv_mast_uid
									and inv_loc.location_id <> inv_loc.replenishment_location
		WHERE EXISTS(SELECT 1 FROM inv_loc replen_loc (NOLOCK) 
					 WHERE replen_loc.location_id = inv_loc.replenishment_location 
					   and replen_loc.inv_mast_uid = inv_loc.inv_mast_uid)
		GROUP BY
		inv_loc.replenishment_location
		, inv_period_usage.demand_period_uid
		, inv_period_usage.inv_mast_uid

	END
END

-- $Author: Ricardo.aguirre $
-- $Revision: 6 $
-- $Date: 3/26/19 6:05p $
-- $Log: /Server/CommerceCenter/Z_Leemar (18.2)/Stored Procedures/p21_enable_distribution_center_functionality.sql $
-- 
-- 6     3/26/19 6:05p Ricardo.aguirre
-- DEV: RAR
-- DBA: RAR 
-- JIRA: P21CD-14008: Modify Stored Procedures for Timezone feature to use
-- @current_timestamp variable
-- b018_002_051346(familyB).sql 
-- 
-- 5     8/28/18 3:32p Syed.yunus
-- Feature 69545: P21CD-11361 Modifying CURRENT_TIMESTAMP/GETDATE() to
-- support timezone settings
-- DBA: SYUNUS
-- DEV: SYUNUS
-- Script: b018_002_050038 Family
-- 
-- 3     11/23/15 2:39p Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- add usage location column
-- b012_016_043680c
-- 
-- 1     5/21/14 4:52p Bernie.pomidor
-- DBA: BGP
-- DEV: JRL
-- new SP
-- b012_013_039791a
-- 
GO


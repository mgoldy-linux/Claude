USE [P21Upgrade]
GO

/****** Object:  Trigger [dbo].[t_inv_period_usage_temp_ssb]    Script Date: 9/27/2026 1:26:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE TRIGGER [dbo].[t_inv_period_usage_temp_ssb] ON [dbo].[inv_period_usage_temp] INSTEAD OF INSERT
AS

BEGIN  
	 IF (@@rowcount = 0)     
		RETURN
		
	SET NOCOUNT ON;
	
	DECLARE	@conv					UNIQUEIDENTIFIER
			,@from_svc				SYSNAME
			,@to_svc				SYSNAME
			,@contract				SYSNAME
			,@msg					XML
			,@trig_uid				UNIQUEIDENTIFIER
			,@use_SB_flag			CHAR(1)
	;

	SET @from_svc = '//ssb.p21/trigger/ackSvc';
	SET @to_svc =   '//ssb.p21/trigger/activateSvc';
	SET @contract = '//ssb.p21/trigger/inv_period_usage_temp/contract';
	SET @trig_uid = NEWID();

	SELECT	@use_SB_flag = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
	FROM	ssb.ssb_check s WITH (NOLOCK)
	WHERE	(s.name in ('ssb.trig_ack_q', 'ssb.trig_q', 'ssb_enabled_inv_period_usage_temp') OR s.type = 'System') 
	  AND	s.status = 'Disabled'
	;

	BEGIN TRY
		-- Construct the message
	IF (@use_SB_flag = 'N')
	BEGIN

		INSERT INTO [ssb].[trig_inv_period_usage_temp]
				(trig_uid
				,row_type
				,location_id
				,inv_mast_uid
				,demand_period_uid
				,date_last_modified
				,last_maintained_by
				,inv_period_usage
				,scheduled_usage
				,number_of_hits 
				,number_of_orders
				,replenishment_location)  
			SELECT	@trig_uid AS [trig_uid]
					,'I'
					,inserted.location_id
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
		;
	
		EXEC ssb.inv_period_usage_temp_react @trig_uid = @trig_uid;

	END
	;

	IF (@use_SB_flag = 'Y')
	BEGIN

		-- Construct the message
			SET @msg =	(
			SELECT	@trig_uid AS [trig_uid]
					,'I'  AS row_type
					,inserted.location_id
					,inserted.inv_mast_uid
					,inserted.demand_period_uid
					,MAX(inserted.date_created)  as date_last_modified
					,MAX(inserted.last_maintained_by) as last_maintained_by
					,SUM(inserted.inv_period_usage) as inv_period_usage
					,SUM(inserted.scheduled_usage) as scheduled_usage
					,SUM(inserted.number_of_hits) as number_of_hits
					,SUM(inserted.number_of_orders) as number_of_orders
					,inserted.location_id   as replenishment_location
			FROM	inserted
			GROUP BY inserted.location_id
					,inserted.inv_mast_uid
					,inserted.demand_period_uid  
					FOR XML RAW('InvPeriodUsageTempXML'), ELEMENTS
					)	
					;
	
		 -- We have to begin a new Service Broker conversation with the TargetService
		BEGIN DIALOG CONVERSATION @conv
			FROM SERVICE @from_svc
			TO SERVICE @to_svc
			ON CONTRACT @contract
			WITH ENCRYPTION = OFF
		;

		-- Send the message to the TargetService
		SEND ON CONVERSATION @conv
		MESSAGE TYPE [//ssb.p21/trigger/inv_period_usage_temp/activate] (@msg)
		;
    
	END

	END TRY
	BEGIN CATCH
		EXEC util.Rethrow;
	END CATCH
	;
END
;

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
--$Date: 4/03/23 12:40p $
--$Revision: 1 $
--$Log: /Server/CommerceCenter/Z_Turtle (22.2)/Stored Procedures/t_inv_period_usage_temp_ssb.sql $
-- 
-- 1     4/03/23 12:40p Claudia.gonzalez
-- DEV: CEG
-- DBA: CEG
-- JIRA P21S-8000: Convert period usage trigger to Service Broker
-- b022_002_060110family.sql
; 
GO

ALTER TABLE [dbo].[inv_period_usage_temp] ENABLE TRIGGER [t_inv_period_usage_temp_ssb]
GO


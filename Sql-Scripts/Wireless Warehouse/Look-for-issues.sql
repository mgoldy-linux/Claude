use P21Play;

DECLARE	@li_LocationID	INTEGER
DECLARE	@ls_Action		VARCHAR(255)

--====================================================================================
-- Location ID -255 will do all locations, otherwise use a specific location ID
--====================================================================================
SET	@li_LocationID = 100

--====================================================================================
--	Actions are LIST and UPDATE.
--	List will list the problem items, update will update them
--====================================================================================
SET	@ls_Action = 'LIST'

IF UPPER(@ls_Action) = 'LIST'
	BEGIN

		SELECT	inv_mast.item_id [Item ID], inv_mast.delete_flag [Item Deleted]
				,inv_loc.location_id [Location ID], inv_loc.delete_flag [Location Deleted]
				,CASE WHEN COALESCE(inv_loc.track_bins, 'N') = 'N'
					THEN 'Track Bins = ''N'''
					ELSE 'Primary Bin = NULL'
				 END [Reason]
		FROM	inv_loc
		INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = inv_loc.inv_mast_uid)
		LEFT JOIN assembly_hdr ON (assembly_hdr.inv_mast_uid = inv_loc.inv_mast_uid)
		WHERE	(COALESCE(inv_loc.track_bins, 'N') = 'N'
		   OR	(COALESCE(inv_loc.track_bins, 'N') = 'Y'
		  AND	inv_loc.primary_bin IS NULL))
		  AND	COALESCE(assembly_hdr.production_order_processing, 'N') = 'N'
		  AND	(inv_loc.stockable = 'Y'
		   OR	inv_loc.qty_on_hand <> 0)
		  AND	(inv_loc.location_id = @li_LocationID
		   OR	@li_LocationID = -255)
		ORDER BY inv_mast.item_id
				,inv_loc.location_id
				,reason
	END

ELSE
	IF UPPER(@ls_Action) = 'UPDATE'
		BEGIN

			IF EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'temp_bin_table')
				DROP TABLE temp_bin_table

			IF EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'temp_inv_bin_table')
				DROP TABLE temp_inv_bin_table
			
			DECLARE @ll_Counter		INTEGER
			DECLARE	@ll_TotalRows	INTEGER
			
		 	SELECT 	IDENTITY(INT, 1, 1) AS uid
					,inv_loc.company_id AS company_id
					,inv_loc.location_id AS location_id
					,'NOBIN' AS bin
			INTO	temp_bin_table
			FROM	inv_loc
			INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = inv_loc.inv_mast_uid)
			LEFT JOIN assembly_hdr ON (assembly_hdr.inv_mast_uid = inv_loc.inv_mast_uid)
			WHERE	COALESCE(inv_loc.track_bins, 'N') = 'N'
			   OR	(COALESCE(inv_loc.track_bins, 'N') = 'Y'
			  AND	inv_loc.primary_bin IS NULL)
			  AND	COALESCE(assembly_hdr.production_order_processing, 'N') = 'N'
			  AND	(inv_loc.stockable = 'Y'
			   OR	inv_loc.qty_on_hand <> 0)
			  AND	(inv_loc.location_id = @li_LocationID
			   OR	@li_LocationID = -255)
			  AND	NOT EXISTS
					(SELECT	1
					 FROM	bin
					 WHERE	bin.location_id = inv_loc.location_id
					   AND	bin.bin_id = 'NOBIN')
			GROUP BY inv_loc.company_id
					,inv_loc.location_id

			SET @ll_TotalRows = (SELECT	COUNT(1)
								 FROM	temp_bin_table)

			IF (@ll_TotalRows > 0)
				EXECUTE @ll_Counter = p21_get_counter 'bin', @ll_TotalRows
			ELSE
				SET @ll_TotalRows = 0

			INSERT INTO bin
					(company_id
					,location_id
					,bin_id
					,delete_flag
					,date_created
					,date_last_modified
					,last_maintained_by
					,date_last_counted
					,created_by
					,bin_type_uid
					,pick_locked_flag
					,put_locked_flag
					,full_flag
					,frozen_flag
					,max_weight
					,current_weight
					,current_volume
					,putaway_zone_uid
					,putaway_zone_sequence
					,pick_zone_uid
					,pick_zone_sequence
					,warehouse_sequence
					,bin_length
					,bin_height
					,bin_width
					,bin_uid
					,rf_bin_flag
					,consolidation_bin_flag
					,rf_terminal_uid)
			   SELECT 	company_id
						,location_id
						,'NOBIN'
						,'N'
						,CURRENT_TIMESTAMP
						,CURRENT_TIMESTAMP
						,'ItemBinQuery'
						,NULL
						,'ItemBinQuery'
						,NULL
						,'N'
						,'N'
						,'N'
						,'N'
						,0
						,0
						,0
						,NULL
						,0
						,NULL
						,0
						,0
						,0
						,0
						,0
						,uid + (@ll_Counter - @ll_TotalRows)
						,'N'
						,'N'
						,NULL
				FROM	temp_bin_table

			SELECT	IDENTITY(INT, 1, 1) AS uid
					,inv_loc.company_id AS company_id
					,inv_loc.location_id AS location_id
					,inv_loc.inv_mast_uid AS inv_mast_uid
					,'NOBIN' AS bin
			INTO	temp_inv_bin_table
			FROM	inv_loc
			INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = inv_loc.inv_mast_uid)
			LEFT JOIN assembly_hdr ON (assembly_hdr.inv_mast_uid = inv_loc.inv_mast_uid)
			WHERE	COALESCE(inv_loc.track_bins, 'N') = 'N'
			   OR	(COALESCE(inv_loc.track_bins, 'N') = 'Y'
			  AND	inv_loc.primary_bin IS NULL)
			  AND	COALESCE(assembly_hdr.production_order_processing, 'N') = 'N'
			  AND	(inv_loc.stockable = 'Y'
			   OR	inv_loc.qty_on_hand <> 0)
			  AND	(inv_loc.location_id = @li_LocationID
			   OR	@li_LocationID = -255)
			  AND	NOT EXISTS
					(SELECT	1
					 FROM	inv_bin
					 WHERE	inv_bin.inv_mast_uid = inv_loc.inv_mast_uid
					   AND	inv_bin.location_id = inv_loc.location_id
					   AND	inv_bin.bin = 'NOBIN')
			
			SET @ll_TotalRows = (SELECT	COUNT(1)
								 FROM	temp_inv_bin_table)
			
			IF (@ll_TotalRows > 0)
				EXECUTE @ll_Counter = p21_get_counter 'inv_bin', @ll_TotalRows
			ELSE
				SET @ll_TotalRows = 0
			
			INSERT INTO inv_bin
					(company_id
					,location_id
					,bin
					,quantity
					,date_created
					,date_last_modified
					,last_maintained_by
					,inv_mast_uid
					,qty_allocated
					,inv_bin_uid
					,row_status_flag)
			   SELECT 	company_id
						,location_id
						,bin
						,0
						,CURRENT_TIMESTAMP
						,CURRENT_TIMESTAMP
						,'ItemBinQuery'
						,inv_mast_uid
						,0
						,uid + (@ll_Counter - @ll_TotalRows)
						,1037
				FROM	temp_inv_bin_table

			UPDATE	inv_loc
			SET		primary_bin = 'NOBIN'
					,track_bins = 'Y'
					,last_maintained_by = 'ItemBinQuery'
					,date_last_modified = CURRENT_TIMESTAMP
			FROM	inv_loc
			INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = inv_loc.inv_mast_uid)
			LEFT JOIN assembly_hdr ON (assembly_hdr.inv_mast_uid = inv_loc.inv_mast_uid)
			WHERE	COALESCE(inv_loc.track_bins, 'N') = 'N'
			   OR	(COALESCE(inv_loc.track_bins, 'N') = 'Y'
			  AND	inv_loc.primary_bin IS NULL)
			  AND	COALESCE(assembly_hdr.production_order_processing, 'N') = 'N'
			  AND	(inv_loc.stockable = 'Y'
			   OR	inv_loc.qty_on_hand <> 0)
			  AND	(inv_loc.location_id = @li_LocationID
			   OR	@li_LocationID = -255)

			IF EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'temp_bin_table')
				DROP TABLE temp_bin_table

			IF EXISTS (SELECT * FROM information_schema.tables WHERE table_name = 'temp_inv_bin_table')
				DROP TABLE temp_inv_bin_table
			
		END

-- SA-56034: My Customer Price List - 2.2 fails when 'Group Items by Class' = True
-- Msg: Column '#cpaa.contract_price' is invalid in the select list (not in aggregate or GROUP BY)
-- Fix: customer_price CASE in the manufacturing-class UNION branch referenced bare cpaa.contract_price; wrap in MIN().
-- Only change vs live definition (modified 2026-04-06). CREATE OR ALTER keeps grants. Deploy Play/Dev first.
USE P21; --P21Play;  --
GO
CREATE OR ALTER PROCEDURE [dbo].[asi_proc_customer_pricing_loc_items] (
	@comp_id AS VARCHAR(8), 
	@cust_id AS DECIMAL(19,0), 
	@loc AS DECIMAL(19,0), 
	@items AS dbo.asi_TableTypeItemDec READONLY,
	@one_off_only AS VARCHAR(1) NULL,
	@group_by_mfg_class AS VARCHAR(1) NULL
)
	
AS
BEGIN
-- KB PROC Location-Specific Price List Generator for SSRS
	IF @one_off_only IS NULL
		SET @one_off_only = 'N'
	IF @group_by_mfg_class IS NULL
		SET @group_by_mfg_class = 'N'

	DECLARE @debug_mode VARCHAR(1) = 'N'

	-- Create a table of all the item-based information we'll need
	CREATE TABLE #i (
		company_id VARCHAR(8),
		inv_mast_uid INT, 
		sales_pricing_unit_size DECIMAL(19,9), 
		price1 DECIMAL(19,9),
		price2 DECIMAL(19,9),
		price3 DECIMAL(19,9),
		price4 DECIMAL(19,9),
		price5 DECIMAL(19,9),
		price6 DECIMAL(19,9),
		price7 DECIMAL(19,9),
		price8 DECIMAL(19,9),
		price9 DECIMAL(19,9),
		price10 DECIMAL(19,9),
		contract_price DECIMAL(19,9),
		customer_price DECIMAL(19,9),
		inv_sup_list_price DECIMAL(19,9),
		inv_sup_cost DECIMAL(19,9),
		standard_cost DECIMAL(19,9),
		moving_average_cost DECIMAL(19,9),
		last_rec_po DECIMAL(19,9),
		next_due_in_po_cost DECIMAL(19,9),
		sales_pricing_unit VARCHAR(8),
		rolled_item_flag VARCHAR(1),
		sales_discount_group VARCHAR(8),
		product_group_id VARCHAR(8),
		manufacturing_class_id VARCHAR(8),
		customer_part_their_item_id VARCHAR(40),
		default_price_family_uid INT,
		primary_supplier_id DECIMAL(19,0)
	)
	CREATE CLUSTERED INDEX idx_i_items ON #i (inv_mast_uid)
	IF @debug_mode = 'Y'
		PRINT 'Inserting into item table'
	INSERT INTO #i (company_id, inv_mast_uid, sales_pricing_unit_size, price1, price2, price3, price4, price5, price6, price7, price8, price9, price10, 
		contract_price, customer_price, inv_sup_list_price, inv_sup_cost, standard_cost, moving_average_cost, last_rec_po, next_due_in_po_cost, sales_pricing_unit, rolled_item_flag, 
		sales_discount_group, product_group_id, manufacturing_class_id, customer_part_their_item_id, default_price_family_uid, primary_supplier_id)
	(
		SELECT '1', 
			im.inv_mast_uid,
			im.sales_pricing_unit_size,
			il.price1,
			il.price2,
			il.price3,
			il.price4,
			il.price5,
			il.price6,
			il.price7,
			il.price8,
			il.price9,
			il.price10,
			jpc.PRICE,
			jpc.PRICE,
			inv_sup.list_price,
			inv_sup.cost,
			il.standard_cost,
			il.moving_average_cost,
			il.last_rec_po,
			il.next_due_in_po_cost,
			im.sales_pricing_unit,
			im.rolled_item_flag,
			il.sales_discount_group,
			il.product_group_id, 
			inv_sup.manufacturing_class_id,
			cust_part.their_item_id,
			im.default_price_family_uid,
			il.primary_supplier_id

		FROM @items AS proc_items
		INNER JOIN inv_mast AS im ON proc_items.item_id = im.item_id
		INNER JOIN inv_loc AS il ON il.inv_mast_uid = im.inv_mast_uid AND il.location_id = @loc
			AND ISNULL(il.delete_flag,'N') = 'N' AND il.discontinued = 'N' AND il.requisition = 'N'
		INNER JOIN p21_view_inventory_supplier AS inv_sup -- Based on the primary supplier
			ON inv_sup.supplier_id = il.primary_supplier_id AND inv_sup.inv_mast_uid = il.inv_mast_uid AND inv_sup.delete_flag = 'N'
		LEFT JOIN p21_view_inv_xref AS cust_part
			ON cust_part.company_id = '1' AND cust_part.customer_id = @cust_id AND cust_part.inv_mast_uid = il.inv_mast_uid
		left join (
          select
            job_price_hdr.CORP_ADDRESS_ID,
            job_price_hdr.JOB_PRICE_HDR_UID,
            job_price_hdr.JOB_NO,
            job_price_hdr.CONTRACT_NO,
            job_price_hdr.CONTACT_ID,
            job_price_hdr.TAKER,
            job_price_line.CUSTOMER_PART_NO,
--            job_price_line.UOM,
--            job_price_line.PRICE,
            job_price_line.INV_MAST_UID,
            inv_mast.ITEM_ID,
            job_price_line.UOM as CONTRACT_UNIT,
            inv_mast.SALES_PRICING_UNIT as UOM,
            item_uom_selling.UNIT_SIZE as SALES_UNIT_SIZE,
            item_uom_contract.UNIT_SIZE as CONTRACT_UNIT_SIZE,
            job_price_line.PRICE/item_uom_contract.UNIT_SIZE*item_uom_selling.UNIT_SIZE as PRICE
          from job_price_hdr (NOLOCK)
          left join job_price_line (NOLOCK) on job_price_line.JOB_PRICE_HDR_UID=job_price_hdr.JOB_PRICE_HDR_UID
		  left join job_price_customer_shipto (NOLOCK) on (job_price_customer_shipto.JOB_PRICE_HDR_UID=job_price_hdr.JOB_PRICE_HDR_UID)
          left join inv_mast (NOLOCK) on inv_mast.INV_MAST_UID=job_price_line.INV_MAST_UID 
          left join item_uom (NOLOCK) as item_uom_selling on (item_uom_selling.INV_MAST_UID=inv_mast.INV_MAST_UID) and (item_uom_selling.UNIT_OF_MEASURE=SALES_PRICING_UNIT) and (item_uom_selling.DELETE_FLAG='N')
          left join item_uom (NOLOCK) as item_uom_contract on (item_uom_contract.INV_MAST_UID=inv_mast.INV_MAST_UID) and (item_uom_contract.UNIT_OF_MEASURE=job_price_line.UOM) and (item_uom_contract.DELETE_FLAG='N')
          where
            (job_price_customer_shipto.CUSTOMER_ID=@cust_id) and
            (job_price_hdr.APPROVED='Y') and
            (job_price_hdr.CANCELLED='N') and
            (job_price_hdr.START_DATE<=GetDate()) and
            (job_price_hdr.END_DATE>=GetDate()) and
            (job_price_line.ROW_STATUS_FLAG=704) and
            (coalesce(job_price_line.EXPIRATION_DATE,GetDate())>=GetDate())
		) as jpc on jpc.INV_MAST_UID=im.INV_MAST_UID
		WHERE im.delete_flag = 'N'
	)
		
	CREATE TABLE #cpaa (company_id VARCHAR(8), customer_id DECIMAL(19,0), inv_mast_uid INT, price_page_uid INT,
		price DECIMAL(19,9), contract_price DECIMAL(19,9), customer_price DECIMAL(19,9), uom VARCHAR(8), roll_type VARCHAR(9), lxc_sequence_number INT, lowest_library_sequence_no INT)
	IF @debug_mode = 'Y'
		PRINT 'Inserting into customer price table'
	INSERT INTO #cpaa (company_id, customer_id, inv_mast_uid, price_page_uid, price, contract_price, customer_price, uom, roll_type, lxc_sequence_number)
	(
		SELECT 
			lxc.company_id
			,cust.customer_id
			,i.inv_mast_uid
			,pp.price_page_uid
			-- Price Calculation
			,ROUND(
				-- IT'S ME.  HI.  I'M THE PROBLEM; IT'S ME.
				--CASE pp.pricing_method_cd WHEN 221 THEN pp.price * i.sales_pricing_unit_size ELSE
				CASE WHEN pp.pricing_method_cd = 221 AND COALESCE(pp.price,0.00) <> 0.00 AND COALESCE(pp.calculation_value1,0.00) = 0.00 THEN pp.price * i.sales_pricing_unit_size ELSE
				
				CASE pp.calculation_method_cd 
				
					--1292    Fixed Price
					WHEN 1292 THEN pp.calculation_value1 
				
					-- 211    Multiplier
					WHEN 211 THEN 
						CASE pp.source_price_cd
							WHEN 101 THEN i.price1 * pp.calculation_value1 
							WHEN 102 THEN i.price2 * pp.calculation_value1 
							WHEN 103 THEN i.price3 * pp.calculation_value1 
							WHEN 104 THEN i.price4 * pp.calculation_value1 
							WHEN 105 THEN i.price5 * pp.calculation_value1 
							WHEN 106 THEN i.price6 * pp.calculation_value1 
							WHEN 107 THEN i.price7 * pp.calculation_value1 
							WHEN 108 THEN i.price8 * pp.calculation_value1 
							WHEN 109 THEN i.price9 * pp.calculation_value1 
							WHEN 110 THEN i.price10 * pp.calculation_value1
							WHEN 200 THEN i.inv_sup_list_price * pp.calculation_value1
							WHEN 201 THEN i.inv_sup_cost * pp.calculation_value1
							WHEN 202 THEN i.standard_cost * pp.calculation_value1
							WHEN 203 THEN i.moving_average_cost * pp.calculation_value1
							WHEN 204 THEN i.last_rec_po * pp.calculation_value1
							WHEN 205 THEN i.next_due_in_po_cost * pp.calculation_value1
							ELSE 0
						END
					--228    Difference
					WHEN 228 THEN
						CASE pp.source_price_cd
							WHEN 101 THEN i.price1 - pp.calculation_value1 
							WHEN 102 THEN i.price2 - pp.calculation_value1 
							WHEN 103 THEN i.price3 - pp.calculation_value1 
							WHEN 104 THEN i.price4 - pp.calculation_value1 
							WHEN 105 THEN i.price5 - pp.calculation_value1 
							WHEN 106 THEN i.price6 - pp.calculation_value1 
							WHEN 107 THEN i.price7 - pp.calculation_value1 
							WHEN 108 THEN i.price8 - pp.calculation_value1 
							WHEN 109 THEN i.price9 - pp.calculation_value1 
							WHEN 110 THEN i.price10 - pp.calculation_value1
							WHEN 200 THEN i.inv_sup_list_price - pp.calculation_value1
							WHEN 201 THEN i.inv_sup_cost - pp.calculation_value1
							WHEN 202 THEN i.standard_cost - pp.calculation_value1
							WHEN 203 THEN i.moving_average_cost - pp.calculation_value1
							WHEN 204 THEN i.last_rec_po - pp.calculation_value1
							WHEN 205 THEN i.next_due_in_po_cost - pp.calculation_value1
							ELSE 0
						END

					--229    Mark Up (Formula taken directly from help file)
					WHEN 229 THEN 
						CASE WHEN pp.calculation_value1 = 100 THEN 0 ELSE 
							CASE pp.source_price_cd
								WHEN 101 THEN i.price1 * (100/(100 - pp.calculation_value1))
								WHEN 102 THEN i.price2 * (100/(100 - pp.calculation_value1))
								WHEN 103 THEN i.price3 * (100/(100 - pp.calculation_value1))
								WHEN 104 THEN i.price4 * (100/(100 - pp.calculation_value1))
								WHEN 105 THEN i.price5 * (100/(100 - pp.calculation_value1))
								WHEN 106 THEN i.price6 * (100/(100 - pp.calculation_value1))
								WHEN 107 THEN i.price7 * (100/(100 - pp.calculation_value1))
								WHEN 108 THEN i.price8 * (100/(100 - pp.calculation_value1))
								WHEN 109 THEN i.price9 * (100/(100 - pp.calculation_value1))
								WHEN 110 THEN i.price10 * (100/(100 - pp.calculation_value1))
								WHEN 200 THEN i.inv_sup_list_price * (100/(100 - pp.calculation_value1))
								WHEN 201 THEN i.inv_sup_cost * (100/(100 - pp.calculation_value1))
								WHEN 202 THEN i.standard_cost * (100/(100 - pp.calculation_value1))
								WHEN 203 THEN i.moving_average_cost * (100/(100 - pp.calculation_value1))
								WHEN 204 THEN i.last_rec_po * (100/(100 - pp.calculation_value1))
								WHEN 205 THEN i.next_due_in_po_cost * (100/(100 - pp.calculation_value1))
								ELSE 0
							END
						END

					--230    Percentage (Formula taken directly from help file)
					WHEN 230 THEN
						CASE pp.source_price_cd
							WHEN 101 THEN i.price1 * (pp.calculation_value1 * .01)
							WHEN 102 THEN i.price2 * (pp.calculation_value1 * .01)
							WHEN 103 THEN i.price3 * (pp.calculation_value1 * .01)
							WHEN 104 THEN i.price4 * (pp.calculation_value1 * .01)
							WHEN 105 THEN i.price5 * (pp.calculation_value1 * .01)
							WHEN 106 THEN i.price6 * (pp.calculation_value1 * .01)
							WHEN 107 THEN i.price7 * (pp.calculation_value1 * .01)
							WHEN 108 THEN i.price8 * (pp.calculation_value1 * .01)
							WHEN 109 THEN i.price9 * (pp.calculation_value1 * .01)
							WHEN 110 THEN i.price10 * (pp.calculation_value1 * .01)
							WHEN 200 THEN i.inv_sup_list_price * (pp.calculation_value1 * .01)
							WHEN 201 THEN i.inv_sup_cost * (pp.calculation_value1 * .01)
							WHEN 202 THEN i.standard_cost * (pp.calculation_value1 * .01)
							WHEN 203 THEN i.moving_average_cost * (pp.calculation_value1 * .01)
							WHEN 204 THEN i.last_rec_po * (pp.calculation_value1 * .01)
							WHEN 205 THEN i.next_due_in_po_cost * (pp.calculation_value1 * .01)
							ELSE 0
						END

					ELSE 0
				END 
			END,2) AS price

			,i.contract_price
			,i.customer_price
			,i.sales_pricing_unit AS uom

			,CASE i.rolled_item_flag
				WHEN 'Y' THEN CASE pp.rolled_item_pricing_type_cd
					WHEN 3546 THEN 'Full Roll'
					ELSE 'Cut'
					END
				ELSE ''
			END AS roll_type
		
			,lxc.sequence_number AS lxc_sequence_number

		FROM p21_view_price_book_x_library AS bxl
		LEFT JOIN p21_view_price_library_x_cust_x_cmpy AS lxc
			ON bxl.price_library_uid = lxc.price_library_uid AND lxc.row_status_flag = 704
		LEFT JOIN p21_view_price_page_x_book AS pxb
			ON pxb.price_book_uid = bxl.price_book_uid AND pxb.row_status_flag = 704
		LEFT JOIN p21_view_price_page AS pp
			ON pxb.price_page_uid = pp.price_page_uid AND pp.row_status_flag = 704
		LEFT JOIN p21_view_price_book AS pb
			ON bxl.price_book_uid = pb.price_book_uid AND pb.row_status_flag = 704
		LEFT JOIN price_book_ud AS pbu ON pbu.price_book_uid = pb.price_book_uid
		LEFT JOIN p21_view_price_library AS pl
			ON lxc.price_library_uid = pl.price_library_uid AND pl.row_status_flag = 704
		INNER JOIN p21_view_customer AS cust
			ON cust.customer_id = lxc.customer_id AND cust.company_id = lxc.company_id AND cust.delete_flag = 'N'
	
		INNER JOIN #i AS i ON i.company_id = cust.company_id
			-- New price page to items join that avoids manual type conversions:
			AND (
				-- Item half, natural VARCHARs
				CASE pp.price_page_type_cd 
					-- Supplier / Discount Group
					WHEN 213 THEN i.sales_discount_group
					-- Supplier / Product Group
					WHEN 214 THEN i.product_group_id
					-- Supplier / Manufacturing Class
					WHEN 215 THEN i.manufacturing_class_id
					-- Discount Group
					WHEN 217 THEN i.sales_discount_group
					-- Product Group
					WHEN 218 THEN i.product_group_id
					-- Customer Part Number
					WHEN 219 THEN i.customer_part_their_item_id
					-- Otherwise, match base case
					ELSE '----BASE-CASE-VARCHAR' END
				-- Price Page half, natural VARCHARs
				= CASE pp.price_page_type_cd
					-- Supplier / Discount Group
					WHEN 213 THEN pp.discount_group_id
					-- Supplier / Product Group
					WHEN 214 THEN pp.product_group_id
					-- Supplier / Manufacturing Class
					WHEN 215 THEN pp.mfg_class_id
					-- Discount Group
					WHEN 217 THEN pp.discount_group_id
					-- Product Group
					WHEN 218 THEN pp.product_group_id
					-- Customer Part Number
					WHEN 219 THEN pp.customer_part_no
					-- Otherwise, match base case
					ELSE '----BASE-CASE-VARCHAR' END
			) AND (
				-- Item half, natural INTs
				CASE pp.price_page_type_cd 
					-- Item
					WHEN 212 THEN i.inv_mast_uid 
					-- Price Family
					WHEN 2339 THEN i.default_price_family_uid 
					-- Supplier / Price Family
					WHEN 2340 THEN i.default_price_family_uid
					-- Otherwise, match base case
					ELSE 0 END
				-- Price Page half, natural INTs
				= CASE pp.price_page_type_cd
					-- Item
					WHEN 212 THEN pp.inv_mast_uid 
					-- Price Family
					WHEN 2339 THEN pp.price_family_uid 
					-- Supplier / Price Family
					WHEN 2340 THEN pp.price_family_uid 
					-- Otherwise, match base case
					ELSE 0 END
			) AND (
				-- Item half, natural DECIMALs
				CASE pp.price_page_type_cd 
					-- Supplier
					WHEN 216 THEN i.primary_supplier_id 
					-- Supplier / Discount Group
					WHEN 213 THEN i.primary_supplier_id
					-- Supplier / Product Group
					WHEN 214 THEN i.primary_supplier_id
					-- Supplier / Manufacturing Class
					WHEN 215 THEN i.primary_supplier_id
					-- Supplier / Price Family
					WHEN 2340 THEN i.primary_supplier_id
					-- Otherwise, match base case
					ELSE 0 END
				-- Price Page half, natural DECIMALs
				= CASE pp.price_page_type_cd
					-- Supplier
					WHEN 216 THEN pp.supplier_id 
					-- Supplier / Discount Group
					WHEN 213 THEN pp.supplier_id
					-- Supplier / Product Group
					WHEN 214 THEN pp.supplier_id
					-- Supplier / Manufacturing Class
					WHEN 215 THEN pp.supplier_id
					-- Supplier / Price Family
					WHEN 2340 THEN pp.supplier_id 
					-- Otherwise, match base case
					ELSE 0 END
			) 

		WHERE 
			bxl.row_status_flag = 704
			-- For selected customer
			AND lxc.customer_id = @cust_id AND lxc.company_id = @comp_id 
			-- For today
			AND pp.effective_date <= GetDate() 
			AND pp.expiration_date >= GetDate()
			-- Omit not handled price_page_type_cds (should be none)
			AND pp.price_page_type_cd IN (212,213,214,215,216,217,218,219,2339,2340)
			-- Omit quantity break pricing that doesn't have a lower bracket
			AND ISNULL(pp.calculation_value1,0) < 98999

			-- Consider whether to only show one off pricing
			AND (
				@one_off_only = 'N' 
				OR pb.price_book_id LIKE '1off-%' 
				OR ISNULL(pbu.one_off,'N') = 'Y'
				OR pb.price_book_id LIKE 'CH-%' 
				OR pb.price_book_id LIKE '1ovb-%'
			)

			-- NOT SURE WHETHER TO ENABLE THIS
			-- Remove pages for one off pricing that price by large groups (manufacturing class, discount group, price family, sales discount group, supplier, etc)
			AND (
				-- Only do this for one off price lists
				@one_off_only = 'N'
				-- Only do this for ROP, MAP, PRF, OSC, and RAI items 
				OR i.primary_supplier_id NOT IN (3003400, 3003671, 3010538, 3002511, 3003625)
				-- Only include priced by customer part number or item
				OR pp.price_page_type_cd IN (219,212) 
			)
	)

	CREATE CLUSTERED INDEX idx_cpaa_one ON #cpaa (company_id, customer_id, inv_mast_uid, roll_type, lxc_sequence_number)
	
	-- Find and remove prices that won't apply due to evaluating to $0
	IF @debug_mode = 'Y'
		PRINT 'Finding prices that won''t apply because they''re $0'
	DELETE FROM #cpaa WHERE price = 0.0

	-- Find and remove prices that won't apply due to overbills
	IF @debug_mode = 'Y'
		PRINT 'Finding prices that won''t apply due to overbills'
	UPDATE cpa
	SET cpa.lowest_library_sequence_no = cpa_join.lowest_library_sequence_no
	FROM #cpaa AS cpa
	LEFT JOIN (
		SELECT cpaa2.company_id, cpaa2.customer_id, cpaa2.inv_mast_uid, cpaa2.roll_type, MIN(cpaa2.lxc_sequence_number) AS lowest_library_sequence_no
		FROM #cpaa AS cpaa2 
		GROUP BY cpaa2.company_id, cpaa2.customer_id, cpaa2.inv_mast_uid, cpaa2.roll_type
		) AS cpa_join 
		ON cpa.company_id = cpa_join.company_id
		AND cpa.customer_id = cpa_join.customer_id
		AND cpa.inv_mast_uid = cpa_join.inv_mast_uid
		AND cpa.roll_type = cpa_join.roll_type
	IF @debug_mode = 'Y'
		PRINT 'Removing that pricing'
	DELETE FROM #cpaa WHERE lowest_library_sequence_no <> lxc_sequence_number

	-- Find and remove prices that won't apply due to not being the lowest
	IF @debug_mode = 'Y'
		PRINT 'Finding prices that won''t apply due to not being the lowest'
	UPDATE cpa
	SET cpa.lowest_library_sequence_no = CASE WHEN cpa_join.lowest_price = cpa.price THEN 1 ELSE 0 END
	FROM #cpaa AS cpa
	LEFT JOIN (
		SELECT cpaa2.company_id, cpaa2.customer_id, cpaa2.inv_mast_uid, cpaa2.roll_type, 
			MIN(cpaa2.price) AS lowest_price
		FROM #cpaa AS cpaa2 
		GROUP BY cpaa2.company_id, cpaa2.customer_id, cpaa2.roll_type, cpaa2.inv_mast_uid
		) AS cpa_join 
		ON cpa.company_id = cpa_join.company_id
		AND cpa.customer_id = cpa_join.customer_id
		AND cpa.inv_mast_uid = cpa_join.inv_mast_uid
		AND cpa.roll_type = cpa_join.roll_type
	IF @debug_mode = 'Y'
		PRINT 'Removing that pricing'
	DELETE FROM #cpaa WHERE lowest_library_sequence_no <> 1

	-- Remove any extra instances of that item/price combination (where there are two pages that give the same, lowest price)
	IF @debug_mode = 'Y'
		PRINT 'Finding item/price duplicates'
	UPDATE cpa
	SET cpa.lowest_library_sequence_no = rn 
	FROM (
		SELECT inv_mast_uid, company_id, customer_id, roll_type, lowest_library_sequence_no, 
			ROW_NUMBER() OVER (PARTITION BY inv_mast_uid, company_id, customer_id, roll_type ORDER BY price_page_uid ASC) AS rn
		FROM #cpaa
		) AS cpa
	IF @debug_mode = 'Y'
		PRINT 'Removing that pricing'
	DELETE FROM #cpaa WHERE lowest_library_sequence_no > 1

	-- Remove any $0 prices
	DELETE FROM #cpaa WHERE ROUND(price,2) = 0.00

	-- Query the remaining data
	IF @group_by_mfg_class = 'N'
	BEGIN
		-- List out each item individually
		IF @debug_mode = 'Y'
			PRINT 'Listing individual item prices'
		SELECT cpaa.company_id,
			cpaa.customer_id, 
			cpaa.inv_mast_uid,
			ic.item_id,
			ic.extended_desc,
			ic.manufacturing_class_name AS manufacturing_class_desc,
			ic.manufacturing_class_id,
			ic.manufacturer_id,
			ic.manufacturer_name,
			cpaa.price,
			cpaa.contract_price,
			case when cpaa.contract_price is null then cpaa.price else cpaa.contract_price end as customer_price,
			cpaa.roll_type,
			cpaa.uom,
			cpaa.price_page_uid,
			pp.[description] AS price_page_description,
			CASE pp.price_page_type_cd
				WHEN 212 THEN 'Item'
				WHEN 213 THEN 'Supplier and Discount Group'
				WHEN 214 THEN 'Supplier and Product Group'
				WHEN 215 THEN 'Supplier and Manufacturing Class'
				WHEN 216 THEN 'Supplier'
				WHEN 217 THEN 'Sales Discount Group'
				WHEN 218 THEN 'Product Group'
				WHEN 219 THEN 'Customer Part Number'
				WHEN 2339 THEN 'Price Family'
				WHEN 2340 THEN 'Supplier and Price Family'
				ELSE 'Unknown'
			END AS price_page_type,
			dbo.kb_fn_pricing_convert(ic.item_id, cpaa.price, cpaa.uom, 'CT') AS carton_price

		FROM #cpaa AS cpaa
		INNER JOIN kb_view_item_classifications_loc100 AS ic ON cpaa.inv_mast_uid = ic.inv_mast_uid
		INNER JOIN price_page AS pp ON pp.price_page_uid = cpaa.price_page_uid
	END
	ELSE 
	BEGIN
		-- Group items by manufacturing class, where possible, else show by item
		IF @debug_mode = 'Y'
			PRINT 'Starting to group items'
		UPDATE #cpaa
		SET lxc_sequence_number = 0
		
		-- Determine which items can be grouped 
		IF @debug_mode = 'Y'
			PRINT 'Evaluating grouping items'
		UPDATE cp
		SET cp.lxc_sequence_number = 
			CASE WHEN coll.unique_prices = 1 AND ic.include_pl_by_class = 'Y' THEN 1 ELSE 0 END
		FROM #cpaa AS cp
		INNER JOIN kb_view_item_classifications_loc100 AS ic
			ON ic.inv_mast_uid = cp.inv_mast_uid
		LEFT JOIN (
			SELECT cpaa.company_id, cpaa.customer_id, ic.manufacturing_class_id, cpaa.roll_type,
				COUNT(DISTINCT cpaa.price) AS unique_prices
			FROM #cpaa AS cpaa
			INNER JOIN kb_view_item_classifications_loc100 AS ic
				ON ic.inv_mast_uid = cpaa.inv_mast_uid
			GROUP BY cpaa.company_id, cpaa.customer_id, ic.manufacturing_class_id, cpaa.roll_type
			) AS coll
			ON coll.company_id = cp.company_id
			AND coll.customer_id = cp.customer_id
			AND coll.manufacturing_class_id = ic.manufacturing_class_id
			AND coll.roll_type = cp.roll_type


		-- Show item-level prices where needed
		IF @debug_mode = 'Y'
			PRINT 'Selecting from ungrouped and grouped items'
		SELECT cpaa.company_id,
			cpaa.customer_id, 
			cpaa.inv_mast_uid,
			ic.item_id,
			ic.extended_desc,
			ic.manufacturing_class_name AS manufacturing_class_desc,
			ic.manufacturing_class_id,
			ic.manufacturer_id,
			ic.manufacturer_name,
			cpaa.price,
			cpaa.contract_price,
			case when cpaa.contract_price is null then cpaa.price else cpaa.contract_price end as customer_price,
			cpaa.roll_type,
			cpaa.uom,
			cpaa.price_page_uid,
			pp.[description] AS price_page_description,
			CASE pp.price_page_type_cd
				WHEN 212 THEN 'Item'
				WHEN 213 THEN 'Supplier and Discount Group'
				WHEN 214 THEN 'Supplier and Product Group'
				WHEN 215 THEN 'Supplier and Manufacturing Class'
				WHEN 216 THEN 'Supplier'
				WHEN 217 THEN 'Sales Discount Group'
				WHEN 218 THEN 'Product Group'
				WHEN 219 THEN 'Customer Part Number'
				WHEN 2339 THEN 'Price Family'
				WHEN 2340 THEN 'Supplier and Price Family'
				ELSE 'Unknown'
			END AS price_page_type,
			dbo.kb_fn_pricing_convert(ic.item_id, cpaa.price, cpaa.uom, 'CT') AS carton_price

		FROM #cpaa AS cpaa
		INNER JOIN kb_view_item_classifications_loc100 AS ic ON cpaa.inv_mast_uid = ic.inv_mast_uid
		INNER JOIN price_page AS pp ON pp.price_page_uid = cpaa.price_page_uid

		WHERE cpaa.lxc_sequence_number = 0

		UNION
		-- Show manufacturing class grouped prices where possible
		SELECT cpaa.company_id,
			cpaa.customer_id, 
			NULL AS inv_mast_uid,
			NULL AS item_id,
			NULL AS extended_desc,
			ic.manufacturing_class_name AS manufacturing_class_desc,
			ic.manufacturing_class_id,
			ic.manufacturer_id,
			ic.manufacturer_name,
			MIN(cpaa.price) AS price,
			MIN(cpaa.contract_price) as contract_price,
			CASE WHEN MIN(cpaa.contract_price) IS NULL THEN MIN(cpaa.price) ELSE MIN(cpaa.contract_price) END AS customer_price,
			cpaa.roll_type,
			MIN(cpaa.uom),
			MIN(cpaa.price_page_uid),
			MIN(pp.[description]) AS price_page_description,
			CASE MIN(pp.price_page_type_cd)
				WHEN 212 THEN 'Item'
				WHEN 213 THEN 'Supplier and Discount Group'
				WHEN 214 THEN 'Supplier and Product Group'
				WHEN 215 THEN 'Supplier and Manufacturing Class'
				WHEN 216 THEN 'Supplier'
				WHEN 217 THEN 'Sales Discount Group'
				WHEN 218 THEN 'Product Group'
				WHEN 219 THEN 'Customer Part Number'
				WHEN 2339 THEN 'Price Family'
				WHEN 2340 THEN 'Supplier and Price Family'
				ELSE 'Unknown'
			END AS price_page_type,
			dbo.kb_fn_pricing_convert(MIN(ic.item_id), MIN(cpaa.price), MIN(cpaa.uom), 'CT') AS carton_price

		FROM #cpaa AS cpaa
		INNER JOIN kb_view_item_classifications_loc100 AS ic ON cpaa.inv_mast_uid = ic.inv_mast_uid
		INNER JOIN price_page AS pp ON pp.price_page_uid = cpaa.price_page_uid

		WHERE cpaa.lxc_sequence_number = 1

		GROUP BY cpaa.company_id, cpaa.customer_id, ic.manufacturing_class_name, ic.manufacturing_class_id, 
			ic.manufacturer_name, ic.manufacturer_id, cpaa.roll_type

		ORDER BY manufacturer_id, manufacturing_class_desc, extended_desc, roll_type

	END
	IF @debug_mode = 'Y'
			PRINT 'Dropping temp tables'
	DROP TABLE #cpaa
	DROP TABLE #i

	RETURN
END


GO

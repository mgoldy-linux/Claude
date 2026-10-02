USE [P21Play]
GO

/*
=====================================================================================================
 dbo.asi_fnt_get_sales_manager  (inline TVF)
 Set-based replacement for two scalar UDFs, as they are called by kb_sales_history_report_view_roii_costs:
     kb_fn_get_sales_manager(@salesrep_id, @commission_class_id, NULL)        -> sales_manager_id
     kb_fn_get_sales_manager_names(@salesrep_id, @commission_class_id, NULL)  -> sales_manager_names
 (the 3rd @sales_manager_value argument was always NULL from that view, so it is dropped here)

 Why: scalar UDFs run once per row and force a serial plan; kb_fn_get_sales_manager sat inside
 a JOIN predicate. An inline TVF is expanded into the caller's plan like a view.

 Semantics kept exactly, including the two functions' differences:
   - sales_manager_id: the division's sales_manager_value -> the 'foremost' manager in
     kb_table_sales_manager_values_all; otherwise contacts.sales_manager_id. No division match = NULL value.
   - sales_manager_names: same division lookup, but a non-matching division falls back to the SUM of
     ALL the rep's manager values (the "return all managers" branch). Comma list, ordered by
     sales_manager_value, 'Name (id)'. Name logic inlined from kb_fn_get_contact_name / asi_fn_get_contact_name.
   - Return types match the scalar UDFs: VARCHAR(8) and VARCHAR(500) (truncation included).

 kb_ dependencies still here (data, not logic): kb_table_sales_manager_values, kb_table_sales_manager_values_all.
 Created 2026-10-02 Mark Goldyn.
=====================================================================================================
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION dbo.asi_fnt_get_sales_manager
(
	@salesrep_id VARCHAR(16),
	@commission_class_id VARCHAR(8)
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		CAST(COALESCE(
			(SELECT smva.salesrep_id_varchar
			 FROM kb_table_sales_manager_values_all AS smva
			 WHERE smva.sales_manager_value = mv.value_for_id
				AND smva.foremost = 1),
			(SELECT c.sales_manager_id FROM contacts AS c WHERE c.id = @salesrep_id)
		) AS VARCHAR(8)) AS sales_manager_id

		,CAST(STUFF(
			(SELECT ', '
					+ LTRIM(RTRIM(
						CASE
							WHEN LEN(RTRIM(LTRIM(ISNULL(cu.nickname, '')))) > 0 THEN
								CASE WHEN SUBSTRING(LTRIM(cu.nickname), 1, 1) = '*'
									THEN cu.nickname + ' ' + c.first_name
									ELSE cu.nickname
								END
							ELSE c.first_name
						END + ' ' + c.last_name))
					+ ' (' + c.id + ')'
			 FROM kb_table_sales_manager_values_all AS smva
			 INNER JOIN contacts AS c ON smva.salesrep_id_varchar = c.id
			 LEFT JOIN contacts_ud AS cu ON c.id = cu.id
			 INNER JOIN kb_table_sales_manager_values AS smv ON smv.salesrep_id_varchar = smva.salesrep_id_varchar
			 WHERE smva.sales_manager_value = mv.value_for_names
			 ORDER BY smv.sales_manager_value ASC
			 FOR XML PATH(''), TYPE
			).value('.', 'VARCHAR(MAX)')
		, 1, 2, '') AS VARCHAR(500)) AS sales_manager_names

	FROM (SELECT (SELECT iccu.division
				  FROM item_commission_class_ud AS iccu
				  WHERE iccu.commission_class_id = @commission_class_id) AS division
		) AS d
	CROSS APPLY (
		SELECT
			-- kb_fn_get_sales_manager: unknown division -> NULL
			(SELECT CASE d.division
						WHEN 'Flooring'  THEN su.sales_manager_value_flooring
						WHEN 'Surfacing' THEN su.sales_manager_value_laminate
						WHEN 'Board'     THEN su.sales_manager_value_board
						WHEN 'Pad'       THEN su.sales_manager_value_pad
						WHEN 'Supplies'  THEN su.sales_manager_value_supplies
						ELSE NULL END
			 FROM contacts_ud AS su
			 WHERE su.id = @salesrep_id) AS value_for_id

			-- kb_fn_get_sales_manager_names: unknown division -> every manager the rep has
			,(SELECT CASE d.division
						WHEN 'Flooring'  THEN su.sales_manager_value_flooring
						WHEN 'Surfacing' THEN su.sales_manager_value_laminate
						WHEN 'Board'     THEN su.sales_manager_value_board
						WHEN 'Pad'       THEN su.sales_manager_value_pad
						WHEN 'Supplies'  THEN su.sales_manager_value_supplies
						ELSE
							CASE WHEN @salesrep_id IS NULL THEN NULL
							ELSE (
								SELECT SUM(DISTINCT smv.sales_manager_value)
								FROM kb_table_sales_manager_values_all AS smva
								INNER JOIN kb_table_sales_manager_values AS smv ON smva.salesrep_id_varchar = smv.salesrep_id_varchar
								WHERE smva.sales_manager_value IN (su.sales_manager_value_flooring, su.sales_manager_value_laminate,
									su.sales_manager_value_board, su.sales_manager_value_pad, su.sales_manager_value_supplies)
							)
							END
						END
			 FROM contacts_ud AS su
			 WHERE su.id = @salesrep_id) AS value_for_names
	) AS mv
)
GO

GRANT SELECT ON dbo.asi_fnt_get_sales_manager TO p21_application_role
GO
GRANT SELECT ON dbo.asi_fnt_get_sales_manager TO PxxiUser
GO

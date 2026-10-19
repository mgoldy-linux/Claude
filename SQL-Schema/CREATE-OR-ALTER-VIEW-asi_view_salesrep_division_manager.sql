USE [P21] -- [P21Play]
GO

/*
=====================================================================================================
 dbo.asi_view_salesrep_division_manager
 Lookup of rep x division -> sales manager, plus the rep's display name.
 Replaces, for portal tabs:   kb_fn_get_sales_manager(@salesrep_id, @commission_class_id, NULL)
                              kb_view_salesrep.salesrep_name (-> kb_fn_get_contact_name)
 as plain joins (a scalar UDF per row forces a serial plan; PowerBuilder can't parse APPLY/TVF calls).

 One row per salesrep (contacts.salesrep = 'Y') per division. division '' = "no/unknown division"
 (commission class missing from item_commission_class_ud, or a division outside the five) ->
 falls back to contacts.sales_manager_id, exactly as the scalar UDF did.
 Join in a .srd:
   LEFT JOIN item_commission_class_ud iccu ON iccu.commission_class_id = <inv_mast>.commission_class_id
   LEFT JOIN asi_view_salesrep_division_manager sm ON sm.salesrep_id = <updated_salesrep_id>
                                                  AND sm.division = COALESCE(iccu.division, '')

 kb_ dependency still here (DATA only): kb_table_sales_manager_values_all.
 Created 2026-10-16 Mark Goldyn.
=====================================================================================================
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW dbo.asi_view_salesrep_division_manager
AS
SELECT
	CONVERT(INT, c.id) AS salesrep_id,
	d.division,
	CAST(COALESCE(smva.salesrep_id_varchar, c.sales_manager_id) AS VARCHAR(8)) AS sales_manager_id,
	CAST(LTRIM(RTRIM(
		CASE WHEN LEN(RTRIM(LTRIM(ISNULL(cu.nickname, '')))) > 0
			THEN CASE WHEN SUBSTRING(LTRIM(cu.nickname), 1, 1) = '*'
				THEN cu.nickname + ' ' + c.first_name
				ELSE cu.nickname END
			ELSE c.first_name END
		+ ' ' + c.last_name)) AS VARCHAR(65)) AS salesrep_name
FROM contacts AS c
LEFT JOIN contacts_ud AS cu ON cu.id = c.id
CROSS JOIN (
	SELECT division FROM item_commission_class_ud WHERE division IS NOT NULL AND division <> ''
	UNION
	SELECT ''
) AS d
-- compute the division's manager value first, then match it by equality so the kb_ table is SEEKED
-- (a CASE inside the predicate forced a scan per row: 589K reads per evaluation of the view)
CROSS APPLY (
	SELECT CASE d.division
		WHEN 'Flooring'  THEN cu.sales_manager_value_flooring
		WHEN 'Surfacing' THEN cu.sales_manager_value_laminate
		WHEN 'Board'     THEN cu.sales_manager_value_board
		WHEN 'Pad'       THEN cu.sales_manager_value_pad
		WHEN 'Supplies'  THEN cu.sales_manager_value_supplies
		ELSE NULL END AS mgr_value
) AS mv
LEFT JOIN kb_table_sales_manager_values_all AS smva
	ON smva.foremost = 1
	AND smva.sales_manager_value = mv.mgr_value
WHERE c.salesrep = 'Y'
GO

GRANT SELECT ON dbo.asi_view_salesrep_division_manager TO p21_application_role
GO
GRANT SELECT ON dbo.asi_view_salesrep_division_manager TO PxxiUser
GO

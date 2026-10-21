/* ----------------------------------------------------------------------------
   SA 57138 - Usage Query Template (Alex Boeve, Commodity Manager - Sundries)
   Enter a supplier ID -> every item/location whose PRIMARY supplier it is, with
   the last 12 demand periods of usage (current, partial period included).
   Source: data warehouse asdwdb01.ahi.local / P21 (nightly Prod restore).
   Column order matches the attached "Usage Query Template.xlsx" row 2.
   p21_view_* + inv_mast_ud only - no kb_/js_/ds_ objects.
   ---------------------------------------------------------------------------- */
DECLARE @supplier_id DECIMAL = 3003671;   -- Excel SupplierID cell (B1) replaces this

SELECT  ud.division                    AS [Division],
        m.default_product_group        AS [Product Group],
        l.location_id                  AS [Location],
        l.replenishment_location       AS [Replenish Location],
        l.item_id                      AS [Item ID],
        l.discontinued                 AS [Discontinued Flag],
        l.stockable                    AS [Stockable Flag],
        d.period                       AS [Month (period)],
        d.year_for_period              AS [Year],
        u.inv_period_usage             AS [Actual Usage],
        u.filtered_usage               AS [Filtered Usage (BUOM)]
FROM    p21_view_inv_loc l
        JOIN p21_view_inv_mast m          ON m.inv_mast_uid = l.inv_mast_uid
        LEFT JOIN inv_mast_ud ud          ON ud.inv_mast_uid = l.inv_mast_uid
        JOIN p21_view_inv_period_usage u  ON u.inv_mast_uid = l.inv_mast_uid
                                         AND u.location_id  = l.location_id
        JOIN p21_view_demand_period d     ON d.demand_period_uid = u.demand_period_uid
                                         AND d.company_id = l.company_id
WHERE   l.primary_supplier_id = @supplier_id
  AND   l.delete_flag = 'N'
  AND   m.delete_flag = 'N'
  AND   d.computed_year_period >= (SELECT YEAR(DATEADD(MONTH, -11, GETDATE())) * 100
                                          + MONTH(DATEADD(MONTH, -11, GETDATE())))
  AND   d.computed_year_period <= (SELECT YEAR(GETDATE()) * 100 + MONTH(GETDATE()))
ORDER BY l.location_id, l.item_id, d.computed_year_period;

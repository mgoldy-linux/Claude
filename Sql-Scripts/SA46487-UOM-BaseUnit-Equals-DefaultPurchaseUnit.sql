-- SA 46487 - UOM Ad Hoc Report
-- Items where Base Unit = Default Purchase Unit
-- Columns match the P21 Unit Info tab (Item Maintenance)

USE P21; -- P21BusinessRules;  -- 
GO

SELECT
     im.item_id
    ,im.item_desc
    ,im.base_unit                                                               AS [Unit of Measure]
    ,uom.unit_description                                                       AS [Unit Description]
    ,iu.unit_size                                                               AS [Unit Size]
    ,iu.selling_unit                                                            AS [Default Sales Unit]
    ,CASE WHEN im.sales_pricing_unit    = im.base_unit THEN 'Y' ELSE 'N' END   AS [Default Sales Pricing Unit]
    ,iu.purchasing_unit                                                         AS [Default Purchase Unit]
    ,CASE WHEN im.purchase_pricing_unit = im.base_unit THEN 'Y' ELSE 'N' END   AS [Default Purchase Pricing Unit]
    ,'Y'                                                                        AS [Base Unit]
    ,CASE WHEN iu.inv_mast_uid IS NOT NULL THEN 'Y' ELSE 'N' END               AS [Base Unit Is Item UOM]
    ,iu.wwms_flag                                                               AS [WWMS Unit]
FROM inv_mast im WITH (NOLOCK)
LEFT JOIN item_uom iu WITH (NOLOCK)
    ON  iu.inv_mast_uid    = im.inv_mast_uid
    AND iu.unit_of_measure = im.base_unit
    AND iu.delete_flag     = 'N'
LEFT JOIN unit_of_measure uom WITH (NOLOCK)
    ON  uom.unit_id        = iu.unit_of_measure
WHERE im.base_unit = im.default_purchasing_unit
  AND im.delete_flag = 'N'
  AND im.base_unit IS NOT NULL
ORDER BY im.item_id

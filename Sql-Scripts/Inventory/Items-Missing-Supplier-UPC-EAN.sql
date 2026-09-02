/*  Items-Missing-Supplier-UPC-EAN.sql
    --------------------------------------------------------------------------
    Item / supplier rows where the UPC or EAN barcode is missing.

    UPC and EAN codes in P21 are held PER SUPPLIER, not per location and not
    on the item master:
        inventory_supplier.upc_code     varchar(14)
        inventory_supplier.check_digit  decimal
        inventory_supplier.ean_code     varchar(255)
    (inv_mast.upc_or_ean_id is a separate, essentially unused item-level field
     -- ignore it for this request.)

    Grain: one row per item x supplier (inventory_supplier).
    Tables all stock P21 (inventory_supplier / inv_mast / supplier) - no kb_/js_.

    P21 Prod snapshot 2026-09-02, active item + active inv_supplier link + active
    supplier (144,741 rows):
        missing UPC ......... 141,733  (~98%)
        missing EAN ......... 106,850  (~74%)
        missing UPC or EAN .. 143,457  (~99%)
        missing UPC and EAN . 105,126  (~73%)
    i.e. the barcode fields are almost entirely unpopulated - expect a very
    large result. (primary_supplier_flag is blank on every row, so "primary
    supplier only" is not a usable filter here.)
    --------------------------------------------------------------------------  */

SELECT  im.item_id,
        im.item_desc,
        im.extended_desc,
        isup.supplier_part_no,
        s.supplier_name,
        isup.supplier_id,
        isup.upc_code,
        isup.check_digit,
        isup.ean_code
FROM    inventory_supplier isup
JOIN    inv_mast im ON im.inv_mast_uid = isup.inv_mast_uid AND im.delete_flag = 'N'
JOIN    supplier  s ON s.supplier_id   = isup.supplier_id  AND s.delete_flag  = 'N'
WHERE   isup.delete_flag = 'N'
  AND ( NULLIF(LTRIM(RTRIM(isup.upc_code)), '') IS NULL      -- no UPC
     OR NULLIF(LTRIM(RTRIM(isup.ean_code)), '') IS NULL )    -- ...or no EAN
  /* -- for rows missing BOTH, swap the OR above for: AND ... AND ...          */
ORDER BY s.supplier_name, im.item_id;


------------------------------------------------------------------------------
-- Rollup by supplier (how much of each supplier's catalog has no barcode)
------------------------------------------------------------------------------
-- SELECT s.supplier_id, s.supplier_name,
--        COUNT(*)                                                            AS item_supplier_rows,
--        SUM(CASE WHEN NULLIF(LTRIM(RTRIM(isup.upc_code)),'') IS NULL THEN 1 ELSE 0 END) AS missing_upc,
--        SUM(CASE WHEN NULLIF(LTRIM(RTRIM(isup.ean_code)),'') IS NULL THEN 1 ELSE 0 END) AS missing_ean,
--        SUM(CASE WHEN NULLIF(LTRIM(RTRIM(isup.upc_code)),'') IS NULL
--                   OR NULLIF(LTRIM(RTRIM(isup.ean_code)),'') IS NULL THEN 1 ELSE 0 END) AS missing_either
-- FROM   inventory_supplier isup
-- JOIN   inv_mast im ON im.inv_mast_uid = isup.inv_mast_uid AND im.delete_flag = 'N'
-- JOIN   supplier  s ON s.supplier_id   = isup.supplier_id  AND s.delete_flag  = 'N'
-- WHERE  isup.delete_flag = 'N'
-- GROUP BY s.supplier_id, s.supplier_name
-- HAVING SUM(CASE WHEN NULLIF(LTRIM(RTRIM(isup.upc_code)),'') IS NULL
--                   OR NULLIF(LTRIM(RTRIM(isup.ean_code)),'') IS NULL THEN 1 ELSE 0 END) > 0
-- ORDER BY missing_either DESC;

/*  Perf note: the NULLIF(LTRIM(RTRIM())) blank tests aren't SARGable, but the
    driver is the two delete_flag='N' joins; inventory_supplier is ~161k rows,
    so a full pass is cheap. No plan hints needed for an ad-hoc extract.        */

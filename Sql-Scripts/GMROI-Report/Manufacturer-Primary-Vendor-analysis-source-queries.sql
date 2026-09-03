/* =====================================================================
   GMROI report — "is each manufacturer a primary vendor?"  (Jerome Butler, no ticket)
   Source queries behind  GMROI-Manufacturer-Primary-Vendor-Analysis.xlsx
   Run against P21 Prod (p21.allsurfaces.com / p21). 2026-09-03.

   The report's "manufacturer" is a P21 inventory Manufacturer CLASS
   (class.class_id where class_type='IV' AND class_number=1). It has NO key
   to vendor_id / supplier_id. vendor_supplier only pairs supplier_id <->
   vendor_id with a primary_vendor flag ('Y' on ~83% of rows, so weak alone).

   Approach: per manufacturer class -> every supplier of its items
   (inventory_supplier) ranked by item count -> "dominant supplier" ->
   roll up to vendor via vendor_supplier + vendor -> fuzzy name-match
   (done in PowerShell, see Deploy-Guides\gmroi-report-kb-view-removal.md).

   NOTE: inventory_supplier.primary_supplier_flag is BLANK on every row in
   this DB, and inv_mast has no primary_supplier_id, so "dominant supplier"
   is derived by item volume, not an explicit P21 flag.
   ===================================================================== */

-- 1) Manufacturer classes (code -> description)
SELECT class_id, class_description
FROM class
WHERE class_type = 'IV' AND class_number = 1;

-- 2) Suppliers of the items in each manufacturer class, by item count
SELECT im.class_id1 AS mfr_code, isup.supplier_id, s.supplier_name,
       COUNT(DISTINCT im.inv_mast_uid) AS item_ct
FROM inv_mast im
JOIN inventory_supplier isup
     ON isup.inv_mast_uid = im.inv_mast_uid
     AND isup.delete_flag = 'N'
JOIN supplier s
     ON s.supplier_id = isup.supplier_id
WHERE im.delete_flag = 'N'
  AND im.class_id1 IS NOT NULL
  AND im.class_id1 <> ''
GROUP BY im.class_id1, isup.supplier_id, s.supplier_name;

-- 3) vendor_supplier pairings with names + the primary_vendor flag
SELECT vs.supplier_id, s.supplier_name, vs.vendor_id, v.vendor_name,
       vs.primary_vendor, vs.delete_flag
FROM vendor_supplier vs
JOIN supplier s ON s.supplier_id = vs.supplier_id
JOIN vendor   v ON v.vendor_id   = vs.vendor_id;

-- 4) full supplier / vendor name lists (for the "match against ALL" pass)
SELECT supplier_id, supplier_name, delete_flag FROM supplier;
SELECT vendor_id,   vendor_name,   delete_flag FROM vendor;

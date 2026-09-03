# Deployment Guide — (no ticket) GMROI Report: remove `kb_view_item_classifications_loc100` from Power Query

> Produced during development 2026-09-03. Update as the artifact changes; commit with the code.

## Artifact(s)
- **Workbook:** `…\OneDrive - All Surfaces Inc\Documents\Excel\GMROI inventory turns by manufacturer from Derek refreshable 8.19.25 MG_unprotected.xlsx`
  — the Power Query named **`Trailing-90-Day-qry`** (feeds the **Sales** sheet).
- **Repo copy of the rewritten SQL:** `Sql-Scripts/GMROI-Report/Trailing-90-Day-qry-REWRITTEN-no-kb.sql`
- Ticket: none (ad-hoc, originated from Jerome Butler's "is the manufacturer a primary vendor?" question)
- Related, separate deliverable: `GMROI-Manufacturer-Primary-Vendor-Analysis.xlsx` (standalone; not part of this change)

## What changed
One join in `Trailing-90-Day-qry`:

| | Before | After |
|---|---|---|
| join | `INNER JOIN kb_view_item_classifications_loc100 k ON i.inv_mast_uid = k.inv_mast_uid` | `INNER JOIN p21_view_inv_mast im ON im.inv_mast_uid = i.inv_mast_uid` + `LEFT JOIN p21_view_class mfr_class ON im.class_id1 = mfr_class.class_id AND mfr_class.class_type='IV' AND mfr_class.class_number=1` |
| `manufacturer_id` | `k.manufacturer_id` | `im.class_id1` |
| `manufacturer_name` | `k.manufacturer_name` | `mfr_class.class_description` |

This is the identical manufacturer-class lookup the workbook's **other** query
(`qryInventoryValuebyLocation`, the Inventory sheet) already uses. That query was
already `kb_`-free — no change needed there. After this edit **both** queries in the
workbook are `kb_`-free.

## Target
- The workbook above (`MG_unprotected` copy) — **DONE 2026-09-03**.
- **Derek Sievertsen's "refreshable" master** (the file this copy derives from) — the
  same one-join edit should be applied there so it isn't lost. Path not yet confirmed;
  ask Derek / Jerome. **NOT DONE.**

## Dependencies & deploy order
- None. Pure query-text change, no DB objects created. `kb_view_item_classifications_loc100`
  itself is left untouched.

## Backward-compatibility notes
- Output schema is unchanged: same column names, order, and grain. Proven below.
- The rewrite drops the `kb_` view's incidental scan of `inventory_supplier` (~336K scans
  for columns the report never used) → measurably lighter, see Verification.

## Deploy steps (Excel, per workbook copy)
1. Back up the workbook first: `<name>.PRE-KBFIX-<yyyymmdd-hhmmss>.xlsx`
   (done for MG_unprotected: `…PRE-KBFIX-20260903-111101.xlsx`).
2. Open the workbook → **Data → Queries & Connections** → right-click `Trailing-90-Day-qry`
   → **Edit** → **Advanced Editor**.
3. Replace the `kb_` join + the two `k.manufacturer_*` column refs (SELECT list and
   GROUP BY) per the table above. Full text: `Sql-Scripts/GMROI-Report/Trailing-90-Day-qry-REWRITTEN-no-kb.sql`.
4. **Close & Load**, then **Refresh All**.
   - The MG_unprotected copy was edited head-less via Excel COM
     (`Queries("Trailing-90-Day-qry").Formula`), signature/sheets/cached data all intact,
     verified — but it has **not been Refresh-All'd through Excel yet**. The Sales tab
     still shows cached rows from the old query. First user action: open + Refresh All.

## Verification
- **Equivalence (proven on Prod, `EXCEPT` both directions):**
  - manufacturer columns only, `(inv_mast_uid, manufacturer_id, manufacturer_name)`:
    `kb EXCEPT native = 0`, `native EXCEPT kb = 0`, 150,642 rows each.
  - full report query: same **2,443 rows**, `EXCEPT` 0/0 both ways,
    `SUM(sales) = 83,353,406.37` and `SUM(cost) = 60,717,901.91` identical.
- **Performance (measured, `SET STATISTICS IO/TIME`, warm cache):**
  logical reads **20,913,743 → 19,817,584 (−5.2%)**, CPU **46.4 s → 44.0 s**,
  elapsed 34 s → 23 s.
- **Post-edit workbook checks:** re-extracted the DataMashup — **0 `kb_`** in either
  query; all 5 sheets present; sheet data byte-identical to the pre-edit backup (0 row diffs).
- After Refresh All: Sales sheet still has ~2,443 rows, `manufacturer_id` / `manufacturer_name`
  populated as before, brand/location/GP columns unchanged.

## Rollback
- Restore `…GMROI inventory turns by manufacturer from Derek refreshable 8.19.25 MG_unprotected.PRE-KBFIX-20260903-111101.xlsx`
  over the working file. That copy predates the query edit (data identical, `kb_` join intact).

## Tracker
- `kb-replacement-tracker.csv` row added 2026-09-03 (`kb_view_item_classifications_loc100`
  → `p21_view_inv_mast` + `p21_view_class`, View Join, Excel / Power Query report).

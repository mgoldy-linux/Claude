# SA-50249 Step 02 — generate the persistent objects in ASI_ReportCache

These three objects are **generated from the already-validated `_fast3` logic** (proven equal to the
original view in P21Play, EXCEPT both ways, all 195 columns). They live in `ASI_ReportCache` and
reference `P21.dbo.*` via **3-part names** so they survive the nightly P21 restore.

## Objects
1. **`dbo.SalesrepManagerMap`** — table
   ```sql
   CREATE TABLE dbo.SalesrepManagerMap (
       salesrep_id_varchar VARCHAR(16)  NULL,
       commission_class_id VARCHAR(8)   NULL,
       manager_id          VARCHAR(16)  NULL,
       manager_name        VARCHAR(500) NULL
   );
   CREATE CLUSTERED INDEX CX_SalesrepManagerMap
       ON dbo.SalesrepManagerMap(salesrep_id_varchar, commission_class_id);
   ```
2. **`dbo.FiveWaySalesCompute`** — VIEW = the `_fast3` definition with:
   - every `P21` base object (`invoice_line`, `oe_line`, `inv_mast`, `contacts`, `p21_view_*`,
     `kb_view_*`, `kb_fn_*`, …) qualified to **`P21.dbo.<name>`**;
   - the sales-manager-name join pointed at **`dbo.SalesrepManagerMap`** (local);
   - product-manager map + inlined manager_id exactly as validated in `_fast3`.
3. **`dbo.FiveWaySalesFact`** — table + clustered columnstore, structure from the compute view:
   ```sql
   SELECT * INTO dbo.FiveWaySalesFact FROM dbo.FiveWaySalesCompute WHERE 1 = 0;
   CREATE CLUSTERED COLUMNSTORE INDEX CCI_FiveWaySalesFact ON dbo.FiveWaySalesFact;
   ```

## Generation (from the validated Play view)
The validated `_fast3` and map definitions are saved in the working scratchpad
(`CREATE_fast3.sql`, plus the product-manager CASE and map-build SQL). The generator:
1. reads the `_fast3` view body,
2. qualifies P21 object references to 3-part `P21.dbo.*`,
3. repoints the map join to `ASI_ReportCache.dbo.SalesrepManagerMap`,
4. renames the view to `FiveWaySalesCompute`.

> **REVIEW/TEST REQUIRED:** the 2-part → 3-part qualification must be verified object-by-object on
> the DW (a missed qualifier would bind to `ASI_ReportCache` instead of `P21`). Recommended: generate,
> then `EXCEPT` both-ways `FiveWaySalesCompute` vs `P21.dbo.asi_3yr_sales_history_report_view` on a
> populated slice **on the DW** before wiring up the proc — same gate we used in Play.

## Alternative considered (documented, not chosen)
Keep `FiveWaySalesCompute` inside `P21` (2-part names, no qualification) and have the refresh proc
`CREATE OR ALTER` it each night post-restore. Avoids 3-part rewriting but puts a volatile 58 KB view
definition inside the proc. Chosen approach (3-part view in `ASI_ReportCache`) keeps all logic
persistent and inspectable; revisit if qualification proves fragile.

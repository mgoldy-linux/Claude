/* ============================================================================
   inv_loc bulk replenishment-setting change  --  SIDE-EFFECT CHECK (READ-ONLY)
   ----------------------------------------------------------------------------
   Run order:   P21Dev  first, then  P21Training   (change the USE below)
   Author:      mgoldyn / Claude session
   Date:        2026-09-13

   WHY: Extended Events trace of the native P21 "Build/Update Items" import
   (Sql-Scripts\Extended-Events\Trace-Replenishment-Method-Import.sql, read
   back via Read-Trace-Filtered-2026-09-13.sql) showed the import forces
   TWO unrequested side effects on every inv_loc row it touches, not just
   the rows where replenishment_method actually changes:
     - iva_taxable_flag   -> unconditionally set to 'N'
     - usage_lock_period / usage_lock_year -> unconditionally set to NULL
       (seen on one location row per item in the 10-item test trace)

   The team already decided to do the real bulk change via a direct SQL
   batch UPDATE (Batch-Update-inv_loc-Replenishment.sql), which does NOT
   touch these columns. This script just quantifies whether that distinction
   matters in practice -- i.e. whether any in-scope row would actually lose
   data if it had gone through the native import path instead.

   Scope: same as inv_loc-replenishment-change-impact-counts.sql --
   delete_flag = 'N'.
   ============================================================================ */

USE P21Training; --P21Dev;      -- <<< switch to P21Training for the second run
GO

/* ---- 1. iva_taxable_flag distribution, in-scope rows ---------------------- */
SELECT ISNULL(iva_taxable_flag,'(NULL)') AS iva_taxable_flag,
       COUNT(*)                          AS row_count
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
GROUP  BY iva_taxable_flag
ORDER  BY row_count DESC;
GO

/* ---- 2. iva_taxable_flag = 'Y' rows that ALSO need the replenishment_method
          change -- these are the rows that would lose data if the native
          import had been used instead of the batch UPDATE. ----------------- */
SELECT COUNT(*) AS at_risk_rows_iva_Y_and_needs_replenishment_change
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
  AND  iva_taxable_flag = 'Y'
  AND  (replenishment_method <> 'Up To' OR replenishment_method IS NULL);
GO

/* ---- 3. iva_taxable_flag = 'Y' rows that would NOT otherwise be touched
          by the batch UPDATE (i.e. same rows the native import would still
          blanket-touch just by processing the item, even with no field
          change needed) -- confirms scope of the native-import blast radius
          vs. the batch UPDATE's narrower one. ------------------------------ */
SELECT COUNT(*) AS iva_Y_rows_in_scope_total
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
  AND  iva_taxable_flag = 'Y';
GO

/* ---- 4. usage_lock_period / usage_lock_year -- how many in-scope rows
          currently have a non-NULL value that the native import would wipe. */
SELECT
   SUM(CASE WHEN usage_lock_period IS NOT NULL THEN 1 ELSE 0 END) AS rows_with_usage_lock_period_set,
   SUM(CASE WHEN usage_lock_year   IS NOT NULL THEN 1 ELSE 0 END) AS rows_with_usage_lock_year_set
FROM   dbo.inv_loc
WHERE  delete_flag = 'N';
GO

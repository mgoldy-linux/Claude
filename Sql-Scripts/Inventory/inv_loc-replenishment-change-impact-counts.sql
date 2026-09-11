/* ============================================================================
   inv_loc bulk replenishment-setting change  --  IMPACT COUNTS (READ-ONLY)
   ----------------------------------------------------------------------------
   Run order:   P21Dev  first, then  P21Training   (change the USE below)
   Author:      mgoldyn / Claude session
   Date:        2026-09-10

   Proposed updates (management report):
     1. inv_loc.replenishment_method  ->  'Up To'
     2. inv_loc.inv_min               ->  0
     3. inv_loc.safety_stock_type     ->  0        ('ABC Class')

   Scope:   every row where delete_flag = 'N'   (NULLs reported separately in #0)
   Counts:  rows that would ACTUALLY change value. Rows already at the target
            value are no-ops and are excluded from the "would_change" numbers.

   NOTE: no UPDATE statements in this file. Each batch is GO-separated so one
         bad object name cannot abort the rest.
   ============================================================================ */

USE P21Dev;      -- <<< switch to P21Training for the second run
GO

/* ---- 0. delete_flag distribution  (confirms in-scope row total) ----------- */
SELECT ISNULL(delete_flag,'(NULL)') AS delete_flag,
       COUNT(*)                     AS row_count
FROM   dbo.inv_loc
GROUP  BY delete_flag
ORDER  BY delete_flag;
GO

/* ---- 1. DISCOVERY -- current values, so the counts below are correct ------ */

-- 1a. replenishment_method: confirm the EXACT stored spelling of the "Up To"
--     option before trusting would_change_replenishment_method in step 2.
SELECT ISNULL(replenishment_method,'(NULL)') AS replenishment_method,
       COUNT(*)                              AS row_count
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
GROUP  BY replenishment_method
ORDER  BY row_count DESC;
GO

-- 1b. safety_stock_type: confirm 0 is the "ABC Class" code in this DB.
SELECT safety_stock_type,
       COUNT(*) AS row_count
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
GROUP  BY safety_stock_type
ORDER  BY safety_stock_type;
GO

-- 1c. inv_min buckets
SELECT CASE WHEN inv_min IS NULL THEN '(NULL)'
            WHEN inv_min = 0     THEN '0  (already target)'
            ELSE                      '<> 0' END AS inv_min_bucket,
       COUNT(*)                                  AS row_count
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
GROUP  BY CASE WHEN inv_min IS NULL THEN '(NULL)'
               WHEN inv_min = 0     THEN '0  (already target)'
               ELSE                      '<> 0' END;
GO

/* ---- 2. CHANGE COUNTS  -- the three numbers for management ---------------- *
   >>> After step 1a, replace 'Up To' in the first sub-select with the exact
       string P21 stores, if it differs. <<<
 * ------------------------------------------------------------------------- */
SELECT
   (SELECT COUNT(*) FROM dbo.inv_loc
     WHERE delete_flag = 'N'
       AND (replenishment_method <> 'Up To' OR replenishment_method IS NULL)
   ) AS would_change_replenishment_method,

   (SELECT COUNT(*) FROM dbo.inv_loc
     WHERE delete_flag = 'N'
       AND (inv_min <> 0 OR inv_min IS NULL)
   ) AS would_change_inv_min,

   (SELECT COUNT(*) FROM dbo.inv_loc
     WHERE delete_flag = 'N'
       AND (safety_stock_type <> 0 OR safety_stock_type IS NULL)
   ) AS would_change_safety_stock_type,

   (SELECT COUNT(*) FROM dbo.inv_loc
     WHERE delete_flag = 'N'
   ) AS total_in_scope_rows;
GO

/* ---- 3. rows touched by AT LEAST ONE of the three updates ---------------- */
SELECT COUNT(*) AS rows_touched_by_any_update
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
  AND (
        (replenishment_method <> 'Up To' OR replenishment_method IS NULL)
     OR (inv_min <> 0 OR inv_min IS NULL)
     OR (safety_stock_type <> 0 OR safety_stock_type IS NULL)
      );
GO

/* ---- 4. OPTIONAL -- BOM-component overlap (the P21 Dev popup you saw) ----- *
   The "This item/unit of measure combination is used as a component of an
   existing assembly ... Convert at OE" message is P21 *client-side* validation
   on the Item Location screen. A direct SQL UPDATE runs no business rule and
   will NOT raise it. This count is only to quantify, for the writeup, how many
   in-scope rows belong to items that are assembly components.

   This DB has no bom_line table. Run 4a first to find the real name/column,
   then run 4b. This batch is isolated by GO -- a wrong name does not affect 0-3.
 * ------------------------------------------------------------------------- */

-- P21 assembly definition: assembly_line.component_inv_mast_uid = the COMPONENT
-- item (assembly_line.inv_mast_uid is the assembly PARENT -- do not use that here).
SELECT COUNT(*) AS in_scope_rows_whose_item_is_an_assembly_component
FROM   dbo.inv_loc il
WHERE  il.delete_flag = 'N'
  AND  EXISTS (SELECT 1 FROM dbo.assembly_line al
               WHERE al.component_inv_mast_uid = il.inv_mast_uid
                 AND al.delete_flag = 'N');
GO

-- For reference: item-locations whose item is an assembly PARENT (this is what
-- the earlier draft counted by mistake -- 27,136 in P21Dev).
SELECT COUNT(*) AS in_scope_rows_whose_item_is_an_assembly_parent
FROM   dbo.inv_loc il
WHERE  il.delete_flag = 'N'
  AND  EXISTS (SELECT 1 FROM dbo.assembly_line al
               WHERE al.inv_mast_uid = il.inv_mast_uid
                 AND al.delete_flag = 'N');
GO


/* ============================================================================
   WHEN YOU RUN THE REAL UPDATE  (guidance -- not executed here)
   ----------------------------------------------------------------------------
   * Small-subset test first: scope to a handful of inv_mast_uid values (or one
     low-volume location_id) and eyeball the Item Location screen afterward.

   * Take a rollback image before any write:
        SELECT inv_mast_uid, location_id,
               replenishment_method, inv_min, safety_stock_type
        INTO   dbo.zz_inv_loc_bkp_20260910
        FROM   dbo.inv_loc
        WHERE  delete_flag = 'N';

   * Only write rows that differ (matches the counts above -- no wasted writes,
     smaller transaction log, fewer locks):
        WHERE delete_flag = 'N'
          AND (replenishment_method <> 'Up To' OR replenishment_method IS NULL)

   * Batch large updates (inv_loc is big) to avoid lock escalation and log
     growth -- e.g. UPDATE TOP (10000) ... in a loop until @@ROWCOUNT = 0,
     run outside business hours.

   * inv_loc has no kb_/js_ dependencies -- dependency chain is clean.
   ============================================================================ */

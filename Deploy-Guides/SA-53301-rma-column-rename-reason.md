# Deployment Guide — SA-53301 RMA Column Rename: "Lost Sales Desc" → "Reason"

> Follow-up to [SA-51376](SA-51376-rma-transaction-history-reason-code.md), which added the column. This ticket only renames its header.

## Artifact(s)
- DynaChange screen customization on **Transaction Master Inquiry Orders**, RMA tab — column `ufc_lost_sales_lost_sales_desc`
- Ticket: SA-53301

## Target environments
- **Play** (P21Play @ P21Dev.allsurfaces.com) — done
- **Business Rules** (P21BusinessRules @ P21Dev.allsurfaces.com) — done, used as a Prod dry run
- **Prod** (P21 @ P21.allsurfaces.com) — done 2026-08-27

**Status: CLOSED.** Jessica & Chad signed off on the Play change 2026-08-26; user ran the Prod script 2026-08-27 and confirmed complete, no errors.

## Dependencies & deploy order
No cross-artifact dependency — this is a same-database, three-statement rename. Order within a single run matters only in that step 3 (`version_desc`) depends on nothing failing in steps 1–2; all three are independent scopes (`custom_objects_detail`, `fc_dataobject_column`, `custom_objects`) and can run in any order.

## Backward-compatibility notes
- The underlying field/data source (`lost_sales.lost_sales_desc`) is unchanged — this is a display-label-only change, not a schema change. No rule, view, or report references the on-screen label text.

## Deploy steps
1. **Play:** `Sql-Scripts\Update-SA53301-RMA-ColumnHeader-Play.sql`, then `Update-SA53301-Version-Desc-Play.sql`, then `Update-SA53301-AuditColumns-Play.sql` — all against `USE P21Play`. **Done, verified.**
2. **Business Rules (dry run):** `Sql-Scripts\Update-SA53301-RMA-ColumnHeader-Prod.sql` against `USE P21BusinessRules`. **Done** — steps 1–2 (header text, shared field description) succeeded on all 21 roles; step 3 (`version_desc`) originally failed on `varchar(255)` truncation (role `uid 2990`, "Vendor Maintenance," already had a 208-char description). Finished via `Sql-Scripts\Update-SA53301-VersionDesc-Fix-BusinessRules.sql` (shortened note + `LEFT(...,255)` guard). **Verified end-to-end** — DB confirmed via SQL, then the P21 client (after closing/reopening the window to clear its cached DynaChange layout).
3. **Prod:** `Sql-Scripts\Update-SA53301-RMA-ColumnHeader-Prod.sql` against `USE P21`, run manually by the user (per their explicit "I will run") on 2026-08-27, after Jessica & Chad signed off on the Play change. Script carried the shortened-note/`LEFT()` fix proven in step 2 — **ran clean on all 21 Prod roles, confirmed complete, no errors.**

## Verification
- RMA tab header reads "Reason" instead of "Lost Sales Desc," on every role that has the field placed.
- After running via direct SQL (not the P21 client), the on-screen result won't refresh until the DynaChange screen is reloaded — close and reopen Transaction Master Inquiry Orders (or log out/back into P21) before checking.
- Query to confirm at the DB level:
  ```sql
  SELECT custom_objects_uid,
      CASE WHEN CHARINDEX('text="Reason"', attribute_value) > 0 THEN 'Reason'
           WHEN CHARINDEX('text="Lost Sales Desc"', attribute_value) > 0 THEN 'Lost Sales Desc'
           ELSE 'OTHER' END AS current_text
  FROM custom_objects_detail
  WHERE object_name = 'ufc_lost_sales_lost_sales_desc_t' AND attribute_name = 'create';
  ```
  Expect `Reason` on all rows (2 in Play, 21 in Business Rules/Prod).

## Rollback
Reverse `REPLACE` calls, included at the bottom of `Update-SA53301-RMA-ColumnHeader-Prod.sql`:
```sql
UPDATE custom_objects_detail SET attribute_value = REPLACE(attribute_value, 'text="Reason"', 'text="Lost Sales Desc"') WHERE object_name = 'ufc_lost_sales_lost_sales_desc_t' AND attribute_name = 'create' AND attribute_value LIKE '%text="Reason"%';
UPDATE fc_dataobject_column SET description = 'Lost Sales Desc' WHERE user_column_name = 'ufc_lost_sales_lost_sales_desc' AND description = 'Reason';
```
`version_desc`/audit-column rollback would need to strip the appended note manually — not scripted, low risk to leave as-is.

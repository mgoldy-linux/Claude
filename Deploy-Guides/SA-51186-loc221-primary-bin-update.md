# Deployment Guide — SA-51186 Location 221 Primary-Bin Bulk Update

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `Sql-Scripts\Updates\Update-Loc221-Primary-Bins.sql` — one-time data-fix script (SQL)
- `Sql-Scripts\Updates\Verify-Loc221-Primary-Bins.sql` — read-only companion (COUNT checks, no UPDATE)
- Ticket: SA-51186 (WWMS Putaway Consolidation, Location 221)

## Target environments
- `P21BusinessRules` (WWMS Testing) @ `P21Dev.allsurfaces.com`, port 3444 → `P21Play` @ `P21Dev.allsurfaces.com` → `p21` (Prod) @ `P21.allsurfaces.com`

## Dependencies & deploy order
1. No dependent front-end artifact — this is a standalone data update against `inv_loc.primary_bin`.
2. Source data (5,042 `item_id → primary_bin` pairs) comes from Mike Learned's `Loc-221-Bins-ML-Update.xlsx` (`PrimaryBinUpload_br` sheet, snapshot 2026-08-17) and is hardcoded into the script's `#PrimaryBinUpdates` temp-table `INSERT` statements — it is not re-pulled from the workbook at runtime.
3. Run BusinessRules → Play → Prod, in that order, each time re-checking the pre-flight validation output before letting the UPDATE proceed (target data can drift between environments and between runs).

## Backward-compatibility notes
- Script only updates rows where `inv_loc.primary_bin = 'NOBIN'` — it cannot overwrite a primary bin already set (manually or by a prior partial run), so it's safe to re-run.
- Not tied to any code version; no rollback compatibility concerns beyond the data itself.

## Deploy steps
1. Open `Sql-Scripts\Updates\Update-Loc221-Primary-Bins.sql`.
2. Set the active `USE` statement to the target environment (only one uncommented at a time): `P21BusinessRules` / `P21Play` / `p21` (Prod).
3. Run the script. It loads the 5,042 rows into `#PrimaryBinUpdates`, runs 4 pre-flight checks (unmatched `item_id`, no `inv_loc` row at 221, target bin no longer holds real stock for the item, `primary_bin` already changed from `NOBIN` since the snapshot), then a single set-based `UPDATE...JOIN` restricted to `primary_bin = 'NOBIN'`.
4. Review the pre-flight check output before trusting the run — known non-blocking exceptions from the BusinessRules run: 1 item (`MAP38439`) has no `inv_mast` match; 23 items (a Schluter Kerdi-product cluster) resolve to a bin with no current `inv_bin` stock (data drift since the 8/17 snapshot, not a script defect).

## Verification
- Run `Sql-Scripts\Updates\Verify-Loc221-Primary-Bins.sql` (read-only, COUNT-based) against the same environment.
- Expected: ~5,041 of 5,042 rows show `primary_bin` set to their target bin; 0 remain `NOBIN` (accounting for the `MAP38439` exception).
- **BusinessRules:** verified 2026-08-25 — 5,041/5,042, 0 remain `NOBIN`.
- **Play:** run by user 2026-08-25 ("no problems") — **not yet verified** with the verify script.
- **Prod:** run by user 2026-08-25 ("commands completed successfully") — **not yet verified** with the verify script.

## Rollback
- No saved "before" snapshot of `primary_bin` values was captured prior to the update (source data itself came from an external workbook analysis, not a DB export).
- To revert a specific item, manually `UPDATE inv_loc SET primary_bin = 'NOBIN' WHERE item_id = '<id>' AND location_id = 221` (or its prior known bin, if recorded elsewhere) — no bulk rollback script exists.

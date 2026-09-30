# Workbench `221-ORDER-PICKS` — rolling print_date (tomorrow = through end of today)

> **Status 2026-09-30: NOT DEPLOYED — closed.** Tested in P21BusinessRules only (6 rows updated, output verified). Management ruled out customizations, so this stays a reference. The 6 BusinessRules rows were last set to `<=10/01/2026`; restore with the Rollback block below (or let a Prod refresh overwrite). Prod was never touched.

**Problem:** Workbench query criteria are stored as text in `workbench_query_pt` and validated as literal dates by P21's
query mode. `GETDATE()`, `CAST(...)`, and `t` are all rejected, so someone re-types the cutoff by hand
(`<=09/30/2026`, last saved 2026-09-25 by MLEARNED).

**Approach (option B):** a daily job rewrites the stored text to `<=` + (tomorrow, so `<=` includes all of today), same format P21 writes itself.
The delivered view `p21_view_workbench_query_pt` is NOT touched (Scopus-delivered; upgrades overwrite it).

**Caveats**
- Direct write to a P21 table — not a supported path. **Play first.**
- A user who already has the query open may keep the old value until they reload it.
- Only rows where `print_date` already starts with `<=` are updated; anyone who changes the criterion to something else is left alone.
- `date_last_modified` / `last_maintained_by` are deliberately not touched, so the header still shows who last edited the query by hand. Confirm in Play that P21 doesn't rely on `date_last_modified` to refresh its cache; if it does, set it in the UPDATE.
- Matches by `workbench_query_hdr_id`, not uid, so it survives a refresh that renumbers.

## 1. Preview (read-only) — run first

```sql
SELECT p.workbench_query_pt_uid, p.query_sequence_no,
       p.print_date AS current_text,
       '<=' + CONVERT(varchar(10), DATEADD(DAY, 1, CAST(GETDATE() AS date)), 101) AS new_text
FROM dbo.workbench_query_pt p
JOIN dbo.workbench_query_hdr h ON h.workbench_query_hdr_uid = p.workbench_query_hdr_uid
WHERE h.workbench_query_hdr_id = '221-ORDER-PICKS'
  AND p.print_date LIKE '<=%';
-- Expect the 6 rows (sequence 1-6) seen 2026-09-29. Each row is one carrier_id block (3023180-3023185) — all 6 must carry the date.
-- Cutoff is tomorrow because every print_date has a time component (1101/1101 in P21BusinessRules, 2026-09-30); `<=` today would exclude everything printed after midnight.
```

## 2. The update

```sql
SET NOCOUNT ON;

DECLARE @new varchar(255) = '<=' + CONVERT(varchar(10), DATEADD(DAY, 1, CAST(GETDATE() AS date)), 101);

UPDATE p
SET    p.print_date = @new
FROM   dbo.workbench_query_pt p
JOIN   dbo.workbench_query_hdr h ON h.workbench_query_hdr_uid = p.workbench_query_hdr_uid
WHERE  h.workbench_query_hdr_id = '221-ORDER-PICKS'
  AND  p.print_date LIKE '<=%'
  AND  p.print_date <> @new;          -- skip rows already current

PRINT CONCAT('221-ORDER-PICKS print_date rows updated: ', @@ROWCOUNT, ' -> ', @new);
```

Style 101 = `mm/dd/yyyy`, matching the stored `<=09/30/2026`.

## 3. SQL Agent job (create DISABLED, enable after Play verification)

Run in the target instance's `msdb`. Time is a placeholder — pick one before the first pick wave.

```sql
USE msdb;
EXEC dbo.sp_add_job         @job_name = N'ASI - Workbench 221-ORDER-PICKS rolling print_date', @enabled = 0;
EXEC dbo.sp_add_jobstep     @job_name = N'ASI - Workbench 221-ORDER-PICKS rolling print_date',
     @step_name = N'Update print_date', @subsystem = N'TSQL', @database_name = N'<P21 database>',
     @command = N'
DECLARE @new varchar(255) = ''<='' + CONVERT(varchar(10), DATEADD(DAY, 1, CAST(GETDATE() AS date)), 101);
UPDATE p SET p.print_date = @new
FROM dbo.workbench_query_pt p
JOIN dbo.workbench_query_hdr h ON h.workbench_query_hdr_uid = p.workbench_query_hdr_uid
WHERE h.workbench_query_hdr_id = ''221-ORDER-PICKS'' AND p.print_date LIKE ''<=%'' AND p.print_date <> @new;';
EXEC dbo.sp_add_schedule    @schedule_name = N'Daily 05:00', @freq_type = 4, @freq_interval = 1, @active_start_time = 050000;
EXEC dbo.sp_attach_schedule @job_name = N'ASI - Workbench 221-ORDER-PICKS rolling print_date', @schedule_name = N'Daily 05:00';
EXEC dbo.sp_add_jobserver   @job_name = N'ASI - Workbench 221-ORDER-PICKS rolling print_date';
```

## 4. Verify in Play (before Prod)

1. Run 1, then 2. Re-run 1: `current_text` should equal `new_text`, and step 2 should report 0 rows.
2. Open Workbench → `221-ORDER-PICKS` → SQL Statement tab: `print_date <= '<today+5>'`.
3. Confirm the pick list matches a hand-typed `<=` today+5 (`EXCEPT` both directions on `pick_ticket_no`).
4. Enable the job, let it fire once, re-check.

## Rollback

```sql
UPDATE p SET p.print_date = '<=09/30/2026'   -- original text as of 2026-09-29
FROM dbo.workbench_query_pt p
JOIN dbo.workbench_query_hdr h ON h.workbench_query_hdr_uid = p.workbench_query_hdr_uid
WHERE h.workbench_query_hdr_id = '221-ORDER-PICKS' AND p.print_date LIKE '<=%';
```
Then disable the job. (Matches by query name, so it still works if P21 re-inserted the rows with new `workbench_query_pt_uid`s — the test rows were 8665-8670.)

## Other findings from this investigation
- `SALES ORDER PICK WAVE` (hdr 5, JORTIZ) stores `required_date = 05/08/2026` — stale since May. Ask the owner.
- The six `print_date` rows in `221-ORDER-PICKS` are NOT redundant: each is one OR'd carrier_id block (3023180-3023185) and all need the date.
- `p21_view_workbench_query_pt`: `document_line_bin` is aggregated over all `'PT'` rows and `pt_line_count` is built for every open pick ticket regardless of outer filters. Worth a plan check (logical reads) if the Workbench is slow.

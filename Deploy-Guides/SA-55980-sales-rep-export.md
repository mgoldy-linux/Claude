# Deployment Guide - SA-55980 Customer Sales Rep Username Export

> Updated 2026-10-02. **Built and tested on Play/Training; NOT deployed to Prod; SFTP upload untested.**

## Artifact(s)
- `SQL-Schema\CREATE-OR-ALTER-PROC-asi_proc_sales_rep_export.sql` - stored proc (2 result sets: snapshot, exceptions; params `@IgnoreDeleteFlag` test-only, `@ResultSet` for testing). Includes `GRANT EXECUTE` to `p21_application_role`, `PxxiUser`.
- `C:\PowerShell-Scripts\Export-SQL\Export-SalesRepSftp.ps1` - ONE script, PS 5.1, `-Instance Play-Dev|Play-Sandbox|Training-Stage|Prod-Prod|All`.
- `Sql-Scripts\SalesReps\Crosscheck-SA55980-sales-rep-export.sql` - independent proof of the proc (checks 1-8, expect 0 rows). `Test-Play-multirep-SA55980.sql` - rolled-back multi-rep/over-5 test (P21Play only). `Verify-SA55980-Schema.sql` - schema checks.
- Ticket: SA-55980

## Instances (SQL host / database -> SFTP folder)
Play-Dev: P21Dev.allsurfaces.com / P21Play -> /DEV | Play-Sandbox: same DB -> /Sandbox | Training-Stage: P21Dev.allsurfaces.com / P21Training -> /Stage | Prod-Prod: P21.allsurfaces.com / P21 -> /Prod. **SFTP host/folders are placeholders until IT confirms** (Prod folder unconfirmed).

## Business rules / decisions
- Customers = distinct `contacts.address_id` where role `contact_role_id = 'Oro User'` and contact not deleted.
- Reps = active rows (`row_status_flag = 704`) in `asi_table_customer_comclass_salesrep`; username = `users_ud.salesrep_id` -> `users.id`, only `users.delete_flag = 'N'` (`users.active` is unused). Lowercase, deduped.
- Slot order: lowest salesrep_id, then username. More than 5 users: first 5 exported, rest logged as `OVER_5_USERS` (requester to confirm).
- **House / placeholder accounts are ignored (Matt, 2026-10-02):** contact last name `House%`, last name `Rep`, or first name `( Unassigned%`. They never get a username and are not reported. Customers with only house reps stay in the file with blank columns. Pattern lives in the proc's NO_USERS_UD query.
- Real reps with no login are reported as `NO_USERS_UD`. Logins whose `users_ud.salesrep_id` points at the wrong person would export the wrong username - check with the Prod mismatch query (open: JKUZEMCHAK/SWILLIAMS on 1260, CSKELTON/DNAGEL on 1303, RTAYLOR on 1088).
- **Shared rep IDs: include ALL current logins (Matt, 2026-10-02)** - e.g. rep 1260 lists both `jkuzemchak` and `swilliams`. A current login carrying another person's rep ID (e.g. `CSKELTON` on 1303 in Prod) would list the wrong person - clear before go-live.
- OPEN with Matt: who receives the exceptions file; is Sales Region (`users_ud.sales_region`) meant to be required (71 of 84 current rep logins blank; the 13 filled look like managers' regions); include or exclude employee accounts (customer class EM; 73 of 2,719 Oro customers).
- OPEN with requester: ticket title says "Sales Manager", columns say salesRep - confirm rep vs manager.

## Dependencies & deploy order
1. Verify with `Crosscheck-SA55980-sales-rep-export.sql` after each proc deploy (Play first; set `@ign = 1` in non-Prod to ignore stale delete flags).
2. Deploy the proc: Play, Training (done), then **Prod** (not done).
3. Copy the ONE script to ASWEB1 `D:\SalesRepExport\scripts\`, then `Unblock-File` it (policy RemoteSigned; copying over RDP marks it).
4. SFTP: Posh-SSH copied offline (`Save-Module` on a PC, copy into `C:\Program Files\WindowsPowerShell\Modules`; no `Install-Module` on the server - SentinelOne #331962). Credential: `Get-Credential | Export-Clixml <BaseDir>\secure\sftp-salesrep.cred.xml` as the account that runs the task.
5. Dry run on ASWEB1 (worked 10/2 for Play): `powershell.exe -NoProfile -File D:\SalesRepExport\scripts\Export-SalesRepSftp.ps1 -Instance Play-Dev -BaseDir D:\SalesRepExport -SkipUpload -IgnoreDeleteFlag`
6. Real run with `-SftpHost`, then register the scheduled task (Matt).

## Output layout (under `-BaseDir`, created automatically)
`out\<instance>\` unsent files | `sent\<instance>\` backup copy of every SFTP'd file (SHA256-checked, kept 90 days) | `logs\<instance>\` run log | `logs\Record-of-<PC>-Scripts-Ran-yyyyMM.txt` one line per run | `secure\` credential.

## Verification
- Cross-check checks 1-8 return no rows; proc logical reads/CPU from `sys.dm_exec_procedure_stats` (Prod numbers pending).
- Script: exit 0, record line `result=OK`, backup copy present after a real upload.

## Rollback
- Disable/delete the scheduled task; `DROP PROCEDURE dbo.asi_proc_sales_rep_export`. No data is modified by the proc or script.

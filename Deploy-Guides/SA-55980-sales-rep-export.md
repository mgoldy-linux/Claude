# Deployment Guide - SA-55980 Customer Sales Rep Username Export

> Updated 2026-10-09. **Built and tested on Play/Training; NOT deployed to Prod.** 10/9: SFTP connection + test put proven from ASWEB1 (key-only Serv-U user `SalesRepExport`, RSA key); the script's upload step is now `sftp.exe` + key and SQL auth can use the `orosvc` credential file - both written 10/9, **offline-tested only, not yet run against the server.** Parked - Mark to resume.
>
> **Companion files (10/9):** `Deploy-Guides\SA-55980-ASWEB1-sftp-test-guide.md` (session steps), `C:\PowerShell-Scripts\Export-SQL\Test-SftpKeySetup.ps1` (key/connection/upload/drill tests), `C:\PowerShell-Scripts\Export-SQL\New-SalesRepSqlCredential.ps1` (DPAPI `orosvc` credential file, run as the job account), `Sql-Scripts\SalesReps\Check-SA55980-Departed-Reps-And-Deleted-Customers.sql` (Matt's departed-rep question).
>
> **Facts learned 10/9:** Serv-U 15.5.4.108 accepts RSA/ECDSA, not ed25519 -> RSA 4096. The `tneuman` account requires key AND password (unusable unattended); `SalesRepExport` is key-only. sftp options go before user@host; `-i` takes the next word as its path. The 10/2 Play-Dev export was left in `/Dev/SalesRepImport/` by the test put - delete it and check Oro Dev did not ingest it.

## Artifact(s)
- `SQL-Schema\CREATE-OR-ALTER-PROC-asi_proc_sales_rep_export.sql` - stored proc (2 result sets: snapshot, exceptions; params `@IgnoreDeleteFlag` test-only, `@ResultSet` for testing). Includes `GRANT EXECUTE` to `p21_application_role`, `PxxiUser`.
- `C:\PowerShell-Scripts\Export-SQL\Export-SalesRepSftp.ps1` - ONE script, PS 5.1, `-Instance Play-Dev|Play-Sandbox|Training-Stage|Prod-Prod|All`.
- `Sql-Scripts\SalesReps\Crosscheck-SA55980-sales-rep-export.sql` - independent proof of the proc (checks 1-8, expect 0 rows). `Test-Play-multirep-SA55980.sql` - rolled-back multi-rep/over-5 test (P21Play only). `Verify-SA55980-Schema.sql` - schema checks.
- Ticket: SA-55980

## Instances (SQL host / database -> SFTP folder)
Play-Dev: P21Dev.allsurfaces.com / P21Play -> /DEV | Play-Sandbox: same DB -> /Sandbox | Training-Stage: P21Dev.allsurfaces.com / P21Training -> /Stage | Prod-Prod: P21.allsurfaces.com / P21 -> /Prod. **SFTP host/folders are placeholders until IT confirms** (Prod folder unconfirmed).

## Business rules / decisions
- Customers = distinct `contacts.address_id` where role `contact_role_id = 'Oro User'` and contact not deleted. **Only addresses that are ACTIVE customers (`dbo.customer.delete_flag='N'`) - added 2026-10-05** after Matt asked why customer 100 was in the file (100 = Wood Dale location; also a vendor, two non-customers and one deleted customer; Prod 2,734 -> 2,729).
- Reps = active rows (`row_status_flag = 704`) in `asi_table_customer_comclass_salesrep`; username = `users_ud.salesrep_id` -> `users.id`, only `users.delete_flag = 'N'` (`users.active` is unused). Lowercase, deduped.
- Slot order: lowest salesrep_id, then username. **No cap (10/19, per Matt's ORO_INT09 v1.0):** columns = the most users any customer has (`salesRep 1..N Username`, min 1). Optional proc parameter `@MaxSlots` caps it (used only by the cross-check, which needs a fixed width); exceptions then log `OVER_MAX_USERS`. **The proc MUST be re-created in Play/Training/Dev/BRR (and Prod) before the script change works** - the new script reads the column list from the proc output.
- **House / placeholder accounts are ignored (Matt, 2026-10-02):** contact last name `House%`, last name `Rep`, or first name `( Unassigned%`. They never get a username and are not reported. Customers with only house reps stay in the file with blank columns. Pattern lives in the proc's NO_USERS_UD query.
- Real reps with no login are reported as `NO_USERS_UD`. Logins whose `users_ud.salesrep_id` points at the wrong person would export the wrong username - check with the Prod mismatch query (open: JKUZEMCHAK/SWILLIAMS on 1260, CSKELTON/DNAGEL on 1303, RTAYLOR on 1088).
- **Matt 2026-10-05:** Joseph Kuzemchak mirrors Sam Williams under 1260 (50/50 territory) - keep both; customers with no rep are NOT exceptions (exceptions = assigned rep with no current login); **YES to creating the proc in Prod** (user still tests lower envs first); file format for Lokion (BOM/quotes) - Matt checking; he will share the 'reps who left but still assigned' list with Customer Maintenance.
- **Shared rep IDs: include ALL current logins (Matt, 2026-10-02)** - e.g. rep 1260 lists both `jkuzemchak` and `swilliams`. A current login carrying another person's rep ID (e.g. `CSKELTON` on 1303 in Prod) would list the wrong person - clear before go-live.
- OPEN with Matt: who receives the exceptions file; is Sales Region (`users_ud.sales_region`) meant to be required (71 of 84 current rep logins blank; the 13 filled look like managers' regions); include or exclude employee accounts (customer class EM; 73 of 2,719 Oro customers).
- OPEN with requester: ticket title says "Sales Manager", columns say salesRep - confirm rep vs manager.

**PENDING (2026-10-05): re-run the proc's CREATE OR ALTER on Play, Training, Dev, BusinessRules, then `Crosscheck-SA55980-sales-rep-export.sql` (now checks 1-9; check 9 = every customer is active).**

## Dependencies & deploy order
1. Verify with `Crosscheck-SA55980-sales-rep-export.sql` after each proc deploy (Play first; set `@ign = 1` in non-Prod to ignore stale delete flags).
2. Deploy the proc: Play, Training (done), then **Prod** (not done).
3. Copy the ONE script to ASWEB1 `D:\SalesRepExport\scripts\`, then `Unblock-File` it (policy RemoteSigned; copying over RDP marks it).
4. **SUPERSEDED 2026-10-05 (Tony: sftp.exe + SSH key, nothing installed)** - was: SFTP: Posh-SSH copied offline (`Save-Module` on a PC, copy into `C:\Program Files\WindowsPowerShell\Modules`; no `Install-Module` on the server - SentinelOne #331962). Credential: `Get-Credential | Export-Clixml <BaseDir>\secure\sftp-salesrep.cred.xml` as the account that runs the task.
5. Dry run on ASWEB1 (worked 10/2 for Play): `powershell.exe -NoProfile -File D:\SalesRepExport\scripts\Export-SalesRepSftp.ps1 -Instance Play-Dev -BaseDir D:\SalesRepExport -SkipUpload -IgnoreDeleteFlag`
6. Real run with `-SftpHost`, then register the scheduled task (Matt).

## Test everything on lower environments BEFORE Prod (user's rule, 2026-10-02)
1. `-ConfirmProd` switch so `Prod-Prod` cannot upload (or be scheduled) by accident. [DONE 10/9 - uploads only; untested]
2. SFTP upload from ASWEB1 to the DEV / Sandbox / Stage folders (Tony's team creates the Serv-U user + public key and the Windows service account; script uses sftp.exe with the key; guided test from ASWEB1). [TODO]
3. Failure drills: bad credential, wrong folder, missing proc -> exit code 1, record line `FAILED`, file left in `out\`, email summary. [TODO]
4. Register the scheduled task for Play-Dev only; run now, then daily for several days; confirm under the service account (execution policy: `Unblock-File` or `-ExecutionPolicy Bypass`). [TODO]
5. Only after Matt approves: create the proc on Prod -> cross-check on Prod -> dry run `-Instance Prod-Prod -ConfirmProd -SkipUpload` -> real run.

## SFTP method (decided 2026-10-05, Tony Neuman)
- `sftp.exe` (already on ASWEB1) with an SSH key; public key on a dedicated Serv-U user (key-only, limited to the SalesRepImport folder(s)); host `ftp.allsurfaces.com`, Play-Dev `/Dev/SalesRepImport/`; Sandbox/Stage/Prod folders TBD (Matt). Private key stays on ASWEB1, readable only by the job's Windows account (empty passphrase; protected by file ACL); verify the server fingerprint on first connect.
- NOT Posh-SSH/WinSCP: nothing is installed or downloaded. **Upload step rewritten 10/9** for `sftp.exe -i <key> -o BatchMode=yes -b <batchfile>` (`Send-SftpFile`: exit code 0 AND remote `ls -l` size = local size; `-UseTempName` optional .part+rename; `-ConfirmProd` required for Prod-Prod). Offline-tested only - first real run must confirm the `ls -l` size parses. [VERIFY]
- **SQL login (10/9 decision): `orosvc`** via `-SqlCredFile` (DPAPI Export-Clixml PSCredential, created AS THE JOB ACCOUNT with `New-SalesRepSqlCredential.ps1`; password never in the script/log/repo). Without `-SqlCredFile` the script uses Windows auth (testing as yourself). `orosvc` is shared with the live Oro sync - a password rotation breaks the export until the file is recreated; owner TBD.
- Accounts: ecommerce jobs on ASWEB1 connect to SQL as SQL login `orosvc` (db_datareader/db_datawriter + CONNECT + EXECUTE in P21, P21Play, P21Training - no new SQL grants needed); the job still needs a WINDOWS account (not pimsvc - not a PIM job) to run on ASWEB1 and hold the key, plus CONNECT/EXECUTE for that account if the script keeps Windows authentication. Open with Tony's team.

- **Matt 2026-10-06:** existing Serv-U account `OroUser` has root access to all outbound folders/environments; each environment (Dev, Stage, Sandbox, Prod) has its OWN `SalesRepImport` folder (exact names to verify on first listing; script has only `/Dev/SalesRepImport/` confirmed). Existing ASWEB1 scheduled jobs run under the **pimsvc** Windows service account (PIM + Oro); use as-is or rename (ASWEB1SVC). => scheduler = Task Scheduler on ASWEB1 under pimsvc. **Gap:** only SQL logins `pimsvc`/`orosvc` exist on the SQL servers (no Windows login seen) - the script uses Windows authentication, so the Windows account needs CONNECT + EXECUTE on `dbo.asi_proc_sales_rep_export` in P21, P21Play, P21Training (or switch to SQL auth with a protected password file). Recommended: separate key-only Serv-U user limited to the four SalesRepImport folders (OroUser can reach every environment incl. Prod). Reply-all to Matt/Tony drafted 10/6, not sent.

## Output layout (under `-BaseDir`, created automatically)
`out\<instance>\` unsent files | `sent\<instance>\` backup copy of every SFTP'd file (SHA256-checked, kept 90 days) | `logs\<instance>\` run log | `logs\Record-of-<PC>-Scripts-Ran-yyyyMM.txt` one line per run | `secure\` credential.

## Status 2026-10-14 (ASWEB1 test)
- Scripts live in `D:\SalesRepExport\scripts\` (copied from `C:\PowerShell-Scripts\Export-SQL\`); key + known_hosts in `scripts\.ssh` (ACL: one account, Read only); credential file `D:\SalesRepExport\secure\sql-orosvc.cred.xml`.
- Real `-Instance Play-Dev` run: CSV written, SFTP upload OK, `SFTP size check OK` (87,359 bytes with `-IgnoreDeleteFlag`). Play delete flags are mostly 'Y' after the refresh, so lower-env tests need `-IgnoreDeleteFlag`; Prod does not.
- Prod proc scripts for the DBA step: `Documents\SQL Server Management Studio\SA-55980-Sales-Rep-Export\` on ASDWDEVTOOLS (create proc, then crosscheck 1-9, then DMV reads/CPU).
- Scheduled tasks: one per environment (Play-Dev first, Prod last with `-ConfirmProd`); job account TBD; credential file + key Read must be set for that account. NOT registered yet.

## Status 2026-10-21 (per-environment folders + task registration)
- **Folder layout (Matt):** `D:\SalesRepExport\<Env>\` with `logs`, `out`, `scripts`, `secure`, `sent` and `orosvc.cred` in the environment root; key + `known_hosts` in `<Env>\scripts\.ssh\`. Environments: **Dev = Play, Sandbox = Play, Stage = Training, Prod = Prod** (instances `Play-Dev`, `Play-Sandbox`, `Training-Stage`, `Prod-Prod`). `New-SalesRepExportFolders.ps1 [-Environment ...] [-CopyScripts <folder>] [-LockSecure] [-WhatIf]` creates it (idempotent, never overwrites).
- **Dev task action now:** `-File D:\SalesRepExport\Dev\scripts\Export-SalesRepSftp.ps1 -Instance Play-Dev -BaseDir D:\SalesRepExport\Dev -KeyPath D:\SalesRepExport\Dev\scripts\.ssh\id_rsa -SqlCredFile D:\SalesRepExport\Dev\orosvc.cred -SftpUser SalesRepExport -UseTempName -IgnoreDeleteFlag`, Start in `...\Dev\scripts`. Note `-BaseDir ...\Dev` puts files in `Dev\out\Play-Dev` (one level deeper than Matt's flat `Dev\out`).
- **What went wrong 10/21:** the 02:00 run made no file because moving the folders left the task on the old paths and the copied key carried the new parent's ACL (owner `a-tneuman`, Users/Administrators/groups). OpenSSH then rejects it ("Permissions ... too open"). Fix = ACL SYSTEM-only + `takeown /f <key> /a`. Order matters: grant SYSTEM BEFORE removing inheritance only if you are still owner; otherwise `takeown /a` first, then `icacls <key> /grant:r "*S-1-5-18:(R)"`. After ANY move or copy of the key, re-check `icacls` + owner.
- **Register a task per environment:** `Register-SalesRepExportTask.ps1 -Environment Dev|Sandbox|Stage|Prod [-IgnoreDeleteFlag] [-ConfirmProd] [-Force] [-WhatIf]` (elevated, ASWEB1). Task `\MindHARBOR\P21_<Source>_to_Oro_<Env>_SalesRep_Sync`, SYSTEM, daily (Dev 02:00, Sandbox 02:10, Stage 02:20, Prod 02:30), preflight checks files + key ACL, refuses to overwrite without `-Force`, Prod refused without `-ConfirmProd` and never with `-IgnoreDeleteFlag`. Only -WhatIf-tested; NOT yet used on ASWEB1.
- **SFTP paths fixed in `Export-SalesRepSftp.ps1`:** Sandbox/Stage/Prod now `/<Env>/SalesRepImport/` (they were `/Sandbox`, `/Stage`, `/Prod`, which would have uploaded to the wrong folder). Hand-edited ASWEB1 copies need the same change. Existence of those server folders and write access for `SalesRepExport` NOT confirmed.
- **Stage steps:** folders + copy scripts -> key/known_hosts into `Stage\scripts\.ssh` + lock -> `New-SalesRepSqlCredential.ps1 -Path D:\SalesRepExport\Stage\orosvc.cred -TestServer P21Dev.allsurfaces.com -TestDatabase P21Training` -> dry run `-Instance Training-Stage -SkipUpload` (compare with/without `-IgnoreDeleteFlag`; Training delete flags unknown) -> register -> run once -> list `/Stage/SalesRepImport/` with the one-time SYSTEM `sftp ls` task.

## Status 2026-10-20 (scheduled task as SYSTEM - Play-Dev WORKS)
- Task `\MindHARBOR\P21_Play_to_Oro_Dev_SalesRep_Sync` on ASWEB1 (created by Matt; SYSTEM, run level Highest, daily 02:00). Action: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\SalesRepExport\scripts\Export-SalesRepSftp.ps1 -Instance Play-Dev -BaseDir D:\SalesRepExport -KeyPath D:\SalesRepExport\scripts\.ssh\id_rsa -SqlCredFile D:\SalesRepExport\orosvc.cred -SftpUser SalesRepExport -UseTempName -IgnoreDeleteFlag`, Start in `D:\SalesRepExport\scripts`. (`-IgnoreDeleteFlag` = Play only; refused for Prod-Prod. Matt's original `-NoDelete` is not a parameter.)
- **SQL credential for SYSTEM:** `New-SalesRepSqlCredential.ps1` (run once, elevated, types the `orosvc` password at the Get-Credential prompt; optional `-TestServer P21Dev.allsurfaces.com -TestDatabase P21Play`) now writes a **machine-scope DPAPI JSON** file (default `D:\SalesRepExport\orosvc.cred`, ACL SYSTEM + Administrators). SYSTEM cannot open a per-user file and cannot prompt. Anyone with admin read access on ASWEB1 can recover the password - keep the ACL tight. Export script still reads old Export-Clixml files (same account only).
- **Key for SYSTEM (OpenSSH is strict):** ACL = `NT AUTHORITY\SYSTEM:(R)` only (no user, no Users) **and** owner = Administrators or SYSTEM. Recipe, elevated: `icacls <key> /inheritance:r`, `icacls <key> /remove:g "<your account>" ...`, `icacls <key> /grant:r "*S-1-5-18:(R)"`, then `takeown /f <key> /a` (plain `takeown` gives it back to you; `icacls /setowner SYSTEM` = access denied). Symptom otherwise: `Permissions for '...id_rsa' are too open` / exit 255. `known_hosts` sits beside the key and is read by the script.
- **Verified 10/20 08:42 (manual run):** 2,011 rows, 1,852 with >=1 rep, 8 rep columns; `SFTP size check OK` 70,453 B; server `ls -l /Dev/SalesRepImport/` shows the file. Listing the folder afterwards needs a one-time SYSTEM task (key is SYSTEM-only) from an ELEVATED session.
- **Not verified:** the 02:00 scheduled run (first 10/21); that Oro Dev ingested the file (Matt has not told Oro yet); newest-only vs all-files behaviour (3 older test CSVs remain in the folder). Open question: Oro/Matt want "a separate log file for each server" - the script already writes `logs\<Instance>\Export-SalesRepSftp-yyyyMM.log` per instance (monthly); clarify before changing.
- Rollback: disable the task; delete the uploaded files from `/Dev/SalesRepImport/` (needs the SYSTEM-only key via a one-time task, or Tony).
- Repo vs server: scripts were hand-edited in the ISE on ASWEB1 - diff against `C:\PowerShell-Scripts\Export-SQL` before the next copy so nothing is overwritten.

## Verification
- Cross-check checks 1-8 return no rows; proc logical reads/CPU from `sys.dm_exec_procedure_stats` (Prod numbers pending).
- Script: exit 0, record line `result=OK`, backup copy present after a real upload.

## Rollback
- Disable/delete the scheduled task; `DROP PROCEDURE dbo.asi_proc_sales_rep_export`. No data is modified by the proc or script.

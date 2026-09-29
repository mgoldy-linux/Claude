# Deployment Guide - SA-55980 Customer Sales Rep Username Export

> Produced during development. **DRAFT - nothing deployed or verified against SQL yet.**

## Artifact(s)
- `SQL-Schema\CREATE-OR-ALTER-PROC-asi_proc_sales_rep_export.sql` - stored proc (2 result sets: snapshot, exceptions)
- `C:\PowerShell-Scripts\Export-SQL\Export-SalesRepSftp.ps1` - unattended export + SFTP script (PS 5.1 compatible)
- `Sql-Scripts\SalesReps\Verify-SA55980-Schema.sql` - read-only pre-check
- Ticket: SA-55980

## Target environments
- Test the proc on Play/Training first, then Prod (P21 @ P21.allsurfaces.com). Scheduled task runs on **ASWEB1** (Windows PowerShell 5.1 only).

## Dependencies & deploy order
1. Run `Verify-SA55980-Schema.sql`; correct proc column-name guesses (`contact_role_desc`, `users.active`, `users.delete_flag`).
2. Create the proc (includes `GRANT EXECUTE` to `p21_application_role`, `PxxiUser`) + grant to the task's service account.
3. Copy Posh-SSH to ASWEB1 offline (`Save-Module Posh-SSH -Path <dir>` here, then copy to `C:\Program Files\WindowsPowerShell\Modules`). Do not `Install-Module` on the server (SentinelOne #331962).
4. On ASWEB1, as the service account: `Get-Credential | Export-Clixml <CredFile>` (DPAPI: only that user+machine can read it).
5. Copy the script to a plain local folder (not OneDrive/Documents/Downloads); register the daily scheduled task.

## Backward-compatibility notes
- New objects only; nothing existing is changed. Result columns must stay in the fixed order the script validates.

## Deploy steps
1. Proc against Prod `USE [P21]`. 2. Dry run script with `-SkipUpload`, inspect CSV. 3. Real run with SFTP host/path. 4. Register task.

## Verification
- `EXEC dbo.asi_proc_sales_rep_export` -> one row per Oro User customer, no duplicate customer IDs; exceptions set reviewed. Measure logical reads/CPU from plan-cache DMVs. Compare a few customers against Customer Maintenance. Confirm file lands on SFTP.

## Rollback
- Disable/delete the scheduled task; `DROP PROCEDURE dbo.asi_proc_sales_rep_export`. No data is modified.

## Open items
- Slot sort rule, >5 users handling, deleted customers, CSV BOM/quoting, SFTP host/folder/service account, run time + timezone.

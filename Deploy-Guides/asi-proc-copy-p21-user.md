# Deployment Guide — asi_proc_copy_p21_user (retiring kb_proc_copy_user)

> Produced after deployment (rollout completed same session as the fix). Update as the artifact changes; commit with the code.

## Artifact(s)
- `asi_proc_copy_p21_user` — stored procedure, replacement for `kb_proc_copy_user` (copies a P21 user account: `users`, `users_ud`, `users_x_application_security`, `portal_assignment`, `users_x_company`)
- `C:\PowerShell-Scripts\DBATools\Users\Add-P21User-v1.ps1` — interactive wrapper that calls the proc and copies its summary line to clipboard
- Ticket: none (internal backlog item, originally tracked against the 2026 kb_/js_ retirement goal; resurfaced by SysAid 51571)

## Target environments
All 6 P21 environments — deployed to all of them in this rollout:
- P21 (Prod) @ `P21.allsurfaces.com`
- P21Play, P21Dev, P21BusinessRules, P21Training, P21Upgrade @ `P21Dev.allsurfaces.com`

## Dependencies & deploy order
1. No dependencies — single self-contained stored procedure, no other objects to deploy first.
2. EXECUTE grants must be applied after the `CREATE OR ALTER` (SQL Server does not auto-grant on new objects).

## Backward-compatibility notes
- `kb_proc_copy_user` is **not retired** — it remains live and callable in all 6 environments. This proc is a parallel replacement, not a hard cutover. Existing scripts/processes that still call `kb_proc_copy_user` directly are unaffected.
- P21Upgrade previously had the same build deployed under the name `asi_copy_p21_user` (no `_p21_` — modified 3/19/2026, confirmed line-for-line identical body). That object was renamed: deployed under the correct name, old name dropped after confirming no dependents (`sys.dm_sql_referencing_entities`) and no grants on it.
- `contact_id` ("Buyer ID") is **intentionally never copied** by this proc — same behavior as the original `kb_proc_copy_user`. A freshly created user will have a blank Buyer ID in the summary output until assigned separately in P21; it only appears when overwriting an existing user that already had one.

## Deploy steps
1. Run `SQL-Schema\CREATE-OR-ALTER-PROC-asi_proc_copy_p21_user.sql` against each target `USE [<db>]` — safe to re-run (`CREATE OR ALTER`).
2. Grant EXECUTE:
   ```sql
   GRANT EXECUTE ON [dbo].[asi_proc_copy_p21_user] TO [p21_application_role];
   GRANT EXECUTE ON [dbo].[asi_proc_copy_p21_user] TO [PxxiUser];
   ```
   Kept intentionally narrower than `kb_proc_copy_user`'s grant set (which also includes `kbenish`/`AHI\kbenish`/`AHI\ereyes`/`kb_ViewDefinitions`) — a deliberate choice, not an oversight; revisit if someone besides the app role/PxxiUser needs direct EXEC access.
3. In P21Upgrade only: after deploying under the new name, drop the old-named duplicate: `DROP PROCEDURE [dbo].[asi_copy_p21_user]`.

## Verification
- Object + grants: `SELECT o.name, STRING_AGG(dp.name, ', ') FROM sys.objects o LEFT JOIN sys.database_permissions perm ON perm.major_id = o.object_id LEFT JOIN sys.database_principals dp ON dp.principal_id = perm.grantee_principal_id WHERE o.name = 'asi_proc_copy_p21_user' GROUP BY o.name` → expect `p21_application_role, PxxiUser`.
- Functional test (always wrap in a transaction and roll back — do not leave test users behind):
  ```sql
  BEGIN TRANSACTION TestCopy;
  EXEC asi_proc_copy_p21_user @strUserToCopy = '<real user with a description/job title>', @strNewUserID = 'ZZTESTCOPY', @strFirstName = 'Test', @strLastName = 'Copy';
  SELECT u.id, ud.user_description, ud.job_title FROM users u JOIN users_ud ud ON ud.id = u.id WHERE u.id = 'ZZTESTCOPY';
  ROLLBACK TRANSACTION TestCopy;
  ```
  Expect the summary `PRINT` line: `Created in <DB> | User ID: ZZTESTCOPY | Role: <security role> | Location ID: 100` — and `user_description`/`job_title` populated from the source user.
- PowerShell wrapper: run `Add-P21User-v1.ps1`, confirm the clipboard receives the `Created in ...` line (captured via `Invoke-Sqlcmd -Verbose 4>&1`, since the proc reports via `PRINT`, not a result set).

## Rollback
- Drop the proc in any environment: `DROP PROCEDURE [dbo].[asi_proc_copy_p21_user]` — `kb_proc_copy_user` remains available as the fallback everywhere since it was never removed.
- P21Upgrade only: the old `asi_copy_p21_user` name was dropped as part of this rollout; if it needs to come back, redeploy `CREATE-OR-ALTER-PROC-asi_proc_copy_p21_user.sql` under that name (git history has the pre-rename version).

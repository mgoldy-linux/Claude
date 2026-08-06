# Deployment Guide — asi_proc_compare_p21_users

> Produced during development (built + tested same session, 2026-08-06). Update as the artifact changes; commit with the code.

## Artifact(s)
- `asi_proc_compare_p21_users` — read-only stored procedure, diffs two P21 users across `users`, `users_ud`, `users_x_application_security`, `portal_assignment`, `users_x_company`
- Ticket: none (general-purpose diagnostic; built to support SysAid 51844's access-mirroring request)

## Target environments
Deployed so far — **not all 6 environments**, deploy the rest on demand since this is a read-only diagnostic with no urgency:
- ✅ P21Play @ `P21Dev.allsurfaces.com` (built/tested here first)
- ✅ P21 (Prod) @ `P21.allsurfaces.com`
- ⬜ P21Dev, P21BusinessRules, P21Training, P21Upgrade — not deployed

## Dependencies & deploy order
1. No dependencies — single self-contained, read-only stored procedure. Safe to deploy to any environment independently.

## Backward-compatibility notes
- None — new object, nothing depends on it yet.

## Deploy steps
1. Run `SQL-Schema\CREATE-OR-ALTER-PROC-asi_proc_compare_p21_users.sql` against each target `USE [<db>]` — safe to re-run (`CREATE OR ALTER`).
2. No grants applied yet — only run directly by `mgoldyn` so far. Add `GRANT EXECUTE` if/when someone else needs to call it directly.

## Verification
- Self-compare sanity check (should return zero rows in every result set):
  ```sql
  EXEC asi_proc_compare_p21_users @strUserA = 'MGOLDYN', @strUserB = 'MGOLDYN';
  ```
- Real compare, default (differences only):
  ```sql
  EXEC asi_proc_compare_p21_users @strUserA = 'EROVELLO', @strUserB = 'RWAYMAN';
  ```
- `@bit_ShowAllColumns = 1` to see every column including matches (useful when confirming a column is genuinely absent from the diff, not just excluded).
- **Known trap**: lower environments (P21Play especially) are periodically refreshed from Prod and can carry stale `delete_flag`/`active` state for recently-changed users — a diff run there can show a difference that's just refresh staleness, not real. Confirmed 2026-08-06: EROVELLO showed `delete_flag='Y'` in P21Play (refreshed 5/28, before this user's 8/4 ticket) but was active in Prod. For any comparison that will inform a real access decision, run against **Prod**, not just Play. See `feedback_play_stale_access_diagnostics.md`.

## Rollback
- Drop the proc in any environment: `DROP PROCEDURE [dbo].[asi_proc_compare_p21_users]` — read-only, no data impact from removing it.

# Deployment Guide — SA 56290 Complete Expired Quotes (scheduled job)

> Status: cancel job DRAFT 2026-10-02, nothing run. **Portal-by-role cleanup (added 2026-10-08):** Play role script RUN, Prod scripts written NOT run - see the last section.

## Artifact(s)
- `Sql-Scripts/Quotes/SA-56290-Complete-Expired-Quotes.sql` — table `dbo.asi_expired_quote_complete_log`, proc `dbo.asi_proc_complete_expired_quotes`, SQL Agent job `ASI - Complete Expired Quotes` (commented in script)
- Ticket: SA-56290

## Target environments
- Play (P21Play @ P21Dev.allsurfaces.com) → Prod (P21 @ P21.allsurfaces.com). Test cutoff 90 days past quote_hdr.expiration_date; final value pending Sales.

## Dependencies & deploy order
1. Log table, then proc (same script, Step 2). 2. Grant EXECUTE to p21_application_role. 3. Agent job last, only after Play test passes.

## Backward-compat notes
- Updates only quotes (`oe_hdr.projected_order='Y'`) not already complete with non-NULL expiration older than cutoff. Same four tables/flags as the P21WWUG forum scripts.

## Deploy steps
1. Step 0 (schema check) and Step 1 (counts) — read-only. 2. Step 2 creates objects. 3. `EXEC ... @Preview = 1`, review, then `@Preview = 0`. 4. Create Agent job (Step 4).

## Verification
- Preview rows = quotes expected; after run, `asi_expired_quote_complete_log` rows match; open a touched quote in Order Entry (complete, no allocation); Item Maintenance delete of an item only on those quotes no longer blocked (UNCONFIRMED).

## Rollback
- Log table lists every order_no touched. Reverse by setting the four flags back for those orders (not scripted yet). Disable the Agent job to stop future runs.

## Play test before building (10/10)
- `Sql-Scripts/Quotes/SA-56290-Cancel-2-Test-Quotes-Play.sql`: cancel 2 quotes past 90 days, skip 1 inside the window; backup table `asi_bak_SA56290_cancel_test`; rollback default. Written, NOT run. Goal: confirm a cancelled quote can be reopened in Order Entry with a new expiration date.

## Open
- Sales (Al Ross 10/7) wants CANCEL 90 days after expiry; proc currently completes, switch after the reopen test passes. Final X still pending Sales.


## Part 2 - Open Quote portals: role-based access (added 2026-10-08)
Why: Sales/Counter/CS need to review open quotes before the cancel job runs; access today is a mix of roles and 23 direct (per-user) assignments.

**Scripts** (`Sql-Scripts/Portals Queries/`, `Sql-Scripts/Quotes/`)
1. `SA-56290-Open-Quote-Portal-Roles.sql` - read-only: roles + direct users per quote portal (Prod).
2. `SA-56290-Assign-OpenQuoteSearch-ToRoles-Play.sql` - adds OPEN QUOTES SEARCH to Sales Manager (exists), Branch Manager, Outside Sales, Customer Service, Customer Service Manager, Purchasing, Management; inactivates (705) the 10 direct rows of 7 current users. New uids from `seq_portal_assignment`. **Play: RUN 10/8 (6 inserts, counter 2103 = max 2103); the direct-row step was not separately confirmed.** Prod version NOT written yet.
3. `SA-56290-Unassign-DeletedUsers-OpenQuotePortals-Play.sql` / `-Prod.sql` - inactivate the 13 direct rows of 5 deleted users (DMUSICK, RGERLACH, KBENISH, LBERRY, RGUDERJAHN). Prod: auto-ROLLBACK unless exactly 13. **Neither run.**

**Order:** Play deleted-user script -> verify -> Prod deleted-user script; Play role script verified -> write the Prod role script (re-run script 1 first: Prod role rows may have changed) -> Prod.
**Waiting on Matt:** do Customer Service + CS Manager get Search (if no, undo those two in Play, drop them from the Prod script); is the front counter = Branch Manager (no Counter role exists).
**Rollback:** each script writes a backup table (`asi_portal_assignment_quote_*_bak_20261008`; the role script also logs inserted uids) and ends with a restore block; never a hard DELETE.
**Traps:** portal_assignment_uid is not identity (use the sequence); Play users.delete_flag is stale vs Prod, so the Play scripts hardcode user IDs; Play portal/role ids differ from Prod (look up by name).

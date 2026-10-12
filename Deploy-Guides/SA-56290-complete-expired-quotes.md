# SA 56290 - Scheduled Job to Cancel Expired Quotes

> Status (2026-10-12): tested on Play and working; handed to Matt for additional testing. Not created on Prod. The weekly SQL Agent job is written but not created. Part 2 (portal access by role) is a separate piece of the same ticket.

## What it does
Open quotes that are past their expiration date stay open and cause problems when the Item Maintenance team tries to delete items. This job cancels open quotes once they are more than X days past their expiration date (Sales, Al Ross: 90 days; 90 is used for testing, final number still to be confirmed).

- It sets the same flags Order Entry sets when a quote is cancelled, so a cancelled quote can be reopened.
- Quotes with no expiration date, and quotes already cancelled, completed or deleted, are never touched.
- Every quote it cancels is written to a log table, so there is a record of what it did.

## Files
- `Sql-Scripts/Quotes/SA-56290-Complete-Expired-Quotes.sql` - log table `dbo.asi_expired_quote_cancel_log`, procedure `dbo.asi_proc_cancel_expired_quotes`, test calls, and the SQL Agent job (commented out). The file name still says "Complete" from the first draft.
- Ticket: SA-56290

## Where it runs
- Play (P21Play on P21Dev.allsurfaces.com) first, then Prod (P21 on P21.allsurfaces.com).

## Deploy order
1. Run Step 2 of the script: creates the log table, then the procedure.
2. Grant EXECUTE on the procedure to p21_application_role.
3. Test on Play (below).
4. Create the SQL Agent job last, only after testing passes and Sales confirms the number of days.

## How to run it
- Preview (changes nothing): `EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 1;`
- Run: `EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;`
- One day only (for testing): add `, @OnlyExpiredOn = '2026-07-04'` to either call. The day must be older than today minus 90 days.
- Always preview first.

## What was tested on Play
1. Cancelled two quotes by SQL (5815698, 5815931) and skipped a third that was exactly 90 days past expiry (5819761). The skipped quote was untouched. Both cancelled quotes were reopened in Order Entry: the cancel flags cleared, all lines reopened, and a new expiration date saved.
2. Ran the real procedure for one day only (expiration 7/4/2026): it found two quotes (5794591, 5794592), cancelled both, and logged both. 5794591 was then reopened with a new expiration date. 5794592 was left cancelled.
3. Open quotes more than 90 days past expiration on Play, by the year they expired: 2018: 2; 2019: 2,331; 2020: 5,043; 2021: 6,699; 2022: 7,543; 2023: 7,633; 2024: 10,561; 2025: 12,679; 2026: 6,776. Total about 59,266.

## Things to know
- A reopened quote keeps its old expiration date unless someone changes it, so the next run would cancel it again. Whoever reopens a quote must set a new expiration date.
- The first full run would cancel the backlog (about 59,000 on Play). Run it once manually, off-hours, after a preview, so the weekly job only handles small runs afterward.
- Not yet confirmed: that a cancelled quote stops blocking Item Maintenance deletes (the original problem).

## What Matt should test on Play
Run this on Play (P21Play), changing the date to any day that is more than 90 days ago:

`EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 1, @OnlyExpiredOn = '2026-07-10';`

- This is a preview only. It lists the quotes that would be cancelled for that one day and changes nothing. Dates that have quotes on Play: 7/10 (1 quote), 7/3 (6 quotes), 7/5 (48 quotes). 7/4 no longer works because it was already used for my test.
- Check that the quotes listed look like expired, open quotes for that day.
- Optional: to actually cancel them, run the same line with `@Preview = 0`. Then reopen one in Order Entry with a new expiration date, and try an Item Maintenance delete for an item that is only on cancelled quotes.

## SQL Agent job (not created yet)
- Name: ASI - Cancel Expired Quotes. One T-SQL step in database P21: `EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;`. Weekly, Sunday 2:00 AM.
- Still to add before it goes to Prod: a failure email, an owner that is not a person, and one retry.

## Rollback
- The log table lists every order number the job cancelled. To undo, reopen the quote in Order Entry and set a new expiration date, or reset the cancel flags for those orders (not scripted yet).
- Disable the SQL Agent job to stop future runs.

## Open
- Sales to confirm the final number of days (90 used for testing).
- Item Maintenance delete test.
- Matt's test results.
- Cancel vs complete is settled: Sales wants cancel.

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

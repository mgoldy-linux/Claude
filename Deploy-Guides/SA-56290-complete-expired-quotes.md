# Deployment Guide — SA 56290 Complete Expired Quotes (scheduled job)

> Status: DRAFT 2026-10-02. Nothing run in any environment yet.

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

## Open
- Complete vs Cancel (ticket wording conflicts); final X days from Sales.

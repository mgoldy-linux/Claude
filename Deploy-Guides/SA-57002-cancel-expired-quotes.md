# Deployment Guide — SA 57002 Cancel expired quotes (nightly job)

> Change request spun out of SA 56290. Cancels quotes more than 90 days past `quote_hdr.expiration_date` (quotes auto-expire 90 days after creation, so ~180 days after creation).

## Artifact(s)
- `dbo.asi_proc_cancel_expired_quotes` + log table `dbo.asi_expired_quote_cancel_log` — script `Sql-Scripts/Quotes/SA-56290-Complete-Expired-Quotes.sql` (STEP 2)
- Prod runbook: `Sql-Scripts/Quotes/SA-57002-Prod-Cancel-Expired-Quotes-Runbook.sql`
- Agent job `ASI - Nightly Cancel Expired Quotes`
- Ticket: SA 57002 (change), SA 56290 (origin)

## Target environments
- Play (tested 2026-10-12: cancel, reopen in Order Entry with new expiration) → Prod (P21 @ P21.allsurfaces.com, DONE 2026-10-21)

## Dependencies & deploy order
1. STEP 0 schema check on target (19 rows), then proc + log table (STEP 2), then `GRANT EXECUTE ... TO p21_application_role`.
2. Preview, then ONE-TIME catch-up run, then verify (log count = rows cancelled, re-preview = 0).
3. Only then the nightly Agent job (03:30 daily).
- Notes: for a big catch-up the proc runs one transaction - run after hours or add batching first (see memory feedback_prod_bulk_updates_batch_small_chunks).

## Backward-compatibility notes
- NULL expiration never touched (446 open quotes on Prod 10/21). Reopened quotes need a NEW expiration date or the next run re-cancels them.

## Deploy steps
1. Runbook sections A-E against Prod `P21` (done 10/21: 59,124 quotes, 217,484 lines, 7:59-8:37 PM).
2. Job: T-SQL step `EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;` database P21, schedule daily 03:30. Created by Mark 10/21 (owner AHI\MGOLDYN); Tony to change owner to `sa` after a few clean runs.

## Verification
- `SELECT COUNT(*) FROM dbo.asi_expired_quote_cancel_log WHERE run_date >= CAST(GETDATE() AS date)` → equals quotes cancelled.
- Preview again → 0 rows. Open a logged quote in Order Entry → cancelled. Item Maintenance location delete that was blocked → now works (NOT yet verified 10/21).
- Day after: job history succeeded; log rows for the run (~42 expected for 10/22).

## Rollback
- Disable (don't delete) the job. Cancelled quotes are in the log table (order_no): clear cancel/complete flags on oe_hdr/oe_line/quote_hdr/quote_line and set a new expiration date. NO undo script exists yet. Single quotes: reopen in Order Entry with a new expiration date.

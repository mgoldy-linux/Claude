# Deployment Guide — Salesrep Contact Email Fixes (no ticket)

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- `Sql-Scripts\Alerts\Fix-Kevin-Isken-Email-BusinessRules-TEST.sql` — single-contact `UPDATE`, contact `1049`
- `Sql-Scripts\Alerts\Fix-Nick-Kessler-Email-BusinessRules-TEST.sql` — single-contact `UPDATE`, contact `38117`
- `Sql-Scripts\Alerts\Fix-Blank-Salesrep-Emails-From-Login.sql` — bulk `UPDATE`, NULL `contacts.email_address` population scoped to `contacts.salesrep = 'Y'`
- Origin: alert email queue failures investigation (`alert_queued_mail` 1060/1063), 2026-09-23 — no ticket opened

## Target environments
- **P21BusinessRules** (test) → **P21 (Production)**. Both single-contact scripts are file-named `-BusinessRules-TEST` because they were deliberately proven there first per the user's stated preference (test before Prod).
- The bulk script has no `USE` statement — it has never been run against any environment; whoever runs it must confirm the connection first.

## Dependencies & deploy order
1. No dependencies on other artifacts. Each script is a standalone `UPDATE` against `dbo.contacts`.
2. Order between the three scripts doesn't matter — they're scoped to disjoint or overlapping-but-idempotent contact sets.
3. **Environment discipline matters more than usual here** — this session repeatedly hit confusion from running audits against different connections (Play/BusinessRules/unstated) without confirming first, which cost real time chasing a false "reversion." Confirm the connection every time before running any of these.

## Backward-compatibility notes
- None — these are plain data corrections to `contacts.email_address`, read by the P21 alert engine (`p21_fn_validate_email_address(contacts_salesrep.email_address)`) and nothing else structural.

## Deploy steps
1. **P21BusinessRules (done 2026-09-23):**
   - `Fix-Nick-Kessler-Email-BusinessRules-TEST.sql` — run, verified, `COMMIT TRANSACTION` executed. Confirmed: contact `38117` now `nkessler@allsurfaces.com`.
   - `Fix-Kevin-Isken-Email-BusinessRules-TEST.sql` — run, verified, `COMMIT TRANSACTION` executed. Confirmed: contact `1049` now `kevini@allsurfaces.com`.
2. **Prod (not started):** re-run both single-contact scripts against Prod (change `use [P21BusinessRules]` to the Prod connection, or just connect to Prod in SSMS before running — either script has no other environment-specific logic).
3. **Bulk NULL-email fix (not started anywhere):** run `Fix-Blank-Salesrep-Emails-From-Login.sql`'s preview step (section 1) first, eyeball the `domain_flag` column for any source address that isn't itself `@allsurfaces.com`, then run the `UPDATE` inside the transaction (section 2), compare `@@ROWCOUNT` to the preview's row count, verify (section 3), then explicitly `COMMIT TRANSACTION` or `ROLLBACK TRANSACTION` — nothing persists automatically.
4. **Not built yet:** a bulk fix for the ~30-name WRONG DOMAIN population (contacts still on `@alltileccs.com` where the login already has the correct address) — no decision made yet on whether to mass-sync these the same way as the NULL population, or handle case-by-case given the larger blast radius.

## Verification
- `SELECT id, email_address FROM contacts WHERE id IN (38117, 1049)` → `nkessler@allsurfaces.com` / `kevini@allsurfaces.com` respectively.
- For the bulk script: row count from `@@ROWCOUNT` should match the preview query's row count exactly before committing.

## Rollback
- Single-contact scripts: re-run with the old value substituted (`kisken@alltileccs.com` for 1049, the prior corrupted/blank value for 38117 — not preserved verbatim, pull from `Docs/P21-Env-Status-Customizations.txt` history or this guide's prior commits if ever needed).
- Bulk script: no automated rollback — the preview step's output is the only record of prior values; capture it before committing if rollback might be needed.

# Deployment Guide — (no ticket) 90 Day Usage Report — Blank Subscriptions

> Produced during investigation. Update as the artifact changes; commit with the code.

## Artifact(s)
- `PowerShell-Scripts\Fix-NinetyDayUsageSubscriptions-MfgParam.ps1` — one-off repair script for corrupted SSRS subscription parameters
- Report: `/Company Reports/Sales/Inventory Usage 90 Days by Location` (SSRS, `reports.allsurfaces.com`) — recommended query fix NOT yet applied
- Ticket: none assigned

## Target environments
- SSRS catalog: `reports.allsurfaces.com` (report server), catalog DB on `ASDWDB01.ahi.local\ReportServer`
- Report's own data source: `/Data Sources/DW-P21` → `ASDWDB01.ahi.local\P21` (nightly restore from Prod)

## What was actually wrong
Two separate, unrelated problems surfaced under the same complaint ("report comes in blank"):

1. **4 of ~44 branch subscriptions had a corrupted `mfg` (manufacturer) parameter** — collapsed to 0–1 selected values instead of the full manufacturer list (~328 at time of fix). Confirmed by shredding `dbo.Subscriptions.Parameters` XML and comparing `mfg` value counts across all subscriptions on the report. Affected: **162, 241, 261, 400**. This is a real, reliable-every-time bug — not intermittent.
2. **An intermittent zero-row render bug**, confirmed real (same location renders full data, then 0 rows minutes later, both logged `rsSuccess` in `ExecutionLog3`) but root cause NOT confirmed. Three mechanisms were checked and ruled out: report-level caching (off), the three parameter-default shared datasets' 30-minute cache serving a bad refresh (checked full history, clean), and a suspected `kb_`-branded live data source dependency (**this was a false lead** — verified via `dbo.DataSource.Link` that all parameter datasets genuinely resolve to `DW-P21`, same as the main query; the `kb_` name was stale metadata in the shared dataset's `Content` XML blob, not the live binding).

Problem 1 is fixed and verified. Problem 2 is unresolved.

## Dependencies & deploy order
1. No deploy order concerns — this is a subscription **parameter correction**, not a code/view/report deploy. It edits data already in the SSRS catalog via the supported API.
2. If the recommended query fix (NULL-guard, below) is ever applied to the `.rdl`, redeploy the `.rdl` to the SSRS catalog as normal, then re-verify parameter defaults per [[feedback_ssrs_rdl_vs_catalog_defaults]] (redeploys can silently reset stored defaults).

## Backward-compatibility notes
- None — parameter correction only, brings the 4 broken subscriptions in line with how the other ~40 are already configured.

## Deploy steps (already executed)
1. Dry run: `powershell.exe -NoProfile -File Fix-NinetyDayUsageSubscriptions-MfgParam.ps1` (no `-Apply`) — prints before/after `mfg` counts per subscription, changes nothing.
2. Apply: same command with `-Apply`.
3. **Must run under Windows PowerShell 5.1 (`powershell.exe`), not PowerShell 7 (`pwsh`).** `New-WebServiceProxy` against SSRS's `ReportService2010.asmx` WSDL silently returns a hollow object (0 real methods) under pwsh 7 — no error, it just doesn't work. Under 5.1 it builds the full 503-method proxy correctly. See [[feedback_new_webserviceproxy_pwsh7]].

## Verification
- Ran independently against the DB (not just trusting the script's own report): shredded `dbo.Subscriptions.Parameters` XML for all 4 target `SubscriptionID`s post-fix — confirmed all 4 now show `MfgCount = 328`, matching healthy subscriptions.
- Next real verification is external: Jami / branch managers confirming the next scheduled Sunday run for 162, 241, 261, 400 comes through with data.

## Rollback
- If needed, the previous (broken) parameter state is NOT saved anywhere — this was a corrupted state to begin with, not a deliberate prior configuration, so there is nothing meaningful to roll back to. If a rollback were ever needed, re-run the dry-run script to see current state, then manually adjust the `mfg` parameter in **Manage > Subscriptions > Parameters** in the portal.

## Open follow-up (not part of this deploy)
- **Recommended query fix, not applied:** the report's embedded SQL has `ic.product_group_name IN (@product_group)` and `ic.manufacturer_id = @mfg` with no NULL/empty-safe guard, unlike `price_family`/`abc_class` which both use `(@x IS NULL OR ...)`. Worth adding defensively regardless of whether it's the cause of problem 2.
- **Root cause of the intermittent zero-row bug is still open.** Next angle: SQL Server blocking/timeout/`system_health` extended events on `ASDWDB01.ahi.local` at the known anomaly timestamps (7/8 9:17–9:21 AM, 7/16 4:23–4:26 PM).
- **Standing kb_/js_ retirement candidates** (still genuinely executing, not proven broken): `kb_view_item_classifications_loc100`, `kb_sales_history_report_view`, `kb_view_inventory_by_loc`.

# Deployment Guide — (no ticket) 90 Day Usage Report — Blank Subscriptions

> Produced during investigation. Update as the artifact changes; commit with the code.

## Artifact(s)
- `PowerShell-Scripts\Fix-NinetyDayUsageSubscriptions-MfgParam.ps1` — one-off repair script for 4 corrupted SSRS subscription parameters (2026-07-23; since shown NOT to be durable — see below)
- `PowerShell-Scripts\Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1` — the durable fix: switches `mfg` from a static "Enter value" list to "Use Default Value" for all 44 per-location subscriptions. **Applied 2026-07-27** (confirmed via `dbo.Subscriptions.ModifiedDate` batch update 14:49-14:50).
- `PowerShell-Scripts\Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1` — one-time forced rerun of all 44 per-location subscriptions via `FireEvent`, requested by Jami to validate the fix before the normal Sunday schedule. **Built 2026-07-28, NOT yet run.**
- `C:\PowerShell-Scripts\Create-Excel\Export-90DayUsageSubscriptionParameters.ps1` — per-location parameter + Source-of-Value export (verification tool)
- Report: `/Company Reports/Sales/Inventory Usage 90 Days by Location` (SSRS, `reports.allsurfaces.com`) — recommended NULL-guard query fix still NOT applied
- Ticket: none assigned

## Target environments
- SSRS catalog: `reports.allsurfaces.com` (report server), catalog DB on `ASDWDB01.ahi.local\ReportServer`
- Report's own data source: `/Data Sources/DW-P21` → `ASDWDB01.ahi.local\P21` (nightly restore from Prod)

## What was actually wrong
Three problems, discovered in layers under the same complaint ("report comes in blank") — the first two were what we knew as of 7/23; the third is what actually explains why the fix didn't hold:

1. **4 of ~44 branch subscriptions had a corrupted `mfg` (manufacturer) parameter** — collapsed to 0–1 selected values instead of the full manufacturer list (~328 at time of fix). Confirmed by shredding `dbo.Subscriptions.Parameters` XML and comparing `mfg` value counts across all subscriptions on the report. Affected: **162, 241, 261, 400**. Fixed 2026-07-23 by rebuilding the full list via the SOAP API.
2. **An intermittent zero-row render bug**, confirmed real (same location renders full data, then 0 rows minutes later, both logged `rsSuccess` in `ExecutionLog3`). Three mechanisms were checked and ruled out: report-level caching (off), the three parameter-default shared datasets' 30-minute cache serving a bad refresh (checked full history, clean), and a suspected `kb_`-branded live data source dependency (**false lead** — verified via `dbo.DataSource.Link` that all parameter datasets genuinely resolve to `DW-P21`, same as the main query; the `kb_` name was stale metadata in the shared dataset's `Content` XML blob, not the live binding).
3. **(2026-07-27) The real, durable root cause.** Subscription 241 — one of the 4 "fixed" on 7/23 — relapsed to blank on its very next Sunday run (7/26), proving the rebuild-the-list fix doesn't hold. Investigating further: the report's `mfg` parameter is now deployed as **`MultiValue: False`** (single-value) — confirmed via the SSRS REST v2.0 `/ParameterDefinitions` endpoint — yet every subscription still stores 300+ individual entries under that parameter name, which only makes sense for a *multi-value* parameter. The report was last redeployed 2026-06-01; this is a third instance of the class of bug in [[feedback_ssrs_rdl_vs_catalog_defaults]] (a redeploy silently changing catalog-side parameter shape without updating dependent subscriptions). Checked what "Use Default Value" resolves to before recommending it: `mfg`'s default is query-based but evaluates to `NULL`, and the query is written `(@mfg IS NULL OR ic.manufacturer_id = @mfg)` — `NULL` means *no filter*, which is safe. **A live census (SOAP `GetSubscriptionProperties`) found 46 of 49 subscriptions still on the frozen "Enter value" list**; only 100, 103, 241 were on "Use Default," all three edited that same morning while testing.

Problem 1's fix (2026-07-23) is superseded — it did not hold. Problem 2 (intermittent bug) is very likely explained by problem 3, but that connection is not proven. Problem 3's fix was **applied 2026-07-27** (confirmed via `ModifiedDate`).

## Dependencies & deploy order
1. No deploy order concerns — this is a subscription **parameter correction**, not a code/view/report deploy. It edits data already in the SSRS catalog via the supported API.
2. If the recommended query fix (NULL-guard, below) is ever applied to the `.rdl`, redeploy the `.rdl` to the SSRS catalog as normal, then re-verify parameter defaults per [[feedback_ssrs_rdl_vs_catalog_defaults]] (redeploys can silently reset stored defaults).

## Backward-compatibility notes
- `Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1` only ever *removes* stored `mfg` overrides (never adds/changes other parameters), and only touches subscriptions whose Description matches a 3-digit branch code (`^\s*\d{3}\b`). Explicitly excludes 5 non-location subscriptions on this same report — **Karndean 90 Day Global Report** and **Lotte Weekly 90 Day Report** intentionally filter to a single manufacturer each and must never be switched to "Use Default"; **90 Day**, **Test of missing Paramater**, and **Weekly Global 90 Day Usage** are not per-branch and were left alone out of caution, not because they were checked individually.

## Deploy steps
**2026-07-23 fix (superseded, kept for history):**
1. Dry run: `powershell.exe -NoProfile -File Fix-NinetyDayUsageSubscriptions-MfgParam.ps1` (no `-Apply`).
2. Apply: same command with `-Apply`. Fixed 162/241/261/400 to a 328-value list — **241 relapsed by its next Sunday run**, so this fix is not considered durable; superseded by the fix below.

**2026-07-27 fix (current, applied):**
1. Dry run: `powershell.exe -NoProfile -File Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1` (no `-Apply`) — pulls the subscription list live from the catalog DB, prints which of the 44 per-location subscriptions would change and which are already on "Use Default." Confirmed clean on 2026-07-27 (44 in scope, 3 already default, 41 would change, 5 correctly excluded).
2. Apply: same command with `-Apply`. **Run 2026-07-27 14:49-14:50** — confirmed via `dbo.Subscriptions.ModifiedDate` batch timestamp across all 44.
3. **Must run under Windows PowerShell 5.1 (`powershell.exe`), not PowerShell 7 (`pwsh`).** `New-WebServiceProxy` against SSRS's `ReportService2010.asmx` WSDL silently returns a hollow object (0 real methods) under pwsh 7 — no error, it just doesn't work. Under 5.1 it builds the full 503-method proxy correctly. See [[feedback_new_webserviceproxy_pwsh7]]. Same applies to `Export-90DayUsageSubscriptionParameters.ps1` and `Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1`.

**2026-07-28 one-time validation fire (requested by Jami, not yet run):**
1. Dry run: `powershell.exe -NoProfile -File Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1` (no `-Apply`) — lists the 44 `SubscriptionID`/`ScheduleID` pairs it would fire.
2. Apply: same command with `-Apply` — calls `ReportingService2010.FireEvent("TimedSubscription", ScheduleID)` per location. Sends real email to real recipients, identical to a normal scheduled run, but does not move or alter the underlying Sunday schedule.
3. Recommended timing: run in the evening, before the `asdwdb01` nightly 2:05 AM restore-from-Prod window, and after business hours per Jami's own "tonight" framing.

## Verification
- **2026-07-23 fix:** shredded `dbo.Subscriptions.Parameters` XML for all 4 target `SubscriptionID`s post-fix — confirmed all 4 showed `MfgCount = 328` at the time. **This did not hold** — subscription 241 was back to 0 `mfg` entries by 2026-07-27, and Jami reported it blank again off the 7/26 Sunday run. Treat any future "fix confirmed via count snapshot" claim on this report with the same skepticism until the underlying type-mismatch (problem 3) is resolved.
- **2026-07-27 fix:** confirmed applied via `dbo.Subscriptions.ModifiedDate` — all 44 in-scope subscriptions show a tight batch-update timestamp (14:49:51-14:50:06), matching a single scripted run. Have not yet re-run `Export-90DayUsageSubscriptionParameters.ps1` to see the `mfg_Source` column flip to "Use Default Value" per row — worth doing for belt-and-suspenders confirmation, but the `ModifiedDate` evidence is already solid given the earlier caution about count-snapshot claims (problem 3).
- **Real-world verification still pending:** Jami wants all 44 forced to rerun tonight (one-time, her request) specifically to validate before the normal Sunday schedule. Once `Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1 -Apply` runs, check `dbo.Subscriptions.LastRunTime`/`LastStatus` or `ExecutionLog3` afterward to confirm every location actually rendered non-empty — this is the verification step that matters most, since the type-mismatch class of bug (problem 3) has already produced one false "confirmed fixed" before.

## Rollback
- 2026-07-27 fix: re-run `Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1 -Apply` is not reversible via the script (it only removes overrides, doesn't restore a prior list). If a manufacturer-scoped filter is ever needed again for a specific location, set it manually in **Manage > Subscriptions > Parameters** in the portal.
- Fire-tonight script has no rollback concept — it only triggers a real subscription send, same as the resulting email would look identical to a normal Sunday run. No schedule or data is altered.

## Open follow-up (not part of this deploy)
- **Run `Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1 -Apply` this evening** (before the 2:05 AM `asdwdb01` restore window) — Jami's explicit request, one-time. **Not yet run.**
- **After firing, check `LastStatus`/`ExecutionLog3`** to confirm all 44 rendered non-empty before Jami reviews them.
- **5 newly-reported branches not yet individually checked:** Naperville, St. Cloud, Omaha, Wixom, Ft Wayne — assumed covered by the same across-the-board `mfg` fix since it's not location-specific, but that's an assumption, and should be confirmed by tonight's fire results specifically for those 5.
- **Recommended query fix, not applied:** the report's embedded SQL has `ic.product_group_name IN (@product_group)` with no NULL/empty-safe guard, unlike `price_family`/`abc_class` which both use `(@x IS NULL OR ...)`. Worth adding defensively.
- **Standing kb_/js_ retirement candidates** (still genuinely executing, not proven broken): `kb_view_item_classifications_loc100`, `kb_sales_history_report_view`, `kb_view_inventory_by_loc`.

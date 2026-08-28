# Epicor Support Case Draft — Scheduled "Generate PO Requirements" (Auto-Buy) job never creates a PO

**Environment:** P21 Training (`P21Training`, middleware `p21train.allsurfaces.com:3447`) and P21 Business Rules (`P21BusinessRules`, `p21businessrules.allsurfaces.com:3444`), both on Installer Version `2021.1.4559.0`. Reproduces on both.

## Summary

A scheduled task built to run PO Requirements Generation ("Auto Buy") unattended never creates a purchase order, no matter how it's configured — even when the run finds real, positive demand against a supplier with a valid Target Value, and even when explicitly built with the window's own **Task Type: Auto-Buy** option (as opposed to the default "Save Session"). The job type used, `P21.Scheduler.Jobs.SaveWindowJob`, appears to only be able to replay field values into the `m_generatepurchaseorder` window's criteria screen (the "compute requirements" step) and cannot drive the window through to the separate step that actually writes `po_hdr`/`po_line`, regardless of which Task Type is selected.

## What we ruled out first

- **Scheduler/UI Server connectivity** — confirmed working; the job reaches the UI Server and executes.
- **KB0124783 (`allow_gpor_work_save_restore` System Setting)** — applied and confirmed via direct SQL (`system_setting.value = 'Y'`) in both environments. Needed to get past an initial `Unknown menu name: m_processscheduledjob` error, but did not by itself get the job producing POs.
- **Scheduler Location URL** — was missing in both environments; setting it (`https://{env-middleware}:{port}/Scheduler/api`) cleared the menu-name error, surfacing later errors instead (`Tab page is disabled`, `Column is disabled: beg_supplier_id` — both inside `PoRequirementCustomizationProvider.Process → InteractiveRestClient.ChangeData`, i.e. the job's attempt to push saved field values into a live window instance).
- **A live P21 client window open against the same environment while the job runs** — traced via Extended Events and found a real SQL error 15408 (`"Impersonate Session Security Context" cannot be called in this batch because a simultaneous batch has called it`) firing at the exact moment of one failure, caused by a concurrently-open Scheduled Task Manager grid refresh. Real, but not the only failure mode — the job also fails cleanly with no other client window open.
- **Supplier Target Value not cleared (KB0132445)** — this explained an earlier round of "Success, no PO" (target supplier had `target_value = $0.00`). Re-tested against **criteria 251**, supplier Jasztex (`target_value = $300.00`), with genuine unmet demand (three items, ~$629–$1,996 shortfall each against min/max, well over the $300 target). The job logged **Success** and **found 21 items** (`gpor_run_hdr.detail_count = 21`) — and still created **zero** purchase orders.

## The actual reproducible evidence

Two fresh scheduled jobs run today (8/27/2026), both `SaveWindowJob`, both logged `Success`:

| Job | Criteria | Run | `gpor_run_hdr.detail_count` | `po_hdr` rows created |
|---|---|---|---|---|
| Test 251 (uid 1692419) | 251 — Jasztex, Stock/Non-Stock/Special, target $300 | 10:01 AM | 21 | 0 |
| Test 08.27.2026 (uid 1692420) | 786 — direct-ship, all suppliers | 1:09–1:14 PM | 44 | 0 |

`gpor_run_hdr.default_to_order = 'N'` on every automated run we've captured. We also compared against manual clicking in the live window the day before (8/26, 5:27–5:31 PM), which produced a few runs with `default_to_order = 'Y'` — **those also produced no PO**. The most recent `po_hdr` row anywhere in P21Training is from **8/6/2026**, created by real interactive users — none from any GPOR/scheduler-originated process, automated or manual-preview, in the period we traced.

This is consistent with PO Requirements Generation being a two-step wizard (1: compute requirements into `gpor_run`/`gpor_run_hdr`; 2: a separate, explicit "create the PO(s)" action) where `SaveWindowJob` can only automate step 1.

## Task Type: Auto-Buy — tested directly, made no difference

The Schedule dialog on `m_generatepurchaseorder` offers a **Task Type** dropdown with (at least) two relevant options: **"Save Session"** and **"Auto-Buy"** (plus a "Freight Target must also be met for Auto-buy" checkbox and a "Price Items" checkbox). Every job tested through 8/26 defaulted/reverted to "Save Session." On 8/27 we built and ran both variants side by side, same criteria (251, Jasztex), same everything else, differing only in Task Type — confirmed at three independent layers:

1. **DB**: diffing `job_config` for the two jobs shows the only difference is `scheduled_job_type` (`1` = Save Session, `2` = Auto-Buy) plus its companion field (`scheduled_job_price_items` for type 1, `scheduled_job_auto_buy_consider_freight` for type 2).
2. **Live network capture** (P21 web client, browser DevTools): selecting Task Type = Auto-Buy fires `PUT /data` with `DatawindowName: "tp_2_dw_2", FieldName: "scheduled_job_type", Value: 2`. The response echoes back `scheduled_job_type: 2, scheduled_job_price_items: "Y", scheduled_job_auto_buy_consider_freight: "N"` — matching the DB exactly, and the response's `Events` array shows the DataWindow's own field-enablement formulas (`if(scheduled_job_type = 1, ...)` / `if(scheduled_job_type = 2, ...)`), confirming P21 treats these as two genuinely distinct, purpose-built modes.
3. **Execution results**, both jobs run more than once, including user-initiated (not just scheduled):

| Job | `scheduled_job_type` | Trigger | Result | `detail_count` | `po_hdr` created |
|---|---|---|---|---|---|
| Test 251 (1692419) | 2 (Auto-Buy) | User-initiated, 3:56:43 PM | Success | 21 | 0 |
| Test 251 (1692419) | 2 (Auto-Buy) | User-initiated, 4:17:18 PM | Success | 21 | 0 |
| 251 without Auto-Buy (1692421) | 1 (Save Session) | User-initiated, 4:00:59 PM | Success | 21 | 0 |

Identical `gpor_run_hdr` signature (`default_to_order = N`, `gpor_flag = G`, `detail_count = 21`) regardless of Task Type. **Zero POs from either.** This rules out Task Type as the missing lever — it's a real, verified, distinct setting, and it doesn't change the outcome.

One incidental finding along the way: `Test 251` got stuck in a `running_flag = 'Y'` state for over an hour after a Deactivate→Activate→fire sequence in quick succession, and rejected a manual re-trigger with `P21.Scheduler.JobManagementException: ... already running`. A stop/start cleared it. Not central to the core issue, but worth flagging as a separate scheduler-reliability quirk.

## What we're asking Epicor

1. Is `SaveWindowJob` (or any current scheduled-job type) supported for driving `m_generatepurchaseorder` (PO Requirements Generation / "Auto Buy") all the way through to PO creation, or only through the requirements-computation step? We've tested both the default "Save Session" Task Type and the dedicated "Auto-Buy" Task Type — neither creates a PO.
2. If it is supported, what job configuration (or a different job `type`, since none of the ~20 job types installed — `FormToDocumentJob`, `GenerateAndSendFormJobEmail`, `FastEditJob`, `BinReplenishmentJob`, etc. — appear purpose-built for GPOR) is required to reach the actual "create PO" action unattended?
3. Is `Column is disabled: beg_supplier_id` (seen when a `SaveWindowJob` snapshot with `supplier_option_cd` set writes directly to `beg_supplier_id`) a known incompatibility, and is there a documented/supported way to configure a supplier range for an automated GPOR replay that avoids it?
4. Is a scheduled task getting permanently stuck in a "running" state after a rapid Deactivate/Activate cycle (blocking further on-demand execution with `JobManagementException`) a known issue, and is there a supported way to clear it other than stop/start?

## Supporting material available on request

- Extended Events trace of the SQL issued during a live failure (both the BusinessRules impersonation-collision run and today's Training run).
- `scheduled_job.job_config` XML snapshots for all four test jobs (1692418/1692419/1692420/1692421).
- `gpor_run_hdr` / `gpor_run` rows for every run referenced above.
- Full network capture (request/response JSON) of the Task Type: Auto-Buy field selection from the P21 web client.

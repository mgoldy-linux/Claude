# Work Log

**Newest first. One entry per task — not per resume.** When you pick a task back up, update its
existing row; don't add a new one. Move a task to **Completed** once it's accepted/shipped.

**Status key:** 🟡 Awaiting feedback/testing · 🔵 In progress · ⏸ Parked · 🔴 Blocked · 🟢 Done

> The `/resume` GUIDs are a convenience only — transcripts prune at ~30 days, so older ones are dead.
> The durable record is the task, its status, and the memory note linked in **Detail**.

---

## Active — awaiting feedback, in progress, or parked

| Last touched | Task | Status | Where it stands / next step | Detail |
|---|---|---|---|---|
| 2026-07-20 | WWMS Alert "Open" throws `Window <<m_binreplenishment>>` error (BRR, post-refresh) | 🟡 Awaiting feedback/testing | Root cause found via browser network trace (not SQL): AHI-API1's P21 UI Server (web/EVA client) caches menu/security in-process from pre-refresh DB state; desktop-side `p21_view_dc_menu_security` is clean in both BRR and Prod, so it's not a data/permission issue. Fix = recycle the IIS app pool behind **API-P21BusinessRules - P21 SOA** (site confirmed on `*:3444`) on AHI-API1 — not a site Restart. User was mid-recycle when session ended. Next: confirm the Bin Replenishment "Open" button now works; if so, consider adding an app-pool recycle step to the After-refresh checklist | `project_2026_07_20_wwms_alert_binreplenishment_error.md` |
| 2026-07-20 | BRR refresh — WWMS/RF location flags capture + CMECHEM whitelist bug | 🟡 Awaiting feedback/testing | Added Phase 0E/2I (location WWMS/RF flag capture-restore) + settings-script override for Document Imaging (789). Found & fixed a real, pre-existing bug: settings script's user-disable block runs *after* Phase 2A's per-user restore and silently undoes it for anyone not on its hardcoded whitelist — CMECHEM was falling through. Fixed by whitelisting it. Neither fix confirmed against a live Prod-restore yet. **Note:** the `.ps1`/`.sql` files touched are outside the `C:\Claude` git repo — not version-controlled. Next: verify both on the next real BRR refresh | `project_p21businessrules_refresh.md` |
| 2026-07-17 | SA-50249 Five Way report acceleration (columnstore materialization) | 🔵 In progress | Built + proven in Play **and** on the DW (149,547 ms → 125 ms, ~1,200×; all 195 cols `EXCEPT`-equal). New `ASI_ReportCache` DB + synonyms + compute view live on `asdwdb01`. One-time **build+verify** Agent job scheduled **2026-07-17 23:00** (no live swap). Next: read `ASI_ReportCache.dbo.BuildLog`; if clean → GO-LIVE (refresh proc w/ swap + nightly post-restore job + `SSRS_Users` grant). Ticket itself = user education (Jeff Eichler picked a team he's not on) | `project_sa50249_five_way_acceleration.md` |
| 2026-07-15 | YTD Sales ribbon tile — `asi_ribbon_cm_SYTD` (ref 20251229) | 🟡 Ready to test/deploy | Rewrite of `kb_CustRM_getYTDSalesAbbr` is built: critical year-filter bug fixed (VARCHAR `year_for_period` vs INT → blank tile), all kb_ deps removed (now on `p21_sales_history_view`). Never deployed or logged. Next: run test plan TC-01..08 in Dev/Test, then Prod per changelog rollback plan | `Docs\asi_ribbon_cm_SYTD_changelog.txt` |
| 2026-07-15 | P21 Play API — create orders | 🔵 In progress | Postman auth to Play working; only a GET read exists. Next: hit `/uiserver0/ui/interactive/v1` docs to learn if orders POST-create or must drive UI-server window endpoints | `project_2026_07_15_p21_play_api_orders.md` |
| 2026-07-17 | Low Margin Alert (Evan) | 🟡 Awaiting feedback | **Evan signed off** on the audience split (2026-07-17). All 3 original blockers cleared. Fired live in Play; fixed Outlook line-break mangling (blank-line-separated fields — Outlook strips single newlines), price-page `(no price page)` fallback, and a latent flag bug (parent created 705=inactive → now **704=active**). Next: await Evan's OK on the re-fired blank-line sample, then Prod (real recipients + `USE P21`). Open Q: `N/A` for MAC when item has no moving-avg cost | `project_2026_07_13_low_margin_alert.md` |
| 2026-07-13 | SA-48715 Five Way Params (SSRS) | 🔵 In progress | Deployed `-SA-48715-Fix` lost the Null default on 17 params; `@division` unwired in `…Dropdown-1.rdl`. Next: confirm working copy, re-set the 17 defaults | `project_2026_07_13_sa48715_five_way_params.md` |
| 2026-07-13 | SA-49504 EDI 855 view fix | 🟡 Awaiting feedback | View + v4 .srd deployed to Prod, both cols verified. Awaiting user feedback | `project_2026_07_13_edi_855_view_fix.md` |
| 2026-07-13 | SA-48732 CSR Open Order Team | 🟡 Prod deploy pending | Play verified (uid 333). Prod needs only the .srd overwrite | `project_2026_07_13_sa48732_csr_open_order_team.md` |
| 2026-06-26 | SA-48124 Vendor Invoice EDI Charges | ⏸ Parked | Research done, ticket write-up committed. Next: build asi_view_vendor_invoice_edi_charges + Crystal subreport, deploy to Play, retest invoice 26190433 → 76.53 | `project_sa48124_vendor_invoice_edi_charges.md` |
| 2026-06-26 | jsTextValidator / B2B popup | ⏸ Parked (open Q) | Traced popup to jsTextValidator→js_proc_string_fix err 997-5. OPEN: is B2B 80-char/no-symbol limit still valid? (gates asi_po_entry_text_validator rewrite) | `project_2026_06_26_js_text_validator_b2b.md` |
| 2026-06-25 | SA-47981 WWMS Pick Item Desc | ⏸ Parked | Pre-SQL injects WWMSITEMDESC (confirmed live) but screen-only column won't populate. Next: a 2nd BR to populate the field directly | `project_2026_06_25_sa47981_wwms_pick_item_desc.md` |
| 2026-06-23 | kb_Order_Validator_v2 | 🟡 Follow-up test | P21 ACCEPTED deploy 2026-06-24. Built OLD-vs-NEW harness. Resume at A1 finder → run case A1 in Play | `project_2026_06_23_kb_order_validator_v2.md` |
| 2026-06-16 | QTO Taker BR | 🟡 Partial | Wizard path ready for Prod. RMB path on hold (P21 message-box event has no order context); emailed Chad & Tyler 2026-06-23 | `project_2026_06_16_qto_taker_br.md` |
| 2026-06-17 | Portal cleanup (Goal 1) | 🔵 In progress | 156 unused .srd + 32 assets staged; to-dos #2–#5 open (unassign users/roles). Read `C:\_P25\Portal-Cleanup-Progress.md` on resume | `project_2026_06_17_portal_cleanup.md` |

## Completed

| Date | Task | Detail |
|---|---|---|
| 2026-07-15 | Efrain — Discontinued items + on-hand qty query (fixed C2 alias bug; delivered inline) | `Sql-Scripts\Discontinued-Items-With-QOH.sql` |
| 2026-06-22 | Portal Tab Tracking XE deployed (Play + Prod) | `project_2026_06_22_portal_tab_tracking.md` |
| 2026-06-18 | SA-48237 asi_view_inv_mast built (P21Dev) | `project_2026_06_18_asi_view_inv_mast.md` |
| 2026-06-15 | Compare-P21-Users.sql built | `project_2026_06_15_compare_p21_users.md` |
| 2026-06-15 | P21 Dev refresh | `project_p21dev_refresh.md` |
| 2026-06-11 | asi_ribbon_rm_default_products committed | `project_2026_06_11_ribbon_default_products.md` |
| 2026-06-02 | BRR refresh fixes (Phase 0D crash, grants, Training proc deploy) | `project_2026_06_02_brr_refresh_fixes.md` |
| 2026-06-02 | Suppress Messages business rule → Prod | `project_suppress_messages_business_rule.md` |
| 2026-05-28 | SA-45138 BOP portals V2 + drill-through → Prod (approved by Pamela) | `project_sa45138_bop_portals.md` |
| 2026-05-27 | P21 Play refresh (EDI-aware settings v2026-05-27) | `project_p21play_refresh.md` |
| 2026-05-19 | SA-45865 apc_business_rule_extensions_xml varchar fix | `project_apc_permissions.md` |
| 2026-05-14 | Check-Job-History daily failed-job checker | `project_check_job_history.md` |
| 2026-05-01 | P21Training DB refresh scripts | `project_p21training_refresh.md` |

<!-- Older sessions (pre-May 2026) are captured in memory; add rows here only for notable shipped work. -->

## Backlog — requests, side projects, nice-to-haves (not yet started)

**No status here — these haven't started.** When you pick one up, cut the row and add it to **Active** with a status.

| Added | Item | Type | Priority | Who / why | Notes |
|---|---|---|---|---|---|
| 2026-07-15 | Raise `cleanupPeriodDays` so `/resume` reaches older sessions | Nice-to-have | Med | Me — transcripts prune at ~30d, killing older resume points | Config change in settings.json; notes remain the durable layer regardless |
| 2026-07-15 | Cleanup deleted salesreps (ribbon default products) | Side project | Low | Follow-up from `asi_ribbon_rm_default_products` (3c76bac) | See `project_2026_06_11_ribbon_default_products.md` |
| 2026-07-15 | Confirm B2B 80-char / no-symbol limit still valid | Request (open Q) | Med | Gates the `asi_po_entry_text_validator` rewrite | Blocks the parked jsTextValidator task; see `project_2026_06_26_js_text_validator_b2b.md` |
| 2026-07-15 | Ticket 47715 — waiting on user | Request | Med | External ticket; waiting on user reply | Keep: 3 Goals |
| 2026-07-15 | Fix `asi_proc_copy_p21_user` — missing user description before Prod update | Side project | Med | Bug fix before Prod update | Keep: Project Focus |
| 2026-07-15 | Purch open-PO EDI portal — update `kb_ref` | Request | Med | **kb_ flag** — retire the kb_ dependency | Keep: Project Focus |
| 2026-07-15 | Fix CMI Open Orders & RMA tab — more SQL fix | Side project | Med | Follow-on SQL fix | Keep: BR list |
| 2026-07-15 | Combine all ribbon BRs into one rule (start with Order-Entry ribbon) | Side project | Med | **Check kb_/js_ in the ribbon rules**; overlaps the `asi_ribbon_cm_SYTD` YTD work | Keep: BR list |
| 2026-07-15 | Update refresh scripts to include alerts/emails | Side project | Med | Refresh-script enhancement | Keep: To do |
| 2026-07-15 | P21 Upgrade — check PO fix / latest UnApproved-PO portal; how to update POs (for Jere) | Side project | Med | Q2 upgrade focus; Jere | Keep: P21 Upgrade Q2 |
| 2026-07-15 | Check with Tony about P21 emails | Request | Med | Waiting on Tony | Keep: To do |
| 2026-07-15 | Set up weekly Compare-folders job (Fridays) | Side project | Low | Automate the folder compare | Keep: To do |
| 2026-07-15 | sp conversion for Jossy — add examples | Request | Low | Jossy | Keep: To do |
| 2026-07-15 | Rename wireless portal; add to module & limit to two weeks | Side project | Low | Portal task | Keep: To do |
| 2026-07-15 | "scan * pack" in audit trail — look deeper | Side project | Low | Investigation | Keep: To do |
| 2026-07-15 | Price-change tracking — any source other than audit trail? | Request (open Q) | Low | Investigation | Keep: To do |
| 2026-07-15 | P21 user-def tables — is it possible to check? (ask Claude) | Request (open Q) | Low | Investigation | Keep: To do |
| 2026-07-15 | Suspended Alerts status (ref 1/5/26) | Request | Low | Alerts review | Keep: Project Focus |
| 2026-07-15 | Create Confluence doc for non-regular tasks (Rewards alerts, holidays in P21 & data warehouse, periods) | Side project | Low | Documentation | Keep: Project Focus |
| 2026-07-15 | Fax Number cleanup (ref 20250925) | Side project | Low | — | Keep: Project Focus |
| 2026-07-15 | Portal: order-no on top; click order number → line-location info (see "RE: Report") | Side project | Low | Portal enhancement | Keep: Project Focus |
| 2026-07-15 | P21 Upgrade — add "P21 Web" related docs to folder | Side project | Low | Documentation | Keep: P21 Upgrade Q2 |
| 2026-07-15 | Look at `DirectShipPriceCheck_0801_0805.dll` — item with the same… | Side project | Low | BR investigation | Keep: BR list |
| 2026-07-15 | Fix ProPerks Title in Dev | Side project | Low | — | Keep: BR list |
| 2026-07-15 | Check "validate orders" BR (ref 20251215) | Request | Low | May overlap `kb_Order_Validator_v2` (Active) — verify before starting | Keep: BR list |
| 2026-07-15 | Test Visual Rule — on hold / long-term | Side project | Low | See `project_p21_visual_rules_guide.md` | Keep: 3 Goals |
| 2026-07-15 | Cleanup BR documentation in general | Side project | Low | Overlaps Goal 2 (BR docs, due 2026-10-30) | Keep: BR list |
| 2026-07-15 | Use API to create/update P21 users | Side project | Med | Adjacent to Active "P21 Play API — create orders" (that one is orders, this is users) | Keep: Long Term Goals |
| 2026-07-15 | Update "Add & Remove P21 Users" script to copy messages to clipboard | Side project | Low | PowerShell enhancement | Keep: Long Term Goals |
| 2026-07-15 | Write script to monitor files added to the old file server | Side project | Low | PowerShell | Keep: Long Term Goals |
| 2026-07-15 | Extract data from the parameters column of the execution log/plan | Side project | Low | Investigation | Keep: Long Term Goals |
| 2026-07-15 | Pass SQL SP parameters from VBA (currently not working) | Side project | Low | Investigation | Keep: Long Term Goals |
| 2026-07-15 | `Get-CallerLineNumber` → output to file | Side project | Low | PowerShell | Keep: Long Term Goals |
| 2026-07-15 | Understand "Sale Reps factor of 2" | Nice-to-have | Low | Likely the split-commission ×2 row-doubling (`primary_salesrep`) — see `feedback_p21_split_commission_dedup` | Keep: Long Term Goals |
| 2026-07-15 | Understand EDI 832 (how it works) | Nice-to-have | Low | Learning | Keep: Long Term Goals |
| 2026-07-15 | Improve Power Query skills | Nice-to-have | Low | Learning | Keep: Long Term Goals |
| 2026-07-15 | Focused time on API/Postman (learning) | Nice-to-have | Low | Skill-building companion to the API work above | Keep: Long Term Goals |

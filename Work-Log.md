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
| 2026-07-15 | P21 Play API — create orders | 🔵 In progress | Postman auth to Play working; only a GET read exists. Next: hit `/uiserver0/ui/interactive/v1` docs to learn if orders POST-create or must drive UI-server window endpoints | `project_2026_07_15_p21_play_api_orders.md` |
| 2026-07-14 | Low Margin Alert (Evan) | 🟡 Awaiting sign-off | Built + tested in Play (2 alerts, split by audience). Prod blocked on Evan's sign-off, the "Ship Location" question, and Pam Dundas / Alex Boeve addresses | `project_2026_07_13_low_margin_alert.md` |
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

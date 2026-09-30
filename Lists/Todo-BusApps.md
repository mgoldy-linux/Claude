# To-Do — Business Apps

*(Blocked / date-gated items moved to `Waiting-On-Info.md` in the repo's `Lists/` folder. Personal/non-BusApps items live in `Todo-Private.md`.)*

2. Ensure BRs, portals & Crystal are equal between environments
   - Also check **deleted P21 users** across environments — other people are deleting users (`users.delete_flag='Y'`), so the set is drifting between envs. Diff who's deleted where and reconcile.
3. Create Customer Price List — management wants: enter a customer ID, generate a price list for that customer based on their discounts & contracts. Session note: exists as SSRS v2.2, clears 6 `kb_` — decide with Mark/Jossy whether to reuse v2.2 or rebuild
4. Clean up test orders (cancel) / finish testing the cancel-order stored procs — `Sql-Scripts\asi_cancel_order.sql` and `asi_cancel_open_orders_by_user.sql` already built 8/31 (uncommitted, never run/verified). Phase 5 (`lost_sales_transaction`) is written and **redeployed in Play but never run**. Cancel a throwaway multi-line order and diff its rows against the client-cancelled 6062441 (expect N line rows + 1 trailer, `transaction_code_no` 2143). Also decide the two defaults: `@write_lost_sales`, and `@lost_sales_uid` (16 Other vs 31 Doesn't Need, far more common in real data). `Cancel_Order_SP_Guide.docx` + `Cancel-Order-Trace.csv` are the supporting profiler trace/docs.
5. Use API to cancel orders — same 8/31 starting point as #4, but not yet proven through the API path specifically (existing procs are SQL, called directly)
6. Delete Users — need to also check sales rep & portals too (beyond the Delete User V2 stored-procedure check already done on lower environments)
7. AHI-API1 IIS cleanup — Outlook draft to Aziz ready (Drafts, screenshot attached) recommending removal of **P21Production**, **P21Upgrade**, **P21Play2** SOA sites (all dead on that box). **Next:** send it; open a SysAid ticket if Aziz wants one; remove sites + app pools once he confirms.
8. For Chad — create BR flow path for OE
9. For Chad — ensure Purpose, Roles and Logic are up to date on [Order Entry Improvement – Design Changes.docx](https://alltileccs.sharepoint.com/sites/ITTeam/Shared%20Documents/Business%20Applications/Platforms/Order%20Entry%20Improvement%20Project/Order%20Entry%20Improvement%20-%20Design%20Changes.docx?web=1)
10. ⏳ due Mon 10/5 — find the source of all OE popups (per popup: Business Rule, P21 setting, or DynaChange)
12. Order Ack subject email (SA 54321) — exclude ShagTools from the PO/Job Number stamping
13. Create a design doc for the Order Ack subject email (SA 54321) — requirement: if the rep already typed a subject line, don't append PO & Job Number
14. Send email to Tina about poorly written Job Numbers
15. Investigate pulling contract/job pricing info into the Low Margin Alert when Price Page Description shows "(no price page)" — Evan Jenkins ask (order 6163019, Tim's Construction Group). P21's Job/Contract Pricing (`job_price_hdr`/`job_price_line`) is a separate mechanism from Price Pages the alert doesn't look at today; measured 16% of "(no price page)" lines (35,986/228,898 over 120d) actually have an active contract price behind them.
16. Edit why each business rule exists — the "reason it exists" description must be written in human/business terms, not technical/code jargon.
17. Find which roles have access to Schedule Task Manager
18. Find who has access to PO Receipts
19. Could a DynaChange prevent cancel on PO Receipts?
20. Find who has access to cancel PO Receipts
21. Expired-quote deletion — pull a count of how many quotes would be deleted (by year, 2016–2025 full year + 2026 past the screen's default expiration cutoff), before running the native P21 deletion screen — 🟡 waiting on Matt (menu path / P21Dev availability) — see `project_2026_09_20_expired_quote_deletion.md`
22. SA 55209 — 🔵 in progress: ship_to (173) + 7 open orders + ~13 live quotes confirmed for Prepaid → Out Freight; Play pre-check done (180 rows), UPDATE + client-save test not yet run in any environment — see `project_2026_09_23_sa55209_freight_codes.md`
23. APC business rule documentation — Atlas Surcharge Rule dedicated pass, 5 of 7 `apc_*` objects still need one-pagers built (`apc_fe_conv_limit_class_surcharge`, `apc_fe_val_update_surcharge_price`, `apc_od_apply_surcharge_fc`, `apc_od_apply_surcharge_shipping`, `apc_os_conv_validate_surcharge_shipping`). Real source found for all 5 (no reverse-engineering needed) — `.cs`/`.sql` in `C:\Business_Rules`, plus `P21_BR01 REQ Surcharge Business Rule v1.5.docx` for the "Why It Exists" business rationale. Same template as the other one-pagers.
24. Discuss the DC purchase/transfer email (sent over the weekend) with Jossy in the 9/30 1:1 — see `project_2026_09_27_dc_porg_trg_feasibility.md`

---

## Done

- ~~Ensure all Business Apps team members have access to P21 Play, BRR, Training & Dev~~ — 9/30. Play/Dev/Training clean. Only BRR had gaps: Chad + Efrain `delete_flag='Y'`, and Chad/Efrain/Matt/Tina missing company 1. Scripts in `Sql-Scripts\Users\` (`Check-BusApps-Team-*.sql`, `Undelete-BusApps-Team-BRR.sql`, `Fix-BusApps-Team-Company-Access-BRR.sql`), committed a02fd76; BRR fixes not yet run there and a Prod refresh would overwrite them.
- ~~Call Epicor about the Directs Auto-Buy case again — CS0005626127 (SysAid 53769)~~ — 9/30. Root cause trace-confirmed 9/24 (`default_to_order` never captured); see `project_2026_08_21_directs_auto_buy_scheduler.md`
- ~~Ensure all salesreps have a valid email — clean up deleted salesreps~~ — 9/24
- ~~Missing UPC/EAN report, v2~~ — 9/22
- ~~Surfacing/Closeout/E&O — Closeout/E&O exclusion applied to all four alerts~~ — 9/22
- ~~Reply to "FW: Low PAD Margin - Order# 6143117 for Arlun Floor Covering Denver"~~ — 9/22
- ~~Create sales order deletion test cases~~ — 9/22 (full matrix run, Matt's summary + follow-up sent/answered — see `project_2026_09_21_order_deletion_criteria_test_cases.md`)
- ~~Explain cancelled vs. deleted order in P21~~ — 9/22 (KB0022345 cancel-vs-delete mechanics confirmed, owed to Matt)
- ~~Monday's Meeting (9/21) — WWMS: should users be using it?~~ — 9/22
- ~~Answer Chad's questions (yellow highlight) on Order Entry Improvement – Design Changes.docx~~ — 9/8
- ~~Add SSRS email check to the PowerShell launch menu~~ — 9/10
- ~~Complete corporate training~~ — 9/2

- ~~Send a list of items where the EAN or UPC is missing~~ — 9/2. Requester's "by location" framing was a misconception — UPC/EAN are per **supplier** (`inventory_supplier.upc_code`/`.ean_code`). Query at `Sql-Scripts\Inventory\Items-Missing-Supplier-UPC-EAN.sql`; ~99% of active item-supplier rows are missing one or both. Query + numbers delivered; user runs/sends the extract.
- ~~Add Order Ack business rules to P21 Business Rules~~ — 8/31
- ~~Finish business rules picture documentation~~ — 8/31
- ~~Modify stored procedure "Delete User V2" — check lower environments~~ — 8/31
- ~~Fill out P21UWWG survey~~ — 8/31
- ~~Create a script to check SSRS emails sent~~ — 8/31 (`Check-SSRS-Subscription-Sends.ps1` deployed, live in both profiles)
- ~~Verify the two re-owned SSRS subscriptions ran clean~~ — 8/31. Were owned by departed `AHI\kbenish`; owner changed to `AHI\ssrssvc` on 8/28 ("Changes to Orders by Sales Reps" `days_to_check=3` dupe to JMartin; "P21 Users' Last Login Dates" → ITSupport@allsurfaces.com). kbenish's other 2 owned subs already Disabled; her ~335 created catalog items are audit stamps only.
- ~~Create a test order through the API~~ — 8/31. Order 6109022 created via API after the APTCA fix (v1.0.2.0). Broader API-orders work is still open in its own session (`project_2026_07_15_p21_play_api_orders.md`) — surcharge shortcut, seed batch, and rolling to other environments remain.
- ~~`inv_loc` bulk update for Training/Prod~~ — 9/17. Batch UPDATE (`Sql-Scripts\Inventory\Batch-Update-inv_loc-Replenishment.sql`) run clean on P21Training 9/13 (361 batches, 3,597,160 rows, ~27.5 min, verify-zero-remaining passed). Rollback backup `zz_inv_loc_bkp_20260913`. Prod run is a separate, still-gated step (Purchasing sign-off required) — see `project_2026_09_11_inv_loc_replenishment_batch_update.md` for the Prod pre-flight checklist if/when that's picked back up.

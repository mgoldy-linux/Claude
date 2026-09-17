# To-Do — Business Apps

*(Blocked / date-gated items moved to `Waiting-On-Info.md` in the repo's `Lists/` folder. Personal/non-BusApps items live in `Todo-Private.md`.)*

1. Ensure BRs, portals & Crystal are equal between environments
   - Also check **deleted P21 users** across environments — other people are deleting users (`users.delete_flag='Y'`), so the set is drifting between envs. Diff who's deleted where and reconcile.
2. Create Customer Price List — management wants: enter a customer ID, generate a price list for that customer based on their discounts & contracts. Session note: exists as SSRS v2.2, clears 6 `kb_` — decide with Mark/Jossy whether to reuse v2.2 or rebuild
3. Clean up test orders (cancel) / finish testing the cancel-order stored procs — `Sql-Scripts\asi_cancel_order.sql` and `asi_cancel_open_orders_by_user.sql` already built 8/31 (uncommitted, never run/verified). Phase 5 (`lost_sales_transaction`) is written and **redeployed in Play but never run**. Cancel a throwaway multi-line order and diff its rows against the client-cancelled 6062441 (expect N line rows + 1 trailer, `transaction_code_no` 2143). Also decide the two defaults: `@write_lost_sales`, and `@lost_sales_uid` (16 Other vs 31 Doesn't Need, far more common in real data). `Cancel_Order_SP_Guide.docx` + `Cancel-Order-Trace.csv` are the supporting profiler trace/docs.
4. Use API to cancel orders — same 8/31 starting point as #3, but not yet proven through the API path specifically (existing procs are SQL, called directly)
5. Delete Users — need to also check sales rep & portals too (beyond the Delete User V2 stored-procedure check already done on lower environments)
6. AHI-API1 IIS cleanup — Outlook draft to Aziz ready (Drafts, screenshot attached) recommending removal of **P21Production**, **P21Upgrade**, **P21Play2** SOA sites (all dead on that box). **Next:** send it; open a SysAid ticket if Aziz wants one; remove sites + app pools once he confirms.
7. For Chad — create BR flow path for OE
8. For Chad — ensure Purpose, Roles and Logic are up to date on [Order Entry Improvement – Design Changes.docx](https://alltileccs.sharepoint.com/sites/ITTeam/Shared%20Documents/Business%20Applications/Platforms/Order%20Entry%20Improvement%20Project/Order%20Entry%20Improvement%20-%20Design%20Changes.docx?web=1)
9. ⏳ before 9/14 — find the source of all OE popups (per popup: Business Rule, P21 setting, or DynaChange)
10. Missing UPC/EAN report, v2 — stockable items only, primary supplier only, broken down by count missing **per location**. Follow-up to the 9/2 delivery (`Sql-Scripts\Inventory\Items-Missing-Supplier-UPC-EAN.sql`), where "by location" was flagged as a misconception since UPC/EAN lives on `inventory_supplier` per supplier, not per location — so this needs a real location join (e.g. `inventory_supplier_x_loc`) filtered to primary supplier + stockable. If running it for all locations is slow, do location 221 first.
11. Surfacing/Closeout/E&O — Closeout/E&O exclusion should apply to all four alerts
12. Reply to "FW: Low PAD Margin - Order# 6143117 for Arlun Floor Covering Denver - Total: $6448.99"
13. Create sales order deletion test cases — testing P21's native order deletion criteria (separate from the custom cancel-order SPs in #3). Before & after captures, record timing per test, perform in the P21 web client, letter each test case (A, B, C, ...).
14. Explain the difference between a cancelled order and a deleted order in P21 — is it possible to bring a deleted order back up (recover/undelete) in P21?
15. Ensure all salesreps have a valid email — clean up deleted salesreps

---

## Done

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

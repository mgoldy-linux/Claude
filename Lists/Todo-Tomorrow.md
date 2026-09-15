# To-Do — Friday 9/11

*(Blocked / date-gated items moved to `Waiting-On-Info.md` in the repo's `Lists/` folder.)*

*(This is now the single combined to-do list — merged from this file and the repo's `Lists/Todo.md`, which was drifting out of sync. `Lists/Todo.md` now just points here.)*

1. Learn how to create a HAR
2. Ensure BRs, portals & Crystal are equal between environments
   - Also check **deleted P21 users** across environments — other people are deleting users (`users.delete_flag='Y'`), so the set is drifting between envs. Diff who's deleted where and reconcile.
3. General review of the PowerShell launch menu
4. Create Customer Price List — management wants: enter a customer ID, generate a price list for that customer based on their discounts & contracts. Session note: exists as SSRS v2.2, clears 6 `kb_` — decide with Mark/Jossy whether to reuse v2.2 or rebuild
5. Clean up test orders (cancel) / finish testing the cancel-order stored procs — `Sql-Scripts\asi_cancel_order.sql` and `asi_cancel_open_orders_by_user.sql` already built 8/31 (uncommitted, never run/verified). Phase 5 (`lost_sales_transaction`) is written and **redeployed in Play but never run**. Cancel a throwaway multi-line order and diff its rows against the client-cancelled 6062441 (expect N line rows + 1 trailer, `transaction_code_no` 2143). Also decide the two defaults: `@write_lost_sales`, and `@lost_sales_uid` (16 Other vs 31 Doesn't Need, far more common in real data). `Cancel_Order_SP_Guide.docx` + `Cancel-Order-Trace.csv` are the supporting profiler trace/docs.
6. Use API to cancel orders — same 8/31 starting point as #5, but not yet proven through the API path specifically (existing procs are SQL, called directly)
7. Delete Users — need to also check sales rep & portals too (beyond the Delete User V2 stored-procedure check already done on lower environments)
8. AHI-API1 IIS cleanup — Outlook draft to Aziz ready (Drafts, screenshot attached) recommending removal of **P21Production**, **P21Upgrade**, **P21Play2** SOA sites (all dead on that box). **Next:** send it; open a SysAid ticket if Aziz wants one; remove sites + app pools once he confirms.
9. For Chad — create BR flow path for OE
10. For Chad — ensure Purpose, Roles and Logic are up to date on [Order Entry Improvement – Design Changes.docx](https://alltileccs.sharepoint.com/sites/ITTeam/Shared%20Documents/Business%20Applications/Platforms/Order%20Entry%20Improvement%20Project/Order%20Entry%20Improvement%20-%20Design%20Changes.docx?web=1)
11. ⏳ before 9/14 — find the source of all OE popups (per popup: Business Rule, P21 setting, or DynaChange)
12. `inv_loc` bulk update for Training/Prod — `replenishment_method`→'Up To', `inv_min`→0, `safety_stock_type`→0 (ABC Class). 9/11: impact counts done (3,903,896 of 4,945,731 P21Dev rows change), batching approved (10,000/batch, ~391 batches, Teams sign-off), `sa` login bug on Imports/Exports System Settings found + fixed by Tony across all 4 lower envs. **Next: run `Sql-Scripts\Inventory\Batch-Update-inv_loc-Replenishment.sql` against P21Training.** See `project_2026_09_11_inv_loc_replenishment_batch_update.md`.
13. Test `New-WeeklyStatusReport.ps1` (`C:\Users\mgoldyn\Documents\Status Reports\`) for real — built 9/11 to auto-generate the weekly "IT Individual Status" report from the template (stamps Completed by/Time Period, seeds Accomplishments from `Work-Log.md`'s Completed section). Only dry-run tested so far against a scratch copy; run it for the 9/23 report (period 9/16–9/22) once that period has passed and confirm the real output opens clean in Word.
14. Missing UPC/EAN report, v2 — stockable items only, primary supplier only, broken down by count missing **per location**. Follow-up to the 9/2 delivery (`Sql-Scripts\Inventory\Items-Missing-Supplier-UPC-EAN.sql`), where "by location" was flagged as a misconception since UPC/EAN lives on `inventory_supplier` per supplier, not per location — so this needs a real location join (e.g. `inventory_supplier_x_loc`) filtered to primary supplier + stockable. If running it for all locations is slow, do location 221 first.

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

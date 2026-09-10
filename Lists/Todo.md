# To-Do — Monday 9/8

*(Blocked / date-gated items moved to `Waiting-On-Info.md`.)*

1. Learn how to create a HAR
2. Ensure BRs, portals & Crystal are equal between environments
   - Also check **deleted P21 users** across environments — other people are deleting users (`users.delete_flag='Y'`), so the set is drifting between envs. Diff who's deleted where and reconcile.
3. Create a test order through the API
4. AHI-API1 IIS cleanup — Outlook draft to Aziz ready (Drafts, screenshot attached) recommending removal of **P21Production**, **P21Upgrade**, **P21Play2** SOA sites (all dead on that box). **Next:** send it; open a SysAid ticket if Aziz wants one; remove sites + app pools once he confirms.
5. For Chad — create BR flow path for OE
6. For Chad — ensure Purpose, Roles and Logic are up to date on [Order Entry Improvement – Design Changes.docx](https://alltileccs.sharepoint.com/sites/ITTeam/Shared%20Documents/Business%20Applications/Platforms/Order%20Entry%20Improvement%20Project/Order%20Entry%20Improvement%20-%20Design%20Changes.docx?web=1)
7. ⏳ before 9/14 — find the source of all OE popups (per popup: Business Rule, P21 setting, or DynaChange)
8. Finish testing the cancel-orders stored procs — Phase 5 (`lost_sales_transaction`) is written and **redeployed in Play but never run**. Cancel a throwaway multi-line order and diff its rows against the client-cancelled 6062441 (expect N line rows + 1 trailer, `transaction_code_no` 2143). Also decide the two defaults: `@write_lost_sales`, and `@lost_sales_uid` (16 Other vs 31 Doesn t Need, far more common in real data).
9. For Jossy — update P21 **Training**: `replenishment_method`, ABC (anc) class, and minimum inventory = 0. See Teams message. (Groundwork done 9/9: `SELECT replenishment_method, COUNT(*) FROM inv_loc WHERE delete_flag = 'N' GROUP BY replenishment_method` — column is `varchar`, not a numeric code; the "Invalid column name" squiggle was stale SSMS IntelliSense.)

---

## Done

- ~~Finish business rules picture documentation~~ — 9/10
- ~~Add SSRS email check to the PowerShell launch menu~~ — 9/10
- ~~Add Order Ack business rules to P21 Business Rules~~ — 9/8
- ~~Answer Chad's questions (yellow highlight) on Order Entry Improvement – Design Changes.docx~~ — 9/8
- ~~Modify stored procedure "Delete User V2" — check lower environments~~ — 9/3
- ~~Complete corporate training~~ — 9/3

- ~~Fill out P21UWWG survey~~ — 8/31
- ~~Create a script to check SSRS emails sent~~ — 8/31 (`Check-SSRS-Subscription-Sends.ps1` deployed, live in both profiles)
- ~~Verify the two re-owned SSRS subscriptions ran clean~~ — 8/31. Were owned by departed `AHI\kbenish`; owner changed to `AHI\ssrssvc` on 8/28 ("Changes to Orders by Sales Reps" `days_to_check=3` dupe to JMartin; "P21 Users' Last Login Dates" → ITSupport@allsurfaces.com). kbenish's other 2 owned subs already Disabled; her ~335 created catalog items are audit stamps only.

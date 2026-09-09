# To-Do — Monday 9/8

*(Blocked / date-gated items moved to `Waiting-On-Info.md`.)*

1. Finish business rules picture documentation
2. Learn how to create a HAR
3. Ensure BRs, portals & Crystal are equal between environments
4. Create a test order through the API
5. Add SSRS email check to the PowerShell launch menu
6. Ask Aziz about the IIS on AHI-API1 — remove middleware extra pools
7. For Chad — create BR flow path for OE
8. For Chad — ensure Purpose, Roles and Logic are up to date on [Order Entry Improvement – Design Changes.docx](https://alltileccs.sharepoint.com/sites/ITTeam/Shared%20Documents/Business%20Applications/Platforms/Order%20Entry%20Improvement%20Project/Order%20Entry%20Improvement%20-%20Design%20Changes.docx?web=1)
9. ⏳ before 9/14 — find the source of all OE popups (per popup: Business Rule, P21 setting, or DynaChange)
10. Low Margin alerts — is it possible to show whether the price was edited? — **answered: yes, and free.** `<price_edit>` renders `Y`/`N` with no view change; live in the Play Team alert. Reply drafted to Evan (out to **9/14**) asking wording + placement. Blocked on his answer.
11. Finish testing the cancel-orders stored procs — Phase 5 (`lost_sales_transaction`) is written and **redeployed in Play but never run**. Cancel a throwaway multi-line order and diff its rows against the client-cancelled 6062441 (expect N line rows + 1 trailer, `transaction_code_no` 2143). Also decide the two defaults: `@write_lost_sales`, and `@lost_sales_uid` (16 Other vs 31 Doesn t Need, far more common in real data).

---

## Done

- ~~Add Order Ack business rules to P21 Business Rules~~ — 9/8
- ~~Answer Chad's questions (yellow highlight) on Order Entry Improvement – Design Changes.docx~~ — 9/8
- ~~Modify stored procedure "Delete User V2" — check lower environments~~ — 9/3
- ~~Complete corporate training~~ — 9/3

- ~~Fill out P21UWWG survey~~ — 8/31
- ~~Create a script to check SSRS emails sent~~ — 8/31 (`Check-SSRS-Subscription-Sends.ps1` deployed, live in both profiles)
- ~~Verify the two re-owned SSRS subscriptions ran clean~~ — 8/31. Were owned by departed `AHI\kbenish`; owner changed to `AHI\ssrssvc` on 8/28 ("Changes to Orders by Sales Reps" `days_to_check=3` dupe to JMartin; "P21 Users' Last Login Dates" → ITSupport@allsurfaces.com). kbenish's other 2 owned subs already Disabled; her ~335 created catalog items are audit stamps only.

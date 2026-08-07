# Deployment Guide — BusinessRulesDLL Share Cleanup (business_rule_log Initialize noise)

> Produced during rollout. In progress, paused 2026-08-05 to work SA-51376. Update as remaining environments are done; commit with the code.

## Artifact(s)
- `C:\Claude\PowerShell-Scripts\Archive-BusinessRulesDLL-Duplicates.ps1` — moves confirmed stale/dead rule DLLs out of a P21 environment's live `BusinessRulesDLL` share into a new `_Archive` subfolder (never deletes)
- `C:\Claude\Sql-Scripts\Delete-BusinessRule-By-Name.sql` — deletes a single `business_rule` row (and dependents) by name
- `C:\Claude\Sql-Scripts\Delete-BusinessRules-Batch.sql` — deletes a batch of `business_rule` rows (and dependents) by `business_rule_uid`
- Ticket: none (internal cleanup, found via `business_rule_log` noise analysis 2026-08-04/05)

## Background
`business_rule_log` analysis (45-day window, then all-time) showed 99.99%+ of the table's volume is client-startup `Initialize` noise from `P21.Extensions.BusinessRule.RuleManager` scanning every DLL in the live `BusinessRulesDLL` share on every login — not real business-rule execution. All-time: 8,728,346 `Initialize` rows vs. 139 `Invoke` + 139 `Return` + 51 `Update` combined, across 10 years.

Two DLL-level root causes identified:
1. **"An item with the same key has already been added"** — stale 2016/2019 dev-iteration DLLs left in the live share, colliding with whatever file wins the RuleManager's class-name dictionary registration.
2. **`P21.Accounting.MX.dll` CAS/inheritance-security load failures** — unused vendor module (Mexico e-invoicing), resolved by archiving (see below).

Each P21 environment (Dev, Play, Training, BusinessRules, Upgrade, Prod) has its **own independent copy** of `\\ASP21FS1.ahi.local\{Instance}\BusinessRulesDLL\`, each carrying the identical cruft — confirmed by checking each environment's own `business_rule_log`.

A second, related problem surfaced while investigating: the P21 client's "Rules" maintenance screen listed many `kb_`-prefixed `business_rule` config rows that are dead in the same way the DLLs were — see the **Dead business_rule config rows** section below.

## Target environments — DLL archive
All 6, one at a time, lower environments first:
- ✅ **BusinessRules** — done 2026-08-04/05 (24 files) + a 2nd pass 2026-08-07 (13 more files,
  evidence-based via `Get-BusinessRuleDllStatus.ps1` + source-code review — see below)
- ✅ Dev — done 2026-08-05, all 24 files
- ✅ Play — done 2026-08-05, all 24 files
- ✅ Training — done 2026-08-05, all 24 files
- ✅ Upgrade — done 2026-08-05, all 24 files
- 🔵 **Prod (last) — started 2026-08-07.** 9 files archived so far: `P21.Accounting.MX.dll`
  (re-verified zero rows in live `sat_invoice_auxfoliorep_mx`/`sat_payment_transfer_mx` on Prod
  itself, not just carried over from lower envs) + the 8-file `kb_Order_SaleDay*`/`kb_Order_Sale_*`
  family (6 confirmed via rule-name match, 2 orphans re-confirmed zero `business_rule` rows on
  Prod). The original 24-file dev-iteration batch (`DirectShipPriceCheck*`, `OrderEntry_SalesRepAddition*`)
  has **not** been run against Prod yet — full audit via `Get-BusinessRuleDllStatus.ps1 -Instance Prod`
  is in `C:\_P25\Data-Out\CSV\Get-BusinessRuleDllStatus.ps1-20260807-Prod.csv`.

## ⚠ Incident — kb_Shipping_IBFSurcharge.dll archived in error (2026-08-07, caught same day)
Archived on `BusinessRules` at 12:23 PM based only on matching `kb_Shipping_IBFSurcharge_Add`/
`_Update` (both Inactive) — the two names it was originally guessed against. A later full-rule-list
scan on **Prod** showed the same file also embeds `kb_RMA_IBFSurcharge_Add`, which is **Active**
(RMA Entry, On-Demand surcharge) on both environments. Re-checked the archived BusinessRules copy
directly and confirmed the same string is present. **Restored to the live BusinessRules folder the
same day** (~2.5 hours later); `business_rule_log` showed zero activity for RMA surcharge during
the gap, so no real-world impact. `kb_Shipping_IBFSurcharge.dll` removed from
`Archive-BusinessRulesDLL-Duplicates.ps1`'s file list for good — **lesson: a file matching
multiple rule names needs every match checked against `has_active`, not just the ones you went
looking for.** Same root cause as `kb_Order_Validator_v2.dll` legitimately bundling 4 rule names —
bundling itself isn't rare here, assuming single-rule-per-file is what caused this miss.

## Target environments — dead business_rule row deletion
- ✅ **BusinessRules** — done 2026-08-05, 15 rows deleted manually via P21 client (traced), verified gone
- ⬜ Dev, Play, Training, Upgrade — **not yet run.** `Delete-BusinessRules-Batch.sql` is ready; user confirmed no adverse effects from the DLL archive alone first, was about to greenlight this when the session paused
- ⬜ Prod — not started

## Dependencies & deploy order
- DLL archive and `business_rule` row deletion are independent of each other technically, but this rollout deliberately did DLL-archive-first-then-verify-then-delete-the-config-row per the user's explicit request (verify the file move alone causes no adverse effects before doing the harder-to-reverse config deletion).
- No cross-environment ordering requirement; doing lower/test environments before Prod per standard practice here.

## Backward-compatibility notes
- Confirmed via `business_rule` table (all 6 environments) before archiving DLLs or deleting rows:
  - `OrderLineSalesRepAddition_LIVE` (uid 44) = `row_status_flag 705` (Inactive), `date_last_modified` 2/19/2022 — identical in all 6 environments.
  - `DirectShipPriceCheck` has **zero rows** in `business_rule` in any of the 6 environments — never wired to any window/rule config anywhere.
  - The 14 `kb_Order_SaleDay*`/`kb_Order_Sale_*` rows all confirmed `row_status_flag 705` (Inactive) — dated seasonal/promotional rules (2020–2024), consistent naming pattern.
- DLL files are **moved, not deleted**, to a `_Archive` subfolder inside the same share — fully reversible.
- `business_rule` row deletion is a **hard delete**, not reversible via the P21 UI (would need a restore from backup) — this is why the user asked to verify the DLL-only change first before running the SQL delete on the remaining 4 environments.

## Deploy steps — DLL archive
1. Preview first: `& 'C:\Claude\PowerShell-Scripts\Archive-BusinessRulesDLL-Duplicates.ps1' -Instance <Dev|Play|Training|BusinessRules|Upgrade|Prod> -WhatIf`
2. Confirm the preview only targets the known files (list is hardcoded in the script — see comments).
3. Re-run without `-WhatIf` to execute.

## Files archived (24 total, per environment)
- `DirectShipPriceCheck_0801_0800.dll`, `_0801_0805.dll`, `_0801_0848.dll`, `_0802_1003AM.dll`, `_0802_1005.dll`, `_1028.dll`, `_1040.dll`, `_1102.dll`, `_1122.dll`, `_1136.dll`, `_1139.dll`, `_1249.dll`, `_204.dll`, `_729_120PM.dll`, `_801_729.dll` (all 15)
- `OrderEntry_SalesRepAddition_update.dll`, `OrderEntry_SalesRepAddition_live.dll`, `OrderEntry_SalesRepAddition.dll` (all 3)
- `P21.Accounting.MX.dll` (1)
- `kb_Order_SaleDay_202005.dll`, `kb_Order_Sale_202006.dll`, `kb_Order_SaleDay_202009_InsApp.dll`, `kb_Order_SaleDay_202305.dll`, `kb_Order_SaleDay_202405.dll` (5)

**Not archived — 3 orphaned files, decision pending:** `kb_Order_SaleDay_201906.dll`, `kb_Order_SaleDay_202205.dll`, `kb_Order_SaleDay.dll` (generic, no year). Confirmed via query on untouched `P21Dev` that **no `business_rule` row has ever existed** for these — same "orphaned, safe" pattern as `DirectShipPriceCheck` — but they weren't part of the batch the user actually deleted from `business_rule`, so held back pending an explicit decision to treat them the same way.

**Explicitly left alone (active/unrelated, do not touch):** `kb_Order_RequiredDate*.dll` (tied to open SA-46321 work), `kb_Order_Validator*.dll` (separate in-progress `kb_Order_Validator_v2` project), `kb_Order_WelcomeBack_202006.dll` (still Inactive in P21 but its rule was never deleted).

## Verification — DLL archive
1. Before having anyone log in, capture the current max `business_rule_log_uid` where `log_action = 'Initialize'` as a baseline.
2. Have a user log out/back into the P21 client for that environment (forces a fresh `Initialize` scan).
3. Query rows with `business_rule_log_uid` greater than the baseline: expect **0 rows** matching `return_message LIKE '%same key%'` and none for `P21.Accounting.MX.dll`.
4. **BusinessRules result:** confirmed **zero** `business_rule_log` rows of any kind on the login after archiving all 24 files — both root causes fully resolved.

## Rollback — DLL archive
- Move the files back from `\\ASP21FS1.ahi.local\{Instance}\BusinessRulesDLL\_Archive\` to the parent `BusinessRulesDLL` folder for the affected environment.

## Dead business_rule config rows

While confirming no live wiring for `DirectShipPriceCheck`/`OrderEntry_SalesRepAddition`, the P21 client's "Rules" maintenance screen surfaced a long list of `kb_`-prefixed rows, all `row_status_flag 705` (Inactive) — a family of dated `kb_Order_SaleDay_*`/`kb_Order_Sale_*` rules (2020–2024, one-off seasonal promotions) among them.

**Methodology — traced rather than guessed the deletion cascade.** Rather than assume which child tables need cleanup, ran a live Extended Events session (`rpc_completed`/`sql_batch_completed`, filtered to the target database) while the user manually deleted rules via the P21 client UI. Captured the exact cascade P21 itself performs:
1. `DELETE FROM business_rule_data_element WHERE business_rule_uid = @uid`
2. `DELETE FROM business_rule_x_roles WHERE business_rule_uid = @uid` (only fires if rows exist)
3. `DELETE FROM business_rule_x_users WHERE business_rule_uid = @uid`
4. `DELETE FROM business_rule WHERE business_rule_uid = @uid`

Cross-checked against `sys.foreign_keys` to confirm completeness — only those 3 tables reference `business_rule.business_rule_uid`, so the cascade is provably complete, not just what the traced examples happened to exercise (the trace never actually fired a `business_rule_x_roles` delete since none of the traced rules had role assignments).

**BusinessRules (2026-08-05):** user deleted 15 rows manually via the P21 client while the trace ran: uid 44 (`OrderLineSalesRepAddition_LIVE`) plus 14 `kb_Order_Sale*` rows (uids 109,110,113,114,116,117,122,123,124,129,130,131,132,146). Confirmed gone afterward via direct query. Matching DLL files (8 of the 15) archived — see Files archived above.

**Remaining 4 environments:** `Delete-BusinessRules-Batch.sql` targets the same 15 `business_rule_uid` values (confirmed identical across environments — verified rule names match on `P21Dev` before building the script). **Not yet run** — paused after the DLL archive step per the user's request to verify no adverse effects first; confirmed none, next action is to run the batch delete.

## Individual rule review — BusinessRules (in progress, 2026-08-07)

Shifted approach: rather than only archiving DLLs by name/content evidence, going through every
remaining Inactive `business_rule` row on **BusinessRules** one at a time in the P21 client's
"Edit Business Rule" screen, which shows a live-resolved **Assembly Name** column (`AssemblyName,
Version=..., Culture=..., PublicKeyToken=...`) for whatever currently loads for that row's
window/field/event context — the real ground truth, not a filename guess. Rows with a DLL already
archived in an earlier pass show blank here (confirmed on `kb_Order_WelcomeBack_202006` and
`kb_Customer_Closed_Workflow_r1`), same as a row with no file at all — blank is not an error.

Once Assembly Name is confirmed (or confirmed blank) for a row, delete it via the P21 client
("Rules" screen), same traced cascade as the original 15-row deletion: `business_rule_data_element`
→ `business_rule_x_roles` → `business_rule_x_users` → `business_rule`.

**Already deleted (before this checklist was built, presumably by user directly):**
- `kb_Customer_Closed_r1`
- `kb_Order_RequiredDate` (bare/predecessor row only — confirmed the **active** `kb_Order_RequiredDate_r3`, uid 126, is untouched, still `row_status_flag=704`, `last_maintained_by=mgoldyn` — SA-46321 unaffected)

**Remaining 17 Inactive rows to review:**

| uid | rule_name | Window / Field | Assembly Name | Status |
|---|---|---|---|---|
| 55 | kb_Order_Validator | Order Entry / oe_hdr_carrier_id | not checked | pending — PROTECTED family, confirm before deleting |
| 56 | kb_Order_Workflow | Order Entry / order_no | not checked | pending |
| 77 | OrderEntry_salesrep | Event: Order Updated | didn't open | pending |
| 79 | OrderEntry_salesrep | Event: Order Updated | not checked | pending |
| 78 | kb_ValidateOO_BlockSave | Validate Open Orders | not checked (DLL already archived) | pending |
| 80 | OrderEntry_salesrep_UPD_319_949 | Event: Order Updated | not checked | pending |
| 91 | kb_Shipping_IBFSurcharge_Add | Shipping | not checked (DLL already archived) | pending |
| 92 | kb_Shipping_IBFSurcharge_Update | Shipping | not checked (DLL already archived) | pending |
| 93 | kb_Shipping_IBFSurcharge_Update | Shipping | not checked (DLL already archived) | pending |
| 101 | kb_Shipping_IBFSurcharge_Update | Shipping | not checked (DLL already archived) | pending |
| 111 | kb_Order_WelcomeBack_202006 | Front Counter Order | **blank (confirmed)** | ready to delete |
| 112 | kb_Order_WelcomeBack_202006 | Order Entry | not checked (sibling of 111, DLL already archived) | pending |
| 43 | OrderEntryFund_LIVE_V3 | Order Entry | not checked (DLL already archived) | pending |
| 45 | RebatePriceTracker | Event: Order Updated | not checked (DLL already archived) | pending |
| 36 | rewardFormat | Order Entry | not checked (DLL already archived) | pending |
| 53 | RMA_RestockAdj_V3 | Front Counter Order | not checked | ⚠ has an ACTIVE sibling row elsewhere on the same rule_name — verify uid 53 specifically before deleting, do not touch the active one |
| 60 | kb_Customer_Closed_Workflow_r1 | Customer Maintenance | **blank (confirmed)** | ready to delete |

## Open items
- Run `Delete-BusinessRules-Batch.sql` against Dev/Play/Training/Upgrade, then Prod (DLL archive + row deletion both, last).
- Decide whether to archive the 3 orphaned `kb_Order_SaleDay` files (201906/202205/generic) the same way as the others.
- Broader `kb_` rule list from the P21 "Rules" screen has many more entries beyond the sale-day family (`kb_Customer_Closed_r1`, `kb_Customer_Closed_Workflow_r1`, `kb_Order_Workflow`, `kb_Shipping_IBFSurcharge_Add`/`_Update` ×3, etc., all Inactive) — candidate for a future dedicated diligence pass under the 2026 kb_/js_ retirement goal, not started.
- Two RuleManager assembly flavors observed side-by-side in the fleet — `P21.Extensions.BusinessRule.RuleManager` and the older `Activant.P21.Extensions.BusinessRule.RuleManager` — suggests inconsistent client build/version across users. Not yet investigated.

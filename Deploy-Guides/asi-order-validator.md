# Deployment Guide — asi_Order_Validator (replaces kb_Order_Validator_v2 + its SQL chain)

> Produced during development 2026-09-01. Phase 1 of the `asi_` rebuild tracked in
> `project_2026_06_23_kb_order_validator_v2.md`. Supersedes the interim CAS fix in
> `kb-order-validator-v2-cas-fix.md` (note that guide states `class_name =
> w_order_entry_sheet`; it is actually **`d_oe_header`** — verified 2026-09-01).

## ⚠ STATUS 2026-09-02 — ROLLED BACK. ROOT CAUSE FOUND. READ THIS BEFORE ANY REGISTRATION WORK.

`asi_Order_Validator` v1.0.0.0 (`_t1.dll`) was deployed to BRR active (704) on 9/1 and
**wrongly blocked order 6108922** with `[v2err#0] The FREIGHT CODE on this order is blank`
while the Ship Info tab showed `WILL CALL` and `oe_hdr.freight_code_uid = 8`. Rolled back the
same afternoon. Current BRR state: `kb_Order_Validator_v2` **704**, `asi_Order_Validator`
(`_t1` row) **705**.

### The cause was the REGISTRATION, not the code

P21 populates a rule's runtime DataSet with **only** the fields registered in
`business_rule_data_element`. A field that is missing or mis-registered is, at runtime,
**indistinguishable from one the user left blank** — the column simply is not present. The
rule was correctly reporting that `d_oe_header` had no `freight_code_uid`, because
**`freight_cd` had been registered instead of `freight_code_uid`**.

Four more of the rule's required fields were also unregistered:
`d_dw_oe_hdr_shipinfo.oe_hdr_carrier_id` (would have been the next false block), and all
three of `d_dw_oe_hdr_notepad_dataentry.topic` / `.mandatory` / `.delete_flag`. Those last
three are worse than a blocked save — they cause **silently wrong verdicts**: check 7
false-fires on every $15k order (signature note invisible) and check 6b cannot fire at all.

### BRR's `kb_Order_Validator_v2` registration is ALSO damaged

The `asi_` rule inherited its gaps because it was registered by copying BRR's `kb_` list —
which is itself broken:

| env | elements | DataWindows |
|---|---|---|
| PROD / Play / Dev | **114** | **11** |
| BRR | **74** | **3** |

Eight whole DataWindows are missing in BRR, including `d_front_counter` (19 fields) — which
is why the OLD rule NREs there with `More initializing, subsection 2`. (An earlier draft of
this guide blamed "a partial DataSet on that save"; that was right in effect, **wrong in
cause**. Every save through that rule in BRR is missing 8 DataWindows.)

**Proven by timestamps:** all 74 surviving BRR rows are `date_created 2026-09-01 14:22:46`,
`created_by MGOLDYN`. PROD and Play still hold all 114 at `2024-02-19 07:22:06`,
`created_by kbenish`. The list was not edited — it was **deleted and rewritten**, keeping
only the DataWindows the UI had loaded, at the timestamp of the **first** Rule Manager edit
that day (before any test).

> ### 🔴 Saving a rule in P21 Rule Manager replaces its ENTIRE registered field list.
> Anything the UI has not loaded is silently destroyed — no warning, no error.
> **This is a live Prod hazard.** The Prod cutover needs a `row_status_flag` flip, and doing
> that through Rule Manager could truncate the registration of the rule gating every order
> save in Prod. Flip it **by SQL** instead:
> ```sql
> UPDATE business_rule SET row_status_flag = 705, date_last_modified = GETDATE(),
>        last_maintained_by = SUSER_SNAME()
> WHERE  rule_name = 'kb_Order_Validator_v2';
> ```
> and snapshot `business_rule_data_element` before **and** after any registration work.
> Mechanism is strongly evidenced but **not yet formally proven** — run
> `Sql-Scripts\Business-Rules\Test-RuleManager-Element-Loss.sql` first.

Blast radius checked across all 135 BRR rules: only this rule shows a large recent loss, and
**`kb_Order_Workflow_v2` (same assembly) is untouched at 115/11** — so the damage is confined
to the rule actually opened and saved, not the assembly or the session.

### Code changes since the rollback (built, harness-verified 55/55, NOT deployed)

- Missing columns are now tracked separately from null values: an absent column logs loudly
  and **allows** the save; a present-but-null value still blocks. This turns a registration
  error into a diagnosable skip instead of a false accusation against the user.
- Numeric reads use `Convert.To*` rather than `Field<T>` (which throws on a DataWindow type
  mismatch and gets swallowed into a fail-open).
- Temporary field-inventory diagnostic dumps what `d_oe_header` actually carries.
- Renamed to **`_t2`** — class, namespace and assembly — so it cannot collide with the
  `_t1.dll` already on the share (two assemblies exporting the same `GetName()` is the
  "second copy being loaded" hazard). Engine moved to suffix-free namespace
  `asi_OrderValidator` so successive `_tN` iterations share one copy. **v1.0.1.0.**
>
> **This build is deliberately bug-for-bug equivalent to the old rule.** Known defects are
> marked `[PRESERVED-BUG]` in the source and are NOT fixed here — they are Phase 2, so the
> equivalence harness can attribute every diff. Do not "helpfully" fix one before the
> baseline diff is clean.

## Artifact(s)
- `asi_Order_Validator.dll` **v1.0.0.0** — synchronous, before-save order validator.
  Replaces **only** the `kb_Order_Validator_v2` rule.
- Source: `CSharp\asi_Order_Validator.cs` (repo copy) → build project under
  `C:\Business_Rules\Projects\asi_Order_Validator\`
- Test tooling: `Testing\kb_Order_Validator_v2\Capture-OldValidator-Baseline.sql`
- Driver: no custom stored procedures / functions / table types permitted going forward;
  the `kb_` retirement goal (`project_2026_goals.md`)

## What changed and why

All validation logic moved from `dbo.kb_fnt_br_order_validator_v2` (a 60-parameter
multi-statement TVF taking three table-valued parameters) into C#. Reference lookups are
now parameterized `SELECT`s over **native P21 objects only**, batched into one round trip.

**Nine `kb_` objects retired from this path:**

| Retired | Replaced by |
|---|---|
| `kb_fnt_br_order_validator_v2` | `Validate()` — 9 ordered checks |
| `kb_fnt_br_shipto_info` | `SqlFreightCharge` — `p21_view_ship_to` + `p21_view_freight_charge_break` |
| `kb_view_carrier` | `p21_view_address` + `address_ud`, `carrier_flag='Y'` |
| `kb_view_item_classifications_loc100` | `inv_mast` + `product_group` |
| `kb_fn_number_shorten` | `NumberShorten()` |
| `kb_table_required_date_statuses` | `RequiredDateStatuses` constants (4 rows) |
| `kb_TableTypeItemsOnOrder`, `kb_TableTypeFourStrings` | dropped — no TVPs |
| `kb_table_inbound_fuel_surcharge`, `kb_view_customer` | dropped — dead code paths only |

**Why it got so much smaller:** `@a_schg_on` was hardcoded `'Y'` in the TVF (the Atlas
surcharge cutover) and never reassigned, which made `@fuel_message` permanently `''` —
killing scenario 5 outright and roughly half the message-building text. Combined with the
commented-out scenarios 8–15, only **9 of 57 scalar parameters** and **3 of 37 TVP columns**
were ever read. The rule was marshalling 60 parameters to feed nine values.

**Performance:** `kb_fnt_br_shipto_info` opened with
`IF @shipto_id NOT IN (SELECT ship_to_id FROM p21_view_ship_to WHERE delete_flag='N')` — a
full scan of the ship-to view on every call purely to test existence. That is the
774-logical-reads-per-call / 21.6M-reads item ranked #1 in
`Docs\Recommended-P21-Performance-Fixes.md`. It is now two index seeks.

**New:** every blocked save is written to `business_rule_log` with
`log_action = 'Validation'` (vs `'Error'` for a broken rule), so the popup text is
queryable and diffable. This is additive and changes no verdict.

## Target environments
- **P21BusinessRules (BRR)** — first and only target for now. Middleware **AHI-API1**.
- **P21Play / P21Dev / P21Training / Prod** — not until the BRR baseline diff is clean.
  Note P21Play, P21Dev and P21Training still run the stale v1.0.1.0 `kb_` DLL with the
  APTCA/CAS bug; that is unrelated and tracked in the CAS guide.

## Dependencies & deploy order

**1. The old DLL must STAY in place.** `kb_Order_Validator_v2.dll` bundles *two* rules and
only the validator is ported. `kb_Order_Workflow_v2` (async after-save note writer, calls
`kb_proc_br_oe_hdr_note`) is untouched and still lives in that assembly. Removing the file
breaks it. The cutover is at the **`business_rule` row** level, not the file level.

**2. The two validators must never be active simultaneously** — both block saves, so the
user would get two popups and double validation. Deactivate one in the same change that
activates the other.

**3. `[assembly: SecurityRules(SecurityRuleSet.Level1)]` and NO `AllowPartiallyTrustedCallers`.**
This rule calls `Atlas.CrownSurcharge5011348` exactly as the old one did, so it inherits the
same CAS trap. Shipping APTCA forces every method `SecurityTransparent` under the .NET 4
Level 2 model and throws `MethodAccessException` on every surcharge order. Target **TFM
v4.7.2** to match the Atlas dependency. See `kb-order-validator-v2-cas-fix.md` for the
full diagnosis.

**4. Ownership chaining no longer covers the reads — check grants per environment.** The old
rule touched `inv_mast`, `product_group`, `p21_view_address`, `address_ud`, etc. *indirectly*,
inside a TVF, so ownership chaining applied the function owner's rights. The new rule queries
them **directly as the caller**. A missing `SELECT` surfaces as a swallowed rule error (both
rules log best-effort and never rethrow) — silence, not an obvious failure.

Run `Testing\kb_Order_Validator_v2\Check-Grants-asi-rules.sql` in the target database. It
covers both `asi_` rules (15 object/permission pairs) and emits ready-to-review `GRANT`
statements for anything missing.

Do **not** substitute `HAS_PERMS_BY_NAME` while connected as yourself — as `db_owner` it
returns 1 for everything and proves nothing. The script reads `sys.database_permissions`
directly, so the answer is independent of who runs it.

**BRR: PASSED 2026-09-01** — all 15 already granted to `p21_application_role`. Grants are
per-database, so re-run before any other environment.

**5. No DB objects are created or dropped by this deploy.** All nine `kb_` objects stay in
place — the baseline harness calls `kb_fnt_br_order_validator_v2` directly for ground truth.
Retiring them is a separate change after the diff is clean.

## Deploy steps (BRR)

1. ~~**Run STEP 0 of `Capture-OldValidator-Baseline.sql`**~~ — **DONE 2026-09-01 (BRR).**
   All five mappings resolved; results are recorded in the script's STEP 0 header so it need
   not be re-run except after an environment refresh.
   - **(a)** `oe_hdr` has **no `ship_to_id` column** — the ship-to is `address_id`. (The
     `d_oe_header` DataWindow exposes the same value *named* `ship_to_id`; that's a
     DataWindow alias, not a column. The C# is correct as written; only the harness needed
     the change.) Harness updated.
   - **(b)** `oe_line.complete` exists, `complete_flag` does not. Code was already correct.
   - **(c)** `inv_mast.product_type` exists. Already correct.
   - **(e)** `oe_hdr.order_type` is an `int` (e.g. 706); code group 1215 resolves it to a
     description (`'OE'`), and `'CUO Entry'` exists as code 1344. **Scenario 7's consignment
     exemption works as designed** — no plan change. Aside for the business: code 3056
     `Consigned Manufacturer Rep Order Entry` is also consignment but is *not* exempted.
   - **(d)** Resolved by direct UI observation, not SQL. `d_oe_hdr_credit.credit_status` is
     **plain `customer.credit_status`**, not `kb_view_customer`'s corporate rollup. Evidence:
     order 6108236 / customer 3025940 (child account, `corp_address_id 1020940 <> id`) —
     plain = COD, rollup = NORMAL, Order Entry Credit tab shows **COD**. Harness
     `@use_rollup` set to `'N'`.

     > **Live production finding, independent of this port.** The validator reads plain
     > credit status; `kb_proc_br_oe_hdr_note` reads the rollup. They disagree for **577
     > customers**. For a child account that is COD locally but NORMAL corporately, the
     > validator applies the COD freight rules (scenario 6a can force Will Advise) while the
     > note writer exits at its first gate and never creates the "Freight Quote Required"
     > note — which scenario 6b requires in order to prompt anyone to take the order back
     > *off* Will Advise. Both behaviors are preserved in the ports. Which source is correct
     > is a business decision for whoever owns the freight-quote workflow.

2. ~~**Run the grant check**~~ — **PASSED 2026-09-01 (BRR).** All 15 required permissions are
   already granted to `p21_application_role`; ownership chaining is a non-issue here and no
   `GRANT` is needed. Re-run `Testing\kb_Order_Validator_v2\Check-Grants-asi-rules.sql`
   against any *other* environment before deploying there — the result is per-database.

   Also confirmed by that script (Section 4): `dbo.p21_ecc_add_order_header_note` takes
   `@OrderNumber varchar(8)`, `@NoteTopic varchar(30)`, `@Note **text**`, created 2015-07-17
   and unmodified since 2015-09-03. `asi_Order_Workflow` binds those by name.

   Two incidental observations, neither blocking: a `kb_ViewReader` database role holds
   SELECT on 7 of these objects (another `kb_` artifact for the retirement inventory), and
   `AHI\ereyes` has a *direct user* grant on `customer` — the individual-grant pattern that
   left Prod exposed when kbenish departed. Worth a separate audit.

3. **Capture the OLD baseline** — harness **STEP 1 → 2 → 3**, in that order:
   - **STEP 1** creates `dbo.asi_validator_baseline` (test-only, dropped in STEP 5).
   - **STEP 2** builds `#corpus` — saved orders the rule would actually validate, newest
     first. Default is `TOP 500` over 90 days; tighten to taste.
   - **STEP 3** loops the corpus, rebuilds both TVPs from `oe_line` / `oe_hdr_notepad`, and
     calls `dbo.kb_fnt_br_order_validator_v2` directly. Row-by-row by necessity (the TVF takes
     TVPs, so there is no set-based form); ~500 orders runs in well under a minute.

   Do this **before** the cutover, while nothing has changed. Two summaries print at the end:
   the verdict spread by `err_code` — confirm it's a realistic mix and not all-NULL — and the
   credit-status exposure, which should now show no ambiguous rows driving a credit-dependent
   verdict.

4. **Build.** VS2022 MSBuild, matching the CAS-fix invocation:
   ```
   MSBuild asi_Order_Validator.csproj -p:Configuration=Release ^
     -p:ReferencePath="C:\Business_Rules\References"
   ```
   Verify the output DLL: **v1.0.0.0**, **no APTCA**, `SecurityRules(Level1)` present,
   TFM **v4.7.2**.

5. **Copy** `bin\Release\asi_Order_Validator.dll` to
   `\\asp21fs1.ahi.local\BusinessRules\BusinessRulesDLL\`. Nothing to save aside — this is
   a new file. Leave `kb_Order_Validator_v2.dll` exactly where it is.

6. **Register the rule in Rule Manager — as INACTIVE (`row_status_flag` 705).** UI, **not**
   raw SQL: `business_rule` is counter-managed and a raw INSERT drifts the counter.

   Create it inactive and leave it inactive until step 7. A rule registered *active* against
   an assembly that won't load — wrong TFM, missing `Atlas.CrownSurcharge5011348`, the APTCA
   trap — breaks **every order save in the environment** the moment the pool recycles. At 705
   a bad DLL costs nothing.

   > **⚠ REGISTER THE DATA ELEMENTS TOO — this is what broke the first attempt.**
   > `business_rule_data_element` is a separate list from the binding fields below, and P21
   > gives the rule **only** the fields registered there. Register these 23, and make sure
   > **`freight_code_uid`** is selected — **not** `freight_cd`:
   >
   > | DataWindow | fields |
   > |---|---|
   > | `d_oe_header` | `order_no`, `date_created`, `requested_date`, **`freight_code_uid`**, `ship_to_id`, `customer_id`, `packing_basis`, `order_type`, `rma_flag`, `quote`, `cancel_flag`, `ufc_oe_hdr_ud_oe_surcharge` |
   > | `d_dw_oe_line_dataentry` | `delete_flag`, `oe_order_item_id`, `qty_ordered`, `oe_line_complete`, `product_type`, `extended_price` |
   > | `d_dw_oe_hdr_shipinfo` | `oe_hdr_carrier_id` |
   > | `d_oe_hdr_credit` | `credit_status` |
   > | `d_dw_oe_hdr_notepad_dataentry` | `topic`, `mandatory`, `delete_flag` |
   >
   > Then **verify** with `Testing\kb_Order_Validator_v2\verify-required-elements.sql`
   > (set `@uid` to the new rule's `business_rule_uid`). Every row must read `ok` before
   > flipping to 704 — any `*** NOT REGISTERED ***` is a latent false block or, for the
   > notepad fields, a silently wrong verdict.

   Binding values, read from BRR 2026-09-01:

   | Field | Value |
   |---|---|
   | `rule_name` | `asi_Order_Validator` |
   | `class_name` (bound DataWindow) | `d_oe_header` |
   | `apply_during_save_flag` | `Y` |
   | `run_type_cd` | `3424` (synchronous) |
   | `internal_rule_flag` | `N` |

   Note `class_name` is **`d_oe_header`**, not `w_order_entry_sheet` as
   `kb-order-validator-v2-cas-fix.md` states — that guide is wrong on this point.
   `run_type_cd` 3424 = synchronous, 3423 = asynchronous. Re-verify against the live row
   before creating:
   ```sql
   SELECT rule_name, class_name, apply_during_save_flag, run_type_cd,
          internal_rule_flag, row_status_flag
   FROM   business_rule
   WHERE  rule_name LIKE '%Order_Validator%' OR rule_name LIKE '%Order_Workflow%';
   -- v1 rules (kb_Order_Validator, kb_Order_Workflow) are already 705/inactive.
   ```

7. **Cut over** — in Rule Manager, set `kb_Order_Validator_v2` inactive (`row_status_flag`
   705) and `asi_Order_Validator` active (704). Leave `kb_Order_Workflow_v2` **active**.
   ```sql
   SELECT rule_name, row_status_flag FROM business_rule
   WHERE  rule_name IN ('kb_Order_Validator_v2','asi_Order_Validator','kb_Order_Workflow_v2');
   -- expect: kb_Order_Validator_v2 = 705, asi_Order_Validator = 704, kb_Order_Workflow_v2 = 704
   ```

8. **Recycle the middleware app pools** on **AHI-API1** — the SOA/UIServer worker caches
   loaded rule assemblies and the file copy alone does nothing. Elevated PowerShell on the host:
   ```powershell
   $appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
   & $appcmd list apppool /text:name |
     Where-Object { $_ -like 'API-P21BusinessRules - P21 SOA*' } |
     ForEach-Object { & $appcmd recycle apppool /apppool.name:"$_"; "recycled: $_" }
   ```

## Verification

1. **The rule loads and runs at all.** Save any qualifying order. No popup and no new
   `Error` row = healthy.
   ```sql
   SELECT TOP 20 date_created, log_action, return_value, LEFT(return_message,150) AS msg, user_id
   FROM   business_rule_log
   WHERE  rule_name = 'asi_Order_Validator'
   ORDER  BY date_created DESC;
   ```

2. **Block logging actually lands.** Force a block (easiest: an order the baseline shows
   with `success_bool = 'N'`) and confirm a row appears with `log_action = 'Validation'` and
   `return_message` shaped `order#<no> :: [v2errNN] …`.
   **If you get the popup but no row**, the insert is failing and being swallowed by design —
   check `INSERT` on `business_rule_log`, and whether anything constrains `log_action` to a
   fixed value set.

3. **No double-validation.** One popup, not two. Two means step 7 didn't take.

4. **Atlas path still wired.** An order that triggers the surcharge branch must not throw
   `MethodAccessException`. If it does, the CAS attributes are wrong — rebuild per step 4.
   The `Assembly '... Version=x.x.x.x'` token in the error text is the litmus.

5. **Equivalence.** Re-save the baseline corpus, then run STEP 4 of the harness. Expect
   every row `MATCH`, `MATCH (both passed)` or `MATCH (both skipped)`. The two documented
   intentional diffs are em-dash rendering and `\r\n` handling; STEP 4 normalizes the first.
   Anything under `*** ***` is a real regression.

6. **Performance sanity** — measure, don't assert. Compare logical reads before/after from
   the plan-cache DMVs (not wall clock). The full-scan existence guard in
   `kb_fnt_br_shipto_info` should be gone entirely.

## Rollback

Fast, and no file changes needed:

1. Rule Manager: set `asi_Order_Validator` inactive (705) and `kb_Order_Validator_v2`
   active (704).
2. Recycle the same app pools (deploy step 8).

The old DLL was never removed, and no DB object was created or dropped, so this reverts
cleanly to the pre-deploy state — including the APTCA/CAS status the env was already in.

Optional cleanup if abandoning entirely:
```sql
DELETE FROM business_rule_log
WHERE rule_name = 'asi_Order_Validator' AND log_action = 'Validation';
-- DROP TABLE dbo.asi_validator_baseline;   -- harness capture table
```

## Not in this deploy (Phase 2)

- The four `[PRESERVED-BUG]` items: unknown-carrier fail-open, `LEFT JOIN`→`INNER JOIN`
  order-total drop, the retired `row_status_flag = 700` required-date row, and `$1.5k`-style
  freight prices in user instructions.
- Dropping the nine `kb_` objects. Confirm no other consumer first — `kb_view_carrier`,
  `kb_view_customer` and `kb_fn_number_shorten` are used well beyond this rule. Note
  `kb_view_item_classifications_loc100` itself depends on `kb_fn_get_product_manager` and
  `kb_table_country_code`.
- Porting `kb_Order_Workflow_v2` and `kb_proc_br_oe_hdr_note`.
- Promoting to lower envs / Prod. When that happens, deploy **inactive (705) first** so the
  registration survives the next env refresh, then flip to 704.

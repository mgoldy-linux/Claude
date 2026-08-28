# Deployment Guide — Low Margin Alert (Evan Jenkins request, no ticket #)

> Produced during development. Update as the artifact changes; commit with the code.
> **STATUS (2026-07-17): EVAN SIGNED OFF** ("everything else looks good") on the audience split, with 2 tweaks now handled:
> 1. *Sell Price on its own line* — already correct in the current template; his sample was stale (generated mid-build 7/14). Regenerate a fresh sample to confirm.
> 2. *Price Page Description blank* — populates on 86% of real low-margin lines; the 14% blank are `price_page_uid = 0` (not priced from a price page). Added a `(no price page)` fallback so the line is never empty. Applied to script 01 (Prod-ready) and to the live Play view.
>
> **Outlook line-break fix (2026-07-17):** the first fired email showed the banner *"We removed extra line breaks from this message"* and merged fields onto single lines. Outlook's *Remove extra line breaks in plain text messages* strips SINGLE newlines but never collapses **blank-line-separated** paragraphs. Also added `%` to percent lines and grouped minor fields with ` | `.
>
> **Spacing final round (2026-07-22, commit `bc64bef`):** Evan found the fully blank-line body too spread out. Reverted header + line-item fields to **single-line** spacing (`@nl`), then per his follow-up added a **blank line (`@br`) around Order Qty and Sell Price only** so the two key figures stand apart; the cost cluster (MAC/Std Cost/Price Page/Req Date/GM%) stays single-spaced. Footer Notes keep `@br`. Confirmed to Evan this is an **Outlook display setting, not P21** — single newlines merge per each reader's own *Remove extra line breaks* setting, so a blank line is the only reliable separator. Applied to script 03 + live Play (both alerts rebuilt, active 704).
>
> **Activation flag: `704 = ACTIVE (fires), 705 = INACTIVE`.** Script 03 now creates the alerts at 704. (Earlier confusion: in Play the old prod alerts sit at 705 = deactivated.)
>
> **Price-page demo recipe (2026-07-22):** to show a populated Price Page Description on a low-margin line, use customer **Flooring Systems Inc (1020066)** + item **MAP36163000** (auto-matches page 93854). Let the page price fill in, *then* override the sell price down to force margin < 5% — a manual override keeps `price_page_uid` on ~⅓ of lines (55,784 / 173,104 over 120d), verified live on order 5923022. The old blank sample (`MAP1785142`) simply had no price page → correct `(no price page)` fallback, not a bug.
>
> **Remaining before Prod (go-live):** (a) Evan's OK on the 7/22 spacing; (b) flip `row_status_flag` 705→704 once (a) is confirmed.
>
> **PROVISIONAL DEPLOY — EXECUTED 2026-07-31** ahead of the Monday P21Play refresh (which restores Play FROM Prod and would have wiped the Play-only alert build). Ran, against **P21** (Prod):
> - `01-alter-view-add-margin-columns-PROD.sql` (copy of 01 with `USE P21`) — all 8 columns confirmed present.
> - `02-register-tokens-PROD.sql` (copy of 02 with `USE P21`) — all 8 new tokens + the 2 repointed existing tokens confirmed.
> - `03-create-alerts-PROD-INACTIVE.sql` — created **uid 104 "Team"** and **uid 105 "Purchasing Escalation (MAC)"** at `row_status_flag = 705` (INACTIVE, does not fire), with the **real recipient list** baked in (Alex Sivongsay/Order Taker/Justine Daugherty/Sales Rep; Pam Dundas/Alex Boeve).
> - Verified full structural parity against Play with `PowerShell\Compare-LowMarginAlert-Prod-vs-Play.ps1` (view columns, `where_clause`, filter counts, message bodies, token registration all match; only `row_status_flag` and recipients differ, as designed).
>
> This is a preservation step, not the go-live deploy — Evan's final spacing sign-off is still open; do not flip `row_status_flag` to 704 until he confirms.
>
> ⚠ **After the Play refresh completes, Play's copy of this alert will also carry the real recipients** (since Play now restores from this Prod state) — the `mgoldyn`-only safety hack from the original Play build is gone. Before resuming any alert testing in Play, re-apply mgoldyn-only recipients there first, or the next test fire will email real people through Play's live SMTP.
>
> **STATUS (2026-08-26): SAMPLES SENT TO EVAN, awaiting his sign-off before flipping Prod active.** Forwarded live samples of both 104 and 105 from P21Play. Two testing traps worth keeping for next time:
> - **Test-customer trap:** Empire Today (`3000703`/`1127792`) shares `corp_address_id = 1046538` — the exact value both alerts' `where_clause` excludes — so it silently never fires there. Use **All Tile, Inc. (`1000260`)** instead. Recipe: `MAP1785142` @ 100 EA, sell price overridden to **$16.00** trips both; `ROB7399-1` @ 60 EA, **$19.80** trips Team only. (Default/list price won't trip either — must manually override the Sell Price field.)
> - **Recipient drift found and fixed:** at some point after the 7/31 refresh, 104's real recipients (Alex Sivongsay, Justine Daugherty, Sales Rep/Order Taker tokens) had gotten reactivated in Play — not mgoldyn-only anymore. Caught it because two test emails to them got stuck in `alert_queued_mail` at status **`1063 = "Email Pending"`** (never actually sent — likely because the Sales Rep token resolved to a blank address on an order with no primary salesrep). Deleted the stuck rows and removed the real recipients in the client before they could send. **Check `alert_queued_mail` for row_status_flag 1063 whenever an expected alert email doesn't show up** — it means P21 generated it but never delivered it, which reads completely differently from "never fired at all."
> - **Recurring check:** re-verify Play recipients are mgoldyn-only after any future P21Play refresh — this is now the second time real recipients have come back active post-refresh.
>
> **STATUS (2026-08-27): RSM recipient built + tested in Play, not yet live.** Evan's reply on the samples thread revealed he expects **RSM** (+ himself, + Jere Butler on Purchasing) on the distribution — see script `07-add-rsm-token.sql`. Adds `contacts.sales_manager_id` self-join + `rsm_email` column to the view (same pattern as P21's own stock `p21_view_alert_cr_Opportunities`), registers token `rsm_email` (`available_areas=80`, recipient-only). Verified via direct SQL (no alert fired) against 6+ real reps — 173/188 salesreps (92%) have a manager, 151 of those (87%) have a usable email; ~22 reps resolve blank. **Drawback disclosed to Evan:** RSM follows whoever manages the salesrep, not a fixed territory, so an RSM overseeing reps in multiple regions sees alerts outside their own region. **Tested the blank-RSM edge case risk-free** using **The Carpet Group Inc (customer_id `1108592`)** — default rep Kevin Isken has no manager assigned at all, so no real employee received a test email; confirmed the alert still fired correctly. **No P21-native way to log alert sends for Prod tracking** (confirmed: `alert_queued_mail` is a pure transient queue, `email_log` covers document email only, never alerts) — plan is to **BCC the user's own address** on both alerts, added in the same recipient build as RSM. Not yet added to `alert_recipient` on 104/105 — pending Evan's reply on scope (Team/Purchasing/both) and To vs CC.
>
> **UPDATE (2026-08-28): Evan OK'd the drawback, asked for a live test to Tyler Priewe** ("I will give him a heads up") and floated flipping Prod live next Wednesday (9/2). Found a genuine (non-contrived) test case in Play: order `6058724` (Carpet Factory Outlet LLC), rep Andrew Restivo, RSM resolving to Tyler Priewe, margin -0.42%/-1.28%, clears every filter clause on the `where_clause`. Note: `p21_view_alert_oe_OrderEntry` can't be queried directly for an already-processed order (inner-joined to the transient `pending_alerts` queue) — had to reconstruct the view's filter/margin math and run it standalone against `oe_hdr`/`oe_line`/`inv_loc` to find this. Drafted + user sent a reply to Evan confirming the example; the actual test send to Tyler will use subject "P21Play & TEST Email" so it reads unmistakably as a test. Test send itself not yet made — awaiting Evan's/Tyler's go-ahead. No `alert_recipient` changes this session.
>
> **UPDATE (2026-08-28, continued): live test sent and confirmed working; RSM ported to Prod; PAD recipients reconciled on both Play and Prod.** The 6058724 recipe hit a real inventory block on reuse (0 on-hand at that location today) — swapped to `MAP1785142` @ location 100 (2,480 available), 100 EA @ $16.00 override, re-verified against **current** costs (still -4.5%/-1.0%, both thresholds trip), same customer/rep chain. **User built the order — both 104 and 105 fired, confirmed received.** First real end-to-end proof of the RSM token, not just SQL-verified.
>
> Ported to **Prod** via new script `07-add-rsm-token-PROD.sql`: diffed Prod's live view against Play's first (per the standing rule) — confirmed Prod was missing both script 06 (deliberately NOT bundled in — separate, still-unapproved) and the RSM column. Built the Prod script from **Prod's own current definition**, not the Play script, so only the RSM delta moved — verified via diff that exactly 2 lines changed (new SELECT column + new LEFT JOIN). Applied via `CREATE OR ALTER VIEW`, token registered (`token_uid 745`, matches Play), join re-verified against real Prod contacts data. Prod alerts stayed `705` inactive throughout. **User then added `<rsm_email>` as a recipient directly on Prod 104/105/106/107 in the client.**
>
> **PAD recipient reconciliation:** checked Play first — PAD-Team (106) was missing Evan Jenkins vs. main Team, and PAD-Purchasing (107) had a genuinely corrupted recipient (`<rsm_email>` and `mgoldyn@allsurfaces.com` jammed into one field, not two rows) — fixed via `UPDATE` back to a clean address, matching 105 exactly per the user's choice. User clarified the real ask was **Prod** — re-checked there and found different gaps: 107 missing 5 of 9 recipients (Jerome Butler, Justine Daugherty, Alex Sivongsay, Sales Rep token, Order Taker token), 106 missing Evan Jenkins. Recommended the client over raw SQL `INSERT` (documented counter-drift history on `alert_recipient`, plus the user's established preference from the 8/3 rebuild). **User added them; re-verified — both alert pairs' recipient sets now match exactly** (Team 6/6, Purchasing 9/9). All four alerts remain `705` inactive throughout — zero live-fire risk from any of this work.
>
> **Status: waiting on Evan** — recipient sets fully built and reconciled, RSM proven live in both Play and Prod, everything still safely inactive. Open: his final confirmation on the recipient set as-built and go-live timing (9/2 floated); BCC-to-self raised as a want, not yet added anywhere.

## Artifact(s)
All under `C:\Claude\Alerts\Low-Margin-Alert\`, run **in numbered order**:

| # | Script | What it does |
|---|---|---|
| 1 | `01-alter-view-add-margin-columns.sql` | Adds 6 columns + 1 join to `dbo.p21_view_alert_oe_OrderEntry` |
| 2 | `02-register-tokens.sql` | Registers 6 tokens on `alert_type_uid = 12` |
| 3 | `03-create-alerts.sql` | Creates the 2 alert definitions (impl + filters + message + recipients) |
| — | `ROLLBACK-p21_view_alert_oe_OrderEntry-Play-BEFORE.sql` | The pre-change view definition — **the rollback artifact** |
| — | `Analyze-Cost-Buckets.sql` | Read-only analysis; not part of the deploy |
| 6 | `06-harden-oe-view-null-tokens.sql` | Wraps 6 previously-unwrapped OE-token columns in `ISNULL`/`COALESCE` — defense against the `p21_sp_alert_generation` NULL-token-collapse bug (see 2026-08-11 note below). `CREATE OR ALTER VIEW`, run standalone against the view already deployed by script 01 |
| 7 | `07-add-rsm-token.sql` | Adds `contacts.sales_manager_id` self-join + `rsm_email` column/token to the view. **Play.** Live-tested 8/28 (real test order fired, received). Does NOT itself touch `alert_recipient` — that was done separately, in the client |
| 7-PROD | `07-add-rsm-token-PROD.sql` | Same RSM change, built from **Prod's own current view definition** (not the Play script — Prod was missing script 06's hardening too, deliberately not bundled in). Deployed 2026-08-28, `CREATE OR ALTER VIEW` + token registration, verified via diff (exactly 2 lines changed) and against live Prod contacts data |

- Request: `REQUIREMENTS-Evan-2026-06-30.md` · Plan: `PLAN.md`
- Ticket: *none assigned*

## Target environments
- **P21Play** (`P21Play` @ `P21Dev.allsurfaces.com`) → **Prod** (`P21` @ `P21.allsurfaces.com`)
- Play was verified at the **Prod baseline** (2026-07-14) before any change, so the scripts proven in Play are the scripts that run in Prod.
- ⚠ **P21Training is NOT the path.** It carries a one-off `price_page_description` token from 2026-05-26 that exists nowhere else. Reference only — do not promote from it.

## Design — split by AUDIENCE, not by trigger  ⚠ differs from Evan's spec

Evan asked for two alerts split by **trigger** (Standard Cost / MAC) because each needs different recipients. Measured on Prod over 14 days, that design **double-emails**: 239 of 477 alerting orders trip **both** thresholds, so the core team would receive **716** emails — 239 of them a second report of the same order. That works against Evan's stated goal of reducing email churn.

Split by **audience** instead — same policy, no duplicates:

| Alert | Fires when | Recipients |
|---|---|---|
| **Low Margin Alert - Team** (uid 103 in Play) | `low_margin_flag = 'Y'` — **either** margin < 5% | Alex Sivongsay, Order Taker, Justine Daugherty, Sales Rep |
| **Low Margin Alert - Purchasing Escalation (MAC)** (uid 104 in Play) | `percent_profit_off_mac < 5` | **Pam Dundas + Alex Boeve only** |

Both emails carry **both** GM% figures, so the reader sees which threshold failed.

**Core team: 716 → 477 emails, zero duplicates. Pam/Alex: 353 either way.** Verified in Play: at $16.00 (both trip) the team gets **one** email; at $16.15 (standard cost only) the team gets one and purchasing correctly gets **none**.

**Rejected:** a single alert with a *conditional recipient token*. It does work — `p21_sp_alert_generation` strips an `<email_not_found/>` recipient and still sends to everyone else — but it also fires a bogus `<email_not_found/>` message into `alert_queued_mail` every time it doesn't escalate (~9/day of permanent queue noise).

**⚠ This is a deviation from Evan's written spec and needs his sign-off.**

## 🚨 RECIPIENTS — the one thing that must change for Prod

**The Play build has `mgoldyn@allsurfaces.com` as the ONLY recipient, deliberately.**
P21Play has **live SMTP** (`enable_email_functionality = Y`, `email_type = SMTP`, sender `noreply@allsurfaces.com`), so real recipients in Play would send real email to real people.

Before Prod, edit the `alert_recipient` INSERT in `03-create-alerts.sql`:

- **Team alert** → `asivongsay@allsurfaces.com`, `<taker_email>`, `jdaugherty@allsurfaces.com`, `<primary_salesrep_email>`
- **Purchasing alert** → Pam Dundas (`pdundas@allsurfaces.com`) + Alex Boeve (`aboeve@allsurfaces.com`)

Notes:
- Recipients may be **tokens** — `<taker_email>` and `<primary_salesrep_email>` resolve per order. That is how "Order Taker" and "Sales Rep" get on the email.
- `recipient_type_cd`: 1281 = To, 1282 = CC, 1283 = BCC. `record_type_cd` = **1059** (NOT NULL — omitting it fails the INSERT).
- **`sender_email_address` MUST be NULL, never `''`.** P21 only falls back to `alert_default_smtp_sender_email` when it IS NULL; an empty string parks the mail as `reason_cd 1060 "Email system down"` — which reads like an outage but is not.
- **Obtained 2026-07-17** (P21Play `users`, both active `delete_flag=N`): Pam Dundas = `pdundas@allsurfaces.com` (id `PDUNDAS`), Alex Boeve = `aboeve@allsurfaces.com` (id `ABOEVE`).

## Dependencies & deploy order
1. **View first** — the tokens reference its columns; registering a token against a missing column fails.
2. **Tokens second.**
3. **Alerts last** — their `where_clause` and message body reference the tokens.
- `uid`s are **not identity columns** — the scripts supply `MAX+1`. **uids will differ in Prod**; match on **name**, never uid.

## Backward-compatibility notes
- **The live `Low Margin Alert` (uid 97) is untouched and keeps running.** All view columns are additive; `line_item_profit_percentage` and its token are unchanged.
- Run the new alerts **alongside** the old one, compare, and only retire uid 97 on Evan's sign-off.
- ⚠ **The new triggers fire on a different set of lines.** Measured on Prod over 14 days: today 283 emails; the two new alerts together = **716** (477 unique orders, but **239 trip both triggers and so get two emails each**). A combined single alert would send 477. The `low_margin_flag` token was registered to allow that switch **with no further view change** — Evan's call.

## Deploy steps
1. **Diff the Prod view against Play first** (standing rule — Prod drift breaks the STUFF anchors):
   ```sql
   SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'))
   ```
   Run on both; if the anchors (`'reward_program_id'`, the `oe_line_ud` join) differ, **stop** and re-cut.
2. **Back up the Prod view definition to a file** — this is the rollback artifact.
3. Run `01-alter-view-add-margin-columns.sql` against `P21.allsurfaces.com` / `USE [P21]` (change the `USE`).
4. Run `02-register-tokens.sql` (change the `USE`).
5. Run `03-create-alerts.sql` (change the `USE`) — **with the real recipients substituted in**.
6. All three are **idempotent**; re-running is safe.

## Verification
- All 6 columns present: `INFORMATION_SCHEMA.COLUMNS` on `p21_view_alert_oe_OrderEntry`.
- 6 tokens with **human-readable descriptions** (`p21_apply_alert_token` overwrites the description with the raw column formula — the `UPDATE` in script 02 is **not optional**).
- **Each `where_clause` parses and runs** against the view — proves every token resolves to a column.
- **Every `<token>` in the message body resolves** to a view column, or it renders as literal text in the email.
- **Enter a real low-margin order and read the actual email.** Check: no 6-decimal values (the `p21_fn_MaskDecimal` trap — we use `CAST AS DECIMAL`), and the MAC/Standard Cost figures agree with the Sales Margins tab.

## Price Page Description — `(no price page)` fallback (Evan 2026-07-17)
- Column is now `COALESCE(NULLIF(price_page.description,''),'(no price page)')`. On lines with `price_page_uid = 0` (priced manually / by contract, ~14% of low-margin lines, incl. Evan's `MAP1785142` sample) there is no price page and thus no description — the fallback text prevents a confusingly empty line.
- Applied to `01-alter-view-add-margin-columns.sql` (runs clean on the fresh Prod view) **and** hot-swapped into the live P21Play view (script 01's idempotency guard would skip a re-run, so Play was patched surgically — `scratchpad/swap-pricepage-play.sql`).

## Known open items
- **`Ship Location ID` is mapped to `source_location_id`** (`oe_line.source_loc_id`). Evan did **not** flag it in his 7/17 sign-off, so the source-location mapping is accepted. Still a **line-level** value shown in the header — confirm it renders on the first real Prod email.
- `sales_location_id` and `source_location_id` are registered `available_areas = 32` (event) but used in the **header**. They resolve as view columns; whether P21 renders them there is unproven until the first real email.
- **Regenerate a fresh sample** from the current Play alert and send to Evan — the sample he reviewed was stale (Sell Price merged, price page blank); the current build fixes both.
- The **Sales Margins tab reconciliation** has not been done (the tab shows Standard Cost only — there is no MAC on it anywhere).

## Duplicate — Low PAD Margin Alert (2026-07-31, Play only so far)

Duplicate of the Team/Purchasing split, scoped to the PAD product group that the original alert deliberately **excludes**. Replaces (eventually) the older, separate `Low PAD Margin Alert` (active since 2025-12-18) that fires on the legacy `line_item_profit_percentage < -5` column with `Taker` "does not begin with" ESTORE — that alert stays **untouched** for now, same pattern as uid 97.

Confirmed with user before building:
- **Trigger:** reuse the new `low_margin_flag` / `percent_profit_off_mac` columns (NOT the legacy `line_item_profit_percentage` measure) — keeps one consistent margin definition across every Low Margin variant.
- **Recipients:** same Team + Purchasing Escalation split as the non-PAD alert.
- **Taker filter:** `NOT LIKE '%ESTORE%'` (does not *contain*) — matching the non-PAD alert, not the old PAD alert's "does not begin with."

**Script:** `04-create-pad-alerts-PLAY.sql` — built and run in **Play only** (uid 105 "Low PAD Margin Alert - Team", uid 106 "...Purchasing Escalation (MAC)"), `row_status_flag = 704`, `mgoldyn`-only recipients, same as the original Play-first build pattern. Both `where_clause`s verified to parse cleanly against the view.

**PROD DEPLOY — EXECUTED 2026-08-03**, after user reviewed the Play build. Ran `05-create-pad-alerts-PROD-INACTIVE.sql` against **P21** — created **uid 106 "Team"** / **uid 107 "Purchasing Escalation (MAC)"** at `row_status_flag = 705` (INACTIVE — no PAD-alert-equivalent stakeholder sign-off yet, confirmed with user before deploying) with the real recipient list. View/tokens already present from the 2026-07-31 deploy, reused as-is. Parity vs. Play confirmed via `Compare-LowMarginAlert-Prod-vs-Play.ps1` (now checks all 4 alerts). Same warning applies: once Play refreshes from Prod, Play's copy will carry real recipients too.

**⚠ PLAY REFRESH SAME DAY (2026-08-03, later) — the Prod-inactive deploy above never reached Play.** Confirmed via `msdb..restorehistory`: the backup used for that refresh was taken 12:01–12:28 AM, roughly 7 hours *before* the 7:49 AM deploy above. A same-day deploy is not automatically safe against a same-day refresh — check the actual backup timestamp, not just the calendar date. Rebuilt the pair directly in Play (`04-create-pad-alerts-PLAY.sql`) — **it never fired** across multiple confirmed-tripping test orders. Root cause narrowed but not proven: rebuilding manually in the P21 client surfaced that `Low Margin Flag` is missing from the filter grid's Column dropdown despite being correctly registered in `token`/`alert_type_x_token` — signature of a stale AHI-API1 client-side metadata cache, not a data problem. Per the user's standing preference (SQL-built alerts have a real history of not firing reliably), the SQL-built Play copy was deleted and **both alerts are being rebuilt manually in the P21 client** using the field export at `Alerts\Low-Margin-Alert\PAD-Alert-Fields-For-Manual-Rebuild.txt`. Not yet confirmed firing as of this note. See [[project_2026_07_13_low_margin_alert]] for the full investigation.

## Hardening — NULL-token collapse bug in `p21_sp_alert_generation` (2026-08-11)

Unrelated blank-email incident (`uid 102 "Test Verify Alerts"`, a leftover diagnostic — deactivated, not part of this alert family) led to reading `p21_sp_alert_generation`'s actual definition for the first time. Confirmed: it chains `REPLACE(@PX, '<column>', @value)` once per token registered for the alert's **type** (all 5 OE alerts share the same token pool, not just the tokens each one's own template references), and `REPLACE()` returns NULL if any argument is NULL — **even when the search pattern isn't present in the string.** So a single NULL token anywhere in the OE pool can blank this alert's email too, regardless of whether its own template mentions that token.

Audited `p21_view_alert_oe_OrderEntry` for every OE-token column not already guarded; found 6: `order_profit_percentage`, `extended_price`, `total_amount`, `line_item_profit_percentage`, `fill_quantity`, `fill_extended_price`. **Measured against 90 days of real order lines (~1.5M rows) in Play/Training/BusinessRules** with filters matching the view's own WHERE clause exactly — zero actual NULLs or divide-by-zero conditions in any of them today. This is insurance against a future edge case, not a fix for an observed failure (the triggering incident's own order had no NULLs in these fields either).

**Applied via `06-harden-oe-view-null-tokens.sql` (`CREATE OR ALTER VIEW`) to P21Play, P21Training, P21BusinessRules** — confirmed byte-identical view definitions across all three before patching; verified equivalent on existing data first (0 diffs), then confirmed all three compile/query cleanly post-patch. **NOT yet applied to Prod** — user wants that done after hours, since Prod's copy of this view is live for other real, currently-firing alerts (not just this still-inactive Low Margin/PAD family). Before running there: diff Prod's view against Play's first (per the standing rule two sections up) since Prod's Low Margin columns were added via a separate PROD-suffixed script and may have drifted.

**Status: PAD pair mid-rebuild in the client, not yet confirmed firing. RESUME: confirm manual rebuild fires on a fresh test order; separately, run the after-hours Prod diff/deploy for script 06.**

## Rollback
1. **Deactivate the two new alerts first** (stops email immediately) — **`704 = ACTIVE, 705 = INACTIVE`**, so set 705:
   ```sql
   UPDATE alert_implementation SET row_status_flag = 705
   WHERE alert_implementation_name IN ('Low Margin Alert - Team','Low Margin Alert - Purchasing Escalation (MAC)');
   ```
2. Delete them (children first — FK order): `alert_recipient` → `alert_message` → `Alert_implementation_query` → `alert_implementation`.
3. **Restore the view** from the backup taken in step 2 of the deploy.
4. **Drop the 6 tokens — child tables first:**
   ```sql
   DELETE FROM Alert_implementation_query WHERE column_id IN (<uids>)
   DELETE FROM alert_type_x_token         WHERE token_uid IN (<uids>)
   DELETE FROM token                      WHERE token_uid IN (<uids>)
   ```
- The live alert (uid 97) is untouched throughout, so rollback fully restores prior behavior.

**Rolling back script 06 alone** (the NULL-token hardening, independent of the rest): `CREATE OR ALTER VIEW` back to the pre-06 definition saved when each environment was patched (Play/Training/BusinessRules — no separate backup file was taken since script 06 is provably a no-op on all existing data; the pre-06 text is recoverable from git history on `06-harden-oe-view-null-tokens.sql`'s parent commit, or from `OBJECT_DEFINITION` on any environment not yet patched).

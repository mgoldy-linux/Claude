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

## Artifact(s)
All under `C:\Claude\Alerts\Low-Margin-Alert\`, run **in numbered order**:

| # | Script | What it does |
|---|---|---|
| 1 | `01-alter-view-add-margin-columns.sql` | Adds 6 columns + 1 join to `dbo.p21_view_alert_oe_OrderEntry` |
| 2 | `02-register-tokens.sql` | Registers 6 tokens on `alert_type_uid = 12` |
| 3 | `03-create-alerts.sql` | Creates the 2 alert definitions (impl + filters + message + recipients) |
| — | `ROLLBACK-p21_view_alert_oe_OrderEntry-Play-BEFORE.sql` | The pre-change view definition — **the rollback artifact** |
| — | `Analyze-Cost-Buckets.sql` | Read-only analysis; not part of the deploy |

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

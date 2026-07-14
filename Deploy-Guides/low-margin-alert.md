# Deployment Guide — Low Margin Alert (Evan Jenkins request, no ticket #)

> Produced during development. Update as the artifact changes; commit with the code.
> **STATUS (2026-07-14): BUILT AND VERIFIED IN PLAY.** Not yet end-to-end tested (needs a real low-margin order entered in the Play client). Not deployed to Prod. Awaiting Evan's sign-off on a sample email.

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

## 🚨 RECIPIENTS — the one thing that must change for Prod

**The Play build has `mgoldyn@allsurfaces.com` as the ONLY recipient, deliberately.**
P21Play has **live SMTP** (`enable_email_functionality = Y`, `email_type = SMTP`, sender `noreply@allsurfaces.com`), so real recipients in Play would send real email to real people.

Before Prod, edit the `alert_recipient` INSERT in `03-create-alerts.sql` to Evan's list:

| Alert | Recipients |
|---|---|
| **Low Margin Alert - Standard Cost** (uid 103 in Play) | Alex Sivongsay, Order Taker (`<taker_email>`), Justine Daugherty, Sales Rep (`<primary_salesrep_email>`) |
| **Low Margin Alert - MAC** (uid 104 in Play) | the same **+ Pam Dundas, Alex Boeve** |

- Recipients may be **tokens** — `<taker_email>` and `<primary_salesrep_email>` resolve per order. That is how "Order Taker" and "Sales Rep" get on the email.
- `recipient_type_cd`: 1281 = To, 1282 = CC, 1283 = BCC. `record_type_cd` = **1059** (NOT NULL — omitting it fails the INSERT).
- **Still to obtain:** email addresses for **Pam Dundas** and **Alex Boeve**.

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

## Known open items
- **`Ship Location ID` is mapped to `source_location_id`** (`oe_line.source_loc_id`). Evan's mock puts it in the header, but it is a **line-level** value — confirm the mapping and that it populates.
- `sales_location_id` and `source_location_id` are registered `available_areas = 32` (event) but used in the **header**. They resolve as view columns; whether P21 renders them there is unproven until the first real email.
- The **Sales Margins tab reconciliation** has not been done (the tab shows Standard Cost only — there is no MAC on it anywhere).

## Rollback
1. **Deactivate the two new alerts first** (stops email immediately):
   ```sql
   UPDATE alert_implementation SET row_status_flag = 704
   WHERE alert_implementation_name IN ('Low Margin Alert - Standard Cost','Low Margin Alert - MAC');
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

# Deployment Guide — Low Margin Alert (Evan Jenkins request, no ticket #)

> Produced during development. Update as the artifact changes; commit with the code.
> **STATUS: IN DEVELOPMENT — NOT READY TO DEPLOY.** Blocked on Phase 0 (formula oracle). See `C:\Claude\Alerts\Low-Margin-Alert\PLAN.md`.

## Artifact(s)
- `dbo.p21_view_alert_oe_OrderEntry` — **modified** P21-standard view: 5 new columns + 1 new join
- `dbo.token` / `dbo.alert_type_x_token` — 5 new tokens; 1 existing token's `available_areas` amended
- **Two new alert definitions** (built in the P21 client, not by script) on `alert_type_uid = 12`
- Request: Evan Jenkins, 2026-06-30 — `C:\Claude\Alerts\Low-Margin-Alert\REQUIREMENTS-Evan-2026-06-30.md`
- Ticket: *none assigned*

## Target environments
- **P21Play** (`P21Play` @ `P21Dev.allsurfaces.com`) → **Prod** (`P21` @ `P21.allsurfaces.com`)
- Play was verified at the **Prod baseline** on 2026-07-14 (`price_page_description` token absent), so the script proven in Play is the script that runs in Prod.
- ⚠ **P21Training is NOT the path.** It carries a one-off `price_page_description` token from 2026-05-26 that exists nowhere else. Treat Training as a reference only; do not promote from it.

## Dependencies & deploy order
1. **View first** — `p21_view_alert_oe_OrderEntry` (the tokens reference its columns; registering a token against a missing column fails).
2. **Tokens second** — `p21_apply_alert_token`, then the manual description fix (see below).
3. **Alert definitions last** — built in the P21 client; they reference the tokens.
- Alerts cannot be built until the tokens exist and appear in the alert editor.

## Backward-compatibility notes
- **The existing (KOW) low-margin alert is left untouched and keeps working.** All new columns are additive; the old `line_item_profit_percentage` column and token are unchanged.
- Run the new alerts **alongside** the old one in Play, compare, and only retire the old one on Evan's sign-off.
- ⚠ The new triggers measure a **different cost basis** than the old one (Standard Cost / MAC vs `sales_cost`), so they fire on a **different set of lines**. This is intended, but it is a business-visible change — get sign-off with the Phase 4 numbers before cutting over.

## Deploy steps

> Fill in exact file names as the scripts are written. Nothing below is ready to run yet.

1. **Diff the Prod view against Play first** (standing rule — Prod drift breaks the STUFF anchors):
   ```sql
   SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'))
   ```
   Run on both servers and compare. If the anchors differ, **stop** and re-cut the script.
2. **Back up the current view definition** to a file (this is the rollback artifact).
3. Run `<01-alter-view.sql>` against `P21.allsurfaces.com` / `USE [P21]`.
4. Run `<02-register-tokens.sql>` — includes the `UPDATE token SET description = ...` fix for **every** token (`p21_apply_alert_token` overwrites the description with the raw column formula — this is not optional).
5. Amend `sales_location_id` `available_areas` so it renders in the header.
6. Build the two alert definitions in the P21 client (recipients differ — Alert B adds Pam Dundas and Alex Boeve).

## Verification
- `INFORMATION_SCHEMA.COLUMNS` → all 5 new columns present on the view.
- View still returns rows (the new `LEFT JOIN price_page` must not have changed the row count) — compare `COUNT(*)` before/after.
- Token verify query (from `Docs\P21-Alert-Token-How-To.md` Step 6) → one row each, **human-readable description**, correct `available_areas`.
- Trigger a real low-margin order → **inspect the actual email**: all fields populate, and **no 6-decimal values** (the `p21_fn_MaskDecimal` trap — we use `CAST AS DECIMAL` instead).
- Confirm Alert B's recipients include Pam Dundas + Alex Boeve and Alert A's do not.

## Rollback
1. **Disable/delete the two new alert definitions** in the P21 client (stops the emails immediately — do this first).
2. **Restore the prior view definition** from the backup taken in step 2.
3. **Drop the new tokens — child tables first** (FK constraints):
   ```sql
   DELETE FROM Alert_implementation_query WHERE column_id  IN (<uids>)
   DELETE FROM alert_type_x_token         WHERE token_uid  IN (<uids>)
   DELETE FROM token                      WHERE token_uid  IN (<uids>)
   ```
4. Revert `sales_location_id.available_areas` to **32**.
- The old KOW alert is untouched throughout, so rollback restores the prior behavior completely.

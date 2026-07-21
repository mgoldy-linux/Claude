# Deployment Guide — SA-47981 WWMS Sales Order Picking: Item Description

> Status: **ON HOLD — display WORKS (2026-07-21).** The Converter rule **does** render the description in the `WWMSITEMDESC` screen-only column (verified on screen: Item ID `CRA197` → "Crain 197 "Comfort Knees" Knee Pads"). The earlier "display not reachable via DynaChange" verdict is **retracted** — the only real blocker was rule *timing*, and the bin-selection re-fire solves it. One UX test remains before this ships. **No Epicor escalation needed.** Related memory: `project_2026_06_25_sa47981_wwms_pick_item_desc`.

## Goal
Show the item's **description** next to the Item ID on the WWMS Sales Order Picking detail screen (window `w_ship_sheet_rf`, "Sales Order Picking"). Today the screen shows Item ID but not its description.

## Artifacts built (in `C:\Claude\CSharp\`)
- `asi_WWMS_sales_order_picking_item_desc_populate_t2.cs` — **Converter rule. THE WORKING ONE.** Looks up `inv_mast.item_desc` from `item_id` and writes it to `ufc_p21soc_wwmsitemdesc`. Logs `SET ufc_p21soc_wwmsitemdesc = '...'` **and the value renders on screen** when it fires with the row loaded (see verification).
- `asi_WWMS_sales_order_picking_item_desc_t3.cs` — **Pre-SQL rule.** Injects `inv_mast.item_desc` into the pick-detail SELECT. Works at the data level but is **not needed** for the display (the Converter carries it). Superseded; keep only as reference. Can be inactivated.
- DynaChange **screen-only column** `WWMSITEMDESC` (real field name `ufc_p21soc_wwmsitemdesc`) — DB config, no file.

## Target environment
- **P21BusinessRules** (@ P21Dev.allsurfaces.com). All WWMS testing is done here, not P21Play (`project_wwms_testing_env`).

---

## What we learned — and the one thing that actually fixed it

**The breakthrough:** while demonstrating the supposed dead-end, the user clicked **Pick Any**, selected a bin, and `WWMSITEMDESC` **populated on screen**. The matching `business_rule_log` fire shows the Converter ran with the row fully loaded (`item_id = CRA197`, `item_desc = Crain 197…`) → `SET ufc_p21soc_wwmsitemdesc = 'Crain 197…'` → it painted. The Converter's output reaches the screen-only column after all. What killed every earlier attempt was **timing, not plumbing**.

**Three findings that were still valuable (they're all true — they just weren't fatal):**

**1. The screen field's real name is prefixed.** A DynaChange screen-only column named `wwmsitemdesc` is exposed to rules and SQL as **`ufc_p21soc_wwmsitemdesc`** (P21 auto-adds `ufc_p21soc_`). Naming anything `wwmsitemdesc` (any case) never matched — the prefix, not case, was the mismatch. Target field in the Converter **must** be `ufc_p21soc_wwmsitemdesc`.

**2. The item and the screen field live on *different* datawindows.** `item_id` / `item_desc` are on `d_dw_oe_pick_ticket_detail_freight`; the `ufc_p21soc_wwmsitemdesc` column is on `d_dw_rf_shipping_bin`. This is fine — the Converter reads the row it's handed (which carries `item_id`) and writes the screen field; it doesn't need them on the same datawindow.

**3. Timing was the whole game.** The Converter fires on **Window Opening**. In the RF flow, `w_ship_sheet_rf` re-opens as the picker advances/selects a bin, so "Window Opening" actually fires **per line** — and when it fires *with the line's data bound*, it renders. The "empty fires" we chased earlier were the **initial** open before any PT/line was loaded (nothing to copy → blank). We mistook "fired empty before data" for "can never fire with data."

### Net
Data side = solved. **Display side = solved too** — the Converter renders `ufc_p21soc_wwmsitemdesc`. The only open question is *when* it fires relative to the picker's workflow (see "What remains").

---

## What remains (why it's on hold, not done)

**One test decides the final shape.** Pick a PT with 2–3 lines and advance **without** selecting a bin:

- **If the description follows each line automatically** → ship as-is. Option A: zero extra UI, the desc is present as the picker works each line.
- **If it only appears after the bin action** → the description lags the moment the picker most wants it (before choosing what/where to pick). Fix with **Option B**: a button (or a hook on an existing RF action) that forces the Converter to re-fire on the loaded line, so the picker can read the description up front. This is the user's proposed approach and is the likely outcome.

Until that test is run and the approach chosen, this is **on hold** — but functional.

---

## Also captured: the Class Name trap (cost us hours after the DB refresh)
When re-registering the Pre-SQL rule, **Class Name must be `--DS d_ds_oe_pick_ticket_detail_val`** (the detail grid). It is easy to grab **`--DS d_ds_oe_pick_ticket_validations`** by mistake — that's the pick-ticket *lookup* query that fires first. Bound to `validations`, the rule only ever sees a query without the anchor and logs `NO SQL FIELD FOUND` (nothing injected). Symptom of the wrong binding: the rule fires but only on the validation query. Fix in `business_rule` (uid was 163): `class_name` and `window_title` → the `detail_val` form.

## Verification — the display works (proven 2026-07-21)
1. Enter a PT / Order number → **Next** → advance to a line and select a bin (**Pick Any** → choose bin).
2. On screen: the **WWMSITEMDESC** field shows the item's description (verified: `CRA197` → `Crain 197 "Comfort Knees" Knee Pads`). Screenshot: `OneDrive\Pictures\Business Rules\set-item-desc-br-worked.png`.
3. `business_rule_log` in P21BusinessRules confirms the fire that painted it:
   - `ROW FIELDS: ... item_id = CRA197 ... item_desc = Crain 197 "Comfort Knees" Knee Pads ...`
   - `SET ufc_p21soc_wwmsitemdesc = 'Crain 197 "Comfort Knees" Knee Pads'.`
   - Note `apply_on = Window Opening`, `trigger_window_name = w_ship_sheet_rf`, `configuration_id = 4305` — the Window-Opening fire lands **with the row bound** on the bin-selection re-open.

## When resumed — the one test, then pick the shape
- **Run the line-advance test** (above under "What remains") to decide Option A (ship as-is) vs Option B (add a button).
- **If Option B:** the trigger candidates are an On Event hook on an existing RF action, or a Converter re-fire driven by a field the picker touches per line. The bin-selection re-fire already proves the mechanism — we just need it to fire *before* the bin step.

## Rollback / cleanup
- `_t3` (Pre-SQL) is no longer needed — it can be inactivated (Row Status → Inactive) in the Business Rule Organizer.
- `_populate_t2` (Converter) is **the working rule — keep it active.** It writes a diagnostic row to `business_rule_log` per fire; that's harmless but can be trimmed later by removing the `LogInfo("ROW FIELDS…")` discovery call.
- Keep the `WWMSITEMDESC` screen-only column.

# Deployment Guide — SA-47981 WWMS Sales Order Picking: Item Description

> Status: **PARKED (2026-07-21).** The data path is fully solved — the item description can be looked up and written — but **P21's WWMS RF picking screen does not let any available DynaChange rule type render a custom column on that screen.** The blocker is display plumbing, not data. Do not re-attempt with DynaChange rules without new information (see "Why it's parked"). Related memory: `project_2026_06_25_sa47981_wwms_pick_item_desc`.

## Goal
Show the item's **description** next to the Item ID on the WWMS Sales Order Picking detail screen (window `w_ship_sheet_rf`, "Sales Order Picking"). Today the screen shows Item ID but not its description.

## Artifacts built (in `C:\Claude\CSharp\`)
- `asi_WWMS_sales_order_picking_item_desc_t3.cs` — **Pre-SQL rule.** Injects `inv_mast.item_desc` into the pick-detail SELECT. **Works** (value reaches the result set) but does not feed the on-screen field. Superseded; keep only as reference.
- `asi_WWMS_sales_order_picking_item_desc_populate_t2.cs` — **Converter rule.** Looks up `inv_mast.item_desc` from `item_id` and writes it to the screen-only column. Lookup **works** (logs `SET ufc_p21soc_wwmsitemdesc = '...'`) but the value does not render (see below).
- DynaChange **screen-only column** `WWMSITEMDESC` (real field name `ufc_p21soc_wwmsitemdesc`) — DB config, no file.

## Target environment
- **P21BusinessRules** (@ P21Dev.allsurfaces.com). All WWMS testing is done here, not P21Play (`project_wwms_testing_env`).

---

## Why it's parked — the three hard-won findings

**1. The screen field's real name is prefixed.** A DynaChange screen-only column named `wwmsitemdesc` is exposed to rules and SQL as **`ufc_p21soc_wwmsitemdesc`** (P21 auto-adds `ufc_p21soc_`). Aliasing/naming anything `wwmsitemdesc` (any case) never matched — the prefix, not case, was the mismatch.

**2. The item and the screen field live on *different* datawindows.**
- `item_id` / `item_desc` are on **`d_dw_oe_pick_ticket_detail_freight`** (the pick-detail data).
- The `ufc_p21soc_wwmsitemdesc` screen-only column is on **`d_dw_rf_shipping_bin`** (the visible RF picking panel).
- When you add a screen-only column you cannot choose the datawindow — it attaches to whatever panel had focus; ours landed on `d_dw_rf_shipping_bin`.

**3. No available rule type can render a per-row custom column on this RF screen.**
- **Pre-SQL** injects the column into the result set, but a *screen-only* column is not fed from the SELECT, and the injected value lands on the freight datawindow, not the visible one.
- **Converter** can look the value up per row, BUT: its **output only goes to the field marked "Triggers Rule."** To display in `WWMSITEMDESC` it must be the trigger — but a screen-only column never changes, so it only fires on **Window Opening**, before the row has data (every row came back empty). Triggering on `item_id` gives data but sends the output to `item_id`, and the write-back to `WWMSITEMDESC` does not render. **Apply Rule On** offers only *Field Edit / Save / Window Opening* — there is **no per-row / after-retrieve** option. The two requirements (fire with data + output to the screen field) cannot be met together.
- **On Event** has **no "pick line displayed/retrieved" event** — its events are all save/process/window-lifecycle (`PickTicketUpdated`, `windowopened`, `AssignPickBin`, …).

### Net
Data side = solved. Display side = not reachable with DynaChange on this RF window. Getting the description onto the screen likely needs an Epicor-supported RF-screen customization (e.g. a Visual Web Rule) or a P21 change request — outside what DynaChange rules expose.

---

## Also captured: the Class Name trap (cost us hours after the DB refresh)
When re-registering the Pre-SQL rule, **Class Name must be `--DS d_ds_oe_pick_ticket_detail_val`** (the detail grid). It is easy to grab **`--DS d_ds_oe_pick_ticket_validations`** by mistake — that's the pick-ticket *lookup* query that fires first. Bound to `validations`, the rule only ever sees a query without the anchor and logs `NO SQL FIELD FOUND` (nothing injected). Symptom of the wrong binding: the rule fires but only on the validation query. Fix in `business_rule` (uid was 163): `class_name` and `window_title` → the `detail_val` form.

## Verification of the data path (proves the lookup, not the display)
1. Enter a PT / Order number → **Next**.
2. `business_rule_log` in P21BusinessRules:
   - `_t3`: `INJECTED into field 'sql_statement'. Snippet: ...,inv_mast.item_desc wwmsitemdesc FROM...`
   - `_populate_t2`: `ROW FIELDS: ... item_id = <id> ...` then `SET ufc_p21soc_wwmsitemdesc = '<description>'`.
3. On screen: the field stays **blank** — expected, per the findings above.

## If resumed — the only untested lever + the right channel
- **Untested (low confidence):** a Converter on a field that is **on `d_dw_rf_shipping_bin` itself** and gets edited during picking (the **Bin** scan field), **Apply Rule On = Field Edit** — testing whether a *same-datawindow* write-back to `WWMSITEMDESC` renders where the cross-datawindow one did not. Needs `d_dw_rf_shipping_bin` to carry `item_id`/`inv_mast_uid`.
- **Right channel:** raise with Epicor / P21 — "how do we display a custom column on the WWMS RF Sales Order Picking screen?" This is likely an RF-screen customization DynaChange does not cover.

## Rollback / cleanup (to leave the env clean while parked)
- Inactivate `_t3` and `_populate_t2` in the Business Rule Organizer (Row Status → Inactive). Both are pass-through and never block picking, but inactivating stops the diagnostic logging.
- The `WWMSITEMDESC` screen-only column can be left in place or removed; it displays nothing either way.

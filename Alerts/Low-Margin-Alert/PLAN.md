# Low Margin Alert — Development & Test Plan

**Request:** Evan Jenkins, 2026-06-30. See `REQUIREMENTS-Evan-2026-06-30.md`.
**Deploy guide:** `C:\Claude\Deploy-Guides\low-margin-alert.md` (maintained alongside this work)
**Test env:** P21Play (`P21Dev.allsurfaces.com`) → **Prod** (`P21.allsurfaces.com`)
**Reference:** `Docs\P21-Alert-Token-How-To.md`, `Docs\P21_Alert_Customization_Summary.md`

---

## Ground truth established (P21Play, 2026-07-14)

| Fact | Consequence |
|---|---|
| `inv_loc` **already joined** (`inv_loc.location_id = oe_line.source_loc_id`) | MAC + Standard Cost need **no new join** |
| `extended_standard_cost` column already exists | Gives the proven UOM idiom: `cost / NULLIF(pricing_unit_size,0) * unit_quantity * unit_size` |
| Existing filter `Product Group ID is not one of OCHARGE, SAMPLES, PAD` | **"Supplies" is already defined** — no question for Evan |
| Existing filter `Line Item Profit Percentage < 5` | Units are **percent** (5 = 5%), margin **off sell price** |
| Tokens already present: `primary_salesrep_name`, `sales_location_id`, `source_location_id`, `unit_price`, `line_item_profit_percentage`, `extended_standard_cost` | Several of Evan's fields need only an `available_areas` change, not a new token |

**Design decision (revised):** add scalar columns to `p21_view_alert_oe_OrderEntry` directly via CHARINDEX+STUFF (the documented, twice-proven pattern). The Friday `asi_view_alert_oe_line_margin` wrapper is **withdrawn** — it assumed new joins were needed; they are not, so it would add indirection for no benefit.

---

## RESOLVED — what today's trigger actually measures  *(was Blocker A)*

`line_item_profit_percentage` =

```sql
(unit_price - <cost>) / unit_price * 100
```

where `<cost>` is:

```sql
CASE WHEN users.default_costing_basis = 2 THEN oe_line.commission_cost
     WHEN users.default_costing_basis = 3 THEN oe_line.other_cost
     WHEN users.default_costing_basis = 4 THEN oe_line.carrier_rebate_cost
     ELSE oe_line.sales_cost END
```

…and the view joins `INNER JOIN users ON oe_hdr.last_maintained_by = users.id` — i.e. the basis belongs to **whoever last saved the order**.

**Traced through the live configuration (P21Play, 2026-07-14):**

| Evidence | Value | Source |
|---|---|---|
| `users.default_costing_basis` | **2** for 815 users, **1** for 55 | `users` |
| `commission_cost_flag` | **2 = Moving Average** | `system_setting`; decoded from P21's own comment in `p21_b2b_price_item`: `--COMMISSION COST- Standard=1 Moving Average=2 Order Cost=3` |
| `inventory_costing_basis` | **Average** | `system_setting` → order cost (`sales_cost`) is pulled from MAC (KB0017615) |

- basis **2** (815 users) → `commission_cost` → **MAC**
- basis **1** (55 users) → `sales_cost` → order cost → **MAC** (costing basis is Average)

### ⇒ Today's alert is already, effectively, "GM% off MAC"

**This inverts the risk assessment:**

- **Alert B (GM% off MAC < 5%) ≈ the status quo.** Expect similar volume. Low risk.
- **Alert A (GM% off Standard Cost < 5%) is the genuinely new trigger.** This is where the volume change lands — measure it (Phase 4).

**Caveat — and it is the reason Evan wants `price_page_description`:** commission cost is
`CASE WHEN cost_page_uid/price_page_uid = 0 THEN <MAC> ELSE <the page's cost> END`.
A line priced off a page **with a cost page** has a commission cost that is **not** MAC. That is exactly the case where the margin looks wrong and nobody can explain why. His instinct was right.

**Still true:** the per-user `default_costing_basis` join is a latent defect in the *current* alert (same line scores differently depending on who last saved it). The new columns read `inv_loc` directly and are **not** subject to it. Do not replicate the pattern.

## RESOLVED — which location  *(was an open question)*

`system_setting.use_sales_loc_for_source_costs = **N**` → costs come from the **source location**, not the sales location.

⇒ **Keep the alert view's existing join** (`inv_loc.location_id = oe_line.source_loc_id`). It matches the configuration. This is also what `extended_standard_cost` already uses.

⚠ The `kb_` Sales Margins tab reads `inv_loc` at **`:sales_location`** — inconsistent with this setting. *Caveat: no DB object reads `use_sales_loc_for_source_costs` (it is consumed by the PowerBuilder client), so this is inference from the setting name, not proof.* Verify on a line where the two locations differ. **If the tab really is reading the wrong location, that is a `kb_` bug to report — not something to replicate.**

## ⚠ Blocker B (STILL OPEN) — the UOM conversion

The Sales Margins tab's `retrieve=` is:

```sql
SET @standard_cost = (SELECT dbo.kb_fn_pricing_convert(il.item_id, il.standard_cost, im.base_unit, :pricing_unit) ...)
...
CASE WHEN ROUND(:unit_price,4) = 0.0000 THEN 0.0
     ELSE 1 - (@standard_cost / :unit_price) END AS [Current Mgn]
```

**Three things fall out of this:**

1. **The tab has NO MAC** — Standard Cost only, plus a price ladder (50%…15% target margins). So **there is no on-screen oracle for "Percent Profit off MAC."** We define it by mirroring the Standard Cost formula with `moving_average_cost` substituted. Evan should know a rep cannot cross-check the MAC figure anywhere today.
2. **`1 - (cost/price)` returns a RATIO** (`-0.13`) — which is exactly the number in Evan's mock. He copied it off this tab. Algebraically identical to the alert's `(price-cost)/price*100`, just without the ×100. **Use percent** (matches the alert convention and the "less than 5%" language) and **warn Evan his `-0.13` will render as `-13.00`**.
3. **The earlier derivation (`cost * unit_size`) was WRONG.** The real conversion is a **UOM lookup**, not a multiply:
   `kb_fn_pricing_convert` = `amount / from_unit_size * to_unit_size`, with sizes from `p21_view_item_uom` per item. Shipping the `* unit_size` guess would have produced wrong margins on precisely the mixed-UOM lines Evan cares about.

**Open decision (asked, not yet answered):** how to source the UOM conversion —
(a) **set-based inline** in the view (join `p21_view_item_uom` twice; fastest, no new `kb_` dependency) — *recommended*;
(b) build `asi_fn_pricing_convert` (a fixed port: `DECIMAL`, not `FLOAT`);
(c) call `kb_fn_pricing_convert` directly — **rejected**: adds a new `kb_` dependency to a brand-new object.

## Phase 0 — Verify against the screen  *(reduced, but still required)*

The formula is now *known*, not guessed — but it must still reconcile to the tab before it ships.

1. Open **Sales Margins** on a Play order line. Capture: item, sales location, source location, order/pricing UOM, base UOM, sell price, Standard Cost, Current Mgn.
2. **Pick a line where the pricing unit ≠ base unit** (the conversion is a no-op otherwise) — and ideally one where **sales location ≠ source location**, to settle the location discrepancy above.
3. Run the candidate SQL against those lines; compare to the cent.

**Exit criteria:** the Standard Cost margin reconciles to the tab. (MAC has no oracle — sanity-check it against `inv_loc.moving_average_cost` by hand instead.)

## Phase 1 — View columns (P21Play)

Add via `OBJECT_DEFINITION` + CHARINDEX/STUFF + `sp_executesql` (**never `REPLACE`** — 3 leading newlines, variable whitespace).

| New column | Source | Notes |
|---|---|---|
| `price_page_description` | `price_page.description` | needs `LEFT JOIN price_page ON price_page.price_page_uid = oe_line.price_page_uid` — the **only** new join |
| `unit_mac` | `inv_loc.moving_average_cost` | `CAST(... AS DECIMAL(19,2))` |
| `unit_standard_cost` | `inv_loc.standard_cost` | `CAST(... AS DECIMAL(19,2))` |
| `percent_profit_off_mac` | formula above | `CAST(... AS DECIMAL(19,2))`, `NULLIF` on the divisor |
| `percent_profit_off_standard_cost` | formula above | ditto |

- **Use `CAST(... AS DECIMAL(19,x))`, never `p21_fn_MaskDecimal`** — it is hardcoded to return `DECIMAL(19,6)` and produces raw 6-decimal values in the email.
- Guard **every** divisor with `NULLIF(...,0)`.
- Verify: `INFORMATION_SCHEMA.COLUMNS` shows all 5; view still returns rows.

## Phase 2 — Tokens (P21Play)

Register with `p21_apply_alert_token`, then **immediately fix the description** (the proc overwrites it with the raw column formula).

`available_areas` bitmask: `4` = line item body, `11` = order header, `32` = event, `36` = 32+4, `43` = 32+11.

| Token | Action | `available_areas` | `data_type_cd` |
|---|---|---|---|
| `price_page_description` | **new** | 4 | 850 (string) |
| `unit_mac` | **new** | 4 | 851 |
| `unit_standard_cost` | **new** | 4 | 851 |
| `percent_profit_off_mac` | **new** | 36 (display **and** filter) | 851 |
| `percent_profit_off_standard_cost` | **new** | 36 (display **and** filter) | 851 |
| `sales_location_id` (110) | **existing, area 32** | ⚠ needs the header bit to render in the header — likely **43** | — |
| `primary_salesrep_name` (153) | existing, area 139 (includes header 11) | ✅ no change | — |
| `unit_price` (70) | existing, area 4 | ✅ no change — this is "Sell Price" | — |

- The two `percent_profit_*` tokens **must** carry bit `32` — they are the alert **triggers**, and filters read event-level tokens.
- **Cleanup order if a token is mis-registered:** `Alert_implementation_query` → `alert_type_x_token` → `token` (FK constraints).

**Open:** "Ship Location ID". `source_location_id` (236) exists; `ship_to_id`/`ship_to_name` are the ship-**to address**, a different thing. Confirm with Evan which he means. **Location names** (both) need a join to `location` — Evan hedged this with "if possible", so it is the first thing to cut if it threatens the timeline.

## Phase 3 — Build the two alerts (P21Play)

Clone the existing alert's filters, then diverge. Build **new**; do **not** mutate the live KOW alert.

**Common filters (from the existing alert):**
`New Order = Yes` · `Total Amount > 1000` · `Corporate Address ID ≠ 1046538` · `Product Group ID not one of OCHARGE, SAMPLES, PAD` · `Customer ID not one of 3021352, 3023035, 3023036` · `Taker does not contain ESTORE` · `Extended Standard Cost > 500`

| Alert | Trigger | Recipients |
|---|---|---|
| **A — Standard Cost** | `Percent Profit off Standard Cost < 5` | Alex Sivongsay, Order Taker, Justine Daughtery, Sales Rep |
| **B — MAC** | `Percent Profit off MAC < 5` | same **+ Pam Dundas, Alex Boeve** |

**Replace** `Line Item Profit Percentage < 5` with the new trigger in each — do not keep both, or the alert still fires on the `sales_cost` basis.

Body = Evan's mock, incl. the 2 new static Note lines (plain text, no tokens).

## Phase 4 — Test (P21Play)

1. **Formula parity** — the Phase 0 oracle lines still reconcile after the view change.
2. **Blast radius (this is the number Evan needs):** over a representative window, count lines that fire under (a) the current `line_item_profit_percentage < 5`, (b) new Alert A, (c) new Alert B. Report overlap and delta. *If the new alerts fire on 10× the lines, that is a business decision, not a bug — surface it before Prod.*
3. **Trigger a real alert** on a seeded low-margin order; inspect the **actual email**.
4. **Decimal check** — no 6-decimal values (the `MaskDecimal` trap).
5. **Divide-by-zero** — a line with `unit_price = 0` and one with `pricing_unit_size = 0` must not error.
6. **Recipients** — confirm B goes to Pam Dundas + Alex Boeve and A does not.
7. Send Evan a **live sample email** for sign-off *before* Prod.

## Phase 5 — Prod

- **One idempotent script**, Prod-baseline → target state. Play is at the Prod baseline (verified: `price_page_description` absent), so the script proven in Play is the script that runs in Prod.
- **Diff the Prod view against Play first** — standing rule; the STUFF anchors must exist in Prod.
- Off-hours. Rollback = saved prior view definition + drop tokens (child tables first).

---

## Also in scope (user's call, 2026-07-13)

**Retire `js_fn_quick_margin` → `asi_`.** `CAST(@COST/(1.0-@MARGIN) AS DECIMAL(10,2))` — price *from* a target margin, the inverse of what this alert needs, so **not** on the critical path. Two real bugs to fix in the rewrite: **divide-by-zero at margin = 1.0**, and `@COST DECIMAL(10,2)` **rounds cost to cents before the math**. Sole caller: `js_view_tool_it_pricing_general`. Retire the pair together, after the alert ships.

## Questions for Evan (batch; do not send piecemeal)

1. **"Standard Cost" in the email body — unit or extended?** His mock says `Standard Cost: $##` but his own note discusses *Extended* Standard Cost. Same for MAC.
2. **"Ship Location ID"** — source location (`oe_line.source_loc_id`) or ship-to address?
3. **Location names** — worth the extra join, or ship with IDs?
4. *(After Phase 4, with numbers)* — the new triggers fire on a **different set of lines** than today's alert. Confirm the change in volume is acceptable.

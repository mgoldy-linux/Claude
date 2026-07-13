# Low Margin Alerts — Adjustments (Evan Jenkins, 2026-06-30)

**Source email:** `C:\Users\mgoldyn\Documents\Outlook Files\Low Margin Alerts Adjustments Follow Up.msg`
**From:** Evan Jenkins (Director, Strategic Pricing) — cc Jossy Vadakkel, Erik Bullock
**Supersedes/expands:** the 2026-05-26 `price_page_description` token work (P21Training only, never deployed)

Captured here because the `.msg` is the only copy and lives outside source control.

---

## Business decisions (not dev work)

- Alerts **stay in email format** — the "inbox pressure" on Order Takers and Reps is considered the mechanism of action. Jossy to revisit in a few months.
- **The Pricing Team becomes first line of defense**, and owns each alert through to resolution.
- **Supplier Cost will NOT be added** — "it is not located in Order Entry (confirmed by CS Team)." This removes the hardest field.

## Escalation sequence (documented for context; drives the static Note lines)

1. Alert triggers (GM% off Standard Cost < 5%, or GM% off MAC < 5%)
2. Sales Rep / Order Taker confirm **Sell Price**
3. Pricing Team (Alex) confirms **price programming and Standard Cost**
4. Purchasing Team verifies **MAC**, and Supplier Cost if needed
5. Fixes: programming → Alex; cost → Alex forwards to Purchasing; MAC → Purchasing notifies Finance; Supplier Cost wrong → Supplier Cost, Standard Cost, and Pricing all updated

---

## Requirement 1 — TWO alerts, not one

Recipient lists differ by trigger, and a P21 alert has a single recipient set. This must be split into two alert definitions.

| Trigger | Recipients |
|---|---|
| GM% off **Standard Cost** on supplies **< 5%** | Alex Sivongsay, Order Taker, Justine Daughtery, Sales Rep |
| GM% off **MAC** on supplies **< 5%** | same group **plus** Pam Dundas, Alex Boeve |

**"Supplies"** = all product groups **EXCEPT** `OCHARGE`, `SAMPLES`, `PAD`.
⚠ This is Mark's working assumption — **confirm with Evan.** It decides which lines trigger at all.

## Requirement 2 — new fields in the email body

Evan highlighted these in yellow in his mock = the delta from today's alert.

| Field | Level | Source |
|---|---|---|
| Sales Rep | header | |
| Sales Location ID (number **and name** "if possible") | header | |
| Ship Location ID (number **and name** "if possible") | header | |
| Sell Price | line | |
| MAC | line | `inv_loc.moving_average_cost` |
| Standard Cost | line | `inv_loc.standard_cost` |
| Price Page Description | line | `price_page.description` (built 5/26, Training only) |
| Percent Profit off MAC | line | formula TBC |
| Percent Profit off Standard Cost | line | formula TBC |

Already present in the current alert (not highlighted, no work): Customer, Taken by, Job Number, Number of Lines, Validation, Order Qty, Req Date, Unit of Measure.

## Requirement 3 — two new static Note lines

Body text in the alert definition; **no tokens, no view change**:

> Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.

> Note: For MAC or Supplier Cost questions, please contact Purchasing Team. For Standard Cost or Sell Price questions, please contact pricingsupport@allsurfaces.com.

A third note (extended standard cost is calculated in the item's **default stocking unit**, not the order UOM) was **not** highlighted — it appears to already exist. It confirms Evan is aware of the UOM mismatch.

---

## Open questions for Evan

1. **GM% formula** — `(sell − cost) / sell` or `/ cost`? His mock shows `Percent Profit off MAC: -0.13` (a **ratio**) while the trigger says **"less than 5%"** (a percent). Wrong units = threshold off by 100×.
2. **"Supplies"** — confirm the OCHARGE / SAMPLES / PAD exclusion is the right definition.
3. **The two-alert split** — follows from his own recipient lists, but confirm he understands it's two alerts.

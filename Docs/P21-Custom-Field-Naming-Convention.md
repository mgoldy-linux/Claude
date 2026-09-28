# P21 Custom Field / Control Naming Convention

Decoder for the cryptic field names (`cb_usersd1`, `ufc_customer_ud_chain`, etc.) that show up
constantly in Prophet21 business rules, DynaChange screens, and `custom_objects_detail`.

Confirmed 2026-09-28 via:

```sql
SELECT * FROM custom_objects_detail
WHERE attribute_name = 'create' AND row_status_flag = 704
```

pulled down to one sample row per distinct prefix-before-underscore in `object_name`. Most of
the "prefixes" that come back this way (`order_`, `item_`, `qty_`, `ship_`, etc.) are **not** a
naming convention at all — they're just ordinary native P21 schema columns that happen to have
an underscore in them. Any field placed on a DynaChange screen, custom or native, gets a row in
`custom_objects_detail`, so a naive prefix split pulls in the whole schema. There are only two
naming systems that actually mean something.

## System 1 — `ufc_<table>_ud_<field>`

Bound to a real custom database column living in a `<table>_ud` companion table. This is the
well-known convention — e.g. `ufc_customer_ud_chain`, `ufc_address_ud_cutoff`,
`ufc_ship_to_ud_default_flooring_wh_loc_id`, `ufc_oe_line_ud_extended_reward`.

## System 2 — `<type>_usersd<N>`

A generic screen-slot name that DynaChange auto-assigns when a developer drops a new control
onto a screen. `N` is just a per-screen sequence number. The prefix tells you the **widget
type** — nothing about what the control is actually labeled or bound to on screen.

| Prefix | Widget type | `attribute_value` starts with |
|---|---|---|
| `cb_` | **Button** — not checkbox, despite the letters | `create button` |
| `cf_` | Compute / calculated field | `create compute` |
| `gb_` | Groupbox | `create groupbox` |
| `txt_` | Text / label field | `create text` |
| `cale$` | Calendar / date-picker button (uses `$`, not `_` — an outlier) | `create button` |

## Why this matters

A field name like `cb_usersd1` alone tells you nothing about which specific control it is or
what it says on screen — you have to check the live screen (Field Chooser) or the
`name=`/`text=`/`caption=` attributes inside `custom_objects_detail.attribute_value`'s XML to
know what it's actually bound to.

**Confirmed case:** `cb_usersd1` on the `apc_od_apply_surcharge` business rule is a **button**
(type-confirmed via this query). An earlier, unverified pass at documenting that rule had
guessed it was a "Ship checkbox" — that guess was wrong twice over: no such checkbox exists on
the Front Counter Remittances tab, and `cb_` means button regardless.

## How to apply

Whenever a business rule summary, code review, or ad hoc investigation cites a
`cb_/cf_/gb_/txt_/cale$` field, decode the widget type from the table above first, then verify
what it's actually bound to / labeled via the live screen or `attribute_value` before writing
anything into a summary doc as fact. Don't assume the letters spell out the field's purpose —
only the widget type is reliable from the prefix alone.

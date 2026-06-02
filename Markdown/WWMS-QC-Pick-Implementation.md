# WWMS QC Before Pick Completion – Reference

**Status:** Design / Review phase  
**Scope:** Location WH3 (configurable)  
**Last updated:** 2026-05-08

---

## Target State

Picked inventory must be moved to a designated QC bin and verified via a mandatory QC step before a pick can be completed. Once `oe_hdr.user_def_fld_1 = 'Y'` (QC Passed), the existing auto ship-confirm proceeds unchanged.

---

## Key P21 Fields

| Field | Table | Purpose |
|---|---|---|
| `user_def_fld_1` | `oe_hdr` | QC Passed flag (Y/N) |
| `user_def_fld_2` | `oe_hdr` | QC User |
| `user_def_fld_3` | `oe_hdr` | QC Date/Time |
| `bin_type` | `bin` | Tag bins as QC-designated (preferred over bin ID list) |

**Before using `user_def_fld_1`:** Run `SELECT DISTINCT user_def_fld_1 FROM oe_hdr WHERE location_id = 'WH3'` to confirm the field is not already in use.

---

## Roles Required

| Role | Needs Creating | Permissions |
|---|---|---|
| Warehouse | No | Pick, Move Inventory only |
| Warehouse QC | **Yes – must be created** | QC scan transaction, QC Workbench, Complete Pick |
| Warehouse Manager | No (extend existing) | All above + override authority |

---

## Business Rules

### BR 1 – Order-Level: Prevent Manual QC Flag Updates

- **Table:** `oe_hdr`
- **Event:** Before Save
- **Conditions:**
  - `user_def_fld_1` changed to 'Y'
  - `location_id IN ('WH3')`
  - Current user NOT in role WAREHOUSE_QC or WAREHOUSE_MANAGER
- **Action:** Stop with error message
- **Implementation note:** P21 has no native "current user role" object. Role check must be a SQL query against P21 security tables (e.g., `sec_user_role`) keyed on `CurrentUser`.
- **Initial state issue:** New orders will have NULL, not 'N'. A BR or system default must set `user_def_fld_1 = 'N'` on order creation at WH3. Quote-to-order conversions need separate handling as the creation BR may not fire.

### BR 2 – Shipment: QC Safety Net

- **Table:** `shipment_hdr`
- **Event:** Before Ship Confirm
- **Conditions:**
  - `oe_hdr.user_def_fld_1 <> 'Y'`
  - `shipment_hdr.location_id IN ('WH3')`
- **Action:** Stop with error: "QC must be completed before shipping."
- **Implementation note:** This BR fires on `shipment_hdr` but must check `oe_hdr`. Requires an explicit SQL lookup to `oe_hdr` via the order number on `shipment_hdr`. This is the most technically complex BR — needs a written implementation spec.

---

## WWMS Workflow Gate

Pick completion blocked unless both:
1. `bin.bin_type = 'QC'` for the inventory's current bin (prefer `bin_type` over a hardcoded bin ID list)
2. `oe_hdr.user_def_fld_1 = 'Y'`

---

## Open Build Items

| Item | Status | Notes |
|---|---|---|
| Warehouse QC role | Not created | P21 security prerequisite |
| QC Scan menu/transaction | Not defined | New custom menu item or repurposed existing? Needs build spec |
| QC Workbench | Not defined | P21 inquiry, custom view, or WWMS screen? Needs design artifact |
| QC bin type in P21 | Not native | P21 has no built-in QC bin type; use `bin.bin_type` field on bin master |
| Quote-to-order conversion | Not addressed | `user_def_fld_1` may not initialize to 'N'; needs separate BR |

---

## Open Design Questions

1. **QC at order entry vs. pick completion** — Is QC a pre-ship warehouse step, an order-entry requirement, or both? Determines where BRs fire and who is responsible.
2. **QC failure path** — What happens when QC fails? Return to reject bin? Cancel pick? Put order on hold? Manager improvisation is not acceptable here.
3. **Y→N reversal** — Should QC Passed be irreversible once set? Currently no BR blocks an authorized user from resetting the flag to 'N'. Add a condition or override-logging requirement if audit integrity requires it.
4. **QC checkbox on shipping screen** — Simpler UX alternative to `user_def_fld_1` on `oe_hdr`. Worth evaluating before committing to the user-defined field design.

---

## Happy Path

1. Warehouse picks inventory
2. Warehouse moves inventory to QC bin (`bin.bin_type = 'QC'`)
3. Pick remains open
4. QC user opens QC Workbench (filtered: `user_def_fld_1 = 'N'`, current bin = QC bin)
5. QC user performs QC scan via QC Scan transaction
6. System sets `user_def_fld_1 = 'Y'`, `user_def_fld_2` = user, `user_def_fld_3` = timestamp
7. QC user completes pick
8. Auto ship-confirm proceeds unchanged

---

## C# / BR Implementation Notes

- P21 targets **C# 7.3** — no nullable syntax, no file-scoped namespaces, no C# 8+ features
- Field access pattern: `this.Data.Fields["field_name"].FieldValue`
- Do **not** use `GetFieldByAlias`
- Role checks require SQL queries against P21 security tables; there is no native CurrentUserRole object

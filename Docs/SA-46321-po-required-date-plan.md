# SA-46321 — PO Required Date (Line + Header)

## Context

Ticket SA-46321 (Jerome Butler) asks for a rework of how Purchase Order "Required Date" is set and protected from later drift:

1. **Line level**: on PO creation, each line's Required Date should default to PO Date + the item/location's **Published** Lead Time (not Average Lead Time; shipping days already baked into the published figure). Once set, it must never change again.
2. **Header level**: on the PO's initial save, the header Required Date should be set to the **latest** of all line Required Dates. After that, it must never auto-change — not from later line Expected Date edits, not from EDI updates.

Today, P21 computes these dates in the client application layer — there is no SQL trigger doing it (checked `t_po_line_i`, `t_po_line_u`, `t_po_hdr_*`, all clean of date logic). A custom P21 Business Rule is the supported way to change this behavior.

## Research findings (P21Play, verified against live schema)

- **Header "Required Date" = `po_hdr.date_due`.** There is no `po_hdr.required_date` column. Confirmed indirectly via system setting `estimated_arrival_date_updates_po_date_due` (currently `N` in Play) — P21 already has a notion of "don't let this field auto-update from Estimated Arrival Date," which is the same class of protection requirement 2 is asking for, just not proven to cover every path (EDI, line Expected Date edits).
- **Line "Required Date" = `po_line.required_date`.** Present and distinct from `po_line.expected_date` / `expected_ship_date`.
- **"Published Lead Time" = `inventory_supplier_x_loc.manual_lead_time`.** Confirmed by reading `p21_view_supplier_purchasing_info`'s definition — a 2019 P21 feature (F72528 / P21CD-15966) explicitly added a `published_lead_time` output column defined as `NULLIF(inventory_supplier_x_loc.manual_lead_time, 0)` when `lead_time_source = 'ITEM'`. This is a real, distinct field from `average_lead_time` (Average Lead Time) on the same table — the ticket's line between the two is a genuine schema distinction, not just labeling.
- **Join path** for a given PO line to its Published Lead Time: `po_line.inv_mast_uid` + `po_hdr.vendor_id` (→ `supplier.supplier_id`) → `inventory_supplier` → `+ po_hdr.location_id` → `inventory_supplier_x_loc.manual_lead_time`. Same join P21's own view uses.
- **Hook event**: `business_rule_event_uid = 9`, `pohdrpostupdate` ("Purchase Order Update" — *"Triggered after a purchase order has been created or modified and saved to the database"*). This is the PO-side analog of `onoehdrpostupdate`, which this repo already has multiple rules built against (e.g. `_oe_order_sales_loc_id_up_v8.cs`). No separate line-only published event exists, so one rule on this single event covers both levels.

**kb_/js_ flag (unprompted, per standing rule):** while searching for existing required-date logic, found `kb_fnt_br_oe_required_date` — a live `kb_` table-valued function still doing Order Entry required-date math. It's unrelated to this PO ticket (OE, not PO) so it's out of scope here, but it's a retirement candidate for the 2026 kb_/js_ goal — worth a separate pass, logged to the KB replacement tracker when picked up.

## Open questions — RESOLVED

Sent to Jerome via SysAid; his reply and follow-up research:

1. **Lead time fallback** — CONFIRMED: if Published Lead Time (`inventory_supplier_x_loc.manual_lead_time`) is missing/0, fall back to **Average Lead Time** (`average_lead_time`) for that item/location.
2. **Calendar math** — CONFIRMED: simple math, `required_date = order_date + lead_time` in calendar days (lead time is entered in calendar days, not workdays) — but if the resulting date lands on a weekend **or a holiday**, slide forward to the next business day. Jerome's example: 10 calendar days landing on a Saturday → moves out to the following Monday (12 days).
   - **Holiday source found**: P21 has no dedicated holiday table, but `service_calendar` (originally built for service/dispatch scheduling) doubles as the company holiday calendar — `SELECT calendar_date FROM service_calendar WHERE day_type_cd = 1788` (user-supplied query; `1788` decodes to `'Holiday'` in `p21_view_code_p21`, confirmed). Verified populated 2016 through 2026-12-25 (86 rows, all `company_id = 1`, the only company in this instance) — currently maintained at least a year out, so it's a safe join target. The slide must be iterative: keep advancing a day at a time while the candidate date is a Saturday, Sunday, or a `service_calendar` holiday (handles a slide landing on a second holiday, e.g. the day after Thanksgiving).

Confirmed already (no email needed): **no backfill** — this only applies to new POs/lines going forward; existing open POs keep whatever Required Date they already have.

## Implementation approach

One multi-row business rule, `asi_po_required_date` (name to confirm), registered on `pohdrpostupdate`, doing **direct SQL UPDATEs** rather than relying on `Data.Set` write-back:

- `pohdrpostupdate` is described as firing *after* the record is already saved to the database — the same phrasing as `onoehdrpostupdate`. Memory `feedback_p21_ondemand_window_control_rules_async` only confirms Data.Set writes reach a real downstream action for *on-demand, button-attached* rules (a write that happens before some later action consumes it) — it does not establish that a genuine post-save published event's Data.Set writes get re-persisted anywhere. Direct SQL against `po_hdr`/`po_line`, keyed by `po_no`, sidesteps that uncertainty entirely and is trivially verifiable.

A small scalar helper does the weekend/holiday slide (called per row — fine at PO-line volumes):

```sql
CREATE FUNCTION dbo.asi_fn_po_next_business_day(@d DATETIME) RETURNS DATETIME
AS
BEGIN
  WHILE DATENAME(WEEKDAY, @d) IN ('Saturday','Sunday')
     OR EXISTS (SELECT 1 FROM service_calendar WHERE calendar_date = @d AND day_type_cd = 1788 AND company_id = 1)
    SET @d = DATEADD(day, 1, @d)
  RETURN @d
END
```

Logic, run every time the event fires (idempotent by design):

```sql
-- 1. Fill any line still missing its Required Date
UPDATE pl
SET required_date = dbo.asi_fn_po_next_business_day(
      DATEADD(day, ISNULL(NULLIF(isxl.manual_lead_time, 0), isxl.average_lead_time, 0), ph.order_date))
FROM po_line pl
JOIN po_hdr ph ON ph.po_no = pl.po_no
JOIN inventory_supplier ins ON ins.inv_mast_uid = pl.inv_mast_uid AND ins.supplier_id = ph.vendor_id
JOIN inventory_supplier_x_loc isxl ON isxl.inventory_supplier_uid = ins.inventory_supplier_uid AND isxl.location_id = ph.location_id
WHERE pl.po_no = @PONo AND pl.required_date IS NULL

-- 2. Fill the header Required Date once, from whatever line dates exist right now
UPDATE po_hdr
SET date_due = (SELECT MAX(required_date) FROM po_line WHERE po_no = @PONo)
WHERE po_no = @PONo AND date_due IS NULL
```

Fallback confirmed: `ISNULL(NULLIF(manual_lead_time, 0), average_lead_time, 0)` — Published Lead Time if set, else Average Lead Time, else 0 days.

The `IS NULL` guards are what deliver "never changes once set" for both levels, without needing to separately detect "is this the first save" — later re-fires of the same event (line edits, EDI updates, Expected Date changes) become no-ops. A line added later to an already-saved PO gets its own Required Date on its own first save (still governed by rule 1); the header stays frozen since `date_due` is already non-null by then.

Code style follows the established pattern in `CSharp\asi_ribbon_rm_default_products.cs`: `P21SqlConnection` for the connection, a `LogRuleError()` helper writing to `business_rule_log` (`log_action='Error'`) per `feedback_br_error_logging`, try/catch around the whole `Execute()`, `GetName()`/`GetDescription()` overrides.

## Steps

1. ~~Email Jerome~~ — done via SysAid; both questions answered and folded into the design above.
2. **Diagnostic pass**: before writing real logic, confirm how `pohdrpostupdate` actually exposes its fields — write a throwaway diagnostic rule (plain name, no `_tN` suffix, per `feedback_p21_rule_naming_diag_no_suffix`) that dumps `Data.Set` table/column structure (or confirms `Data.Fields` if single-row) to `business_rule_log`, register it on the event in P21Play, save a test PO, and read the log back — same technique already used for `qtowindowopening` and `FormPreEmail` (see `feedback_p21_multirow_event_rules`). This tells us the real field names for `po_no`, `vendor_id`, `location_id`, `order_date` before the real rule is built.
3. **Create `dbo.asi_fn_po_next_business_day`** in P21Play (and eventually Prod) — the weekend/holiday slide helper above.
4. **Build the real rule** (`asi_po_required_date` or agreed name) implementing the two guarded UPDATEs above.
5. **Register** on `pohdrpostupdate` (business_rule_event_uid 9) in P21Play.
6. **Test in Play**: 
   - New PO, 2+ lines on items with different Published Lead Times at that location → each line's Required Date = PO Date + its own published lead time; header Required Date = the max of them.
   - An item/location with no Published Lead Time set → falls back to Average Lead Time.
   - A lead time that lands on a weekend, and one that lands on a known `service_calendar` holiday → both slide to the next business day (verify against actual `service_calendar` dates, e.g. 2026-11-26/27 Thanksgiving).
   - Re-save the PO, edit a line's Expected Date → Required Date (line and header) unchanged.
   - Simulate an EDI-driven update to Expected Date → Required Date unchanged.
   - Add a new line to the already-saved PO → new line gets its own Required Date; header stays frozen.
7. **Deploy guide**: write `C:\Claude\Deploy-Guides\SA-46321-po-required-date.md` alongside the build, per established practice — include the new scalar function as a deploy artifact, not just the rule.
8. **Deploy to Prod** after Play validation; update `Work-Log.md` ticket 46321 status.

## Verification

- Manual PO creation/edit tests in P21Play as listed in step 5 — this is client-driven business-rule behavior, not something a unit test can cover; confirm through the actual PO Entry window.
- Query `business_rule_log` after each test save to confirm no errors logged and to see the diagnostic dump during step 2.
- Query `po_hdr.date_due` / `po_line.required_date` directly after each test to confirm the SQL-level guard behavior (values set once, unchanged on subsequent saves).

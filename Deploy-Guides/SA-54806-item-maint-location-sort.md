# Deployment Guide — SA 54806: Select Additional Locations popup sort

> Status: **⏸ PARKED 2026-09-15 — the rule is registered and firing in BRR (uid 169) but does NOT achieve its stated purpose.** Read "Why the ORDER BY does nothing" before touching this. It must be either finished (for the NULL fix alone) or unregistered — do not promote it to another environment expecting the popup to sort.

## Goal (as requested)

Add a sort option to the **Select Additional Locations** popup — Item Maintenance → Location List → Add Company. The grid (Company ID / Company Name / Location ID / Location Name / Selected) has no user-selectable sort.

## What was actually established

**Sorting this popup is not achievable through any customization surface available to us.** See `C:\_P25\Daily-Tasks-Summary.md` (2026-09-15) for the full elimination trail. Summary:

| Surface | Result |
|---|---|
| DynaChange Popup Designer | Not registered — no such entry in this window's RMB menu (Find Item has one) |
| `popup_column` (`default_sort_column`, `sort_descending`) | Zero rows for `d_item_maint_loc_response`; all ~150 entries are `*_popup` framework objects |
| Rule Manager / RMB rule | No hook on this window; Programmer Services offers only DW debug tooling |
| **Pre-SQL rule** | **Rule fires and rewrites the SQL correctly — the grid ignores the row order** |

**The real requirement is different.** The user wants to **add multiple locations at once**; sorting was a symptom of scanning 60+ unordered rows. Parked pending the requester's confirmation of which problem to solve.

## Artifact

- `CSharp\asi_item_maint_loc_sort_t1.cs` — Pre-SQL rule.

Two behaviours:
1. **Strips NULLs out of the `NOT IN` list** — genuinely valuable, see below.
2. **Appends `ORDER BY location.location_id`** — inert, see below.

## Target environment

**P21BusinessRules (BRR)** @ `P21Dev.allsurfaces.com` — registered as **uid 169**. Not deployed anywhere else, and should not be until the parked decision is made.

## Registration (for reference — this is how it was done)

Pre-SQL rules register **only** through the dedicated button, not the grid:

1. Tools → DynaChange™ → **DynaChange Rules** → opens **Business Rule Organizer**.
2. Click **Create Pre-SQL Rule** (bottom right, beside Import Rule).
3. Fill in:
   - **Class Name:** `--DW d_item_maint_loc_response`
   - **Rule Name:** `asi_item_maint_loc_sort_t1`
   - **Run Type:** Synchronous

**Traps:**
- Using **Import Rule**, or setting the grid row's `Rule Type` dropdown, registers it as a *standard* business rule and it never appears in the Pre-SQL picker. There is no compiled distinction between rule types — every rule derives from the same `Rule` base class; the type is purely how it is registered.
- The **Class Name must be the exact `--DS`/`--DW` identifier comment** P21 prepends to the statement, obtained from a live trace (`Sql-Scripts\Dynachange\Create-XE-ItemMaintLocPopup-Trace.sql`). Ours is a `--DW`, not a `--DS`.
- **A rebuilt DLL keeps running the old binary** until every client exits / the AppDomain is torn down. Bump `AssemblyVersion` every build — `business_rule_log.rule_assembly_name` then identifies the running binary at a glance. This cost a full diagnostic round on 9/15.

## Why the ORDER BY does nothing

The DataWindow carries its own **compiled-in sort spec** (PowerBuilder `DataWindow.Table.Sort`) that re-sorts rows *after* retrieve. Proven, not assumed:

- Full 5-column SELECT + `ORDER BY location.location_id` → `business_rule_log` shows the rewritten statement, P21 stamps `--SQL has been modified via Dynachange Rule`, SQL runs clean in SSMS → **display unchanged**.
- 2-column probe (`location_id`, `location_name` only) + same ORDER BY → **sort applied**, and rows/columns changed as expected.
- `location_name` was present in that probe, so the spec is not `location_name A`. It references one of the dropped columns — almost certainly **`company_name`** — and goes no-op when that column is absent.

`company_name` is a visible grid column. **Correct display and custom sort order are mutually exclusive.** Do not spend more rebuild cycles on this.

## What IS worth keeping — the `NOT IN` NULL fix

The stock retrieve is:

```sql
WHERE location.location_id NOT IN (100,342,NULL) AND ...
```

The DataWindow pads its `:al_LocationIdIn17` bind array with unfilled slots and expands them as literal NULLs. Under three-valued logic that is `<> 100 AND <> 342 AND <> NULL`, and `<> NULL` is UNKNOWN — **the statement returns zero rows.** Confirmed in SSMS.

The rule strips them via regex over the `NOT IN (...)` group, falling back to `NOT IN (-1)` when every entry was NULL (a new item with no locations — `NOT IN ()` is a syntax error).

**Unresolved and stated plainly:** the popup displays rows anyway, which it should not if that predicate is what actually executes. Reproduce deliberately — a new item with no locations is the likeliest case — **before** reporting it to Epicor.

## Verification

```sql
SELECT TOP 20 business_rule_log_uid, log_action, rule_name, rule_assembly_name, xml
FROM business_rule_log
WHERE rule_name = 'asi_item_maint_loc_sort_t1'
ORDER BY business_rule_log_uid DESC;
```

Compare the `Invoke` row's `sql_statement` (original) against the `Return` row's (`modifiedFlag = Y`). Check `rule_assembly_name`'s version to confirm which binary ran.

## Rollback / disposition

**Preferred if the parked decision goes to "bulk add" or "Epicor ticket":** unregister the rule. Leaving it active costs a round trip through the rule engine on every popup open for an ORDER BY that provably does nothing.

- Business Rule Organizer → find `asi_item_maint_loc_sort_t1` → set Row Status to **Inactive**, or set `row_status_flag = 705` by SQL.
- Do **not** save the rule from the Rule Manager UI — saving replaces the whole `business_rule_data_element` list (the mechanism that damaged `asi_Order_Validator` uid 133 on 9/1).

**If kept for the NULL fix only:** strip the ORDER BY from the source so the rule's purpose matches its behaviour, and rename it (`_sort_` becomes misleading).

## Related

- `Docs\P21-Item-Location-Add-Write-Recipe.md` — what Save actually writes when locations are added (the bulk-add path).
- `Sql-Scripts\Dynachange\Create-XE-ItemMaintLocPopup-Trace.sql` — the XE trace used throughout.
- `Sql-Scripts\Dynachange\SA54806-Find-Additional-Locations-Popup.sql` — the `popup_detail`/`popup_statement` lookup (dead end, kept as the record of it).

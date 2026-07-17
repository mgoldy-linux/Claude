# SQL Performance Playbook — Business Rules, Portals, Reports, Views

> Working reference for improving performance case-by-case. Applies to P21 SQL, business rules,
> portal DataWindows, and SSRS reports. Measure, never assert.

## The one decision that routes everything
> **Does this need *live* data?**
> - **Yes** → rewrite + index + concurrency (levers 1–3, 5–6). *Never* materialize on the ERP.
> - **No** (read-mostly, staleness OK) → precompute / cache / offload (lever 4).

---

## The toolkit (cheapest/safest first)

### 1. Rewrite the query/logic — usually the biggest win, live-safe
- **Kill per-row scalar UDFs** → inline as set-based joins. *The #1 killer.* Scalar UDFs serialize
  execution and block parallelism. (SA-50249: this alone was ~half the cost.)
- **Flatten nested views** — don't stack `kb_view_` on `p21_view_` on base tables.
- **Fix outer-join fan-out** — a `LEFT JOIN` that multiplies rows silently inflates everything.
- **Sargable predicates** — no `FUNCTION(col) = x`, no leading-wildcard `LIKE '%x'`, no implicit
  conversions on the indexed side.
- **Return only what's needed** — no `SELECT *`; don't fetch 60k rows to display 30.

### 2. Indexing
- Match the **access pattern**; add **covering** indexes for hot lookups; **filtered** indexes for
  narrow subsets. Check the actual plan for scans that should be seeks.

### 3. Locking / concurrency
- A **view gives NO locking advantage** over the base table — locking is set by isolation level +
  hints, not view-vs-table. (Many P21 views just embed `WITH (NOLOCK)`.)
- **RCSI / SNAPSHOT** → readers use row-versions: don't block writers, aren't blocked by them.
- `WITH (NOLOCK)` only where a **dirty read is acceptable** (display-only panels).

### 4. Precompute / cache — read-mostly, staleness OK
- Summary/history tables refreshed on a schedule (nightly/hourly).
- **Offload read-only panels to the DW** so heavy reads don't contend with order entry on the ERP.
- **Columnstore** for analytical scan+GROUP BY workloads; rowstore index for seeks.
- Pattern proven in **SA-50249** (see below).

### 5. Portal-specific
- **Keep DataWindow SQL trivial** → push all logic into an `asi_view_`. Complex SQL in a `.srd`
  `retrieve=` makes PowerBuilder fail to *build* the DataWindow → null-ref crash with NO SQL error.
- **Trim / cascade dropdowns** — filter to active/recent; make big lists depend on an earlier pick.
  (A "…wo Customer Dropdown" variant exists precisely because the full customer list was the offender.)

### 6. Business-rule-specific
- Avoid **per-row DB round-trips** in tight events; batch or cache lookups.
- Do the **minimum** in high-frequency events (field-change, save/validate).

### 7. Always — measure, don't guess
- **Logical reads / CPU from the plan-cache DMVs**, NOT wall-clock. *(Prod wall-clock has reported
  the exact opposite of the truth.)*
- Prove equivalence with **`EXCEPT` in both directions** before trusting any rewrite.
- CPU ≈ elapsed with high CPU = the scalar-UDF signature (serial, CPU-bound).

---

## Known offenders / local traps (check these first)
- **`kb_` / `js_` references** — flag every one, unprompted, even out of scope (2026 retirement goal).
  Check the *dependency chain*, not just the file — a clean-looking query over `kb_view_x` isn't clean.
- **Split commissions** — any join to `oe_hdr_salesrep` MUST filter `primary_salesrep='Y'` or it
  silently multiplies order rows (1.16M orders have 2+ reps). It has no `salesrep_name` — get that
  from `contacts`.
- **Pricing unit ≠ order unit** — convert `inv_loc` costs with `oe_line.pricing_unit_size`, never an
  `item_uom` lookup on `unit_of_measure` (inflated cost 2100× on a pallet-ordered/SF-priced item).
- **P21 flag values are full words** — `complete_flag='completed'` not `'Y'`. Wrong literal → 0 rows.
- **Positional column binding in DataWindows** — order/aliases matter.

---

## Worked example — the materialization pattern (SA-50249)
Slow report view (`asi_3yr_sales_history_report_view`): 3 per-row scalar UDFs over ~3.6M rows.
- **Baseline:** 149,547 ms CPU / 1.3M+ reads.
- **Tier 1 (view rewrite):** inline the UDFs as set-based maps → −49% CPU. Still a live view.
- **Tier 2 (materialize):** precompute nightly into a **columnstore fact table** (`ASI_ReportCache`),
  point the view at it as a passthrough (reports unchanged) → **125 ms / 2,016 reads** (~1,200×).
- Refreshed by a **post-restore Agent job** (the DW is restored from Prod nightly at 2:05 AM).
- Every step proven equal with `EXCEPT` both ways.

**When to reach for Tier 2:** heavy scan/aggregate, read from a complex view, daily freshness is fine.
**When NOT to:** anything needing live data, or anything that would tax the ERP write path.

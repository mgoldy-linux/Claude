# Recommended P21 Performance Fixes
**Date:** 2026-08-12
**Prepared by:** Mark Goldyn
**Trigger:** User reports of general P21 slowness

## Method

Checked P21 Prod (`P21.allsurfaces.com`) two ways:
1. **Live snapshot** of active requests, blocking chains, and waits — catches anything stuck *right now*.
2. **Plan-cache DMV sweep** (`sys.dm_exec_query_stats`), ranked by total logical reads/CPU — catches chronic offenders regardless of whether they're blocking anyone at read time.

No blocking was found at the moment of the check, which means the complaints are either intermittent spikes or cumulative load from high-frequency queries rather than one query stuck holding a lock. The findings below are ranked by realistic performance impact — how much load each item removes and how directly it maps to what users would feel.

---

## Ranked Recommendations

### 1. Rewrite the order-validator freight lookup (`kb_fnt_br_shipto_info`) — Highest impact
- **What it is:** A legacy table-valued function called from the order-entry validation business rule (`kb_fnt_br_order_validator_v2` / `kb_fnt_br_order_validator`) on every order save/line validation.
- **Measured cost:** 27,935 executions in the current plan-cache window, 21.6M total logical reads, ~5.2ms CPU per call (774 reads/call). Row-by-row execution pattern instead of set-based.
- **Why it's #1:** It fires on the order-entry path — the single most frequent, most user-visible workflow in P21. Every rep placing or editing an order pays this cost. Fixing it directly improves the transaction people feel slowness in most.
- **Bonus:** It's a legacy `kb_` object (owner departed in 2026 KB/JS retirement effort) that itself chains to two more `kb_` objects (`kb_fn_number_shorten`, `kb_view_carrier`) — fixing it also retires a small dependency chain.
- **Status:** Rewrite is already queued in an existing project, currently blocked on an unrelated Atlas surcharge DLL CAS error. Recommend prioritizing once that block clears.
- **Effort:** Medium — inline the TVF logic as a set-based join, validate with `EXCEPT` both directions before deploying.

### 2. Stand up recurring performance monitoring — Highest leverage, lowest effort
- **What it is:** A scheduled capture of the same two checks (blocking snapshot + plan-cache top offenders) run every 15–30 minutes, or manually triggered when a complaint comes in.
- **Why it matters:** The single point-in-time check we ran found no active blocking — meaning the actual moment of user pain was missed. Without a live capture running *during* a complaint, root cause is guesswork. This doesn't fix performance directly, but it's the fastest way to convert "P21 feels slow" into a specific, provable query.
- **Effort:** Low — the two diagnostic queries already exist (`Sql-Scripts\Check-Current-Blocking-Prod.sql`, `Sql-Scripts\Check-Top-Offenders-PlanCache-Prod.sql`); wrapping them in a scheduled job with logging is a small build.

### 3. Broader KB/JS retirement audit, prioritized by measured cost — Ongoing, compounding impact
- **What it is:** Continue the existing KB/JS retirement initiative, but prioritize objects by measured plan-cache cost (reads/CPU) rather than "last modified" or DMV usage stats alone.
- **Why it matters:** `kb_fnt_br_shipto_info` looked inactive in the June DMV-based audit (`KB-Function-Analysis.md`) due to a known tracking gap for table-valued functions — it turned out to be live and costly once measured directly. That gap likely hides other real offenders in the remaining ~20 TVFs still marked "Investigate." Each one is a candidate for the same order-of-magnitude win as #1.
- **Effort:** Low to start (repeat this same plan-cache method against the rest of the "Investigate" list), medium per fix depending on complexity.

---

## Not Recommended / No Action Needed

- **Native P21 core queries** (`inv_loc` inventory updates, `audit_trail` inserts) — these are the two highest-volume items in the plan cache by raw execution count, but they're native ERP write-path code. Not something we own or should touch; high volume here is expected and healthy.

---

## Summary for Leadership

| Rank | Fix | Impact | Effort | Status |
|---|---|---|---|---|
| 1 | Rewrite `kb_fnt_br_shipto_info` (order validator) | High — hits every order save | Medium | Blocked on unrelated issue; ready once cleared |
| 2 | Recurring perf monitoring | High leverage for diagnosis | Low | Not started |
| 3 | Cost-ranked KB/JS audit | Compounding, ongoing | Low–Medium | Not started |

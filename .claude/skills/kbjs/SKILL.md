---
name: kbjs
description: Audit code for leftover kb_ / js_ references and recommend measured performance improvements. Use when the user shares SQL, a business rule, a portal .srd, a report, or a PowerShell script and wants it checked before it ships — or whenever code is being touched anyway.
---

# kb_ / js_ + Performance Audit

Two jobs, every time. Do **both** even if the user only asked about one, and even if the finding is outside the immediate task.

KB and JS both left the company. Retiring their objects is an explicit 2026 goal, and the standing rule is: *"if I touch something I want to ensure it is up to date and best performance."* Code already open for edit is the cheapest moment to fix both — a missed reference survives another release.

## 1. Flag every `kb_` and `js_` reference

Search the code and everything it depends on. A view can hide a `kb_` call two levels down — check object definitions, not just the file in front of you.

```
rg -i '\b(kb_|js_)\w+'
```

For SQL, also expand the dependency chain — a clean-looking query over `kb_view_x` is not clean:

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('<object>'));   -- read what the view/proc actually does
```

Report every hit **by name**, say what it is (view / scalar UDF / table), and propose a specific replacement. Do not silently leave one in place. Recommend, then let the user decide scope — do not expand the change on your own.

When a reference is actually replaced, log it per the KB replacement tracker convention.

### Replacements already established
| KB object | Replaced with |
|---|---|
| `kb_view_open_orders` | `oe_hdr` + `oe_line` + `oe_line_ud` + `inv_mast` + `customer` + `oe_hdr_salesrep` |
| `kb_view_salesrep` | `contacts` + `contacts_ud` — it is only a wrapper over `contacts` (`salesrep_id` = `contacts.id`) |
| `kb_fnt_get_user_loc` | `asi_fnt_get_user_loc` |
| `kb_view_item_classifications_loc100` | `inv_mast` + `price_family` |
| `kb_view_users` (price_family_id) | `users_ud` |
| `kb_SQLHelper` | `P21SqlConnection` + native `business_rule_log` |

New replacement logic belongs in an `asi_view_*` / `asi_fnt_*` object, with grants to `p21_application_role` and `PxxiUser`.

## 2. Always recommend performance improvements

Volunteer them; don't wait to be asked.

### Measure, never assert
This is the part that goes wrong. Reasoning about a plan is not evidence.

**Prove equivalence first.** Never ship a rewrite without it:
```sql
WITH old AS (<original>), new AS (<rewrite>)
SELECT (SELECT COUNT(*) FROM old) AS old_rows,
       (SELECT COUNT(*) FROM new) AS new_rows,
       (SELECT COUNT(*) FROM (SELECT * FROM old EXCEPT SELECT * FROM new) a) AS in_old_not_new,
       (SELECT COUNT(*) FROM (SELECT * FROM new EXCEPT SELECT * FROM old) b) AS in_new_not_old;
```

**Then measure with load-independent numbers.** Tag the queries and read the plan cache — logical reads and CPU, *not* wall-clock. Prod load makes elapsed time meaningless (it has reported the exact opposite of the truth):
```sql
SELECT qs.execution_count,
       qs.total_worker_time  / qs.execution_count / 1000 AS avg_cpu_ms,
       qs.total_logical_reads/ qs.execution_count        AS avg_logical_reads
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
WHERE t.text LIKE '%<tag>%';
```

**Report honestly.** If the rewrite is not faster, say so. If your stated reason for the gain was wrong, correct it — SQL Server prunes unused scalar UDFs and correlated subqueries out of a view, so "the view has a UDF in it" is often not the cost.

### What to actually look for
- **Dead joins** — joined but never referenced in the SELECT or WHERE. Common when a query sits on a view that already contains the table. This is usually where the real win is.
- **Row multiplication** — any join that can return >1 row per key.
- **Scalar UDFs** in a SELECT list; row-by-row, can block parallelism (but verify it isn't already pruned).
- **Non-sargable predicates** — `CONVERT()` / functions on the *column* side of a comparison.
- Missing `WITH(NOLOCK)` where the shop's other read-only reporting queries use it.

## P21 traps that have already bitten — check these
- **`oe_hdr_salesrep` split commissions.** It has one row *per rep per order* (1.16M orders have 2 reps, some 5). Any join to it **must** filter `primary_salesrep = 'Y'` or it silently multiplies rows. It has **no `salesrep_name`** — get that from `contacts`.
- **Portal `.srd` DataWindow SQL must stay trivial.** The `retrieve=` SQL is parsed by PowerBuilder to *build* the DataWindow object. Nested `CASE`/`COALESCE`/`NULLIF` or an `IN (SELECT …)` makes PB fail to construct the element — a null-ref crash in `SelectElement` with **no SQL error, because the query never runs.** Put all logic in an `asi_view_*`; keep the `.srd` to plain column references. Deploy the view **first**.
- **DataWindows bind result columns by POSITION, not name.** Reordering the SELECT lands data in the wrong columns silently.
- **`users.delete_flag` in Play is not representative** — Play's refresh flags most accounts as deleted. Never size a user-based filter from Play; use Prod.

## Output
Lead with the `kb_`/`js_` hits (or state plainly that there are none), then the performance findings with the measured numbers behind them. Flag anything you could not verify rather than asserting it.

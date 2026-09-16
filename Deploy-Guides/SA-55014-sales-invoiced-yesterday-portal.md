# Deployment Guide — SA-55014 BR SAL Sales Invoiced Yesterday Portal (kb_ retirement)

> Produced during development. Update as the artifact changes; commit with the code.

**Status: 🟡 Deployed to Prod 2026-09-16, engineering-verified — awaiting feedback from the end
user (John) before this is actually closed out.** Old `.srd` kept by the user for rollback.

## Request
Existing portal (built by Karen Benish, 2016) shows John yesterday's invoiced sales for his
assigned location(s), optionally filtered by manufacturer (`:mfg` retrieval argument). Ask for
this session: convert the `.srd`'s `retrieve=` SQL into a runnable SSMS query, then work through
its `kb_` dependency chain per the standing 2026 KB-retirement goal — not a functional change to
the portal's behavior.

## Artifact(s)
- `dbo.asi_fnt_sa55014_sales_invoiced_yesterday(@user_id, @mfg)` — new inline table-valued
  function, all query logic lives here now.
- The existing portal's `.srd` (`BR SAL SALES INVOICED YESTERDAY`) — `retrieve=` SQL replaced
  with a single trivial call into the new TVF. No column layout change, no new
  `portal_element`/`dc_nav_drill` rows (this is an edit to an existing portal, not a new one).
- Ticket: SA-55014

**⚠️ Not yet committed to the repo.** The TVF creation script, the `.srd` retrieve SQL, and the
`EXCEPT` verification script only exist in this session's scratch folder and clipboard history.
They need to be written into `Portals\SA-55014\` (mirroring the `Portals\SA-53270\` pattern)
before this guide's artifact list is actually backed by anything durable. Do this before/at the
next touch of this ticket.

## kb_ objects retired
| kb_ object | Replaced with |
|---|---|
| `kb_sales_history_report_view` | Hand-ported into the TVF — only the ~16 columns this portal actually selects (of 130+ on the mega-view) were traced back and rebuilt from native P21 tables/views |
| `kb_view_invoice_line_rewards` | `cte_incentive_rewards` inside the TVF — only `incentive_rewards` ported (coop/auto/oe reward columns unused by this portal) |
| `kb_fn_date_rng_calc` | Inline `DATEADD(DAY,-1,CAST(GETDATE() AS DATE))` / `CAST(GETDATE() AS DATE)`, computed once in a `cte_dates` CTE and reused everywhere |
| `kb_fnt_get_user_loc` | `asi_fnt_get_user_loc` (already-established replacement, 3rd portal to use it — see `kb-replacement-tracker.csv`) |

`kb_fn_get_sales_manager`, `kb_fn_get_sales_manager_names`, `kb_fn_get_product_manager`, and
`kb_view_direct_invoices_incl_rebills` (also referenced inside `kb_sales_history_report_view`)
were **deliberately left untouched** — they feed `manager_name`/`product_manager_id`/
`direct_flag`, columns this portal never selects. Flagged, not in scope.

## Why a TVF, not a view
The user was explicit: no new persisted views for this retirement work. That's normally fine —
the standard pattern is "put all logic in an `asi_view_*`, keep the `.srd` trivial" (see
`feedback_p21_portal_datawindow_sql_simple.md`) — but a plain `VIEW` can't accept the `<user_id>`
runtime placeholder P21 substitutes into the `.srd`'s SQL text at request time (real per-user
location filtering). A view would either never get the placeholder substituted (hardcode it,
matches nobody) or would have to hardcode one specific user (breaks for everyone else). An
**inline** table-valued function (`RETURNS TABLE AS RETURN (single SELECT)`) solves this — it
accepts `@user_id`/`@mfg` as real parameters, stays foldable into the caller's plan (no
`DECLARE`/multi-statement body), and the `.srd` stays exactly as trivial as the view pattern
would have made it: `SELECT <cols> FROM dbo.asi_fnt_sa55014_sales_invoiced_yesterday('<user_id>', :mfg)`.

This mattered concretely: the rewritten query (5 CTEs + `CROSS APPLY` + ~150 lines of nested
`CASE`, once the mega-view's pricing logic got inlined) is exactly the shape that crashes
PowerBuilder's DataWindow painter if pasted directly into a `.srd` (`SelectElement`, no SQL error
surfaced — see the DataWindow trap memory). Keeping all of it inside the TVF avoided that
entirely; the `.srd` never sees anything but the one-line function call.

## Verification
- `EXCEPT` both directions, original `kb_sales_history_report_view`-based query vs. the new TVF,
  run against **Prod**: **439 = 439 rows, 0 differences either direction.**
- Post-deploy, live-checked against an independent SSMS query for a second real user (`mgoldyn`):
  **192 rows, matched.**
- Portal loaded clean in P21Play with no errors before Prod (confirms the `.srd` parses — but
  Play's stale data meant it couldn't actually render rows, so this only ruled out the
  PowerBuilder-crash risk, not correctness).

## Performance (wall-clock only — not the DMV logical-reads/CPU method the standing perf rule
calls for; ad hoc SSMS timing during iteration, ~439-row result set each time, so treat as
directional not authoritative)
| Step | Time |
|---|---|
| Original, through `kb_sales_history_report_view` | 1:30 |
| Naive full native port | 4:39 (regression — see below) |
| CTEs scoped to yesterday's date range | 1:41 |
| + CTEs also scoped to the user's location | 1:18 |
| + `COALESCE(a,b,0) IN (...)` join predicates rewritten to sargable `OR` (3 spots) | **0:42** |

The 4:39 regression: the first native port faithfully replicated `kb_sales_history_report_view`'s
own `drv_sumlines` / `kb_view_invoice_line_rewards` pattern — an unfiltered aggregate over the
*entire* invoice history, joined back per row. That design flaw was already in the original
mega-view; the rewrite just made it visible instead of buried inside a view. Fixed by scoping the
aggregating CTEs to only the rows that can possibly match the outer query (same date range +
location), carefully preserving two correctness-sensitive full-history aggregates that must stay
unfiltered: whether an order line was *ever* split across multiple invoices (lifetime property,
not a yesterday-only one), and lot-bill child-row sums (scoped by date/location only because
children always share their parent's exact `invoice_hdr` row).

## Target environments
Play (`P21Play` @ `P21Dev.allsurfaces.com`, smoke-test only — stale data, couldn't verify
correctness there) → Prod (`P21` @ `P21.allsurfaces.com`)

## Deploy steps
1. Run the `CREATE OR ALTER FUNCTION` script for `dbo.asi_fnt_sa55014_sales_invoiced_yesterday`
   against the target environment, including both grants:
   ```sql
   GRANT SELECT ON dbo.asi_fnt_sa55014_sales_invoiced_yesterday TO p21_application_role;
   GRANT SELECT ON dbo.asi_fnt_sa55014_sales_invoiced_yesterday TO PxxiUser;
   ```
   (First draft of this script only had `p21_application_role` — caught by the user. See
   `feedback_p21_new_object_execute_grant.md`.)
2. In InfoMaker, update the existing portal's `retrieve=` SQL to:
   `SELECT <cols> FROM dbo.asi_fnt_sa55014_sales_invoiced_yesterday('<user_id>', :mfg)` — the
   `mfg` argument is declared through InfoMaker's Retrieval Arguments dialog, not typed as text.
3. Save/deploy the `.srd` to the target environment's portal share.

### Play — done, smoke-tested only
TVF deployed, `.srd` updated, opened clean in the P21 client with no errors. Could not verify
actual row output — Play's data hadn't refreshed recently enough to have "yesterday" rows.

### Prod — DONE 2026-09-16
TVF deployed, `.srd` updated. User confirmed live: portal renders, `EXCEPT`-proven-equivalent to
the old query, and a second real user's live row count (192, `mgoldyn`) matched an independent
SSMS check.

## Rollback
Old `.srd` kept by the user (not repo-tracked as of this guide — confirm its location before
relying on it). To roll back: restore the old `.srd` to the Prod portal share; the new TVF can be
left in place (unused, harmless) or dropped:
```sql
DROP FUNCTION dbo.asi_fnt_sa55014_sales_invoiced_yesterday;
```

## Open items
- [ ] **Get John's sign-off** that the live Prod numbers look right — this is the actual blocker
      on calling the ticket closed.
- [ ] **Commit the TVF/`.srd`/`EXCEPT`-verification scripts to `Portals\SA-55014\`** — currently
      only in scratch/clipboard history, not durable.
- [x] `EXCEPT` equivalence proof against Prod (0/0, 439=439).
- [x] Live spot-check against a second real user post-deploy (mgoldyn, 192 rows).
- [x] `kb-replacement-tracker.csv` updated (4 rows).
- [x] SysAid ticket note drafted and copied to clipboard for pasting.

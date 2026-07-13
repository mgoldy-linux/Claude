# Deployment Guide — SA-48732 CSR Open Order Team portal

> Produced during development. Update as the artifact changes; commit with the code.

## Request
Justine Daugherty (`JDAUGHERTY`) needs a portal to monitor her team's assigned open orders.
- Name: `CSR Open Order Team`
- Copy of: `Open Orders mine`
- Add Taker column
- Filter to orders whose **taker** is in the CSR or CSR Manager role

## Artifact(s)
All in `C:\Claude\Portals\SA-48732\`:
- `csr_open_order_team.retrieve.sql` — **the source of truth for the query.** Edit this, then rebuild.
- `Build-CsrOpenOrderTeam-Srd.ps1` — injects the SQL into the `.srd` (validates it contains no `"`,
  which would break the DataWindow string)
- `csr_open_order_team.BASE.srd` — pristine baseline (the unmodified Prod clone); never edit
- `csr_open_order_team.srd` — **generated**; deploy this one
- `Register-CsrOpenOrderTeam-Play.sql` — creates the portal element (idempotent, has rollback)
- Portal element `CSR OPEN ORDER TEAM` (`classname = n_cst_pe_user_def`)
- Ticket: SA-48732

### ⚠ The DataWindow binds columns by POSITION, not by name
The `.srd` column bindings still carry `dbname="kb_view_open_orders.taker"` etc. — that metadata is
stale and harmless (the original portal already had a `dbname` that didn't match its SELECT). What
matters is that the SELECT returns **the same 19 columns in the same order**. If you reorder or
add columns to the SQL, the DataWindow will bind the wrong data to the wrong column with no error.
Verified aligned: srd position 1 `users_ud_taker` ← sql `taker`, then 18 exact name matches.

## Starting state (found 2026-07-13 — read before deploying)
The portal was **already created in Prod on 2026-06-26 by `mgoldyn`** (element uid **324**, `.srd` on
`\\asp21fs1\Prod\Portals`), but it is an **unmodified clone** of `my_open_orders.srd` — the only
difference in the whole file is the export header and one column width (`salesrep` char(40)→char(65)).
It went straight to Prod with no Play test. It is not yet assigned to any user or role, so it is
currently inert — nobody sees it.

This deploy replaces that clone's SQL. **No Prod DB change is required** — element 324 already points at
`csr_open_order_team` in `\\asp21fs1\Prod\Portals`. Only the `.srd` file needs to be overwritten.

## What changed in the SQL
| | Before (inherited "mine" logic) | After |
|---|---|---|
| Filter | `taker = me OR salesrep = me OR sales-manager = me OR product-manager = me` | `taker IN (Customer Service + Customer Service Manager users)` |
| Roster | n/a | resolved at query time from `users` ⋈ `roles`, so role changes need no portal edit |
| Excluded | — | `ECOMM`, `ESTORE`, `SHAGTOOLS` (integration accounts; 547 Prod lines that would swamp the team's real work) + inactive users (`delete_flag = 'N'`) |
| Joins dropped | — | `INNER JOIN inv_mast`, `LEFT JOIN contacts AS manager_contact` |
| Taker column | already present & visible (`users_ud_taker`, header `text="Taker"`) — inherited from `Open Orders mine`, **no change needed** | unchanged |

## KB retirement — the portal is now 100% `kb_`-free
The base views were also replaced (scope added 2026-07-13 at the requester's direction — "if I touch
something I want it up to date and best performance"). All four `kb_` dependencies are gone:

| KB object | Replaced with |
|---|---|
| `kb_view_open_orders` | `oe_hdr` + `oe_line` + `oe_line_ud` + `inv_mast` + `customer` + `oe_hdr_salesrep` |
| `kb_view_salesrep` | `contacts` + `contacts_ud` (it was only ever a wrapper over `contacts`; the portal used just `salesrep_id` + `salesrep_name`) |
| `kb_fn_get_sales_manager` | dropped — only referenced by the old viewer filter |
| `kb_fn_get_product_manager` | dropped — only referenced by the old viewer filter |

### ⚠ The two views originally proposed do NOT work — don't retry them
- **`p21_view_GetOpenOrders`** is header-level, 10 columns. It supplies only 4 of the 19 the portal needs
  (no `taker`, `line_no`, `qty_open`, `item_id`). The portal is one row per order *line*; this view
  cannot express that.
- **`p21_view_oe_hdr_salesrep`** has **no `salesrep_name`** — the only thing the portal wants from a
  salesrep source. Worse, it carries **split commissions** (1.16M orders have 2 reps, 238K have 3, some
  have 5), so joining it naively **multiplies order lines**.

### The split-commission trap (critical)
`kb_view_open_orders` avoided that duplication with `oe_hdr_salesrep.primary_salesrep = 'Y'`. The
replacement keeps it as `INNER JOIN oe_hdr_salesrep AS ohsr ON ... AND ohsr.primary_salesrep = 'Y'`.
**Do not remove that predicate** — row counts will silently inflate.

### Dead joins removed
The old query re-joined `oe_line` and `oe_hdr` on top of a view that already contained both. The
`oe_hdr` join (`oeh`) was referenced nowhere in the SELECT at all. The `inv_mast` join existed only to
feed `commission_class_id` into the sales-manager lookup — verified on Prod that dropping it changes
nothing (identical row count with and without).

### Equivalence — proven, not assumed
`EXCEPT` in both directions against the live `kb_` query on Prod: **6,881 rows each, 0 rows in
`kb` not in `asi`, 0 rows in `asi` not in `kb`.** Re-verify this if the query is ever touched again.

### Performance (measured on Prod, plan-cache DMVs)
| | CPU | Elapsed | Logical reads |
|---|---:|---:|---:|
| `kb_view` (old) | 1,004 ms | 1,444 ms | 222,420 |
| base-table (new) | 1,092 ms | 1,345 ms | **163,484** |

**The durable win is I/O: ~27% fewer logical reads.** CPU is a wash (marginally worse). Elapsed swings
with Prod load — don't trust wall-clock here; logical reads is the stable metric.

Note SQL Server *prunes* the unused scalar UDF (`kb_fn_get_sales_manager_value`) and the three
correlated `disposition` subqueries out of `kb_view_open_orders`, so those cost nothing in practice —
they were **not** the source of the gain. The gain came from dropping the dead joins.

## Roles the filter resolves to
`Customer Service` (role_uid **7**) + `Customer Service Manager` (role_uid **23**) — there is no role
literally named "CSR". 14 active humans after excluding the 3 integration accounts.

## Inactive users are excluded — `u.delete_flag = 'N'` (settled 2026-07-13)
Only **active** P21 accounts are in the roster, so a departed CSR's orders drop off the portal
automatically. Briefly trialled removing this filter, then reverted — keep it.

**Do not size this filter from Play.** Play's refresh flags most user accounts as deleted, so dropping
`delete_flag` there swings the result 2,142 → 9,299 rows and makes the filter look far more consequential
than it is. In Prod it excludes just **11 open order lines** across 39 departed users. Prod is
authoritative for any row-count question on this portal.

There is a second `delete_flag = 'N'` in the SQL, on `oe_pick_ticket` — that one excludes deleted pick
tickets, is unrelated, and stays.

## Target environments
Play (`P21Play` @ `P21Dev.allsurfaces.com`) → Prod (`P21` @ `P21.allsurfaces.com`)

## ⚠ portal_element_uid is NOT aligned across instances
Prod uid **324** = `CSR OPEN ORDER TEAM`, but Play uid **324** = `PURCHASING BOP ORDER DETAIL`.
**Always match portal elements by `portal_element_name`, never by uid, when promoting.**

Also note `portal_element.portal_element_uid` is **not** an identity column (supply it explicitly);
`portal_user_defined.portal_user_defined_uid` **is**. `portal_cd = 932` is a constant classifier for
every `n_cst_pe_user_def` element — it is not a per-element key.

## Deploy steps

### Play — DONE 2026-07-13
1. `.srd` staged → `\\ASP21FS1\play\Portals\csr_open_order_team.srd`
2. Element registered via `Register-CsrOpenOrderTeam-Play.sql` → **uid 333**, `portal_user_defined_uid` 321
3. Restart the P21 client (portal definitions are cached at login)
4. Assign the portal to a test user in Dynachange → open it → verify

### Prod — PENDING acceptance on Play
1. Back up the current Prod file:
   `\\asp21fs1\Prod\Portals\csr_open_order_team.srd` → keep a dated copy
2. Copy the new `.srd` over it (same filename)
3. **No DB change** — element 324 already resolves to this file
4. Assign the portal to Justine (`JDAUGHERTY`, role `ALL`) and/or the CS Manager role via Dynachange
5. Users must restart the P21 client to pick it up

## Verification
- SQL extracted from the `.srd` runs clean on Play: **2,142 rows**, all 19 columns bind, every taker
  returned is Customer Service / CS Manager. (Play shows only 3 CSR takers — stale refresh, see above.)
- Prod expected volume: **~6,817 open order lines** across the 14 active CSRs.
- In the portal: the **Taker** column is the first column; every value should be an active CSR or CS
  Manager. No `E COMM` / `E Store` / `Shag Tools` rows, and no `** LEFT … **` names.
- DB→file linkage resolves: `library_file + '\' + datawindow_name + '.srd'` → `Test-Path` = True.

## Rollback
- **Play:** `DELETE FROM portal_user_defined WHERE portal_element_uid = 333;`
  `DELETE FROM portal_element WHERE portal_element_uid = 333;` then delete the `.srd`.
- **Prod:** restore the dated backup of `csr_open_order_team.srd`. Since element 324 is not yet assigned
  to anyone, a bad deploy is invisible to users until it is assigned — assign last.

## Open items
- [ ] Confirm with Justine that the existing **Taker** column is what she meant (it was already on
      `Open Orders mine`, which is why "add Taker column" may have been a misread of the source portal).
- [ ] Decide who the portal is assigned to: Justine only, or the whole CS Manager role.
- [ ] `kb-replacement-tracker.csv` — log the two dropped `kb_fn_get_*` references. **The tracker file
      could not be found on disk**; path needs to be re-established.

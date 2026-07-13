# Deployment Guide — SA-48732 CSR Open Order Team portal

> Produced during development. Update as the artifact changes; commit with the code.

## Request
Justine Daugherty (`JDAUGHERTY`) needs a portal to monitor her team's assigned open orders.
- Name: `CSR Open Order Team`
- Copy of: `Open Orders mine`
- Add Taker column
- Filter to orders whose **taker** is in the CSR or CSR Manager role

## Artifact(s)
- `csr_open_order_team.srd` — Dynachange portal DataWindow (UTF-16LE, PBExportHeader)
- Portal element `CSR OPEN ORDER TEAM` (`classname = n_cst_pe_user_def`)
- Ticket: SA-48732

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
| Excluded | — | `ECOMM`, `ESTORE`, `SHAGTOOLS` (integration accounts; 547 Prod lines that would swamp the team's real work) |
| Inactive users | — | **Included by design** (no `delete_flag` filter) — see below |
| Joins dropped | — | `INNER JOIN inv_mast`, `LEFT JOIN contacts AS manager_contact` |
| Taker column | already present & visible (`users_ud_taker`, header `text="Taker"`) — inherited from `Open Orders mine`, **no change needed** | unchanged |

Dropping the viewer filter removed the only references to **`kb_fn_get_sales_manager`** and
**`kb_fn_get_product_manager`** — two fewer `kb_` dependencies. The portal still uses
`kb_view_open_orders` and `kb_view_salesrep` (future retirement candidates).

The `inv_mast` join existed only to feed `im.commission_class_id` into the sales-manager lookup.
Verified on Prod that dropping it changes nothing: row count **6,835 with and without it**.

## Roles the filter resolves to
`Customer Service` (role_uid **7**) + `Customer Service Manager` (role_uid **23**) — there is no role
literally named "CSR". 14 active humans after excluding the 3 integration accounts.

## Inactive users are deliberately included (changed 2026-07-13)
The `u.delete_flag = 'N'` filter was **removed at the requester's direction**. Open orders left behind by
CSRs who have left the company stay visible, so they don't go unwatched — which is arguably the point of
a team-monitoring portal. Their taker name renders as `** LEFT 08/2025 ** Christopher Wheeler`, so
orphaned orders are self-labelling in the Taker column.

Impact is small: there are **39 departed/inactive users** across the two roles, holding **11 open order
lines** in Prod (6,816 → 6,827).

**Do not size this change from Play.** Play's refresh deactivates most user accounts, so removing the
filter there swings the result from 2,142 → 9,299 rows. That is a Play artifact, not real behavior. Prod
is authoritative.

The remaining `delete_flag = 'N'` in the SQL is on `oe_pick_ticket` (excludes deleted pick tickets) and
is unrelated — leave it.

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
- SQL extracted from the `.srd` runs clean on Play: **9,299 rows**, all 19 columns bind, every taker
  returned is Customer Service / CS Manager (incl. departed ones, as intended).
- Prod expected volume: **~6,827 open order lines** across the 14 active CSRs + 11 orphaned lines from
  departed CSRs.
- In the portal: the **Taker** column is the first column; every value should be a CSR or CS Manager,
  and no `E COMM` / `E Store` / `Shag Tools` rows should appear. Orders from departed staff will show a
  taker name prefixed `** LEFT … **`.
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

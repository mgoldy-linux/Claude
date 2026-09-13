# Waiting on Info — updated Wednesday 9/9

Items parked here are blocked on someone else (Epicor, IT, a reviewer) or a date gate.
Move back to `Todo-Tomorrow.md` once unblocked.

---

## Scheduler setup for Business Rules

**Blocked on:** IT to verify API access → then Epicor. Epicor case **CS0005626127** submitted 8/28 (awaiting reply). SysAid **53769** (AHI-API1$ share access) still open.

1. Fix the error in P21 Business Rules — same Epicor/IT dependency; nothing to do until they respond.
2. Resolve the no-output-from-the-job issue; open case with Epicor — waiting on IT to verify API access before opening Epicor case. Case reframed: Save Session writes output files, Auto-Buy writes nothing but logs Success (unverified, contradicts finalized doc).

---

## Low Margin alerts — show whether the price was edited

**Blocked on:** Evan (out of office until **9/14**).

Answered: yes, and free. `<price_edit>` renders `Y`/`N` with no view change; already live in the Play Team alert. Reply drafted to Evan asking wording + placement — waiting on his answer before doing anything else.

---

## inv_loc replenishment bulk update — Prod rollout

**Blocked on:** Purchasing team's sign-off after testing the batch update on P21Training (running now/next).

Prod pre-flight checklist once approval comes (full list in memory — `project_2026_09_11_inv_loc_replenishment_batch_update.md`):
1. Re-run impact-counts + iva_taxable_flag/usage_lock side-effect checks against Prod itself (don't reuse Dev/Training numbers)
2. Re-verify `'Up To'` spelling / `safety_stock_type=0` semantics on Prod
3. Take rollback image (`zz_inv_loc_bkp_<date>`) before any write
4. Confirm Purchasing's Training sign-off covers the full population, not just the 10-item spot-check
5. Schedule a low-traffic window; re-estimate batch count off Prod's real row count
6. Confirm batch-runner login has UPDATE rights on Prod `inv_loc`
7. Post-run spot checks + built-in verify-zero-remaining check

**Watch for:** if P21Training gets refreshed from Prod before Purchasing finishes testing, the applied change is wiped and the Training run has to be redone.

---

## Low Margin Alert — 9/3 prep (date-gated)

Not blocked on info; gated to **9/3** for Evan's confirmed **9/4** go-live.

- Re-confirm recipients on `alert_implementation` 104/105/106/107 still match the 8/28 reconciliation
- Decide on BCC-to-self
- Flip `row_status_flag` 705 → 704

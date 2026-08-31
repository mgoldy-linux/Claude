# Waiting on Info — updated Monday 8/31

Items parked here are blocked on someone else (Epicor, IT, a reviewer) or a date gate.
Move back to `Todo-Tomorrow.md` once unblocked.

---

## Scheduler setup for Business Rules

**Blocked on:** IT to verify API access → then Epicor. Epicor case **CS0005626127** submitted 8/28 (awaiting reply). SysAid **53769** (AHI-API1$ share access) still open.

1. Fix the error in P21 Business Rules — same Epicor/IT dependency; nothing to do until they respond.
2. Resolve the no-output-from-the-job issue; open case with Epicor — waiting on IT to verify API access before opening Epicor case. Case reframed: Save Session writes output files, Auto-Buy writes nothing but logs Success (unverified, contradicts finalized doc).

---

## Low Margin Alert — 9/3 prep (date-gated)

Not blocked on info; gated to **9/3** for Evan's confirmed **9/4** go-live.

- Re-confirm recipients on `alert_implementation` 104/105/106/107 still match the 8/28 reconciliation
- Decide on BCC-to-self
- Flip `row_status_flag` 705 → 704

# Deployment Guide — Order Ack email subject: add customer PO + Sidemark (SA 54321)

> **Status (2026-09-08): ON HOLD.** The build is finished and proven end to end
> in BRR — but the CIO (Tina) noted that **ASAP already shows and searches order
> history by PO# and Sidemark**, for all of a customer's orders, not just those
> placed in ASAP. That substantially satisfies the original justification
> ("so customers and territory managers can search their email for a number
> they're familiar with"), which makes this a convenience rather than a gap.
> No decision to cancel — paused pending a business call on whether it is still
> worth doing given ASAP.
>
> **Before leaving it:** `asi_oe_order_ack_email_subject` (uid 171, v1.0.0.3)
> is registered in BRR with `ReadOnlyProbe = false`, i.e. actively writing
> subjects on an environment with real customer data and live SMTP. Set it
> `row_status_flag = 705`. Do **not** touch uid 169 (`asi_email_context_flag`)
> or uid 170 (`asi_oe_email_close_diag`) — 170 is SA 53475's approved ASAP
> message and 169 feeds its gate.

## 2026-09-08 — built, proven, measured, then put on hold

### Registrations rebuilt (uids changed)

The two `cb_ok` rules were deleted and re-registered. **Every uid in the older
sections below is stale.** Current: **169** `asi_email_context_flag`,
**170** `asi_oe_email_close_diag`, **171** `asi_oe_order_ack_email_subject` —
all `multirow_flag = Y`, `run_type_cd = 3424` (Synchronous), one live row each.

Field Selector for 171: `d_dw_email_info` → `subject` + `company_id`,
Buttons → `cb_ok` (Selected + Triggers Rule). **Not** `memo` — 170 owns that.
The first attempt had memo and subject swapped, the mirror image of the 9/6
failure on 170.

### Corrections to earlier entries

- BRR's `asi_oe_email_close_diag.dll` is **1.0.0.8** (dated 8/26), not 1.0.0.7.
  The "BRR is appending `[DIAG-MARKER-7A29]` to real emails" warning was stale.
- The Rule Manager **Test Business Rule** pane cannot test any of these rules.
  It throws `Data.Fields cannot be accessed in a multi-row rule` — from the
  harness's own grid, not the rule (none of this code calls `Data.Fields`).
  It has no `w_email_response` window and no `cb_ok` click to give a rule.
  Ignore it; test with a real send plus `business_rule_log`.
- `Invalid column name 'document_nos'` (error 207) on the first live run: the
  BRR flag table had not had `Create-asi-email-context-flag.sql` re-run against
  it. The rule caught it and the email still sent.

### Proven working

Probe run, order 6108923, v1.0.0.2:

```
Context flag check: is_order_ack=True form_type='Order Acknowledgement'
                    document_nos='6108923' order_no='6108923'
PROBE (no write) order 6108923 -- would set subject 'After Table rebuild'
                 -> '| PO 57354 After Table rebuild'
```

Live write, v1.0.0.3, order 6109021 — delivered subject:

```
** BusinessRules 20260825 ** - Acknowledgement# 6109021 | PO 111-6053217-3210625 | Sidemark x Test
```

No PowerBuilder error on the write.

### Concerns #1–#3 are now measured, not estimated

`Sql-Scripts\Business-Rules\Analyze-OrderAck-Subject-RepText-2026.sql` against
all 211,236 Order Acks sent in 2026 (`email_log`, `transaction_type =
'ORDER ACKNOWLEDGEMENT'` — it stores the **delivered** subject, which is how the
rep's typed text turned out to be recoverable after all).

**Concern #3 (subject length) — effectively closed.** 67.1% of acks have
nothing typed in the subject box. Of the third that do, mean 13 chars; only 301
of 211,236 exceeded 50. Independent confirmation of `char(60)`: max observed
rep text is exactly 60, with zero rows above it. Collision modelling: 209,129
fit untouched, 1,763 (0.8%) lose the Sidemark, 344 (0.2%) are left alone —
**~1% degraded**, under today's stricter policy.

**Concern #2 (spaces) — quantified.**

| | Renders today | If spaces allowed |
|---|---|---|
| PO | 186,237 (88%) | ~207,000 (98%) |
| Sidemark | 93,599 (44%) | 183,274 (87%) |

**+89,675 orders** would gain a Sidemark. Also: 35,246 orders have
`po_no = job_name` (the dedup earns its place), and 1,571 have a 1–2 char
sidemark — the "`| Sidemark x`" case.

**Concern #1 (internal notes) — partly answered, and the evidence has a known
hole.** The 100 most-used spaced sidemarks are mostly legitimate: Bielinski
Homes, Tim Obrien Homes, Fischer Homes, Illinois Holocaust Museum, Wisconsin
Lutheran College, Residences at Eastbank, plus benign operational tags
(Warehouse Stock, Denver Stock). Uncomfortable tail: "Cesar picked up",
"Mike Dipalo picked up", "will advise", "PERSONAL USE", "built qc".
**But that list ranks by frequency, and note-style text is written once** —
"Replacement for Leyza" and "put on wrong account" cannot appear in it.
`Analyze-OrderAck-Sidemark-Tail-2026.sql` was written to sample the single-use
tail and score a middle policy (allow spaces, ≥3 chars, keep the 30-char cap
and a blocklist). **It has not been run.**

### Recommendation if this resumes

Do not flip `SegmentPolicy` to `ScrubAndCap` wholesale. Run the tail script
first, then consider the middle policy. Also settle whether the subject line is
still the right target at all — the memo/body route has no length limit and is
already proven (SA 53475), but note 170 already writes `memo`, so it would need
one rule writing both pieces rather than two independent writers on the same
field and click.

### Outstanding

- Outlook draft to Jossy Vadakkel — **written, updated with the measured
  findings, NOT sent.** Its framing predates Tina's ASAP point and would need
  that added before it goes anywhere.
- Test orders 6109022 (both-empty no-op) and 6108970 (dedup) were never run.
- The SA 53475 regression check — subject stamp *and* ASAP memo on one email —
  was never confirmed; uid 170 has not been seen firing in any log this session.

## 2026-09-06 (b) — second BRR test: assumption disproved

Log rows 8807679–8807683 (`asi_oe_order_ack_email_subject`, uid 167, v1.0.0.1).

**Resolved by this run:**

| Open item | Answer | Evidence |
|---|---|---|
| 1. Is `subject` writable at `cb_ok`? | **Yes** | `subject column: MaxLength=-1 ReadOnly=False DataType=String`, and `readOnly="N"` in the Return XML — unlike `attachment*`, which were `"Y"` and threw an uncatchable PowerBuilder error |
| 2. Real width? | **`char(60)`** | `dataType="char(60)"` in the Return XML. The DataColumn reports `MaxLength=-1`, so .NET will **not** catch an overrun — the in-code clamp is the only guard |

**Disproved by this run:**

```
Context flag says Order Ack, but subject has no 'Acknowledgement# <digits>'
marker -- not modifying. subject='Test 4'
```

The gate passed (`is_order_ack=True`, `form_type='Order Acknowledgement'`). The
parse could not. In the sibling rule's Return XML 48 s earlier — window already
open — `d_dw_email_info.subject` is **empty**; it only became `Test 4` because
the tester typed it.

So **`d_dw_email_info.subject` is not the delivered subject line.** It is the
rep's free-text portion. P21 generates
`All Surfaces - Acknowledgement# <order>` itself at send time and appends this
field — consistent with `char(60)` and with `b_default_subject` /
`use_branch_name_in_subject_flag` existing as separate columns. There is no
order number in this field to parse, and never will be.

**Rework (decided 2026-09-06):** stay at `cb_ok` — writability is proven here
and a `cb_ok` write is already proven to reach the delivered email (SA 53475) —
and source the order number from the flag table instead.

- `asi_email_context_flag` **v1.0.0.2** now also writes `document_nos` (that
  event does expose it). One extra column on a row this rule already reads for
  its gate — no new query, no extra round trip.
- `asi_oe_order_ack_email_subject` **v1.0.0.2**: `ExtractOrderNoFromSubject` /
  `AckMarker` deleted; order number from `document_nos`; segment **prepended**
  rather than spliced after digits; `SubjectCap` 255 → **60**.
- Table gains `document_nos VARCHAR(255) NULL` (ALTER in
  `Create-asi-email-context-flag.sql`). NULLable so an older flag-writer DLL
  keeps working — the subject rule then logs "no order number" and changes
  nothing.

Delivered result for order 5977563 (`po_no = JS001561`, `job_name = ROACH CHRIS`,
rep types `Test 4`):

```
All Surfaces - Acknowledgement# 5977563 | PO JS001561 Test 4
```

`ROACH CHRIS` is a customer name with a space — correctly dropped by
`IdentifierOnly`.

### The 60-char cap is now a real constraint

It applies to **this field only** — P21's `Acknowledgement#` prefix does not
count against it. Budget from the test table:

| Segment | Chars | Left for the rep |
|---|---|---|
| `\| PO 111-6053217-3210625 \| Sidemark x` | 38 | 22 |
| `\| PO 111-6053217-3210625` | 24 | 36 |
| `\| PO 57354` | 10 | 50 |

Drop-order is unchanged (Sidemark first, then leave the subject alone) and never
truncates a value mid-string.

### Side note — `asi_oe_email_close_diag` in BRR (SA 53475)

**It is now failing outright**, separately from the stale-DLL problem. Every
fire logs `d_dw_email_info missing memo column or has no rows.` because its
data-element list holds `d_dw_email_info.subject` and **not** `memo` — Rule
Manager replaced the list (`feedback_p21_rule_manager_destroys_data_elements`).
`business_rule_log` also shows `rule_state.uid = 168`, not the 164/165 recorded
earlier, and two fires 48 s apart with different field ordering — so the
duplicate-registration bug has likely recurred a third time.

Fix order: run
`Sql-Scripts\Business-Rules\Audit-OrderAck-Email-Rule-Registrations.sql` →
deregister duplicates → re-add `d_dw_email_info` → `memo` to the surviving
registration (and drop `subject` from it) → **then** push 1.0.0.8, since BRR is
still on the pre-SA-53475 **1.0.0.7** DLL that appends `[DIAG-MARKER-7A29]`.
Tracked in `Deploy-Guides\order-ack-custom-email-message.md`.

## 2026-09-06 (a) — first BRR test (order 5977563)

- Registered `asi_oe_order_ack_email_subject` at the **`cb_ok` / `w_email_response`**
  attach point (not FormPreEmail). First two runs failed
  `Data.Set cannot be accessed in a non-multi-row rule`; recreated multi-row
  (uid 167). Next runs failed `EmailDataMisc table not found` — that table only
  exists on the FormPreEmail event. **Note in hindsight:** that error came from
  the rule having been *registered* at `cb_ok`, not from FormPreEmail being
  unworkable. The retarget was a response to a registration mismatch.
- **Field Selector on uid 167 (edit in place — do NOT recreate):**
  `d_dw_email_info` → `subject` (Selected), `company_id` (Selected);
  Window Controls → Buttons → `cb_ok` (Selected + Triggers Rule). Not `memo`.

## Request

> "Today, when someone sends an order acknowledgement to a customer via email,
> the subject line references our Order Number. It would be helpful to also
> include the customer's PO and Sidemark (if they exist), so customers and
> territory managers can search their email for a number they're familiar with."

Today's subject: `All Surfaces - Acknowledgement# 5731144 {whatever the rep types}`
Target subject:  `All Surfaces - Acknowledgement# 5731144 | PO 12345 | Sidemark KITCHEN {rep's text}`

## Artifacts

- `CSharp\asi_oe_order_ack_email_subject.cs` — On-Demand rule on **`cb_ok` /
  `w_email_response`**, multi-row. Gates on `asi_email_context_flag.is_order_ack`,
  takes the order number from that row's `document_nos`, pulls `oe_hdr.po_no` /
  `oe_hdr.job_name`, and prepends `| PO … | Sidemark …` to
  `d_dw_email_info.subject` (the rep's portion). Never blocks the send.
- `CSharp\asi_email_context_flag.cs` — On-Event rule on **FormPreEmail**
  (event uid 24). **v1.0.0.2 also records `document_nos`.** Shared with
  SA 53475: `asi_oe_email_close_diag` reads the same row for its own gate, so
  re-registering this rule affects both. Re-saving it in Rule Manager replaces
  its element list — confirm `form_type` **and** `document_nos` survive.
- `Sql-Scripts\Business-Rules\Create-asi-email-context-flag.sql` — creates or
  ALTERs the flag table (adds `document_nos`). Idempotent; re-runnable.
- `Sql-Scripts\Business-Rules\Audit-OrderAck-Email-Rule-Registrations.sql` —
  read-only. Duplicate registrations + per-uid data-element verdict for all
  three rules. Run before any Rule Manager work.

Code is independent of SA 53475; the **flag table and `asi_email_context_flag`
are shared**, so a botched re-registration of that rule breaks the ASAP message
too.

## Concerns / open items

**1. Free-text fields going to a customer-facing subject.**
`oe_hdr.po_no` and `oe_hdr.job_name` have no validation. A content review of
2026 orders and the P21BusinessRules sample shows staff routinely park internal
notes in them — e.g. "Replacement for Leyza", "put on wrong account",
"082426 Mike", "Quote / Pricing", "wrong material sent". Echoing that verbatim
into the subject line a customer receives is the main risk.
*Mitigation in the draft:* `SegmentPolicy = IdentifierOnly` — a value is added
only if it looks like a bare token (no spaces, ≤30 chars, `A–Z a–z 0–9 / # . _ -`).
That drops essentially all of the note-style prose. CR/LF/tab are stripped
regardless (subject-header hygiene). A looser `ScrubAndCap` mode (length cap +
blocklist) exists but should not be enabled until the full 2026 content scan is
reviewed.

**2. The safe policy also drops legitimate project names.**
`IdentifierOnly` suppresses values like "Serena Residence",
"Stuckert-Smaglick OR506247", "Fireplace Surround OR506459" — exactly the kind
of thing a territory manager might search on. `ScrubAndCap` would keep those but
would also pass borderline content ("Replacement for Leyza" contains no
blocklisted word). **Decision needed** on how aggressive to be, after the
content scan. Recommend starting with `IdentifierOnly` in Play and revisiting.

**3. Subject length — RESOLVED, and tighter than assumed.** ⚠️
The earlier 255-char analysis (1,146,440 orders, assembled subject 39–141 chars,
p99 = 93) measured the **whole delivered line**, which is not what this rule
writes. The writable field is the rep's portion only, and it is **`char(60)`**.
P21's `Acknowledgement#` prefix does not count against it. `SubjectCap = 60`;
see the budget table above. Because the DataColumn reports `MaxLength=-1`, .NET
will not catch an overrun — the in-code clamp is the only thing standing between
a long PO and a client-side PowerBuilder error, so do not relax it.

**4. Field writability — RESOLVED at `cb_ok`.**
`ReadOnly=False` / `readOnly="N"`, unlike the `attachment*` fields that threw an
uncatchable client error on the sibling rule. Still run once with
`ReadOnlyProbe = true` to see a real "would set subject" line, then one
`false` run watched for a PowerBuilder error before Play/Prod. Writability at
**FormPreEmail** remains untested — not needed on the chosen path.

**7. Shared dependency on `asi_email_context_flag`.** ⚠️
Both SA 54321 and SA 53475 now read the same flag row. Re-registering that rule
to add `document_nos` replaces its whole element list; if `form_type` is
silently dropped, `is_order_ack` goes false for everything and **both** features
stop working with no error a user would notice. Snapshot
`business_rule_data_element` before and after, and re-verify with the audit
script.

**5. Data-quality quirks seen in the sample (cosmetic).**
- One customer (3023035) systematically uses `job_name = 'x'`; `IdentifierOnly`
  passes single characters, so their acks would read `… | Sidemark x`. Consider
  a 2–3 char minimum.
- When `po_no` already starts with "PO" (`PO216636`), the subject reads
  `… | PO PO216636`. Harmless; could strip a leading "PO" from the value.

**6. Test-environment hazard.**
P21BusinessRules and P21Play have real customer data and a **live outbound SMTP
path** — a prior test on this window emailed 4 real customers on 2026-07-28.
Every test send must have the **To: field changed to the tester** before
clicking OK, and must be verified against the delivered `.msg` (via Outlook),
not just `business_rule_log`.

**Resolved (not a concern):** an Order Acknowledgment is always sent for a
single order, so there is no multi-order / list-parsing case to handle.

## Test orders (picked from P21BusinessRules, 2026-09-06)

| Order | Case | `po_no` → `job_name` | Expected subject suffix |
|-------|------|----------------------|-------------------------|
| 6109021 | both render | `111-6053217-3210625` → `x` | ` \| PO 111-6053217-3210625 \| Sidemark x` |
| 6108923 | prose dropped | `57354` → `Serena Residence` | ` \| PO 57354` |
| 6109022 | no-op (both empty) | *(empty)* → *(empty)* | *subject unchanged* |
| 6108970 | dedup (optional) | `26415` → `26415` | ` \| PO 26415` |

## Next steps (BRR)

Order matters — steps 1–2 also unblock SA 53475's ASAP message.

1. **Audit before touching anything.** Run
   `Sql-Scripts\Business-Rules\Audit-OrderAck-Email-Rule-Registrations.sql` in
   SSMS. Expect exactly one live registration per rule; section 3 gives the
   `memo` / `subject` / `company_id` verdict per uid. Save the output — it is
   the "before" snapshot for step 2.
2. **Repair the registrations** in Rule Manager, one rule at a time, re-running
   the audit after each:
   - `asi_oe_email_close_diag` — deregister any duplicate; on the survivor add
     `d_dw_email_info` → `memo`, remove `subject`. Keep `cb_ok`.
   - `asi_email_context_flag` — add `EmailDataMisc` → `document_nos`, confirm
     `form_type` survived.
   - `asi_oe_order_ack_email_subject` (uid 167) — confirm `subject`,
     `company_id`, `cb_ok` all still present.
3. **Run the table script.** `Create-asi-email-context-flag.sql` on BRR — adds
   `document_nos`. Check the trailing column listing.
4. **Build and deploy** `asi_email_context_flag` **1.0.0.2**. Send one Order Ack
   and confirm `business_rule_log` shows `document_nos='…'` in its Info line and
   that the flag row now holds an order number.
5. **Probe the subject rule.** Build `asi_oe_order_ack_email_subject` **1.0.0.2**
   with `ReadOnlyProbe = true`. Run the 4 test orders; expect
   `PROBE (no write) order … would set subject '' -> '| PO … '`.
6. **Go live on the write.** Flip `ReadOnlyProbe = false`, rebuild, re-test the
   4 orders **with the To: address changed to yourself**, and verify the
   delivered `.msg` **subject line** (via Outlook), not just `business_rule_log`.
   Watch for a PowerBuilder error on the write.
7. **Push 1.0.0.8 of `asi_oe_email_close_diag`** so BRR stops appending
   `[DIAG-MARKER-7A29]`, and confirm the ASAP message in the body.
8. Run the 2026 `po_no` / `job_name` content scan; revisit `SegmentPolicy`.
9. Promote to Play for UAT, then Prod.

### Regression to re-check at every step

`asi_email_context_flag` is shared. After any change to it, confirm **both**
the subject stamp *and* the ASAP memo message appear on the same test email —
a dropped `form_type` breaks both silently.

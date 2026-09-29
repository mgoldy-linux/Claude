# Deployment Guide — Low Margin Alert (Evan Jenkins request, no ticket #)

> Produced during development. Update as the artifact changes; commit with the code.
> **STATUS (2026-07-17): EVAN SIGNED OFF** ("everything else looks good") on the audience split, with 2 tweaks now handled:
> 1. *Sell Price on its own line* — already correct in the current template; his sample was stale (generated mid-build 7/14). Regenerate a fresh sample to confirm.
> 2. *Price Page Description blank* — populates on 86% of real low-margin lines; the 14% blank are `price_page_uid = 0` (not priced from a price page). Added a `(no price page)` fallback so the line is never empty. Applied to script 01 (Prod-ready) and to the live Play view.
>
> **Outlook line-break fix (2026-07-17):** the first fired email showed the banner *"We removed extra line breaks from this message"* and merged fields onto single lines. Outlook's *Remove extra line breaks in plain text messages* strips SINGLE newlines but never collapses **blank-line-separated** paragraphs. Also added `%` to percent lines and grouped minor fields with ` | `.
>
> **Spacing final round (2026-07-22, commit `bc64bef`):** Evan found the fully blank-line body too spread out. Reverted header + line-item fields to **single-line** spacing (`@nl`), then per his follow-up added a **blank line (`@br`) around Order Qty and Sell Price only** so the two key figures stand apart; the cost cluster (MAC/Std Cost/Price Page/Req Date/GM%) stays single-spaced. Footer Notes keep `@br`. Confirmed to Evan this is an **Outlook display setting, not P21** — single newlines merge per each reader's own *Remove extra line breaks* setting, so a blank line is the only reliable separator. Applied to script 03 + live Play (both alerts rebuilt, active 704).
>
> **Activation flag: `704 = ACTIVE (fires), 705 = INACTIVE`.** Script 03 now creates the alerts at 704. (Earlier confusion: in Play the old prod alerts sit at 705 = deactivated.)
>
> **Price-page demo recipe (2026-07-22):** to show a populated Price Page Description on a low-margin line, use customer **Flooring Systems Inc (1020066)** + item **MAP36163000** (auto-matches page 93854). Let the page price fill in, *then* override the sell price down to force margin < 5% — a manual override keeps `price_page_uid` on ~⅓ of lines (55,784 / 173,104 over 120d), verified live on order 5923022. The old blank sample (`MAP1785142`) simply had no price page → correct `(no price page)` fallback, not a bug.
>
> **Remaining before Prod (go-live):** (a) Evan's OK on the 7/22 spacing; (b) flip `row_status_flag` 705→704 once (a) is confirmed.
>
> **PROVISIONAL DEPLOY — EXECUTED 2026-07-31** ahead of the Monday P21Play refresh (which restores Play FROM Prod and would have wiped the Play-only alert build). Ran, against **P21** (Prod):
> - `01-alter-view-add-margin-columns-PROD.sql` (copy of 01 with `USE P21`) — all 8 columns confirmed present.
> - `02-register-tokens-PROD.sql` (copy of 02 with `USE P21`) — all 8 new tokens + the 2 repointed existing tokens confirmed.
> - `03-create-alerts-PROD-INACTIVE.sql` — created **uid 104 "Team"** and **uid 105 "Purchasing Escalation (MAC)"** at `row_status_flag = 705` (INACTIVE, does not fire), with the **real recipient list** baked in (Alex Sivongsay/Order Taker/Justine Daugherty/Sales Rep; Pam Dundas/Alex Boeve).
> - Verified full structural parity against Play with `PowerShell\Compare-LowMarginAlert-Prod-vs-Play.ps1` (view columns, `where_clause`, filter counts, message bodies, token registration all match; only `row_status_flag` and recipients differ, as designed).
>
> This is a preservation step, not the go-live deploy — Evan's final spacing sign-off is still open; do not flip `row_status_flag` to 704 until he confirms.
>
> ⚠ **After the Play refresh completes, Play's copy of this alert will also carry the real recipients** (since Play now restores from this Prod state) — the `mgoldyn`-only safety hack from the original Play build is gone. Before resuming any alert testing in Play, re-apply mgoldyn-only recipients there first, or the next test fire will email real people through Play's live SMTP.
>
> **STATUS (2026-08-26): SAMPLES SENT TO EVAN, awaiting his sign-off before flipping Prod active.** Forwarded live samples of both 104 and 105 from P21Play. Two testing traps worth keeping for next time:
> - **Test-customer trap:** Empire Today (`3000703`/`1127792`) shares `corp_address_id = 1046538` — the exact value both alerts' `where_clause` excludes — so it silently never fires there. Use **All Tile, Inc. (`1000260`)** instead. Recipe: `MAP1785142` @ 100 EA, sell price overridden to **$16.00** trips both; `ROB7399-1` @ 60 EA, **$19.80** trips Team only. (Default/list price won't trip either — must manually override the Sell Price field.)
> - **Recipient drift found and fixed:** at some point after the 7/31 refresh, 104's real recipients (Alex Sivongsay, Justine Daugherty, Sales Rep/Order Taker tokens) had gotten reactivated in Play — not mgoldyn-only anymore. Caught it because two test emails to them got stuck in `alert_queued_mail` at status **`1063 = "Email Pending"`** (never actually sent — likely because the Sales Rep token resolved to a blank address on an order with no primary salesrep). Deleted the stuck rows and removed the real recipients in the client before they could send. **Check `alert_queued_mail` for row_status_flag 1063 whenever an expected alert email doesn't show up** — it means P21 generated it but never delivered it, which reads completely differently from "never fired at all."
> - **Recurring check:** re-verify Play recipients are mgoldyn-only after any future P21Play refresh — this is now the second time real recipients have come back active post-refresh.
>
> **STATUS (2026-08-27): RSM recipient built + tested in Play, not yet live.** Evan's reply on the samples thread revealed he expects **RSM** (+ himself, + Jere Butler on Purchasing) on the distribution — see script `07-add-rsm-token.sql`. Adds `contacts.sales_manager_id` self-join + `rsm_email` column to the view (same pattern as P21's own stock `p21_view_alert_cr_Opportunities`), registers token `rsm_email` (`available_areas=80`, recipient-only). Verified via direct SQL (no alert fired) against 6+ real reps — 173/188 salesreps (92%) have a manager, 151 of those (87%) have a usable email; ~22 reps resolve blank. **Drawback disclosed to Evan:** RSM follows whoever manages the salesrep, not a fixed territory, so an RSM overseeing reps in multiple regions sees alerts outside their own region. **Tested the blank-RSM edge case risk-free** using **The Carpet Group Inc (customer_id `1108592`)** — default rep Kevin Isken has no manager assigned at all, so no real employee received a test email; confirmed the alert still fired correctly. **No P21-native way to log alert sends for Prod tracking** (confirmed: `alert_queued_mail` is a pure transient queue, `email_log` covers document email only, never alerts) — plan is to **BCC the user's own address** on both alerts, added in the same recipient build as RSM. Not yet added to `alert_recipient` on 104/105 — pending Evan's reply on scope (Team/Purchasing/both) and To vs CC.
>
> **UPDATE (2026-08-28): Evan OK'd the drawback, asked for a live test to Tyler Priewe** ("I will give him a heads up") and floated flipping Prod live next Wednesday (9/2). Found a genuine (non-contrived) test case in Play: order `6058724` (Carpet Factory Outlet LLC), rep Andrew Restivo, RSM resolving to Tyler Priewe, margin -0.42%/-1.28%, clears every filter clause on the `where_clause`. Note: `p21_view_alert_oe_OrderEntry` can't be queried directly for an already-processed order (inner-joined to the transient `pending_alerts` queue) — had to reconstruct the view's filter/margin math and run it standalone against `oe_hdr`/`oe_line`/`inv_loc` to find this. Drafted + user sent a reply to Evan confirming the example; the actual test send to Tyler will use subject "P21Play & TEST Email" so it reads unmistakably as a test. Test send itself not yet made — awaiting Evan's/Tyler's go-ahead. No `alert_recipient` changes this session.
>
> **UPDATE (2026-08-28, continued): live test sent and confirmed working; RSM ported to Prod; PAD recipients reconciled on both Play and Prod.** The 6058724 recipe hit a real inventory block on reuse (0 on-hand at that location today) — swapped to `MAP1785142` @ location 100 (2,480 available), 100 EA @ $16.00 override, re-verified against **current** costs (still -4.5%/-1.0%, both thresholds trip), same customer/rep chain. **User built the order — both 104 and 105 fired, confirmed received.** First real end-to-end proof of the RSM token, not just SQL-verified.
>
> Ported to **Prod** via new script `07-add-rsm-token-PROD.sql`: diffed Prod's live view against Play's first (per the standing rule) — confirmed Prod was missing both script 06 (deliberately NOT bundled in — separate, still-unapproved) and the RSM column. Built the Prod script from **Prod's own current definition**, not the Play script, so only the RSM delta moved — verified via diff that exactly 2 lines changed (new SELECT column + new LEFT JOIN). Applied via `CREATE OR ALTER VIEW`, token registered (`token_uid 745`, matches Play), join re-verified against real Prod contacts data. Prod alerts stayed `705` inactive throughout. **User then added `<rsm_email>` as a recipient directly on Prod 104/105/106/107 in the client.**
>
> **PAD recipient reconciliation:** checked Play first — PAD-Team (106) was missing Evan Jenkins vs. main Team, and PAD-Purchasing (107) had a genuinely corrupted recipient (`<rsm_email>` and `mgoldyn@allsurfaces.com` jammed into one field, not two rows) — fixed via `UPDATE` back to a clean address, matching 105 exactly per the user's choice. User clarified the real ask was **Prod** — re-checked there and found different gaps: 107 missing 5 of 9 recipients (Jerome Butler, Justine Daugherty, Alex Sivongsay, Sales Rep token, Order Taker token), 106 missing Evan Jenkins. Recommended the client over raw SQL `INSERT` (documented counter-drift history on `alert_recipient`, plus the user's established preference from the 8/3 rebuild). **User added them; re-verified — both alert pairs' recipient sets now match exactly** (Team 6/6, Purchasing 9/9). All four alerts remain `705` inactive throughout — zero live-fire risk from any of this work.
>
> **Status: waiting on Evan** — recipient sets fully built and reconciled, RSM proven live in both Play and Prod, everything still safely inactive. Open: his final confirmation on the recipient set as-built and go-live timing (9/2 floated); BCC-to-self raised as a want, not yet added anywhere.
>
> ---
>
> ## 🟢 GO-LIVE — EXECUTED 2026-09-04 (Evan's confirmed date)
>
> **All four alerts flipped to ACTIVE; the two legacy single-alerts they replace turned OFF.** State verified against Prod after the flip (all edits `MGOLDYN`, ~06:58–07:18):
>
> | uid | Alert | row_status_flag |
> |----|-------|-----------------|
> | 104 | Low Margin Alert - Team | **704 ACTIVE** |
> | 105 | Low Margin Alert - Purchasing Escalation (MAC) | **704 ACTIVE** |
> | 106 | Low PAD Margin Alert - Team | **704 ACTIVE** |
> | 107 | Low PAD Margin Alert - Purchasing Escalation (MAC) | **704 ACTIVE** |
> | 97 | Low Margin Alert (legacy — `line_item_profit_percentage < 5`) | **705 inactive** |
> | 100 | Low PAD Margin Alert (legacy — `line_item_profit_percentage < -5`) | **705 inactive** |
> | 102 | Test Verify Alerts (decoy) | 705 — confirmed still off |
>
> Legacy 97/100 were **deactivated, not deleted** — a rollback is a flag flip back (see the Rollback section, which now also covers reactivating them).
>
> **Recipient add trap hit and diagnosed.** Adding an "RSM" recipient in the client threw `SQLDBCode 3621 — Violation of UNIQUE KEY constraint 'ak_alert_recipient'`, duplicate key `(110, '', 1059)` = `(alert_message_uid, alert_email_address, record_type_cd)`, and rolled the whole statement back (*"No changes made to database"*). Cause: `<rsm_email>` was **already** on that alert from the 8/28 build — it was being added a second time. This is a *loud* failure (rare for P21 alerts) and effectively a guard that the token recipient already exists. Recorded as trap 8 in `feedback_p21_alerts.md`.
>
> **Recipient list cross-checked on all four.** `code_p21` confirms the type codes: `code_no` 1281 = "To...", 1282 = "CC...", 1283 = "BCC...", 1059 = "Email Recipient". Every recipient row active (704). Membership matched within each pair (104≡106 at 8 each, 105≡107 at 11 each); RSM, Erik Bullock, Evan Jenkins, and a BCC-to-self (`mgoldyn@allsurfaces.com`, type 1283) on all four; Jere Butler on both Purchasing alerts. **To/CC placement was inconsistent** at first check (Erik Bullock CC on all four though the 2026-08-31 request said "To"; RSM To on 106 but CC on 104; the Purchasing pair's To/CC split disagreed) — **the user corrected the assignments** (not re-verified from SQL in that session) and put the family into a **monitoring phase**.
>
> **Status: 🟡 LIVE, in monitoring.** Watch the first real fires for volume against the estimate (~477 unique orders/period for the main pair — see "Backward-compatibility notes"), confirm the RSM token resolves on live orders, then decide when to delete legacy 97/100 rather than leave them parked. BCC-to-self is in place (type 1283, `mgoldyn`). Script 06 (NULL-token hardening) is still **not** on Prod — separate, unapproved, deliberately deferred.

**First monitoring-phase question, 2026-09-04 (later same day):** Evan asked (order 6132881, Freedom Carpeting and Countertops) why `Price Page Description` didn't say "Overridden" after he confirmed the sell price was manually cut to $2.54 — a live instance of the exact behavior already measured in the **Price-page demo recipe** note above (2026-07-22): a manual override doesn't reliably clear `price_page_uid`, so the original price page's description can keep showing. Nothing new to fix; answered Evan with the existing measured numbers (~⅓ of lines, 55,784/173,104 over 120d) rather than treating it as a fresh bug. Reply drafted in Outlook, not yet sent as of this note. **Sent; Evan replied 9/4 4:18pm** asking for the override to be shown alongside the price source, and for a scope conversation.

> ## Phase 1 — show the price override (agreed 2026-09-09, NOT yet built)
>
> **The ask needs almost no build.** P21 already stores both halves on `oe_line`:
> `manual_price_overide` (`'Y'` when a user edited the price — P21's own misspelling, one `r`, do **not** "correct" it)
> and `system_calc_unit_price` (what P21 calculated before the edit).
>
> `manual_price_overide` is **already a column in this alert's view**, exposed as **`price_edit`** — and it is **stock
> P21**, present in `ROLLBACK-p21_view_alert_oe_OrderEntry-Play-BEFORE.sql:82`, so it predates every change this project
> made. It is also **already a registered token**: `token_uid 135`, `available_areas = 36` = `32` (header/event) **+ `4`**
> (line-item body), so it is usable in the body **right now**.
>
> **Phase 1 is therefore a body-text edit on the four alerts — no view change, no token registration, no deploy
> script, and none of the Prod-view-drift risk a `CREATE OR ALTER VIEW` would carry.** Insert one line, single-spaced to
> match the cost cluster (preserves the 7/22 spacing Evan signed off on):
>
> ```
> Price Page Description: <price_page_description>
> Price Overridden: <price_edit>              <-- new
> Req Date: <line_required_date>   |   UOM: <unit_of_measure>
> ```
>
> **RESOLVED 2026-09-09 by a live fire (order 6062441).** `price_edit` renders **`Y`** when overridden and **`N`**
> when not — NOT blank. The view wraps it `ISNULL(oe_line.manual_price_overide, '')`, but P21 actually stores the
> literal `'N'`, so the ISNULL never engages. **Phase 1 therefore needs no view change whatsoever**, exactly as scoped.
> One order carried both cases: `SMGSTR SC457FULL` (not overridden) → `N`, `MAP1785142` overridden to $16.00 → `Y`.
> That email is also the best sample yet for Evan — the overridden line shows a populated
> `Price Page Description: List Price - Mapei Patch Group 2 - EA - Qty Break` alongside `Overridden: Y`, i.e. his exact
> order-6132881 shape, with the contrasting `N` line directly above it.
>
> Consequence for script 08: its **`price_override_display` column is no longer necessary** — it existed only to avoid
> a blank that does not occur. Keep it ONLY if Evan prefers `Yes`/`No` over `Y`/`N`; otherwise drop that column and its
> token and ship just `system_calc_price`.
>
> **Measured justification** (`Analyze-Price-Override-Detection.sql`, Prod, 788,109 lines / 120 days): flag `Y` on
> 324,596; prices differ on 299,373; **differ with the flag NOT set on just 96 (0.012%)**; in the low-margin population
> this alert actually emails on, **1 miss in 12,140**. The alternative of comparing `system_calc_unit_price` to
> `unit_price` loses — that column is NULL or zero on **222,265 lines (28%)** and carries float noise
> (`22.439999997`, `803.680000002`) that would false-positive on rounding alone. Also **103,523 of 324,596 overridden
> lines still carry a price page = 31.9%**, independently reconfirming the ~⅓ figure in the 7/22 note above.
>
> **Order 6132881 re-checked 9/9:** `unit_price` **$3.54**, `system_calc_unit_price` **$4.08**, flag **`Y`**, price page
> still populated. $3.54 is Tyler's already-applied correction — so **the correction is itself still an override**,
> 13% below program pricing. Worth telling Evan.
>
> **Phase 2 (deferred, optional):** add `system_calc_unit_price` so the email shows how far off the price is
> ($4.08 → $2.54 is 38% below program). Additive column on a table already in the FROM — no new join, negligible
> cost — but it *does* mean `CREATE OR ALTER VIEW` on a Prod view live for other alerts, so diff Prod against Play
> first, and note script 06 is still not on Prod.
>
> **Evan's invoice assumption is probably wrong and has not been corrected yet.** Nothing "flips" at invoicing. The
> 'Manual Override' he has seen is almost certainly a report-side display CASE — `Deploy-Guides/SA-50249/original-asi_3yr-view.sql:568`
> does exactly that, and reads the **order** line's flag. That pattern *replaces* the description; Evan asked for **both**,
> so do not copy it as-is. Unverified — the screen he is describing has not been seen.
>
> ### Before any Play test — pre-flight results, 2026-09-09
>
> `Check-Play-Alert-State-Before-Test.sql` run against P21Play. **A predicted hazard did not materialise, and a real
> one did.**
>
> **Play was NOT clobbered by a refresh — an earlier note in this guide asserted it would be, and that was wrong.**
> 104/105/106/107 are active (704) but their recipients are still **mgoldyn-only**, and `date_last_modified` reads
> 8/3–8/28 — Play's own build history, not Prod's 9/4 go-live. The claim came from reading a commit note about a
> **P21Dev** (server) refresh as a **P21Play** (database) refresh, without checking. Legacy 97/100 are 705, so their
> real-people recipient lists are inert.
>
> **The real hazard is narrower:** `<rsm_email>` is an active **CC on 104**, and it resolves to the sales rep's actual
> manager. Chosen workaround — build the test order under **The Carpet Group Inc (`1108592`)**, whose rep Kevin Isken
> has no `sales_manager_id`, so the token resolves blank. That beats deactivating the recipient row: no state to
> restore afterwards, and `alert_recipient` is never touched (avoiding both its counter-drift history and the
> `ak_alert_recipient` unique-key trap).
>
> **Still true and verified:** Play's alerts carry **the same uids as Prod's** (104–107) *and* the same names, so the
> uid does not identify the environment — only the connection does, and the Prod copies are live. Confirm the server
> before editing a body.
>
> **Test recipe re-verified:** `MAP1785142` @ loc 100, **2,480 available**, MAC $15.31 / std $15.84 → at $16.00 that is
> **4.3% off MAC / 1.0% off standard**, both under 5%, both trip.
>
> **Second sample, for the not-overridden rendering:** `MAP36691` (order 6062411) — priced from page 87444,
> `manual_price_overide = N`, −5.18% off MAC. A genuine low-margin line with a populated Price Page Description and no
> override. Stock not yet checked.
>
> ### ⚠ CLEAN-UP OWED IN PLAY — open at end of day 2026-09-09
>
> **Cancel these test orders in P21Play** (user's own reminder, end of 2026-09-09):
> - **6062439** — Empire Today, 8 lines, never fired (excluded customer)
> - **6062441** — Built Rite Construction LLC, 8 lines, $2,665.81, fired 104 successfully
> - plus any other orders built during the 2026-09-09 testing session
>
> **Also still to restore:** the `[OVR=<price_edit>]` subject marker on Play 104, if it was added.
>
> ### ⚠ OPEN STATE TO RESTORE — `<rsm_email>` disabled on Play 104 (2026-09-09)
>
> The user **deactivated the `<rsm_email>` CC recipient on Play's "Low Margin Alert - Team" (104)** to remove the
> live-email risk for Phase 1 testing. This is temporary state, not a design change. **Re-activate it once the test
> emails are done** — otherwise Play's 104 no longer mirrors Prod's recipient set, and the next person to compare the
> two (or the next `Compare-LowMarginAlert-Prod-vs-Play.ps1` run) sees a false drift. Recipient drift on this exact
> table has already been found and fixed twice on this project.
>
> **Verify it landed in Play, not Prod.** Both environments have an alert named *Low Margin Alert - Team* at **uid
> 104** — the uid does not distinguish them. Prod's `<rsm_email>` must remain **active (704)**; if it was switched off
> there, real RSMs stop receiving live alerts with nothing to surface it.
>
> With RSM off in Play, the Carpet Group Inc (`1108592`) blank-manager workaround is **no longer required** — the
> known-good recipe (All Tile / Carpet Factory Outlet chain) can be used directly.
>
> **Verified 2026-09-09 (closing out the earlier unknowns):**
> - **The `[TEST-Play]` env tag was NOT lost** — a second wrong prediction from the same bad refresh inference. All six
>   Play alerts are tagged; **104 reads `[P21Play] Low Margin - ... TEST EMAIL`**, ideal for a sample forwarded to a
>   stakeholder. Tagging is inconsistent across the family (`[P21Play]` on 97/100/104/105, `[TEST-Play]` on 106/107) —
>   cosmetic, left alone.
> - **Kevin Isken (contact `1049`) still has `sales_manager_id = NULL`** — the blank-RSM customer trick remains
>   available, though it is moot while RSM is disabled on 104.
> - **`MAP36691` is unusable as a not-overridden sample — and the query that produced it was flawed.** Its $9.75 comes
>   from page 87444, which belongs to **Empire Today (`1046538`)** — the very customer both alerts exclude via
>   `corp_address_id <> 1046538`. The Q4 query in `Check-Play-Alert-State-Before-Test.sql` filtered on **margin only**,
>   omitting the alert's own exclusions (corp address, the customer NOT IN list, taker, product group,
>   `total_amount`), so its results are **not the alert's real population** — several rows are Empire Today lines that
>   never fired at all. Anything drawn from that list must be re-checked against the full `where_clause`.
>   Incidental: order 6062411's line 1 is `MAP1785142`, 100 units @ $16.00 — the documented 8/26 recipe — so 6062411 is
>   one of the *failed* Empire Today attempts from that session, before the switch to All Tile and the clean 6062415.
>   Corroborates the 8/26 note above.
> - **Schema note for anyone rebuilding these queries:** `corp_address_id` is on **`address`**, not `customer`
>   (`INNER JOIN address AS address_customer ON address_customer.id = oe_hdr.customer_id`), and the view's `taker` is
>   **`users_taker.name`** via `LEFT JOIN users ON users.id = oe_hdr.taker` — filtering `oe_hdr.taker` directly compares
>   against the user *id* and silently matches nothing. Copy joins from script 07's view rather than inventing them.
>
> **Preferred test order** (reproduces Evan's 6132881 shape — populated description *and* override, unlike
> `MAP1785142`, which has no price page and renders `(no price page)`): customer **Flooring Systems Inc (`1020066`)**,
> line 1 **`MAP36163000`** page-priced via 93854 then overridden under 5%, line 2 **`MAP36691`** ~45 units at loc 142
> left at program price. Confirm MAP36163000 stock first (recipe dates from July), and confirm which customer put
> MAP36691 on page 87444 at $9.75 (order 6062411) — if it is not Flooring Systems, run line 2 under that customer.
>
> ### Test order 6062439 did not fire — diagnosed 2026-09-09 (Empire Today, third occurrence)
>
> Root cause, single and unambiguous: the order was built under **Empire Today Procurement LLC (`1046538`)**, whose
> `corp_address_id` is also `1046538` — the exact value every one of these alerts excludes. The order is disqualified
> at header level, so no line can ever fire.
>
> **Everything else passed**, which is worth recording because it rules a lot out: `new_order = Y` (`date_created` =
> `date_last_modified` to the millisecond — the order was built in one save), `total_amount` $2,189.45, a primary
> salesrep exists, not an RMA. `alert_queued_mail` was **empty**, so nothing generated and stalled at 1063 either. And
> the live `where_clause` on all four alerts is intact — no `Price Edit` filter row crept in.
>
> **Line 1 fully qualified:** `MAP1785142`, 100 EA @ $16.00 override, loc 100 — `extended_standard_cost` **$1,584**,
> 4.33% off MAC, 1.00% off standard, `low_margin_flag = Y`. That line would have fired but for the customer.
>
> **New trap — copying an order inherits the excluded customer.** Order 6062439 opens with `MAP1785142`, 100 EA @
> $16.00, byte-for-byte line 1 of order **6062411** — itself one of the failed Empire Today attempts from 8/26. Copying
> a previous test order as a template drags its customer along, which is how Empire Today keeps reappearing despite
> being documented twice. **Build test orders fresh; do not copy.**
>
> Lines 2–8 were all qty 1 and failed `extended_standard_cost > 500` regardless, and `MAP36163000` came in at its
> program price **$190.99 with `manual_price_overide = N`** — the intended override was never applied to it.
>
> **Diagnostic:** `Diagnose-Alert-Did-Not-Fire.sql` (read-only) evaluates every where_clause condition pass/FAIL against
> any order, reconstructed from the view's own expressions, plus the joins that silently drop rows. Reusable — change
> `@order`.
>
> **Two view details worth knowing, both able to drop rows with no trace:** `INNER JOIN oe_hdr_salesrep ... AND
> primary_salesrep = 'Y'` removes the **entire order** when no primary rep is set, and `INNER JOIN supplier ON
> oe_line.supplier_id` removes individual lines. Also `extended_standard_cost` is **not** `qty * standard_cost` — the
> view computes `standard_cost / pricing_unit_size * unit_quantity * unit_size`.
>
> **Next attempt:** build fresh under **All Tile, Inc. (`1000260`)**; line 1 `MAP1785142` 100 EA @ $16.00 (proven), and
> optionally line 2 `MAP36163000` 12 EA @ $102.00 (ext_std $1,291) for a populated-price-page-plus-override sample.
>
> **Status: Phase 1 agreed, NOT executed — nothing changed in any environment.** Session ended for a reboot.
> RESUME: Play pre-flight → env tag → re-check `MAP1785142` stock at loc 100 → one-line body edit **in the
> client** (per the standing preference on this alert family) → fire a test order → read the `price_edit` rendering
> → forward samples to Evan → await his feedback.

## 2026-09-24/25 — a Prod alert that never delivered. Investigated, root cause DISPROVED, closed as a one-off.

**What happened.** Order **6171951** (Vanguard Concrete Coating, −41.37% off MAC, $4,339.44) generated a Low
Margin alert that reached **nobody** — not just the rep, but Alex, Erik, Justine and the Order Taker too. It sat
in `alert_queued_mail` as row **239**: `row_status_flag 1063` ("Email Pending"), `reason_cd 1060` ("Email system
down"), `email_to` ending in a malformed `Sales Rep <>` because the order was on a house account whose rep has no
email.

**The mechanism behind `Name <>`** — real, read from P21 source, and worth knowing even though it is not the
cause here. `p21_fn_validate_email_address` returns `<email_not_found/>` for NULL or empty input (P21's own comment:
"a string that the alert SPs see as a flag that needs special treatment"). In `p21_sp_alert_generation`, when SMTP is
enabled, recipients are built **name-first, before token substitution**:

```sql
Coalesce(alert_email_name + ' <' + alert_email_address + '>', alert_email_address)
```

so the string becomes `Sales Rep <<email_not_found/>>`, and the strip that follows removes **only the marker**,
leaving `Sales Rep <>`.

**The fix that followed was wrong.** The plan was to NULL `alert_email_name` on the three token recipient rows
(NULL specifically — an empty string still leaves ` <>`), collapsing the Coalesce to the bare address so the strip
removes the recipient cleanly. **A Play test disproved it.** Play 104 had only a hardcoded To recipient and so could
not reproduce anything, so a rig was built: `<primary_salesrep_email>` added as a To recipient, house-rep contact
1041 pointed at the user's own mailbox, and a **control run first** (email arrived, address twice — rig proven).
Then the rep's email was cleared and the order rebuilt. **It sent anyway** — identical `Sales Rep <>`, and
`alert_queued_mail` completely empty afterwards, not even the junk `<email_not_found/>` diagnostic row.

**The CC hypothesis died too.** Prod's RSM was suspected, since Play's was inactive. Reconstructing 6171951's chain:
rep contact 7913 (All Surfaces House Supplies) has a NULL email and resolves to the marker as expected, **but its
manager is contact 1047, Al Ross, `aross@allsurfaces.com`** — valid. Prod's CC was clean.

**Conclusion.** Prod's queue held exactly **one** row — no cluster — and the user confirms alerts have been arriving
normally in the BCC-to-self since. A brief mail-relay failure at 14:17:31 on 9/24 caught the one alert in flight.
**Prod recipients were left untouched; the proposed fix would have changed nothing.** The 14 rows captured as a
rollback were never used.

**Corrects a standing assumption.** Trap 1 in `feedback_p21_alerts` has held since 2026-08-26 that a dynamic
recipient resolving blank "appears to stall the whole multi-recipient send." That was an inference from one
incident and is now **disproved by direct test**.

**Also learned:** P21 **does** warn about undelivered alert mail when the client opens — so these are not strictly
silent. But the warning is dismissible and clearing it also clears the row, destroying the evidence.

**Alert Maintenance note.** Adding the recipient through the client threw *"An error has occurred accessing alert
information"* on save. Checked immediately whether that failed save had already fired trap 10's `where_clause`
regeneration — **it had not**; Play 104's clause still matched script 10 byte-for-byte, including the grid-less
`job_name NOT LIKE '%CLOSEOUT%'` and `'%E&O%'` conditions. The recipient was added by SQL instead and the counter
realigned via `Check-Fix-Alert-Table-Counters-Play.sql`.

**New monitoring:** `C:\PowerShell-Scripts\Alerts\Check-Stuck-Alert-Emails.ps1` (commits `f97f2e0`, `07ea131`) —
a daily check for rows sitting in `alert_queued_mail`, reporting age, decoded reason/status codes and a
malformed-recipient flag that is **deliberately labelled triage context rather than a diagnosis**, so it cannot
re-assert the theory disproved here. Follows the `Check-Job-History.ps1` record format. Parse-verified, **not yet
run live**.

**House-account fallback — considered and declined.** A blank rep slot could route to a group mailbox
(`pricingsupport@allsurfaces.com`, already named in the alert footer). Decided against changing the view: six real
people still receive a house-account alert, including Alex Sivongsay, who *is* the pricing team in Evan's own
escalation sequence. If it is ever built, note that `primary_salesrep_email` is shared across all five OE alerts —
a fallback belongs in a **new additive column**, not in that token. A question was drafted to Evan instead
(**not sent**).

**Play left clean:** test recipient 208 deleted, contact 1041 reverted to NULL, test orders cancelled. `<rsm_email>`
remains deactivated on Play 104, as before.

## 2026-09-29 — a SECOND undelivered alert. Recipient theory dead; the P21 codes are meaningless; native notification is unreliable.

**The 9/25 "one-off" call was wrong.** A second alert failed **2026-09-28 14:51:21** — `alert_queued_mail` row **240**,
order **6177600** (The Carpet Group Inc(Pad), 3 PAD lines all negative margin, **$4,946.00**). Two in five days.

**Row 240's `email_to` was entirely valid** — `Alex; Erik; Justine; Order Taker <ggierum@…>; Sales Rep
<kevini@allsurfaces.com>`. No `<>`, no blank. Same `1060`/`1063`, still failed. **The recipient theory is dead**, which
retrospectively confirms that leaving Prod's recipients untouched on 9/25 was correct.

### ⚠ The codes are hardcoded — they are never a diagnosis

`p21_sp_send_mail_error_handler` contains:

```sql
INSERT INTO alert_queued_mail (... reason_cd ... row_status_flag ...)
VALUES (... 1060, -- Code = Email system down.
        ... 1063  -- Code desc = Email Pending. )
```

**Every failed alert email gets `1060 / 1063` regardless of the real cause**, and unlike document email (which keeps
`error_text`) the actual SMTP error is **never persisted**. Reading "Email system down" as literal is what aimed the
9/24–9/25 investigation at recipients.

### Ruled out, with evidence

| Ruled out | Evidence |
|---|---|
| Relay down | **168** document emails in the 9/24 14:00 hour, **0 errors**; **192** on 9/28 |
| SSRS saturating the shared relay | The 9/25 SSRS record covers 9/24 08:46→9/25 08:12: 6 sends, all OK, **none in the afternoon** |
| Blank/malformed recipient | Row 240's To line entirely valid |
| Empty sender → silent MAPI fallback | `p21_sp_send_mail` does have `IF @avc255_Senders = '' SET @MailType = 'MAPI'`, but all four alerts carry `sender_email_address` **NULL** (correct) and defaults resolve to `Internal Alert <noreply@allsurfaces.com>` |

`mailitem_id` is NULL on both stuck rows — never handed off for dispatch. P21 sends via **CDOSYS**
(`p21_sp_send_smtpmail`), not Database Mail, so there is no `msdb` trail either.

### The resend result

The user resent row 240 from the client and the queue went to **zero** — same message, same recipients, same body,
away 19 hours later. **So the message itself is fine and the failures are transient.** ⚠ Not fully confirmed whether it
genuinely delivered or the client action merely cleared the row; the BCC-to-self inbox is the only way to tell, and
that check is still outstanding.

### There is no log of successful alert sends

`email_log` carries **17 transaction types** over 14 days (Order Ack 11,817, Invoice 3,079, Quotation, PO, RMA…) and
**no ALERT type**. With the transient queue and NULL `mailitem_id`, the **BCC-to-self is the only audit trail** —
reconfirming the 2026-08-27 conclusion.

### ⚠ P21's own notification cannot be relied on

The red badge comes from the same error handler, which inserts a `system_alerts` row (type 1065) — **but only for users
who do not already have an undismissed one**:

```sql
WHERE users.receive_system_alerts = 'Y' AND users.delete_flag = 'N'
  AND NOT EXISTS (... row_status_flag = 704 AND system_alert_type_cd = 1065)
```

**11 outstanding rows, all active (704), spanning 2019-03-28 → 2026-09-28** on `MMUNSON, JVADAKKEL, OROSVC, LBERRY,
ADMIN, ADMINISTRATOR, CWOYTKO, JSAMUELS, DEREK, EDI, SHUTCHISON` — including **DEREK (`delete_flag='Y'`, departed)** and
service accounts. Anyone who never dismisses theirs is **silently skipped for every subsequent failure**, in one case
since 2019. Only **8 users** qualify at all. Dismissing is what re-arms it. **The absence of a red badge means nothing.**

### Designed, NOT built

SQL Agent job **`_asi_Alert_Queued_Mail_Monitor`** — every 15 minutes, emails via **Database Mail**, deliberately a
different channel from the failing CDOSYS path so a P21 mail problem cannot swallow its own alarm. Filters to rows
newer than ~20 minutes so a row stuck 19 hours emails once, not 76 times. The `_asi_` prefix means the existing
`Check-Job-History.ps1` monitors the monitor.

**Database Mail is enabled on Prod** — profile **`P21 Alerts`** / `P21_Alerts@allsurfaces.com` — but **dormant since
2025-10-28** (0 sent, 0 failed in 30 days). It must be test-sent before anything depends on it. Permission requested,
not yet given.

⚠ Do **not** wire `Check-Stuck-Alert-Emails.ps1` into profile init — a dbatools call there is the exact pattern behind
the SentinelOne / Arete #331962 incident. Use a Windows scheduled task.

**Status: 🟡 open, waiting for the next failure.** Retroactive diagnosis is exhausted — P21 discards the only evidence
that could answer it. The real route to a cause is the **SMTP relay / Exchange logs at 2026-09-24 14:17:31 and
2026-09-28 14:51:21**; that is an IT ask and has not been made. Prod unchanged throughout.

## Artifact(s)
All under `C:\Claude\Alerts\Low-Margin-Alert\`, run **in numbered order**:

| # | Script | What it does |
|---|---|---|
| 1 | `01-alter-view-add-margin-columns.sql` | Adds 6 columns + 1 join to `dbo.p21_view_alert_oe_OrderEntry` |
| 2 | `02-register-tokens.sql` | Registers 6 tokens on `alert_type_uid = 12` |
| 3 | `03-create-alerts.sql` | Creates the 2 alert definitions (impl + filters + message + recipients) |
| — | `ROLLBACK-p21_view_alert_oe_OrderEntry-Play-BEFORE.sql` | The pre-change view definition — **the rollback artifact** |
| — | `Analyze-Cost-Buckets.sql` | Read-only analysis; not part of the deploy |
| — | `Analyze-Price-Override-Detection.sql` | Read-only analysis; not part of the deploy. Proves `oe_line.manual_price_overide` is the reliable override signal (96 misses in 788,109 lines; 1 in 12,140 low-margin) and that comparing `system_calc_unit_price` is not (NULL/zero on 28% of lines, plus float noise). **Run 2026-09-09 vs Prod.** Note `oe_line` has no `item_id` — join `inv_mast` on `inv_mast_uid`; statements are `GO`-separated because a bad column reference is a bind-time error that aborts the whole batch |
| — | `Check-Play-Alert-State-Before-Test.sql` | Read-only **pre-flight, run before any Play test order**. Q1 active status, Q2 recipients (post-refresh live-email risk), Q3 test-item stock, Q4 a not-overridden low-margin example. **Not yet run** |
| 6 | `06-harden-oe-view-null-tokens.sql` | Wraps 6 previously-unwrapped OE-token columns in `ISNULL`/`COALESCE` — defense against the `p21_sp_alert_generation` NULL-token-collapse bug (see 2026-08-11 note below). `CREATE OR ALTER VIEW`, run standalone against the view already deployed by script 01 |
| 7 | `07-add-rsm-token.sql` | Adds `contacts.sales_manager_id` self-join + `rsm_email` column/token to the view. **Play.** Live-tested 8/28 (real test order fired, received). Does NOT itself touch `alert_recipient` — that was done separately, in the client |
| 7-PROD | `07-add-rsm-token-PROD.sql` | Same RSM change, built from **Prod's own current view definition** (not the Play script — Prod was missing script 06's hardening too, deliberately not bundled in). Deployed 2026-08-28, `CREATE OR ALTER VIEW` + token registration, verified via diff (exactly 2 lines changed) and against live Prod contacts data |

- Request: `REQUIREMENTS-Evan-2026-06-30.md` · Plan: `PLAN.md`
- Ticket: *none assigned*

## Target environments
- **P21Play** (`P21Play` @ `P21Dev.allsurfaces.com`) → **Prod** (`P21` @ `P21.allsurfaces.com`)
- Play was verified at the **Prod baseline** (2026-07-14) before any change, so the scripts proven in Play are the scripts that run in Prod.
- ⚠ **P21Training is NOT the path.** It carries a one-off `price_page_description` token from 2026-05-26 that exists nowhere else. Reference only — do not promote from it.

## Design — split by AUDIENCE, not by trigger  ⚠ differs from Evan's spec

Evan asked for two alerts split by **trigger** (Standard Cost / MAC) because each needs different recipients. Measured on Prod over 14 days, that design **double-emails**: 239 of 477 alerting orders trip **both** thresholds, so the core team would receive **716** emails — 239 of them a second report of the same order. That works against Evan's stated goal of reducing email churn.

Split by **audience** instead — same policy, no duplicates:

| Alert | Fires when | Recipients |
|---|---|---|
| **Low Margin Alert - Team** (uid 103 in Play) | `low_margin_flag = 'Y'` — **either** margin < 5% | Alex Sivongsay, Order Taker, Justine Daugherty, Sales Rep |
| **Low Margin Alert - Purchasing Escalation (MAC)** (uid 104 in Play) | `percent_profit_off_mac < 5` | **Pam Dundas + Alex Boeve only** |

Both emails carry **both** GM% figures, so the reader sees which threshold failed.

**Core team: 716 → 477 emails, zero duplicates. Pam/Alex: 353 either way.** Verified in Play: at $16.00 (both trip) the team gets **one** email; at $16.15 (standard cost only) the team gets one and purchasing correctly gets **none**.

**Rejected:** a single alert with a *conditional recipient token*. It does work — `p21_sp_alert_generation` strips an `<email_not_found/>` recipient and still sends to everyone else — but it also fires a bogus `<email_not_found/>` message into `alert_queued_mail` every time it doesn't escalate (~9/day of permanent queue noise).

**⚠ This is a deviation from Evan's written spec and needs his sign-off.**

## 🚨 RECIPIENTS — the one thing that must change for Prod

**The Play build has `mgoldyn@allsurfaces.com` as the ONLY recipient, deliberately.**
P21Play has **live SMTP** (`enable_email_functionality = Y`, `email_type = SMTP`, sender `noreply@allsurfaces.com`), so real recipients in Play would send real email to real people.

Before Prod, edit the `alert_recipient` INSERT in `03-create-alerts.sql`:

- **Team alert** → `asivongsay@allsurfaces.com`, `<taker_email>`, `jdaugherty@allsurfaces.com`, `<primary_salesrep_email>`
- **Purchasing alert** → Pam Dundas (`pdundas@allsurfaces.com`) + Alex Boeve (`aboeve@allsurfaces.com`)

Notes:
- Recipients may be **tokens** — `<taker_email>` and `<primary_salesrep_email>` resolve per order. That is how "Order Taker" and "Sales Rep" get on the email.
- `recipient_type_cd`: 1281 = To, 1282 = CC, 1283 = BCC. `record_type_cd` = **1059** (NOT NULL — omitting it fails the INSERT).
- **`sender_email_address` MUST be NULL, never `''`.** P21 only falls back to `alert_default_smtp_sender_email` when it IS NULL; an empty string parks the mail as `reason_cd 1060 "Email system down"` — which reads like an outage but is not.
- **Obtained 2026-07-17** (P21Play `users`, both active `delete_flag=N`): Pam Dundas = `pdundas@allsurfaces.com` (id `PDUNDAS`), Alex Boeve = `aboeve@allsurfaces.com` (id `ABOEVE`).

## Dependencies & deploy order
1. **View first** — the tokens reference its columns; registering a token against a missing column fails.
2. **Tokens second.**
3. **Alerts last** — their `where_clause` and message body reference the tokens.
- `uid`s are **not identity columns** — the scripts supply `MAX+1`. **uids will differ in Prod**; match on **name**, never uid.

## Backward-compatibility notes
- **The live `Low Margin Alert` (uid 97) is untouched and keeps running.** All view columns are additive; `line_item_profit_percentage` and its token are unchanged.
- Run the new alerts **alongside** the old one, compare, and only retire uid 97 on Evan's sign-off.
- ⚠ **The new triggers fire on a different set of lines.** Measured on Prod over 14 days: today 283 emails; the two new alerts together = **716** (477 unique orders, but **239 trip both triggers and so get two emails each**). A combined single alert would send 477. The `low_margin_flag` token was registered to allow that switch **with no further view change** — Evan's call.

## Deploy steps
1. **Diff the Prod view against Play first** (standing rule — Prod drift breaks the STUFF anchors):
   ```sql
   SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_alert_oe_OrderEntry'))
   ```
   Run on both; if the anchors (`'reward_program_id'`, the `oe_line_ud` join) differ, **stop** and re-cut.
2. **Back up the Prod view definition to a file** — this is the rollback artifact.
3. Run `01-alter-view-add-margin-columns.sql` against `P21.allsurfaces.com` / `USE [P21]` (change the `USE`).
4. Run `02-register-tokens.sql` (change the `USE`).
5. Run `03-create-alerts.sql` (change the `USE`) — **with the real recipients substituted in**.
6. All three are **idempotent**; re-running is safe.

## Verification
- All 6 columns present: `INFORMATION_SCHEMA.COLUMNS` on `p21_view_alert_oe_OrderEntry`.
- 6 tokens with **human-readable descriptions** (`p21_apply_alert_token` overwrites the description with the raw column formula — the `UPDATE` in script 02 is **not optional**).
- **Each `where_clause` parses and runs** against the view — proves every token resolves to a column.
- **Every `<token>` in the message body resolves** to a view column, or it renders as literal text in the email.
- **Enter a real low-margin order and read the actual email.** Check: no 6-decimal values (the `p21_fn_MaskDecimal` trap — we use `CAST AS DECIMAL`), and the MAC/Standard Cost figures agree with the Sales Margins tab.

## Price Page Description — `(no price page)` fallback (Evan 2026-07-17)
- Column is now `COALESCE(NULLIF(price_page.description,''),'(no price page)')`. On lines with `price_page_uid = 0` (priced manually / by contract, ~14% of low-margin lines, incl. Evan's `MAP1785142` sample) there is no price page and thus no description — the fallback text prevents a confusingly empty line.
- Applied to `01-alter-view-add-margin-columns.sql` (runs clean on the fresh Prod view) **and** hot-swapped into the live P21Play view (script 01's idempotency guard would skip a re-run, so Play was patched surgically — `scratchpad/swap-pricepage-play.sql`).

## Known open items
- **`Ship Location ID` is mapped to `source_location_id`** (`oe_line.source_loc_id`). Evan did **not** flag it in his 7/17 sign-off, so the source-location mapping is accepted. Still a **line-level** value shown in the header — confirm it renders on the first real Prod email.
- `sales_location_id` and `source_location_id` are registered `available_areas = 32` (event) but used in the **header**. They resolve as view columns; whether P21 renders them there is unproven until the first real email.
- **Regenerate a fresh sample** from the current Play alert and send to Evan — the sample he reviewed was stale (Sell Price merged, price page blank); the current build fixes both.
- The **Sales Margins tab reconciliation** has not been done (the tab shows Standard Cost only — there is no MAC on it anywhere).

## Duplicate — Low PAD Margin Alert (2026-07-31, Play only so far)

Duplicate of the Team/Purchasing split, scoped to the PAD product group that the original alert deliberately **excludes**. Replaces (eventually) the older, separate `Low PAD Margin Alert` (active since 2025-12-18) that fires on the legacy `line_item_profit_percentage < -5` column with `Taker` "does not begin with" ESTORE — that alert stays **untouched** for now, same pattern as uid 97.

Confirmed with user before building:
- **Trigger:** reuse the new `low_margin_flag` / `percent_profit_off_mac` columns (NOT the legacy `line_item_profit_percentage` measure) — keeps one consistent margin definition across every Low Margin variant.
- **Recipients:** same Team + Purchasing Escalation split as the non-PAD alert.
- **Taker filter:** `NOT LIKE '%ESTORE%'` (does not *contain*) — matching the non-PAD alert, not the old PAD alert's "does not begin with."

**Script:** `04-create-pad-alerts-PLAY.sql` — built and run in **Play only** (uid 105 "Low PAD Margin Alert - Team", uid 106 "...Purchasing Escalation (MAC)"), `row_status_flag = 704`, `mgoldyn`-only recipients, same as the original Play-first build pattern. Both `where_clause`s verified to parse cleanly against the view.

**PROD DEPLOY — EXECUTED 2026-08-03**, after user reviewed the Play build. Ran `05-create-pad-alerts-PROD-INACTIVE.sql` against **P21** — created **uid 106 "Team"** / **uid 107 "Purchasing Escalation (MAC)"** at `row_status_flag = 705` (INACTIVE — no PAD-alert-equivalent stakeholder sign-off yet, confirmed with user before deploying) with the real recipient list. View/tokens already present from the 2026-07-31 deploy, reused as-is. Parity vs. Play confirmed via `Compare-LowMarginAlert-Prod-vs-Play.ps1` (now checks all 4 alerts). Same warning applies: once Play refreshes from Prod, Play's copy will carry real recipients too.

**⚠ PLAY REFRESH SAME DAY (2026-08-03, later) — the Prod-inactive deploy above never reached Play.** Confirmed via `msdb..restorehistory`: the backup used for that refresh was taken 12:01–12:28 AM, roughly 7 hours *before* the 7:49 AM deploy above. A same-day deploy is not automatically safe against a same-day refresh — check the actual backup timestamp, not just the calendar date. Rebuilt the pair directly in Play (`04-create-pad-alerts-PLAY.sql`) — **it never fired** across multiple confirmed-tripping test orders. Root cause narrowed but not proven: rebuilding manually in the P21 client surfaced that `Low Margin Flag` is missing from the filter grid's Column dropdown despite being correctly registered in `token`/`alert_type_x_token` — signature of a stale AHI-API1 client-side metadata cache, not a data problem. Per the user's standing preference (SQL-built alerts have a real history of not firing reliably), the SQL-built Play copy was deleted and **both alerts are being rebuilt manually in the P21 client** using the field export at `Alerts\Low-Margin-Alert\PAD-Alert-Fields-For-Manual-Rebuild.txt`. Not yet confirmed firing as of this note. See [[project_2026_07_13_low_margin_alert]] for the full investigation.

## Hardening — NULL-token collapse bug in `p21_sp_alert_generation` (2026-08-11)

Unrelated blank-email incident (`uid 102 "Test Verify Alerts"`, a leftover diagnostic — deactivated, not part of this alert family) led to reading `p21_sp_alert_generation`'s actual definition for the first time. Confirmed: it chains `REPLACE(@PX, '<column>', @value)` once per token registered for the alert's **type** (all 5 OE alerts share the same token pool, not just the tokens each one's own template references), and `REPLACE()` returns NULL if any argument is NULL — **even when the search pattern isn't present in the string.** So a single NULL token anywhere in the OE pool can blank this alert's email too, regardless of whether its own template mentions that token.

Audited `p21_view_alert_oe_OrderEntry` for every OE-token column not already guarded; found 6: `order_profit_percentage`, `extended_price`, `total_amount`, `line_item_profit_percentage`, `fill_quantity`, `fill_extended_price`. **Measured against 90 days of real order lines (~1.5M rows) in Play/Training/BusinessRules** with filters matching the view's own WHERE clause exactly — zero actual NULLs or divide-by-zero conditions in any of them today. This is insurance against a future edge case, not a fix for an observed failure (the triggering incident's own order had no NULLs in these fields either).

**Applied via `06-harden-oe-view-null-tokens.sql` (`CREATE OR ALTER VIEW`) to P21Play, P21Training, P21BusinessRules** — confirmed byte-identical view definitions across all three before patching; verified equivalent on existing data first (0 diffs), then confirmed all three compile/query cleanly post-patch. **NOT yet applied to Prod** — user wants that done after hours, since Prod's copy of this view is live for other real, currently-firing alerts (not just this still-inactive Low Margin/PAD family). Before running there: diff Prod's view against Play's first (per the standing rule two sections up) since Prod's Low Margin columns were added via a separate PROD-suffixed script and may have drifted.

**Status: PAD pair mid-rebuild in the client, not yet confirmed firing. RESUME: confirm manual rebuild fires on a fresh test order; separately, run the after-hours Prod diff/deploy for script 06.**

## Rollback
1. **Deactivate the two new alerts first** (stops email immediately) — **`704 = ACTIVE, 705 = INACTIVE`**, so set 705:
   ```sql
   UPDATE alert_implementation SET row_status_flag = 705
   WHERE alert_implementation_name IN ('Low Margin Alert - Team','Low Margin Alert - Purchasing Escalation (MAC)');
   ```
2. Delete them (children first — FK order): `alert_recipient` → `alert_message` → `Alert_implementation_query` → `alert_implementation`.
3. **Restore the view** from the backup taken in step 2 of the deploy.
4. **Drop the 6 tokens — child tables first:**
   ```sql
   DELETE FROM Alert_implementation_query WHERE column_id IN (<uids>)
   DELETE FROM alert_type_x_token         WHERE token_uid IN (<uids>)
   DELETE FROM token                      WHERE token_uid IN (<uids>)
   ```
- The live alert (uid 97) is untouched throughout, so rollback fully restores prior behavior.

**Post-go-live rollback (after 2026-09-04)** — the fastest safe revert, no deletes:
```sql
-- turn the four new alerts back off
UPDATE alert_implementation SET row_status_flag = 705
WHERE alert_implementation_name IN (
  'Low Margin Alert - Team','Low Margin Alert - Purchasing Escalation (MAC)',
  'Low PAD Margin Alert - Team','Low PAD Margin Alert - Purchasing Escalation (MAC)');
-- bring the two legacy single-alerts back
UPDATE alert_implementation SET row_status_flag = 704
WHERE alert_implementation_name IN ('Low Margin Alert','Low PAD Margin Alert');
```
Legacy 97/100 were only deactivated at go-live, so this restores the exact prior behavior. Do the flag flips **by SQL**, not through Rule Manager/Alert Maintenance where avoidable.

**Rolling back script 06 alone** (the NULL-token hardening, independent of the rest): `CREATE OR ALTER VIEW` back to the pre-06 definition saved when each environment was patched (Play/Training/BusinessRules — no separate backup file was taken since script 06 is provably a no-op on all existing data; the pre-06 text is recoverable from git history on `06-harden-oe-view-null-tokens.sql`'s parent commit, or from `OBJECT_DEFINITION` on any environment not yet patched).

## 2026-09-14/17 — Evan's follow-up asks: WRITTEN, NOT YET RUN

Three items came out of the 9/14 monitoring-phase thread (same order, 6132881). Evan confirmed scope on all three (9/16); all three are scoped and scripted but **none has executed against Prod yet** — attempts to run them from this session were blocked by the Claude Code permission classifier as production/shared-resource writes (correctly — these touch a live, currently-firing view and four active alerts). **Run manually (SSMS or `!`-prefixed terminal), in this order:**

1. **`09-add-pricing-unit-size-PROD.sql`** — adds `pricing_unit_size` (decimal, `CAST(ISNULL(oe_line.pricing_unit_size,1) AS DECIMAL(19,2))`) to `p21_view_alert_oe_OrderEntry` and registers it as a token (`available_areas=4` line-item body, `data_type_cd=853` decimal), following the exact proven pattern from script 08 (anchor-based `STUFF`, `CREATE`→`ALTER`, `p21_apply_alert_token`). **Diffed Prod's view against the 9/14 saved copy first — byte-identical, no drift**, backup saved to the session scratchpad before building. Ask: Evan believes Sell Price/MAC/Standard Cost may render in a different unit than the order UOM already shown — confirmed true and common (18.2% of low-margin lines/120d have a different pricing-unit **code** than the order UOM; 11.2% have a size-conversion factor even when the codes match), not a rare edge case. He simplified the original three-part ask ("tag each value") down to *"let's just add the Unit Size for now"* (9/16) — technically the same size of change as the full ask, since `pricing_unit_size` wasn't exposed either way.
2. **`10-add-surfacing-closeout-eo-exclusions-PROD.sql`** — adds `product_group_id <> 'SURFACE'` to the exclusion list on 104/105 only (106/107 already scope to `PAD`, so Surfacing can never match there), and `job_name NOT LIKE '%CLOSEOUT%' AND job_name NOT LIKE '%E&O%'` to **all four** alerts (Evan, 9/16: *"should apply to all four alerts please"*). Guarded — aborts if any alert's current `where_clause` doesn't match the exact 9/14-verified baseline text. "Surfacing" confirmed as a real, existing `product_group_id = 'SURFACE'`; CLOSEOUT/E&O confirmed live in `job_name` (real matches: "Closeout Quote", "E&O 2025", etc.) — 44 + 60 = 104 of 9,783 low-margin lines/120d (~1.1%) would have been suppressed.
3. **Body template edit (all four alerts, in the client)** — after script 09 lands, add `Unit Size: <pricing_unit_size>` to the Req Date/UOM line: `Req Date: <line_required_date>   |   UOM: <unit_of_measure>   |   Unit Size: <pricing_unit_size>`. Must run **after** 09 — the token doesn't exist until then, and would otherwise render as the literal `<pricing_unit_size>` text (same failure mode documented under [[feedback_p21_alert_available_areas]]).

**Status: 🟡 scripted for Prod, PROVEN structurally in Play, functional test still in progress.** Reply to Evan covering both asks already sent (9/14); his answers folded into the scripts above (9/16).

## 2026-09-17 — Play brought to full parity; both new features built there for testing

Before testing, checked whether Play matched Prod — it did not. `where_clause` drift on the PAD pair (106 still on the pre-9/14 `low_margin_flag='Y'` bug; 107 a hybrid `percent_profit_off_mac<5 AND low_margin_flag='Y'` matching neither the old nor the fixed design) and body drift on all four (104 missing its `Sell Price` line, `Price Overridden` in the pre-Evan-feedback position, a leftover `[OVR=<price_edit>]` subject tag; 105/106/107 missing `Price Overridden` entirely). Fixed all of it via guarded UPDATEs (same verify-before-write pattern as every Prod change in this guide), then ran Play equivalents of scripts 09 and 10 successfully — `pricing_unit_size` column + token (`token_uid 746`) added, Surfacing/Closeout/E&O exclusions applied to all four, `Unit Size: <pricing_unit_size>` added to all four bodies on the Req Date/UOM line.

**Test item found from live data:** `CON58006121` (CON Airstep Plus Goldenrod 12'), `pricing_unit_size = 9` — a real instance of the SY-ordered/differently-priced case Evan described — 97K+ SF on hand at location 100, paired with All Tile, Inc. (`1000260`, an established safe test customer).

## 2026-09-18 — new durable trap found; test-order troubleshooting (in progress)

**Found: the Alert Maintenance client's Filter grid regenerates the entire `where_clause` from its own grid rows on save — silently destroying any SQL-only condition.** Confirmed live: a guarded SQL fix to Play's 107 had set `where_clause` correctly, but never touched the underlying `Alert_implementation_query` grid, which still held a stale `percent_profit_off_mac=5` row (from before the fix) and a dormant `low_margin_flag=Y` row untouched since 8/3. The user, working from what the client displayed (correctly reflecting the stale grid), changed the displayed "5" to "-5" and saved — the save rebuilt the whole clause from every active grid row, silently dropping the `job_name` CLOSEOUT/E&O exclusion (no grid representation exists for it) and reintroducing the dormant flag row. Re-fixed via SQL. **uid 106 (Team) has NO grid row at all for its OR-based fix (`percent_profit_off_mac < -5 OR percent_profit_off_standard_cost < -5`) in either Play or Prod — any future client save of it will silently revert it to the old +5% bug.** Banked as trap 10 in `feedback_p21_alerts.md`. **Standing rule going forward: never open uid 106's Filter tab in the client, in either environment — SQL-only maintenance from here on.**

**Test-order troubleshooting, corrected twice against real data:**
- Order 6062516 — wrong price basis. Assumed Sell Price should be entered "per pricing unit" (~$1.15, comparable to MAC $1.12); P21 actually prices per **order unit**, and the view's `unit_mac`/`unit_standard_cost` are scaled to the same order-unit basis (`cost × pricing_unit_size` = $10.08). Comparing $1.15 against $10.08 produced a nonsense -776% margin, and `total_amount` (computed from the same $1.15) landed at $115 — nowhere near `> 1000`.
- Order 6062517 — corrected price ($10.35, giving realistic 2.61%/3.09% margins and `total_amount = $1,035`) — still didn't fire. `extended_standard_cost` is a **per-line** figure (≈$111 at 100 SY) and every alert requires it `> 500`; the order-level total passing doesn't help a line that's individually under the bar.
- **Corrected recipe, not yet tested:** same item/price, qty raised to **500 SY** (`extended_standard_cost ≈ $557`, `total_amount ≈ $5,175`) — should clear every filter.

**Status: 🟡 Play structurally complete and correct (verified by direct SQL query, not by a successful fire yet); functional proof still pending.** No Low Margin alert has fired on the updated Play build as of end of session. Prod untouched — scripts 09/10 remain staged, blocked on a manual run, pending Play proof. Next: build the 500 SY order, confirm fire + Unit Size render, run a negative suppression test, then execute 09/10 on Prod.

## 🟢 2026-09-20/21 — Play proven end-to-end; grid-regeneration trap fully mitigated; 09/10 + body edit deployed to Prod. LIVE, feature-complete.

**Positive test — order 6062519.** 500 SY of `CON58006121` under All Tile, Inc. — the corrected recipe from 9/18 (price re-based to the order-unit basis, qty raised so `extended_standard_cost` clears the per-line $500 floor). Both 104 and 105 fired, landed in Outlook **Inbox** (not the usual `Epicor\Alerts` folder this time), subjects `[P21Play] Low Margin - Order# 6062519...` / `[P21Play] Low Margin vs MAC (Purchasing) - Order# 6062519...`. Bodies confirmed correct: `Unit Size: 4.00` rendered from the new `pricing_unit_size` token, `Price Overridden: Y` positioned above Price Page Description per Evan's 9/14 feedback. Math cross-checked against the view's own predicted SQL before accepting the fire as valid proof.

**Negative/suppression test — order 6062520.** Built to trip the Surfacing/Closeout/E&O exclusions added 9/16–9/17. Only the decoy (`uid 102`, fires on any new order) landed — confirms the suppression logic added in script 10 actually suppresses on a live fire, not just in a `where_clause` parse-check.

**Grid-regeneration trap (trap 10, banked 9/18) resurfaced for real — now fixed with an actual data sync, not just an operational warning.** Investigating why 105's Filter tab in the client didn't display `SURFACE` in the Product Group ID row (it had been added by SQL only, per script 10) reconfirmed that the Alert Maintenance client's Filter grid (`Alert_implementation_query`) **rewrites `where_clause` wholesale from its own active rows on every Save** — a SQL-only condition with no grid row is invisible to the client and gets silently dropped the next time anyone saves that alert's Filter tab, even for an unrelated edit. Per the user's explicit instruction — *"We need to have the screen in sync, incase someone wants to edit other than me"* — did a full grid sync on **both Play and Prod**:

- **104/105** — updated the existing Product Group ID grid row (`column_value`/`column_value_description`) to include `SURFACE`.
- **All four (104/105/106/107)** — added new grid rows for `job_name NOT LIKE '%CLOSEOUT%'` and `job_name NOT LIKE '%E&O%'` (operator code 1102 = "does not contain").
- **106 only** — repointed its dormant `low_margin_flag = Y` grid row (untouched since 8/3) to `percent_profit_off_mac < -5`. This is a **partial** fix only: 106's real trigger is `(percent_profit_off_mac < -5 OR percent_profit_off_standard_cost < -5)`, and P21's grid is AND-only — an OR across two columns cannot be fully represented. The repointed row is the single closest safe approximation. **106's Filter tab must permanently never be opened-and-saved in either environment** — any save reverts it to whatever the grid says, which can never be the full correct OR.

For 104/105/107, this is now a **full, genuine sync** — a future client Save on any of those three will regenerate the exact correct `where_clause` from the grid. Verified via before/after `where_clause` byte-equality on every edit (captured, diffed, confirmed unchanged) — none of the grid-only edits touched live firing behavior.

**New reusable technical detail on `Alert_implementation_query`:** `alert_implementation_query_uid` is **not** a true IDENTITY column — it's generated via a real SQL Server **SEQUENCE**, `NEXT VALUE FOR dbo.seq_alert_implementation_query` (safe to call directly, does not require the `p21_set_counter` workaround used elsewhere for IDENTITY-adjacent counters). `column_value_description` is **NOT NULL** and must mirror `column_value` on every INSERT/UPDATE — omitting it throws "Cannot insert the value NULL into column 'column_value_description'"; the first Play sync attempt hit this on all 8 inserts before the fix, and the fix was carried into the Prod script from the start (succeeded first try).

**Token 126 rename — attempted, unresolved cosmetically, zero functional impact.** With the user's approval ("yes Job Name is good"), renamed token 126's `description` from "Job" to "Job Name" for readability on Play. The DB write succeeded (confirmed via direct query) but the P21 client never displayed the new text — not after restarting the client (desktop and web), not after recycling the UI Server's IIS app pool (`API1-P21PlayDB - P21 SOA-uiserver0`, the same pool/pattern that fixes stale menu/security caching elsewhere — see [[feedback_p21_uiserver_stale_cache]]). Left open as an unresolved, low-priority mystery — user's working theory is a hardcoded display string in the compiled client for old/stock pre-2016 tokens, which is plausible but unconfirmed. Applied the same rename on Prod for consistency regardless (same non-display behavior expected there).

**Prod deployment — executed and fully verified, 2026-09-21.**
1. `09-add-pricing-unit-size-PROD.sql` — ran clean, `pricing_unit_size` column + token registered as `token_uid 746` (matches Play's own 746).
2. `10-add-surfacing-closeout-eo-exclusions-PROD.sql` — **hit a real bug not seen on Play**: the script's guard clauses compare `where_clause = @expectedNNN`, and on Prod this threw "data types text and nvarchar(max) are incompatible in the equal to operator" (`where_clause` is a legacy `text` column; Prod's driver/config path evaluates the implicit conversion differently than Play's). **Fixed by wrapping every guard reference in `CAST(where_clause AS NVARCHAR(MAX))`** — this fix is now permanent in the committed script, so any future re-run on any environment won't hit it again. After the fix, ran clean: all four `where_clause`s updated with the Surfacing (104/105) and Closeout/E&O (all four) exclusions, parse-checked against the live view.
3. Body edit — added `Unit Size: <pricing_unit_size>` to all four alerts' `line_item` template, same Req Date/UOM line position as Play.
4. Grid-sync — same three fixes described above, applied to Prod (`sync-grid-prod.ps1`), verified clean on the first attempt (lesson from Play's `column_value_description` miss applied proactively).

All four steps independently re-verified via direct SQL re-reads against Prod after the fact (grid rows, `where_clause` text, token registration, row_status_flag still 704 on all four).

**Status: 🟢 LIVE on Prod, feature-complete.** Only open item is the cosmetic token-126 rename display mystery — zero functional impact, not worth further investigation unless it recurs on a token that matters.

## 2026-09-21 (later) — three real fired alerts, one new feature scoped + built in Play

Three real alert emails from Evan generated their own findings, each answered on its own thread:

1. **Order 6138356 (Lippert Tile Co) — genuine item-costing error, not an alert bug.** Evan asked whether Standard Cost was mistakenly entered at the Purchase Pricing Unit. Checked the item master: `purchase_pricing_unit_size = 1.0` (already each-based) — so it was the raw dollar value itself keyed at the case rate ($63.61 ≈ 12 × the real $5.30 each cost), not a UOM setup problem. Confirmed `unit_mac`/`unit_standard_cost` in the view use identical formulas with the same `pricing_unit_size` multiplier — no calculation bug on our side. Already corrected in the data by Purchasing the same day. **Follow-on catalog scan** (120-day order history, real orders only): 6 more items with the same near-round-ratio signature (Tego, After It, SCI Luxury, Mapeguard corner trim — ratios ~10x–21x), plus a separate finding of 33 items across 40+ orders sitting at P21's literal `$99,999`/`$99,999.99` "never costed" placeholder instead of a real cost. Delivered as a two-tab spreadsheet, `Reports\Standard-Cost-Anomalies-2026-09-21.xlsx` (not committed to the repo — ad hoc output), attached to a reply looping in Erik Bullock.
2. **Order 6143117 (Arlun Floor Covering Denver) — root cause of the earlier PAD-threshold bug, explained on request.** Evan asked why 1.52% margin fired when he thought the PAD threshold was -5%. This order was built 9/10, four days *before* the 9/14 fix — at that time the PAD Team alert (106) still used the main alerts' `low_margin_flag` (hardcoded `<5%`, positive) instead of `<-5%`. 1.52% is under 5%, so it correctly fired under the bug live that day; it would not fire today. Owned as a build mistake in the reply.
3. **Order 6163019 (Tim's Construction Group) — new feature, scoped then built.** Evan asked whether contract pricing info could be shown when `Price Page Description` reads `(no price page)`. Traced the price to P21's **Job/Contract Pricing** mechanism (`job_price_hdr`/`job_price_line`) — separate from Price Pages, which the view never looked at. Measured over 120 days: of 228,898 lines showing `(no price page)`, 35,986 (~16%) have an active, approved contract price behind them.

### Contract/job price fallback — scoped and built in Play, NOT yet proven by a live fire

`Alerts\Low-Margin-Alert\11-add-contract-price-description-PLAY.sql` (committed). Additive `LEFT JOIN`s only (`job_price_line`, `job_price_hdr`, the latter filtered to `approved='Y' AND cancelled='N'`) — **no new token, no body-template edit needed**, since `price_page_description` is already wired into every alert's body. `price_page_description` now falls back:

```
1) real price page description (unchanged)
2) "Contract Price[: <job_description>][ (Contract #<contract_no>)]" when
   price_page_uid=0 but an approved, active job/contract price exists
3) "(no price page)" (unchanged, when neither applies)
```

Verified structurally against real Play data (job #5787, contract #1023680, customer "Efrain Reyes(ASI)", blank `job_description`) — renders cleanly as `Contract Price (Contract #1023680)`, no double-space artifact from the blank description field (first draft of the CASE expression had that bug, fixed before committing).

**Test recipe, not yet run:** customer **1023680** ("Efrain Reyes(ASI)", confirmed not excluded by the alert's own `where_clause` — not in the excluded customer list, `corp_address_id = 1023680` ≠ the excluded `1046538`), item **`XLBXLGS4G`**, ship-from location **220** (546 available), qty **340 EA**, let the sell price auto-populate from the active contract (should land at $3.00/EA vs. $31.57 standard cost — trivially trips low margin). Expect `total_amount ≈ $1,020`, `extended_standard_cost ≈ $10,734`. Check the email for `Contract Price (Contract #1023680)` in place of `(no price page)`.

**Status: 🟡 scoped + built in Play, structurally verified, no live-fire proof yet. No Prod script exists.** Reply to Evan sent as non-committal ("I'll investigate whether it's possible") since this hasn't been proven live. Tracked as Todo-BusApps #21.

## Separate, unresolved finding from the same testing session — order cancellation/deletion mechanics (KB0022345)

While cleaning up Low Margin Alert test orders (6062516–6062520), investigated the difference between P21's **Cancel** action and the `delete_flag` on `oe_hdr`, using **KB0022345** for reference. This is **not part of the Low Margin Alert feature** — it belongs to the Cancel-order stored procs project and is documented there (`Deploy-Guides\cancel-order-stored-procs.md`, `project_2026_09_09_cancel_order_procs.md`) — noted here only because it was found during this alert's test-order cleanup. Per the user's explicit instruction, KB0022345 is to be referenced when reporting these findings to Matt (not yet drafted).

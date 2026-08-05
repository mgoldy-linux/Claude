# Deployment Guide — SA-51376 RMA Transaction History: Reason Code Column

> Status: **Planned, not yet built.** User will make the DynaChange change directly in the P21 client (knows the steps); this guide documents the plan and the data source so it's captured before/while they do it. Update this file once the column is actually added and tested.

## Goal
On the **Transaction Master Inquiry** screen, **RMA** tab, add a **Reason Code** column between the existing `Class 1` and `Taker` columns (per user's annotated screenshot, `SA-51376-Transaction-History-Inquiry.PNG`), via **DynaChange**.

## Data source (confirmed against P21Play — corrected 2026-08-05)
User supplied and validated the real query:
```sql
SELECT lst.transaction_no AS [RMA No], ls.lost_sales_desc
FROM lost_sales_transaction lst
JOIN lost_sales ls ON lst.lost_sales_uid = ls.lost_sales_uid
WHERE lst.transaction_no = 6000380
```
- `lost_sales_transaction.transaction_code_no = 2145` is P21's stock code for **"Order - RMA"** (confirmed via `p21_view_code_p21`; `2143` = "Order - Cancel Order" — same table is reused across transaction types). This is **header-grain**, keyed directly on `oe_hdr.order_no = lost_sales_transaction.transaction_no` — captured at RMA entry, not at receipt.
- Validated: order `6000380` → "Shipping Error or Wrong Item Shipped". Sampled 10 more RMAs at code 2145, all clean single rows (e.g. `DN`/"Doesn't Need", `WCB`/"Wrong Customer Billed", `DEFECTIVE`/"Defective").
- Confirmed **no `transaction_no` has more than one row at code 2145** in Play — safe as a plain join, no risk of row multiplication, no aggregation needed.
- This resolves the grain concern below: no line-level aggregation needed, and it will populate even for **Open/unreceived RMAs** since it's captured at RMA entry, not at receipt.
- **Superseded finding, kept for the record:** `rma_receipt_line.reason_adjustment_id` → `p21_view_reason.reason` is a *real, populated* field (141,574/240,198 rows in Play) but is **receipt-line grain, not what this screen uses** — do not build against it. Also ruled out `oe_line.reason_id` (0 of 262,251 rows populated anywhere in Play — a red herring, not what drives the value shown in P21's UI).
- "Reason Code" and "Lost Sales Desc" turn out to be **the same field** on this screen — the original SA text wasn't conflating two different things.

## Performance note (measured against P21Play)
The user's query filters only on `transaction_no`, but the existing index on `lost_sales_transaction` is keyed `(lost_sales_uid, transaction_code_no, transaction_no)` — `transaction_no` is the last key column, so SQL Server can't seek on it. Measured **3,082 logical reads** for a single-order lookup on a 752K-row table (a scan, not a seek). If DynaChange evaluates this per visible grid row, cost adds up on a screen showing hundreds of RMAs at once.
- Recommend: add `AND lst.transaction_code_no = 2145` to the query (matches the RMA tab's own scope, cheap to add).
- Recommend (bigger win, needs a decision — new index on a stock P21 table): `CREATE INDEX ... ON lost_sales_transaction (transaction_no, transaction_code_no) INCLUDE (lost_sales_uid)` to allow a seek. Not yet built or requested.

## Trap to watch for (learned the hard way on SA-47981)
If this is added as a DynaChange **screen-only column**, P21 auto-prefixes the real field name with `ufc_p21soc_` (e.g. a column named `reasoncode` becomes `ufc_p21soc_reasoncode`). Confirm the real name via a `Data.Fields` dump if any rule/SQL ever needs to reference it — the un-prefixed name will silently never match. See `feedback_p21_dynachange_screen_only_columns`.

## Resolved — Prod has 21 role-based DynaChange versions of this screen
Not a single base-class customization; Production has **21 separate DynaChange Version Manager versions** of "Transaction Master Inquiry Orders," one per security role. The screen-only column must be added to **each one individually** for the change to be visible to every role. User-supplied list (`version_id`, Prod):

1. `screen_transaction_master_inquiry_orders_all`
2. `screen_transaction_master_inquiry_orders_warehouse office`
3. `screen_transaction_master_inquiry_orders_warehouse manager`
4. `screen_transaction_master_inquiry_orders_warehouse`
5. `screen_transaction_master_inquiry_orders_system admin`
6. `screen_transaction_master_inquiry_orders_sales manager`
7. `screen_transaction_master_inquiry_orders_purchasing`
8. `screen_transaction_master_inquiry_orders_product manager`
9. `screen_transaction_master_inquiry_orders_outside sales`
10. `screen_transaction_master_inquiry_orders_marketing`
11. `screen_transaction_master_inquiry_orders_management`
12. `screen_transaction_master_inquiry_orders_customer service manager`
13. `screen_transaction_master_inquiry_orders_customer service`
14. `screen_transaction_master_inquiry_orders_claims`
15. `screen_transaction_master_inquiry_orders_branch manager`
16. `screen_transaction_master_inquiry_orders_accounts receivable manager`
17. `screen_transaction_master_inquiry_orders_accounts receivable`
18. `screen_transaction_master_inquiry_orders_accounts payable`
19. `screen_transaction_master_inquiry_orders_accounting`
20. `screen_transaction_master_inquiry_orders_accounts_receivable_admin_accounts receivable admin`
21. `screen_transaction_master_inquiry_orders_vendor maintenance`

This also explains the earlier "Open item" below — searching the classic `dynachange` table by `base_class` came up empty because this screen is managed through the **DynaChange Version Manager** (`p21_view_dynachange_version_manager_versions_roles` et al.), not a flat base/personalized class pair.

## Target environment
- **Build and test in P21Play first** (per user, 2026-08-05).

## Deploy steps
1. Build and verify the column once in **P21Play**.
2. Once the requestor approves in Play, repeat the same column addition in **Prod**, once per version in the 21-item list above. Track completion against that list so none are missed.

## Build steps (documented live, per version — P21Play)
**Step 1 — Open DynaChange Screen, select the DynaChange, update the comment.**
Open the DynaChange screen → **Open** dialog → **Version** list shows all 21 role-based versions (`screen_transaction_master_inquiry_orders_*`) — confirms the list above matches what's actually in the client. Select the version to update (starting with `screen_transaction_master_inquiry_orders_all`, Role: ALL). The **Comments** box carries a running dated changelog per version, e.g.:
```
-added carrier, class 1 | 20260805 - SA 51376 Add RMA Reason Code
```
Append a new dated line for this change (`YYYYMMDD - SA 51376 Add RMA Reason Code`) following that same convention before making the column change, so the version's history stays intact.
Screenshot: `OneDrive - All Surfaces Inc\Pictures\Screenshots\Screenshot 2026-08-05 123332.png`.

**Step 2 — Right-click the grid, select Field Chooser.**
With the DynaChange version open in edit mode, right-click (RMB) on the grid → context menu → **Field Chooser** (other options present: Recall Documents, Remove This Column, Modify Dropdown List, MyMenu, Tasks, Services, Help).
Screenshot: `OneDrive - All Surfaces Inc\Pictures\Screenshots\Screenshot 2026-08-05 123509.png`.

**Step 3 — In the Field Chooser window, click New.**
The Field Chooser window lists existing custom fields already on this screen (currently: `Order Type`). Click **New...** (bottom left; a "Show Tooltip" checkbox sits next to it) to start defining the Reason Code field.
Screenshot: `OneDrive - All Surfaces Inc\Pictures\Screenshots\Screenshot 2026-08-05 123604.png`.

**Step 4 — New Field dialog: Field Type = Existing Database Column.**
The **New Field** dialog opens with **Field Type** dropdown (set to `Existing Database Column`), a **Field Name** box (blank so far), a grayed-out **Include dropdown list** checkbox, and an **Edit...** button (where the source column/query gets defined) alongside OK/Cancel.
Screenshot: `OneDrive - All Surfaces Inc\Pictures\Screenshots\Screenshot 2026-08-05 123710.png`.

**Step 5 — Click the Edit button.**
On the New Field dialog (Step 4), click **Edit...** to define the source for the field. (No screenshot provided for this step yet.)

**Step 6 — Select Database Column dialog: click Add Table.**
Edit opens the **Select Database Column** dialog: **Table Name** dropdown, **Column Name** dropdown, **Add Table...** button, a grayed-out **Edit Join...** button (enables once a second table is added), and OK/Cancel. This is how the `lost_sales_transaction` → `lost_sales` join gets built visually (add both tables, then define the join) rather than pasting raw SQL. Click **Add Table...** to add the first table.
Screenshot: `OneDrive - All Surfaces Inc\Pictures\Screenshots\Screenshot 2026-08-05 123913.png`.

**Wizard sequencing rule (learned the hard way across Steps 7-8): a table you Add doesn't actually join into the working query until you also pick a column from it.** The Select Database Column dialog's "Add Table" only registers the table name/join text — it does **not** commit the table into the query being tested/built. That only happens once you select a **column** from that table in the Column Name dropdown. This is why Step 7's second-table test failed with "could not be bound" against `lost_sales_transaction` even though it had already been added: no column had been picked from it yet, so it wasn't really in scope. Correct order for a multi-table field:
1. Add Table `lost_sales_transaction`, set its Join Syntax.
2. **Pick a column from `lost_sales_transaction`** (e.g. `lost_sales_uid`) — this is what actually commits the table into the query.
3. *Then* Add Table `lost_sales`, set its Join Syntax (referencing `lost_sales_transaction.lost_sales_uid`, now valid since step 2 committed it).
4. Pick `lost_sales_desc` from `lost_sales` — the actual field being built.
5. `lost_sales_uid` from step 2 is now a required-but-unwanted column (needed to keep the join valid, not meant to display) — see Step 8 for how to hide it.

**Step 7 — Add `lost_sales_transaction`, join test FAILED — root cause found and fixed (measured).**
Added `lost_sales_transaction` via Add Table with Join Syntax `JOIN lost_sales_transaction on oe_hdr.order_no = lost_sales_transaction.transaction_no`. **Test failed.** Screenshot shows Original 3,864,423 rows vs. Modified 752,214 rows.

Root cause (reproduced and measured against P21Play, not guessed):
- The plain `JOIN` (inner join) **silently drops every order with no matching `lost_sales_transaction` row from the entire grid** — not just a blank new column. Base query = 3,864,423 rows; with the inner join as typed = 752,214 rows (exact match to the screenshot's "Modified" count) — ~3.1M orders would vanish from Transaction Master Inquiry entirely.
- Switching to a plain `LEFT JOIN` alone is **not** sufficient either — tested and it **inflates** the row count to 4,256,861, because some orders have more than one `lost_sales_transaction` row across different `transaction_code_no` values, so rows would duplicate on screen.
- **Fix (measured — reproduces the exact base row count of 3,864,423, i.e. zero rows dropped or duplicated):**
  ```sql
  LEFT JOIN lost_sales_transaction ON oe_hdr.order_no = lost_sales_transaction.transaction_no
      AND lost_sales_transaction.transaction_code_no = 2145
  ```
  Must be `LEFT JOIN` (not `JOIN`), and `transaction_code_no = 2145` must be part of the **ON clause**, not a `WHERE` filter (a `WHERE` filter would turn the outer join back into an inner join for non-matching rows).
- Apply the same fix to the `lost_sales` join once it's added in Step 8 (the earlier validated query already carries `ON lst.lost_sales_uid = ls.lost_sales_uid`, which is fine as-is — no code filter needed there since `lost_sales_uid` is already the exact row from the filtered `lost_sales_transaction` join).

**Step 8 — Add `lost_sales`, same inner-join bug recurred, then a wizard-only trap around hiding the join key.**
- Hit the identical bug shape again: `lost_sales` was added as a plain `join`, dropping ~3.7M rows (3,864,424 → 163,083 modified). Fix: `LEFT JOIN` (no extra code filter needed here — `lost_sales.lost_sales_uid` is that table's own PK, one-to-one, no fan-out risk).
- Building the `lost_sales_desc` field requires `lost_sales_uid` (the join key) to also be selected as a column — but it isn't wanted as a visible grid column. **Removing it via the wizard's "Remove This Column" broke the build**: `The multi-part identifier "lost_sales_transaction.lost_sales_uid" could not be bound.` The wizard derives which tables belong in the query from which columns are currently selected — dropping `lost_sales_uid` mid-build dropped `lost_sales_transaction` out of scope, orphaning the `lost_sales` join's `ON` clause.
- **Fix: set the column's width to `-1`** (not remove it, not toggle a visible flag) — hides it on the grid while keeping it functionally present so the join chain stays intact. Simpler than the SQL-level `visible="0"` approach originally suggested; keep this as the standard trick for "need a join-key column present but not shown" on P21 Field Chooser fields going forward.

*(Next steps to be added as they're performed.)*

## Verification
- RMA tab of Transaction Master Inquiry shows a Reason Code column; a known RMA (e.g. order `6000380` in Play → "Shipping Error or Wrong Item Shipped") displays the correct text.
- **Reason is a required field at RMA entry — blanks should NOT occur, for Open or received RMAs alike.** Confirmed against Play: **163,083 of 163,084** RMA orders have a `lost_sales_transaction` row at code 2145; the single exception is a legacy 2018-12-17 record predating the requirement. A blank Reason Code on any current RMA is a data anomaly worth investigating, not an expected display state — don't treat it as "working as intended" the way the superseded receipt-line approach's blanks-until-received would have been.

### Testing status (P21Play)
Tested so far:
- Role **`_all`** — tested by mgoldyn.
- Role **`customer service manager`** — tested by `island2` (the actual requestor's role).
- Both roles tested on **both desktop and web** clients.

**Data correctness — CONFIRMED (2026-08-05).** Cross-checked a 25-RMA report pull (location 100, `_all` role) against Play's live `lost_sales_transaction`/`lost_sales` data directly via SQL: **24 of 25 matched exactly** on first pass. One discrepancy investigated:
- **Order 6051092**: report showed "Doesn't Need," SQL cross-check showed "Shipping Error or Wrong Item Shipped." Investigated thoroughly before concluding anything — confirmed the database is unambiguous: exactly **one** `lost_sales_transaction` row exists for this order across *any* transaction code (not just 2145), pointing to `lost_sales_uid = 6` ("Shipping Error..."), created 7/28/2026 9:15:08 AM and **never modified since**. "Doesn't Need" (`lost_sales_uid = 31`) has zero database linkage to this order — ruled out duplicate rows, alternate codes, and a modified/edited value.
- **Root cause: stale/cached report pull, not a data or join-logic bug.** A fresh single-RMA pull of 6051092 immediately after showed "Shipping Error or Wrong It..." — matching the live database. The field/join logic is correct; the first report pull just showed a cached value.
- **Net result: 25/25 confirmed correct** once re-verified. No fix needed to the field itself.

**Hidden `lost_sales_uid` column — CONFIRMED (2026-08-05).** User confirmed the `width=-1` hide trick behaves the same on both desktop and web — no stray blank column on either client.

**Open/unreceived RMA behavior — CORRECTED (2026-08-05).** Originally assumed blank was expected/acceptable for RMAs without a match. **Wrong** — reason is a required field at RMA entry, so essentially every RMA (163,083/163,084 in Play) has one regardless of receipt status. Nothing to "confirm" here beyond the data check above; a genuinely blank Reason Code on a current RMA would indicate a real data problem, not normal behavior.

Still not yet confirmed — worth covering before calling Play sign-off complete:
- **Long description truncation** — confirm the column is wide enough that longer `lost_sales_desc` values aren't cut off (some are noticeably longer than "Doesn't Need," e.g. "Shipping Error or Wrong Item Shipped").
- **Performance sanity check** — the join chain includes an unindexed scan on `lost_sales_transaction` (~3,082 logical reads per lookup, see Performance note above); worth a quick check that opening the RMA tab with a normal date range doesn't feel noticeably slower than before.
- **Changelog comment** — the `custom_objects.version_desc` dated-history convention (used throughout this session, e.g. for the `ds_view_open_rma_value` work) hasn't been logged yet for the Reason Code change itself on either tested role.
- **Only 2 of the 21 Prod role versions tested so far.** Fine for Play proof-of-concept, but the Deploy steps section still calls for repeating the build across all 21 in Prod — worth deciding whether any other roles should get a Play test pass first, or whether these 2 are sufficient to greenlight the full Prod rollout.
- **Explicit requestor sign-off** — `island2` testing it is a strong signal, but worth getting an explicit "looks good, ready for Prod" before proceeding, per your usual ticket-closure practice.

## Rollback
- Remove the DynaChange screen-only column / revert via DynaChange Version Manager if it needs to come out.

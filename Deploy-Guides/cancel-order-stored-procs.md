# Deployment Guide — Cancel-Order Stored Procedures (no ticket)

> ## ⚠ READ FIRST
>
> **These procs write directly to `oe_hdr` and `oe_line`, bypassing P21's application layer.**
> They were **reverse-engineered from a SQL Profiler trace** of the client's Cancel Order action on
> order 5923021 (2026-07-22) — they are a *reconstruction*, not a supported interface. They exist to
> clean up **test orders in lower environments**.
>
> **Do not deploy to Prod.** Not because they would fail, but because their mere presence puts a
> one-command "cancel every open order for this user" inside production. If you ever genuinely need
> this in Prod, cancel through the client.

---

## Artifacts

| File | What it is |
|---|---|
| `Sql-Scripts/Store Procedures/CREATE-OR-ALTER-PROC-asi_cancel_order.sql` | Cancels ONE order. Deploy first — the wrapper calls it |
| `Sql-Scripts/Store Procedures/CREATE-OR-ALTER-PROC-asi_cancel_open_orders_by_user.sql` | Cancels every open order for a taker; per-order try/catch; `@preview_only` mode |
| `Sql-Scripts/Cancel-Test-Orders-All-Lower-Envs.sql` | Preview/cancel across all four lower databases in one connection; reports "proc NOT deployed" per DB |
| `Sql-Scripts/Analyze-Lost-Sales-Transaction-On-Cancel.sql` | Read-only. The investigation behind Phase 5 |
| `Docs/Cancel_Order_SP_Guide.docx` | Earlier written guide — **still untracked in git** |
| `CSV-In/Cancel-Order-Trace.csv` | The 3.8 MB source Profiler trace — **still untracked** (raw evidence, large) |

## Target environments

**Lower only** — `P21Play`, `P21Dev`, `Training`, `Business Rules`. All four live on
**`P21Dev.allsurfaces.com`**, so deployment is one connection with four `USE` statements, not four
sessions.

⚠ Confirm the real database names before scripting against them — the notes disagree
(`Training` vs `P21Training`, `Business Rules` vs `P21BusinessRules`):
```sql
SELECT name FROM sys.databases WHERE database_id > 4 ORDER BY name;
```

## 🔁 The refresh problem — why these keep "disappearing"

Every lower environment is restored **from Prod**, and these procs are deliberately *not* in Prod.
**So every refresh deletes them.** Combined with the fact that they sat untracked in git for seven
weeks, that is why they were assumed lost.

Two options, and the second was chosen:

1. Put them in Prod so refreshes carry them down — **rejected**: an order-cancelling proc in
   production is a worse problem than redeploying occasionally.
2. **Treat redeploy as a known post-refresh step.** Tracked in `Docs/P21-Env-Status-Customizations.txt`
   per environment. `Cancel-Test-Orders-All-Lower-Envs.sql` reports which databases are missing them,
   so the check is one query.

## Deploy order

1. `CREATE-OR-ALTER-PROC-asi_cancel_order.sql` — **base proc, first**
2. `CREATE-OR-ALTER-PROC-asi_cancel_open_orders_by_user.sql` — depends on the base
3. Repeat per database

Both are `CREATE OR ALTER`, so re-running is safe and grants are preserved.

## What the procs actually do

Four phases mirroring the client, plus a fifth added 2026-09-09:

1. `oe_hdr` → `cancel_flag='Y'`, `completed='T'` (P21's intermediate state; triggers fire here)
2. Open `oe_line` rows → `disposition='C'`, `qty_canceled = qty_ordered`, `qty_allocated = 0`
3. `oe_hdr` → `completed='Y'`, `profit_percent = 0`
4. Cancelled lines → `complete='Y'`
5. **`lost_sales_transaction` rows** — see below

P21's own triggers handle `audit_trail`, `inv_loc_stock_status` and `customer_order_history`.
**Nothing is deleted** — `delete_flag` stays `'N'`; this is a cancel, exactly as the client does it.

## Phase 5 — `lost_sales_transaction` (added 2026-09-09)

The original proc left this table empty while a client cancel populated it. There is **no trigger** on
it (verified) — it is application-layer behaviour, which is why a proc rebuilt from a trace of the
UPDATEs never reproduced it. Verified against the client's cancel of order **6062441** (9 rows) plus
20 further orders:

| Fact | Verified value |
|---|---|
| `lost_sales_transaction_uid` | **IDENTITY**, no P21 counter → omitted from the INSERT, **no drift risk** |
| `lost_sales_uid` | **Varies** — 120d: uid 31 = 13,201 rows, 16 = 4,352, ~20 more → a **parameter**, default 16 ("Other") |
| `affect_usage` | **Mirrors the chosen reason's own flag** (Lead Time / No Stock / Wrong Customer Billed are `N`) → looked up, not hardcoded |
| `transaction_code_no` | **2143** = "Order - Cancel Order" (2142 = Cancel Quantity) → hardcoded; this proc only does whole-order cancels |
| Shape | N line rows + **exactly one** trailer row (`line_no` NULL, `sku_qty_change` NULL) |
| `sku_qty_change` | **`qty_ordered`**, not `unit_quantity` — clearest on 6062080 where those are 4200 vs 100 |

Phase 2 uses an `OUTPUT` clause so Phase 5 writes rows only for lines *that execution* cancelled,
never a line already sitting at `'C'`.

### Two decisions still open

- **`@write_lost_sales`** defaults `'Y'` (faithful to the client). But `affect_usage='Y'` means these
  rows feed **usage and demand history** — replaying them injects fabricated lost demand from orders
  that only existed to test an alert. The batch wrapper arguably should default to `'N'`.
- **`@lost_sales_uid`** defaults 16 ("Other") because that is what the observed client cancel used —
  but **31 ("Doesn't Need") is far more common in real data**, and may be the better default.

### ⚠ Known limitation — partially shipped lines

Every verification sample had `qty_invoiced = 0`, so **P21's own behaviour on a partially shipped line
is unverified**. As written, Phase 2 sets `qty_canceled = qty_ordered` outright and Phase 5 reports the
same, which would **over-state both the cancelled quantity and the lost demand** on a line with
shipments against it. Confirm before pointing this at any order that has shipped.

## Usage

```sql
USE P21Play;
GO
-- always preview first
EXEC dbo.asi_cancel_open_orders_by_user @user_id = 'MGOLDYN', @preview_only = 'Y';
```

⚠ **`@user_id` matches `oe_hdr.taker`, which holds the users *ID* (`MGOLDYN`), not the display name.**
Passing `'Mark Goldyn'` silently matches nothing — preview mode makes that a safe failure, since an
empty list means wrong id, not "no orders".

⚠ It targets **every** open order for that taker — `delete_flag='N' AND cancel_flag='N' AND
completed='N' AND rma_flag='N'` — not just recent ones. Read the preview.

## Verification

```sql
SELECT name, create_date, modify_date FROM sys.procedures WHERE name LIKE 'asi_cancel%';
```

Then cancel a throwaway multi-line order and diff its rows against a client-cancelled order:

```sql
SELECT * FROM dbo.lost_sales_transaction WHERE transaction_no = <proc-cancelled order>;
```

Expect N line rows + 1 trailer, `transaction_code_no` 2143, `affect_usage` matching the reason.

## Rollback

There is no "un-cancel". A cancelled order stays cancelled — reverse it in the client, or restore the
environment. To remove the procs themselves:

```sql
DROP PROCEDURE dbo.asi_cancel_open_orders_by_user;   -- wrapper first
DROP PROCEDURE dbo.asi_cancel_order;
```

## Status

**🟡 Phase 5 written and redeployed to P21Play by the user 2026-09-09 — but NEVER RUN.** Untested.
The other three lower environments are unconfirmed. Next action is the verification diff above.

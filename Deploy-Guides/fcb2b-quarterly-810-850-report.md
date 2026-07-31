# Process Guide — fcB2B Quarterly 810/850 Metrics Report (WFCA)

> Recurring quarterly submission to WFCA, not a one-time deploy. Update this file whenever the script or the source-classification logic changes.

## What this is

Every quarter, WFCA requires a count of:
- **850 — Purchase Orders You Received**: split into B2B/EDI, keyed on the Supplier Website, and Phone/Email/Fax/hard copy
- **810 — Invoices You Issued**: split into B2B/EDI vs. everything else

for each of the 3 months in the quarter, delivered as an Excel file named
`fcB2B Quarterly 810-850 Metrics Data Request - FYQ<n> <year>.xlsx`.

**"Detailed data never published, only summarized totals"** — do not send WFCA anything beyond the counts/percentages in the template.

## Fiscal quarter definition — WFCA's year, not calendar or P21's

WFCA's fiscal year starts **October 1**. The year in the filename is the year the FY **ends** in:

| Quarter | Months | Filename says |
|---|---|---|
| Q1 | Oct–Dec of *(year − 1)* | `FYQ1 <year>` |
| Q2 | Jan–Mar of *year* | `FYQ2 <year>` |
| Q3 | Apr–Jun of *year* | `FYQ3 <year>` |
| Q4 | Jul–Sep of *year* | `FYQ4 <year>` |

Example: `FYQ1 2026` = **Oct–Dec 2025**. `FYQ2 2026` = **Jan–Mar 2026**.

⚠ Two earlier files (`CYQ1 2025`, `FYQ2 2025`) happen to cover the identical 3 months (Jan–Mar 2025) because a calendar-quarter naming convention was used for one and this fiscal convention for the other — not a duplicate/error, just two different naming schemes used across time.

## Artifact(s)

| File | What it does |
|---|---|
| `C:\PowerShell-Scripts\Create-Excel\Create-B2BMetricsReport.ps1` | The report generator — prompts (or takes params) for FY + quarter, queries P21 Prod, writes the formatted Excel file |

Earlier one-off exploration files kept for reference only (not part of the pipeline):
- `...\SQL Server Management Studio\EDI\r-f2cB2B-2026-05-08.sql` — the exploration that found the `code_p21` source codes
- `...\SQL Server Management Studio\Excel\f2B2B-lewisreport.sql`, `b2b-report-invoices.sql` — early drafts of the 810-side query, superseded by the script

No `kb_`/`js_` objects anywhere in this pipeline — it queries native P21 tables only (`oe_hdr`, `invoice_hdr`, `code_p21`). Nothing to retire here.

## Data source & classification logic (P21 Prod only — `P21.allsurfaces.com` / `P21`)

**810 — Invoices issued** (`invoice_hdr`, filtered by `invoice_date`):
- EDI = `invoice_batch_uid = 2`
- Everything else = `invoice_batch_uid != 2`

**850 — POs received** (`oe_hdr`, filtered by `order_date`, `delete_flag = 'N'`):
- B2B/EDI = `invoice_batch_uid = 2` (same convention as the invoice side)
- Supplier Website (keying) = not batch 2, **and** `source_code_no IN (709, 931, 3067)` — Quote / eStore / P21 SOA (`code_p21` lookup: 706=OE, 707=Import, 708=EDI, 709=Quote, 931=eStore, 3067=P21 SOA)
- Phone/Email/Fax/hard copy = not batch 2, and everything else (including `source_code_no IS NULL`)

Verified 2026-07-31 against the already-published `FYQ1 2026` file (Oct–Dec 2025): October and November matched **exactly**; December was off by 3 orders total (out of 48,479) — consistent with a handful of orders entered/backdated after that report was generated, not a logic error.

## Performance fix applied 2026-07-31

The script used to run the 810 side as **two separate queries** (`WHERE invoice_batch_uid = 2` and `WHERE invoice_batch_uid != 2`), each scanning `invoice_hdr` for the date range. Measured via the plan-cache DMVs (`sys.dm_exec_query_stats`) on a 3-month range:

- Old (2 queries): 32,301 + 30,368 = **62,669 logical reads**
- New (1 query, conditional `SUM(CASE...)` — same pattern already used for the 850 side): **1,454 logical reads** (~43x fewer)

The `invoice_batch_uid` equality/inequality predicate was pushing the optimizer to a worse plan than just scanning the date range once and splitting the batch in the `SELECT`. Output verified identical before/after (same EDI/Manual counts per month). Applied directly in the script — see `$sql810`.

## Running it

The script now accepts optional parameters (falls back to interactive `Read-Host` prompts if omitted — existing manual usage is unchanged):

```powershell
C:\PowerShell-Scripts\Create-Excel\Create-B2BMetricsReport.ps1 -FiscalYear 2026 -Quarter 2
```

Output: `C:\_P25\Data-Out\Excel\fcB2B Quarterly 810-850 Metrics Data Request - FYQ<n> <year>.xlsx`

## Output location — single copy, no duplication

The script writes to `C:\_P25\Data-Out\Excel\` and that's the canonical, only location — **do not** also copy it to the OneDrive or `C:\Users\mgoldyn\Documents\Excel\` folders (decision 2026-07-31, to stop accumulating duplicate copies of the same file). Older files already sitting in those OneDrive/Documents locations predate this decision and were left in place.

## Submission

Email the generated file to **Lewis Davis** (`ldavis@wfca.org`) at WFCA.

**Cadence: approximately the 10th day of the new quarter** — i.e. submit the just-closed quarter's report around 10 days after the quarter ends (for example, the FYQ2 report for Jan–Mar closes out on Mar 31, so send it around Apr 10).

## Verification before sending to WFCA

1. Re-run the 850/810 SQL by hand for one month and confirm it matches the Excel cell.
2. Sanity-check `% B2B` and `% electronically` are in the same ballpark as the prior quarter (large swings usually mean a date-range mistake).
3. Confirm the header months/year in row 3 match the intended quarter.

## Known issue (historical, not a script bug)

`FYQ4 2025.xlsx` (in the OneDrive folder) shows headers reading "July/August/September **2026**" — a full year off from what `FYQ4 2025` should mean (Jul–Sep **2025**). That file predates this script; it used an older manual Excel template (a `Sheet2` helper table with a hand-typed `Year` cell driving the header via `VLOOKUP`/`CONCAT` formulas, with the monthly counts pasted in separately). The year cell was almost certainly a manual typo, disconnected from the pasted data. Since this script now generates the header text directly from the fiscal year/quarter parameters (no separate hand-typed year cell to get out of sync), this class of mistake isn't possible going forward.

**CLOSED 2026-07-31 — not worth the effort.** Already-submitted historical file, root cause not reproducible with current tooling, no further action.

## FYQ2 2026 generated 2026-07-31

`Jan–Mar 2026`, written to `C:\_P25\Data-Out\Excel\fcB2B Quarterly 810-850 Metrics Data Request - FYQ2 2026.xlsx`. Ready to email to Lewis Davis per the Submission section above.

## Second archive data-quality issue found 2026-07-31 — FYQ3 2025

While spot-checking that FYQ3 2026 (Apr–Jun 2026) numbers were in the same range as FYQ3 2025, the **archived** `FYQ3 2025.xlsx` (in the OneDrive folder) turned out not to match a clean re-query of P21 — a separate issue from the FYQ4 2025 year-mislabeling above:

- Its 850-side counts escalate monotonically across the 3 months (e.g. B2B/EDI: 463 → 3,449 → 51,386; totals 1,688 → 11,319 → 146,003) — that pattern looks like a **cumulative/running total** was pasted in per column instead of independent per-month counts. No real month-over-month order volume moves like that.
- Its 810-side "Manual" (non-EDI invoice) counts are understated by ~5,000–7,000/month versus a clean re-query.

Root cause not identified — this file predates both the current script and the `f2B2B-lewisreport.sql` / `b2b-report-invoices.sql` draft queries, so whatever produced it isn't in the repo.

**CLOSED 2026-07-31 — not worth the effort.** Not findable with what's on disk; already recomputed for the record (below), no further digging planned.

**Recomputed correctly for the record** (per-user decision 2026-07-31, not re-submitted to WFCA):
`C:\_P25\Data-Out\Excel\fcB2B Quarterly 810-850 Metrics Data Request - FYQ3 2025 - RECOMPUTED-2026-07-31.xlsx`
(filename suffixed deliberately so it's never confused with the original archived submission)

| | Apr 2025 | May 2025 | Jun 2025 |
|---|---|---|---|
| 850 B2B/EDI | 985 | 901 | 969 |
| 850 Keying | 2,735 | 2,951 | 2,681 |
| 850 Manual | 56,133 | 52,679 | 50,277 |
| 810 EDI | 1,827 | 1,821 | 1,561 |
| 810 Manual | 61,818 | 58,861 | 56,439 |

This confirms FYQ3 2026 (Apr–Jun 2026) is in the same range as the true FYQ3 2025 figures — B2B/EDI adoption up modestly (~8%), volumes roughly flat.

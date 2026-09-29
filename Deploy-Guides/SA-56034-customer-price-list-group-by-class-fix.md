# SA-56034 — My Customer Price List 2.2: "Group Items by Class" fails (Msg 8120)

## Symptom
SSRS `My Customer Price List - 2.2` (and, via the same proc, `/Company Reports/Pricing/Customer Price List v2.2`)
errors with **Group Items by Class (AT style) = True**:

> Column '#cpaa.contract_price' is invalid in the select list because it is not contained in either an aggregate
> function or the GROUP BY clause. (rsProcessingAborted / rsDataSetExecutionError)

Group by Class = False works. The "shared data set 'Customers'" in the message is a red herring (the customer
dropdown dataset); the failing query is DataSet1, which calls `dbo.asi_proc_customer_pricing_loc_items`.

## Root cause
In the manufacturing-class branch (the `UNION` with `GROUP BY`), `customer_price` was built as
`case when cpaa.contract_price is null then Min(cpaa.price) else Min(cpaa.contract_price) end`.
The bare `cpaa.contract_price` in the `CASE` test is neither aggregated nor grouped. SQL Server raises Msg 8120 when it
reaches the statement, which is why Group by Class = False (a different code path) never hits it.

## Fix
One line in `dbo.asi_proc_customer_pricing_loc_items`:

```sql
CASE WHEN MIN(cpaa.contract_price) IS NULL THEN MIN(cpaa.price) ELSE MIN(cpaa.contract_price) END AS customer_price,
```

Script: `Sql-Scripts\Customers\SA-56034-Fix-asi_proc_customer_pricing_loc_items-group-by.sql`
(full live definition with only that line changed, `CREATE OR ALTER` so grants are kept).
The script begins with `USE P21; GO` — **change or remove that for any environment other than Prod's `P21` database**
(lower envs live on `P21Dev.allsurfaces.com`, database `P21Play` / `P21Dev` / etc.).

## Status
| Env | State |
|---|---|
| asdwdb01 `P21` (data warehouse — **the report's actual data source**, restored from Prod nightly ~2:05) | Bug reproduced 2026-09-29. A patch here is **temporary** (wiped by the nightly restore) — OK for testing in SSRS, but the lasting fix must be deployed to Prod first; it reaches the warehouse at the next restore |
| asdwdb01 SSRS test 2026-09-29 | Company-wide `Customer Price List v2.2`, Group by Class = True: **Msg 8120 before patch; after patch no error and price rows displayed** (temporary patch — nightly restore reverts it until Prod is patched) |
| P21Play | **Patched and tested 2026-09-29** — cust 1034300, loc 140, 946 items: Group=Y 801 rows / Group=N 839 rows, no error |
| Prod (`P21.allsurfaces.com`) | **Patched 2026-09-29** (user-confirmed). Warehouse picks it up at the next nightly restore |

Lower-env refresh from Prod overwrites the Play patch — the Prod deploy is what makes it stick.

## Deploy to Prod
1. Confirm Prod's proc still matches what was patched: `SELECT modify_date FROM sys.objects WHERE name = 'asi_proc_customer_pricing_loc_items'`
   (was 2026-04-06 when read from asdwdb01). If it changed, re-diff before overwriting.
2. Run the script against Prod `P21` (proc owner/maintainer of the report: rguderjahn — give a heads-up).
3. Verify: run the report (or the `EXEC` below) with Group by Class = True; expect rows, no Msg 8120.
4. Confirm the `contract_price` column is populated for a customer with contract lines.

```sql
DECLARE @cust DECIMAL(19,0) = 1034300;
DECLARE @acpi AS dbo.asi_TableTypeItemDec;
INSERT INTO @acpi (item_id)
SELECT DISTINCT im.item_id
FROM job_price_customer_shipto jpc
JOIN job_price_hdr  jh ON jh.job_price_hdr_uid = jpc.job_price_hdr_uid
JOIN job_price_line jl ON jl.job_price_hdr_uid  = jh.job_price_hdr_uid
JOIN inv_mast       im ON im.inv_mast_uid       = jl.inv_mast_uid
WHERE jpc.customer_id = @cust;
EXEC dbo.asi_proc_customer_pricing_loc_items '1', @cust, 140, @acpi, 'N', 'Y';
```

## Rollback
Re-create the proc from the pre-change definition (Prod `OBJECT_DEFINITION` captured 2026-09-29 from asdwdb01; the only
diff is the one line above).

## Also noted (not changed)
- "My Reports" version: the Customer dropdown is filtered to the running user's customers — a user with none sees an empty list
  and cannot run the report. The company-wide version is not filtered.
- kb_ dependencies still present (`kb_view_item_classifications_loc100` x5, `kb_fn_pricing_convert` x3, plus
  `kb_view_customer` / `kb_view_users` / `kb_view_ccs_locations` in the RDL). Retirement plan: Work-Log 2026-09-01.

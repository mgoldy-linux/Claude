# P21 Item Maintenance — what "add a location" actually writes

**Captured:** 2026-09-15, BRR (P21BusinessRules), via XE trace
`Sql-Scripts\Dynachange\Create-XE-ItemMaintLocPopup-Trace.sql`
**Context:** SA 54806. The ask was a sort option on the "Select Additional Locations"
popup; the real requirement is adding multiple locations at once. This documents what
P21 does on Save so a bulk path can be evaluated.

**Test case:** item `inv_mast_uid = 152830`, added locations **181, 380, 400**, company `'1'`.

---

## Sequence

1. **Counter block allocated up front**, increment = number of rows:
   ```sql
   exec p21_get_counter N'inv_bin',1
   exec p21_get_counter N'inventory_supplier_x_loc',3
   exec p21_get_counter N'inv_loc_msp',3
   ```
   `inv_loc` gets **no** counter — it is keyed by `inv_mast_uid` + `location_id`.

2. `set implicit_transactions on` — everything below is one transaction, ending
   `IF @@TRANCOUNT > 0 COMMIT TRAN`.

3. Writes, in order:
   | Table | Rows | Notes |
   |---|---|---|
   | `inv_mast` | 1 UPDATE | date_last_modified, default_selling_unit |
   | `inv_loc` | **35 UPDATE** | every pre-existing location row, not just the new ones |
   | `inv_loc` | **3 INSERT** | the actual adds |
   | `inv_bin` | 1 INSERT | only for the location with `track_bins = 'Y'` |
   | `inventory_supplier` | 1 UPDATE | |
   | `inventory_supplier_x_loc` | **39 UPDATE** | again, all existing rows |
   | `inventory_supplier_x_loc` | **3 INSERT** | uid from counter block |
   | `item_uom`, `item_conversion` | 1 UPDATE each | |
   | `inv_loc_msp` | **3 INSERT** | uid from counter block |

---

## The three INSERTs per location

**`inv_loc`** — ~60 columns. Representative values from location 400:

```
location_id=400, company_id='1', inv_mast_uid=152830,
gl_account_no='14000000400', revenue_account_no='40003000400', cos_account_no='50004000400',
purch_or_transfer='P', sellable='Y', stockable='N', buy='N', make='N',
replenishment_location=400, replenishment_method='Up To', safety_stock=7.0,
safety_stock_type=1261, demand_pattern_behavior_cd=1885, demand_pattern_cd=1785,
product_group_id='FINISHED', purchase_discount_group='DEFAULT',
sales_discount_group='ROP.STC', tax_group_id='DEFAULT',
price1..price6 = 92.71 / 60.58 / 56.33 / 76.51 / 72.22 / 71.10,
lot_bin_integration='N', default_shipment=1138, price_family_uid=3,
track_bins='N', default_in_oe='N', usage_lock='N', delete_flag='N'
```

**`inventory_supplier_x_loc`**
```sql
( inventory_supplier_x_loc_uid, inventory_supplier_uid, location_id, primary_supplier,
  average_lead_time, row_status_flag, date_created, date_last_modified,
  last_maintained_by, vmi_status, loc_list_price, loc_cost )
VALUES ( 5304497, 157026, 181, 'Y', 7, 704, ..., 1271, 0, 0 )
```

**`inv_loc_msp`**
```sql
( inv_loc_msp_uid, inv_mast_uid, location_id, receipt_process_flag, row_status_flag,
  date_created, created_by, date_last_modified, last_maintained_by )
VALUES ( 4890742, 152830, 181, 'N', 704, ... )
```

**`inv_bin`** (only when `track_bins='Y'`)
```sql
( company_id, location_id, bin, quantity, date_created, date_last_modified,
  last_maintained_by, inv_mast_uid, qty_allocated, inv_bin_uid, row_status_flag )
VALUES ( '1', 380, 'NOBIN', 0, ..., 152830, 0, 1929607, 1037 )
```

---

## Traps — why hand-rolling this is riskier than it looks

1. **The `inv_loc` column list is not fixed.** PowerBuilder emits a different column
   set per row depending on which fields are non-default. Location 380 included
   `primary_bin='NOBIN'` (it had `track_bins='Y'`); 181 and 400 omitted the column
   entirely. There is no single canonical INSERT shape to copy.

2. **GL accounts are looked up, not computed.** Location 380 got
   `gl_account_no='14000000100'` — location **100**'s number, not 380's. P21 queried
   `d_ds_inventory_defaults` three times just before the writes. Deriving these by
   string concatenation on location_id would silently produce wrong GL accounts, which
   is a finance problem, not a cosmetic one.

3. **Conditional side effects.** `inv_bin` is written only for locations with
   `track_bins='Y'`. Miss it and bin-tracked locations are half-created.

4. **Defaults come from several sources** — item pricing, product group, supplier,
   `inventory_defaults` per location. Reproducing P21's defaulting is the hard part;
   the INSERTs themselves are trivial by comparison.

## Performance observation

The save rewrites **every existing row**, not just the new ones — 35 `UPDATE inv_loc`
and 39 `UPDATE inventory_supplier_x_loc` for 3 additions. Standard PowerBuilder
"update the whole buffer" behavior. It scales with the item's location count, which is
why Item Maintenance saves drag on heavily-stocked items. Relevant to any design that
loops saving items one at a time.

No `kb_`/`js_` references anywhere in this write path.

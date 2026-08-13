# Epicor Support Case: WWMS PO Receiving Deposit Bin Never Defaults

## Summary

On the wireless WWMS **Purchase Order Receipts > Deposit** screen, the **Deposit Bin** field is always blank when receiving a PO line, regardless of whether the item has a primary bin, current on-hand quantity, or any other bin configuration. This happens for both brand-new items with no history and long-established, actively-stocked items. We can find no combination of item/location/system settings that causes this field to auto-populate on this specific screen, and a SQL-level trace shows the application never queries the item's bin data at all during this step of the transaction.

## Environment

- **Instance:** Business Rules (WWMS Testing) — non-production
- **P21 version:** 2021.1.5795 (per client app identifier `PXXI/ReadU/2021.1.5795/UISERVER-FULL`)
- **Database:** `P21BusinessRules` on `P21Dev.allsurfaces.com`, port 3444
- **Interface:** WWMS wireless/RF client (`Setup > Wireless Warehouse > WWMS Transaction > Receiving > WWMS Purchase Order Receipts`)
- **Location:** 221

## Steps to Reproduce

1. Open **WWMS Purchase Order Receipts**
2. Enter a PO number and line (see two independent test cases below)
3. Enter item ID and quantity, press Next
4. Land on the **Receiving - Purchase Order Deposit** screen
5. **Expected:** Deposit Bin field pre-populates with a default bin
6. **Actual:** Deposit Bin field is always blank; "Put In Bin" is left for manual entry

## Test Case 1 — brand-new item, no history

- Item: `GUN131P5` (`inv_mast_uid` 145306), PO `4271997`, line 1, location 221
- Initial state: `inv_loc.primary_bin = 'NOBIN'`, `qty_on_hand = 0`
- Action taken: set `inv_loc.primary_bin = 'B01A'` (confirmed valid — not frozen, not put/pick-locked, zero current weight/volume, real bin in the location's DEFAULT put zone)
- Result: Deposit Bin still blank after the change, after re-entering the transaction, and after recycling the WWMS UI Server's IIS app pool (`API-P21BusinessRules - P21 SOA-uiserver0`) to rule out server-side caching

## Test Case 2 — established, actively-stocked item

- Item: `SCHKERECK/FI10` (`inv_mast_uid` 118337), PO `4319516`, line 35, location 221
- State: `inv_loc.primary_bin = 'H03C'`, real on-hand qty = 35 in that exact bin (not zero, not ambiguous)
- Result: Deposit Bin still blank

This second case rules out "item has no stock yet" as an explanation — this is a normal, real, currently-used item with a valid, populated primary bin, and it behaves identically to the brand-new item in Test Case 1.

## Diagnostic Steps Already Taken

1. **Confirmed the underlying data is correct.** Directly queried the exact SQL the WWMS client uses to read `inv_loc` (captured via trace, see below) — it returns the correct `primary_bin` value for both test items.
2. **Ruled out server-side caching.** Recycled the WWMS UI Server IIS app pool for this instance (`API-P21BusinessRules - P21 SOA-uiserver0`, on AHI-API1) between attempts. No change in behavior, and the underlying SQL data was already confirmed correct even before the recycle.
3. **Ruled out the standalone Putaway module / zone-list mechanism as the driver of this screen.** The System Directed Putaway algorithm (`p21_putaway_main`) is a *separate* mechanism (Setup > Wireless Warehouse > Inventory Operations > System Directed Item Putaway, or the Putaway Trace tool) governed by putaway zones, zone lists, ranks, and attributes. We confirmed via direct proc calls that this algorithm **correctly** identifies `H03C` as the suggested bin for `SCHKERECK/FI10` at location 221 (via the "Primary Bin/Algorithm" putaway strategy, `system_setting.putaway_strategy = 2153`). Since the Putaway module correctly finds this bin but the Receiving Deposit screen does not, they are clearly not using the same logic.
4. **Ran a SQL Server Extended Events trace** (`rpc_completed` + `sql_batch_completed`, filtered to this database) covering the entire client-server interaction from PO number entry through landing on the blank Deposit screen. **No query referencing `inv_loc`, `primary_bin`, or any bin-related table fires at any point during this flow.** The only `inv_loc`-related query in the entire session happened earlier and unrelated, before the PO was even entered. This strongly suggests the Deposit Bin default (if any) is not being computed from the database at all during this transaction step.
5. **Checked `location.po_receipts_bin_uid`** ("PO Receipts Default Bin ID" on the Location Maintenance Inventory tab, per community guidance that this is checked before falling back to the item's primary bin) — blank for location 221, which per that guidance should mean "fall back to primary bin." It does not.
6. **Checked the `po_receipts_use_primary_bin` system setting** (`Inventory Management > Receipts > Purchase Order Receipts`) — currently `O` ("Default Only if Primary Bin Exists"). Note: on closer reading of the WWMS User Guide, this setting's documented behavior is specifically described in the context of the **856 EDI Receipt approval screen** (Receipt Selection screen's Approve/Clear buttons), not the standard wireless PO Receiving Deposit screen — so it may not even apply here, which would be consistent with everything observed above.

## Question for Epicor

What actually determines the default value of the Deposit Bin field on the wireless WWMS Purchase Order Receipts > Deposit screen specifically (not the desktop/terminal PO Receiving screen, and not the standalone System Directed Putaway module)? Is this field expected to ever auto-populate on this screen, and if so, under what configuration?

## Contact

Mark Goldyn — mgoldyn@allsurfaces.com

/*───────────────────────────────────────────────────────────────────────────────
  SA 54033 - "Available Inventory with Dye Lot" - lot/bin mismatch
  Item CBVCPR9258 ("Chassis Pro Backbone 7X48"), inv_mast_uid 103353,
  Location 342 (Tri-State Sioux Falls). Reported on order # 6125351.

  ============================  ROOT CAUSE (confirmed)  ==========================
  lot.qty_on_hand for lot 056 (lot_uid 289617) = 0, while the physical stock,
  the bin record, and the bin->lot link all carry 1,818.70:

    inv_bin        G14D .quantity           = 1,818.70   (alloc 0)
    lot_bin_xref   056 -> G14D .qty_linked  = 1,818.70   (alloc 0)
    inv_loc.qty_on_hand (loc 342)           = 3,077.80   (includes the 1,818.70)
    SUM(inv_bin.quantity)  loc 342          = 3,077.80   -> reconciles
    SUM(lot_bin_xref.qty_linked) loc 342    = 3,077.80   -> reconciles
    SUM(lot.qty_on_hand)   loc 342          = 1,259.10   -> SHORT by 1,818.70
                                                            (all of it = lot 056)

  The Lot tab hides 056 because its header qty is 0, so lot-traceable order
  allocation cannot see the 1,818.70 even though availability (rolled up from
  inv_bin) shows it. "Shows available, cannot book."

  HOW IT BROKE (inv_tran_lot_detail, lot 056, loc 342):
    2026-02-26 15:39  +1818.70   putaway
    2026-03-02 10:41  +1818.70   second putaway (G14D not created yet)
    2026-03-03 10:42            hjohnson creates bin G14D + lot_bin_xref @ 1818.70
    2026-03-03 16:49  -1818.70   jphipps txn 5671236: decremented the LOT HEADER
                                 (qty + alloc) but did NOT cascade to inv_bin
                                 G14D or the lot_bin_xref row - both untouched
                                 since 10:42:53 that morning.
    + 3 more alloc/dealloc cycles, all netting to 0.
  The lot's own transaction detail nets to 0, so it is internally consistent
  with the wrong header - which is why p21_rebuild_* in Prod did not catch it
  (nothing rebuilds the lot bucket from the bin / xref side).
  lot_bin_dealloc_report and p21_unallocate_orders_lot_info are both empty for
  this item - no pending P21 cleanup queued.

  ============================  OUTCOME (P21Dev, 2026-09-10)  ===================
  Ran extended Rebuild Inventory Quantities (Setup/System/Rebuild Inventory
  Quantities) for CBVCPR9258 / loc 342, BOTH boxes ticked:
    [x] Perform extended rebuild
    [x] Allow system to affect Inventory Value if needed (FIFO/Lot Costed/Tag)
  Retrieve -> screenshot -> Save.

  RESULT - clean fix, before -> after:
    lot 056 qty_on_hand            0        -> 1,818.70
    SUM(lot.qty_on_hand) @ 342     1,259.10 -> 3,077.80   (= inv_bin = xref = inv_loc)
    inv_loc.qty_on_hand           3,077.80 -> 3,077.80    UNCHANGED - no GL posting
    inv_loc.qty_allocated           923.34 ->   923.34    unchanged
    inv_bin / lot_bin_xref        0 rows changed
    inv_tran_lot_detail           NO new row posted
    lot 028 .000000000 -> .000000279  (float normalization, harmless)

  Mechanics: bare `UPDATE lot SET qty_on_hand` - did NOT stamp
  last_maintained_by / date_last_modified on lot 056 (still jphipps /
  2026-07-07), and posted no transaction. Functionally fine (P21 allocates off
  lot.qty_on_hand) but no audit trail of the correction. inv_loc did not move,
  so the KB's "G/L postings must be made manually" note does not apply here -
  it was a lot-bucket reclass within an already-correct, already-valued total.

  Post-fix precondition check (allocatable):
    lot 056 lot_free = 1,818.70 ; bin G14D bin_free = 1,818.70 ;
    pick_locked_flag = N ; row_status_flag = 1037. -> OE can book it.

  Client threw "extended rebuild was processed but some issues remain ... please
  save to correct" - extended rebuild wants a 2nd/3rd Retrieve+Save pass; a
  count stuck in a "to be Reviewed" box is the KB report-only bucket and never
  clears via Save.

  PROD: same window, same two checkboxes, Retrieve -> Save, repeat until clean.
  No Epicor case, no manual UPDATE. (Earlier Prod attempt that "didn't work"
  was most likely the plain rebuild without the extended / inventory-value
  boxes, or was not Saved.)

  ============================  FIX (original analysis, superseded by OUTCOME) ==
  inv_loc.qty_on_hand (3,077.80) is already correct and already valued, so this
  is a RECLASS into the lot 056 bucket - NOT an inventory adjustment (a normal
  adjustment would double-count to 4,896.50). Nothing is allocated against 056
  (header, xref, bin all show alloc 0), so it is clean to touch.

  1) Check for a supported proc first (p21_rebuild_zero_lot_bin exists in this
     data, so the family is present):

        SELECT name FROM sys.procedures
        WHERE name LIKE 'p21_rebuild%' OR name LIKE '%lot%rebuild%'
           OR name LIKE '%rebuild%lot%'
        ORDER BY name;

  2) DEV TEST - prove it clears the booking problem:

        BEGIN TRAN;
        UPDATE dbo.lot SET qty_on_hand = 1818.700000000
        WHERE lot_uid = 289617;      -- loc 342, lot '056', inv_mast_uid 103353
        -- lot sum now 3,077.80 = inv_bin = lot_bin_xref = inv_loc
        COMMIT;   -- or ROLLBACK

     Then: Item Inventory > Lot tab shows 056 @ 1,818.70 available, and
     test-allocate it on a scratch order for CBVCPR9258 / loc 342.

  3) PROD - Epicor case. The raw UPDATE fixes the symptom but leaves
     inv_tran_lot_detail unfooted (still nets 0). Ask Epicor for the supported
     lot-bucket resync, or to post a compensating +1,818.70 inv_tran_lot_detail
     row against G14D. Dev is the evidence: reclass, no total / GL movement.

  ============================  ENV NOTES  =====================================
  P21Dev refreshed 09/06/26. lot 056's last txn was 2026-07-07; the G14D
  bin/xref rows are untouched since 2026-03-03 - all pre-refresh, so Dev
  reproduces the live Prod condition and is a valid test bed. The rebuild run
  in Prod before the refresh did not touch the lot header, so Prod is still
  broken.

  No kb_ / js_ objects anywhere in this chain - all P21 base tables and procs.
───────────────────────────────────────────────────────────────────────────────
  Confirmed schema on this build:
    lot            : key col is `lot` (varchar); qty_on_hand, qty_allocated,
                     lot_uid, inv_mast_uid, location_id, delete_flag
    inv_bin        : qty col is `quantity`; bin, inv_mast_uid, location_id,
                     qty_allocated, inv_bin_uid, row_status_flag
    lot_bin_xref   : lot_cd, bin_cd, qty_linked, qty_allocated,
                     lot_bin_xref_uid, inv_mast_uid, location_id
    inv_loc        : lot_bin_integration = 'N' for this item/loc
  READ-ONLY diagnostics below. Run in SSMS (sandbox drops SQL TDS). GO per
  batch so one bad name only ends that batch.
───────────────────────────────────────────────────────────────────────────────*/

/*── 1. inv_loc rollup + flags ──────────────────────────────────────────────*/
SELECT * FROM dbo.inv_loc
WHERE inv_mast_uid = 103353 AND location_id = 342;
GO
SELECT inv_mast_uid, item_id, item_desc, use_tags_flag
FROM dbo.inv_mast WHERE inv_mast_uid = 103353 OR item_id = 'CBVCPR9258';
GO

/*── 2. inv_bin - expect SUM = 3,077.80 ─────────────────────────────────────*/
SELECT ib.* FROM dbo.inv_bin ib
WHERE ib.inv_mast_uid = 103353 AND ib.location_id = 342
ORDER BY ib.bin;
GO
SELECT SUM(quantity) AS bin_qty_total
FROM dbo.inv_bin WHERE inv_mast_uid = 103353 AND location_id = 342;
GO

/*── 3. lot header - 056 sits at 0; SUM = 1,259.10 (short 1,818.70) ─────────*/
SELECT l.* FROM dbo.lot l
WHERE l.inv_mast_uid = 103353 AND l.location_id = 342
ORDER BY l.lot;
GO
SELECT SUM(qty_on_hand) AS lot_qty_total
FROM dbo.lot WHERE inv_mast_uid = 103353 AND location_id = 342;
GO

/*── 4. lot_bin_xref - 056 -> G14D carries 1,818.70; SUM = 3,077.80 ────────*/
SELECT * FROM dbo.lot_bin_xref
WHERE inv_mast_uid = 103353 AND location_id = 342
ORDER BY lot_cd, bin_cd;
GO
SELECT SUM(qty_linked) AS xref_qty_total
FROM dbo.lot_bin_xref WHERE inv_mast_uid = 103353 AND location_id = 342;
GO

/*── 5. how lot 056 got zeroed ────────────────────────────────────────────*/
SELECT * FROM dbo.inv_tran_lot_detail
WHERE inv_mast_uid = 103353 AND location_id = 342 AND lot = '056'
ORDER BY date_created;
GO

/*── 6. P21 cleanup helpers - both empty for this item ─────────────────────*/
SELECT * FROM dbo.lot_bin_dealloc_report        WHERE inv_mast_uid = 103353;
GO
SELECT * FROM dbo.p21_unallocate_orders_lot_info WHERE inv_mast_uid = 103353;
GO

/*── 7. is there a supported lot-bucket rebuild proc? ─────────────────────*/
SELECT name FROM sys.procedures
WHERE name LIKE 'p21_rebuild%' OR name LIKE '%lot%rebuild%' OR name LIKE '%rebuild%lot%'
ORDER BY name;
GO

/*── 8. the order from the ticket (customer already covered by a transfer) ─*/
SELECT * FROM dbo.oe_line WHERE order_no = 6125351;
GO

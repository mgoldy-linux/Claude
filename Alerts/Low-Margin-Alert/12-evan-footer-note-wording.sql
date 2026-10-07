/*==============================================================================
  12 — Evan Jenkins' footer note rewording (email 2026-10-05, item #2)
  Status : APPLIED to P21Play 2026-10-05 and to P21 (Prod) 2026-10-07.
  Author : Mark Goldyn / Claude          Date: 2026-10-05, rewritten 2026-10-07

  Ask (Evan, 2026-10-05 "Low Margin Alert Follow Up", item 2):
    - "Sales Rep and Order Taker"  ->  "Territory Manager and Order Taker"
    - "...confirm programming and GM %, Purchasing Team will confirm cost."
       -> "...confirm price programming and Standard Cost, Purchasing Team will
           confirm MAC and Supplier Cost."
    - Append to the contacts note:
       "For Sales Rep assignment questions, please contact
        customermaintenance@allsurfaces.com."

  *** THIS FILE RUNS AS-IS. DO NOT UNCOMMENT ANYTHING. ***
  Set the USE on the next line, open in SSMS, Execute. The apply commits itself
  only if it touched exactly 2 rows, and rolls itself back otherwise. There is
  no path that leaves a transaction open.

  WHY THAT MATTERS -- what the first version of this script did on 2026-10-07:
  its UPDATE ran live but its COMMIT TRANSACTION was commented out with a
  "uncomment once the text reads right" note. Running the file applied the
  change and then left the transaction OPEN, holding exclusive locks on
  alert_message. Two consequences, both real:
    - the next script (14, for 105/107) blocked behind it and looked hung;
    - a verification SELECT from another session read the OLD text and looked
      like the script had done nothing -- because P21 has READ_COMMITTED_SNAPSHOT
      ON, so readers get the last committed version instead of blocking.
  The transaction sat open on Prod for ~5 minutes. alert_message is read by
  P21's alert generation, so that could have stalled live alert sends.
  Hence: no commented-out COMMIT in this repo. See also scripts 13, 14, 15.

  *** WHY THIS IS SQL AND NOT THE CLIENT ***
  Saving an alert in Alert Maintenance REGENERATES the entire where_clause from
  the Filter grid's rows (trap 10). 104/105/107 had their grids synced 2026-09-21
  and survive a save, but **uid 106's -5% OR-based trigger has no possible grid
  representation** -- saving 106 in the client silently reverts it to the old
  +5% bug. A scoped UPDATE on alert_message.footer touches only that column and
  cannot disturb the trigger, so it is the safe route for ALL of them.

  SCOPE: uid 104 and 106 (the two Team alerts) -- matched on NAME, not uid,
  because uids differ between environments. The Purchasing variants (105/107)
  have a different first note and had no contacts note at all; Evan confirmed
  on 2026-10-06 that they should get one, which is script 14's job, not this
  script's.

  HIS WORDING IS DELIBERATE: he renames the role to "Territory Manager" in the
  first note but keeps "Sales Rep assignment" in the new line. Confirmed by him
  2026-10-06 -- the latter is the P21 term for coding reps to customers.
  Reproduced verbatim. Do not "fix" it.

  footer is a `text` column: every read and REPLACE CASTs to varchar(max) first.
  A Prod-only text/nvarchar(max) CAST bug bit script 10's guard clauses, hence
  the explicit casts in the WHERE as well.

  Idempotent: the first REPLACE is self-cancelling once applied, and the whole
  statement is guarded on 'customermaintenance' not already being present, so a
  second run reports 0 rows and rolls back.
==============================================================================*/
USE P21Play;      -- <<< change to P21 for Prod
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*------------------------------ PREVIEW -----------------------------------
  Read the proposed text end to end before looking at the apply result.
---------------------------------------------------------------------------*/
DECLARE @old_note1 varchar(500) =
  'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.';
DECLARE @new_note1 varchar(500) =
  'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.';
DECLARE @old_tail varchar(200) = 'please contact pricingsupport@allsurfaces.com.';
DECLARE @new_tail varchar(400) =
  'please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';

PRINT '=== PREVIEW: proposed footer ===';
SELECT ai.alert_implementation_uid,
       ai.alert_implementation_name,
       already_done = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%customermaintenance%'
                           THEN 'YES - will be skipped' ELSE 'no' END,
       note1_found  = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%Sales Rep and Order Taker%'
                           THEN 'yes' ELSE 'NO - check wording' END,
       proposed_footer =
           REPLACE(
             REPLACE(CAST(ISNULL(am.footer,'') AS varchar(max)), @old_note1, @new_note1),
             @old_tail, @new_tail)
FROM   dbo.alert_message am
JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Team',
                                        'Low PAD Margin Alert - Team')
ORDER BY ai.alert_implementation_uid;
GO

/*------------------------------- APPLY ------------------------------------
  Commits only on exactly 2 rows. Rolls itself back on anything else.
---------------------------------------------------------------------------*/
DECLARE @old_note1 varchar(500) =
  'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.';
DECLARE @new_note1 varchar(500) =
  'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.';
DECLARE @old_tail varchar(200) = 'please contact pricingsupport@allsurfaces.com.';
DECLARE @new_tail varchar(400) =
  'please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';

BEGIN TRY
  BEGIN TRAN;

  UPDATE am
  SET    am.footer = REPLACE(
                       REPLACE(CAST(ISNULL(am.footer,'') AS varchar(max)), @old_note1, @new_note1),
                       @old_tail, @new_tail)
  FROM   dbo.alert_message am
  JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
  WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Team',
                                          'Low PAD Margin Alert - Team')
    AND  CAST(am.footer AS varchar(max)) NOT LIKE '%customermaintenance%';

  DECLARE @n int = @@ROWCOUNT;

  IF @n = 2
    BEGIN COMMIT; PRINT 'COMMITTED - 2 rows (Team + PAD Team).'; END
  ELSE
    BEGIN ROLLBACK;
          PRINT 'ROLLED BACK - expected 2 rows, got ' + CAST(@n AS varchar(10))
              + '. If 0, it was already applied.'; END
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  PRINT 'ROLLED BACK ON ERROR - ' + ERROR_MESSAGE();
END CATCH;
GO

/*------------------------------ VERIFY ------------------------------------*/
SELECT ai.alert_implementation_uid, ai.alert_implementation_name,
       has_new_line = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%customermaintenance%'
                           THEN 'YES' ELSE 'NO' END,
       footer_now   = CAST(am.footer AS varchar(max))
FROM   dbo.alert_message am
JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Team',
                                        'Low PAD Margin Alert - Team')
ORDER BY ai.alert_implementation_uid;
GO

/*=============================== ROLLBACK ===================================
  COMMENTED ON PURPOSE. Only run this to undo the change.
  Safe to re-run; each REPLACE no-ops if already reversed.
=============================================================================
UPDATE am
SET    am.footer = REPLACE(
                     REPLACE(CAST(am.footer AS varchar(max)),
                       'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.',
                       'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.'),
                     ' For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.', '')
FROM dbo.alert_message am
JOIN dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE ai.alert_implementation_name IN ('Low Margin Alert - Team','Low PAD Margin Alert - Team');
PRINT 'rows reverted: ' + CAST(@@ROWCOUNT AS varchar(10));
=============================================================================*/

/*=========================== EVAN'S OTHER ITEMS =============================
  The notes that used to live here went stale within a day. Current status for
  all four items lives in ONE place: Deploy-Guides\low-margin-alert.md.

  Two corrections worth carrying, because the old notes here were wrong:

  #4 (Jami Klitzman on the PAD alerts) said to realign the counter afterwards
     with Check-Fix-Alert-Table-Counters-Play.sql. NOT NEEDED, and measured on
     Prod 2026-10-06: counter.alert_recipient has counter_num = -1 and
     seq_name = 'seq_alert_recipient', so the uid comes from a SQL SEQUENCE.
     Drawing it with NEXT VALUE FOR dbo.seq_alert_recipient keeps P21 and the
     data in step with nothing to realign. See script 13.

  #3 (new routing alert) is scoped: Evan confirmed 2026-10-06 it applies to the
     MAIN pair only, not PAD, at the current 5% threshold. It needs Supplier
     Cost added to the view first -- reachable via inv_loc.primary_supplier_id
     (100% populated) -> inventory_supplier.cost. Note that
     inventory_supplier.primary_supplier_flag is blank on all 157,584 rows and
     is a dead end.
=============================================================================*/

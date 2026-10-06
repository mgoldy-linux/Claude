/*==============================================================================
  11 — Evan Jenkins' footer note rewording (email 2026-10-05, item #2)
  Target : run on P21Play first, then P21 (change the USE below).
  Author : Mark Goldyn / Claude          Date: 2026-10-05

  Ask (Evan, 2026-10-05 "Low Margin Alert Follow Up", item 2):
    - "Sales Rep and Order Taker"  ->  "Territory Manager and Order Taker"
    - "...confirm programming and GM %, Purchasing Team will confirm cost."
       -> "...confirm price programming and Standard Cost, Purchasing Team will
           confirm MAC and Supplier Cost."
    - Append to the contacts note:
       "For Sales Rep assignment questions, please contact
        customermaintenance@allsurfaces.com."

  *** WHY THIS IS SQL AND NOT THE CLIENT ***
  Saving an alert in Alert Maintenance REGENERATES the entire where_clause from
  the Filter grid's rows (trap 10). 104/105/107 had their grids synced 2026-09-21
  and survive a save, but **uid 106's -5% OR-based trigger has no possible grid
  representation** -- saving 106 in the client silently reverts it to the old
  +5% bug. A scoped UPDATE on alert_message.footer touches only that column and
  cannot disturb the trigger, so it is the safe route for ALL of them.

  SCOPE: only uid 104 and 106 carry the two notes Evan is editing. The Purchasing
  variants (105/107) have a different first note and NO contacts note at all --
  deliberately NOT touched here. Open question for Evan: does he want the new
  customermaintenance@ line on those two as well?

  NOTE ON HIS WORDING: he renames the role to "Territory Manager" in the first
  note but keeps "Sales Rep assignment" in the new line. Reproduced verbatim --
  likely deliberate (it refers to the P21 salesrep_id field), but worth a check.

  footer is a `text` column: every read CASTs to varchar(max) first. A Prod-only
  text/nvarchar(max) CAST bug bit script 10's guard clauses, hence the explicit
  casts in the WHERE as well.

  Idempotent: the first REPLACE is self-cancelling once applied, and the append
  is guarded on 'customermaintenance' not already being present.
==============================================================================*/
USE P21Play;      -- <<< change to P21 for Prod
GO
SET NOCOUNT ON;

DECLARE @old_note1 varchar(500) =
  'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.';
DECLARE @new_note1 varchar(500) =
  'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.';

DECLARE @old_tail varchar(200) = 'please contact pricingsupport@allsurfaces.com.';
DECLARE @new_tail varchar(400) =
  'please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';

/*------------------------------ PREVIEW -----------------------------------
  Run this block on its own first and read the proposed text end to end.
---------------------------------------------------------------------------*/
PRINT '=== PREVIEW: proposed footer ===';
SELECT ai.alert_implementation_uid,
       ai.alert_implementation_name,
       already_done = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%customermaintenance%'
                           THEN 'YES - append already applied' ELSE 'no' END,
       note1_found  = CASE WHEN CAST(am.footer AS varchar(max)) LIKE '%Sales Rep and Order Taker%'
                           THEN 'yes' ELSE 'NO - check wording' END,
       proposed_footer =
           REPLACE(
             REPLACE(CAST(ISNULL(am.footer,'') AS varchar(max)), @old_note1, @new_note1),
             @old_tail, @new_tail)
FROM   dbo.alert_message am
JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Team',
                                        'Low PAD Margin Alert - Team');
GO

/*------------------------------- APPLY ------------------------------------
  Only after the preview reads correctly. Matched on NAME, not uid -- uids
  differ between environments.
---------------------------------------------------------------------------*/
/*
DECLARE @old_note1 varchar(500) =
  'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.';
DECLARE @new_note1 varchar(500) =
  'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.';
DECLARE @old_tail varchar(200) = 'please contact pricingsupport@allsurfaces.com.';
DECLARE @new_tail varchar(400) =
  'please contact pricingsupport@allsurfaces.com. For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.';

BEGIN TRANSACTION;

UPDATE am
SET    am.footer = REPLACE(
                     REPLACE(CAST(ISNULL(am.footer,'') AS varchar(max)), @old_note1, @new_note1),
                     @old_tail, @new_tail)
FROM   dbo.alert_message am
JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Team',
                                        'Low PAD Margin Alert - Team')
  AND  CAST(am.footer AS varchar(max)) NOT LIKE '%customermaintenance%';

PRINT 'Rows updated: ' + CAST(@@ROWCOUNT AS varchar(10));   -- expect 2

-- Re-read before committing
SELECT ai.alert_implementation_uid, ai.alert_implementation_name,
       CAST(am.footer AS varchar(max)) AS footer_now
FROM   dbo.alert_message am
JOIN   dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
WHERE  ai.alert_implementation_name IN ('Low Margin Alert - Team',
                                        'Low PAD Margin Alert - Team');

-- COMMIT TRANSACTION;   <-- uncomment once the text reads right
-- ROLLBACK TRANSACTION; <-- otherwise
*/

/*=============================== ROLLBACK ===================================
  Reverse both edits (safe to re-run; each REPLACE no-ops if already reversed):

  UPDATE am
  SET    am.footer = REPLACE(
                       REPLACE(CAST(am.footer AS varchar(max)),
                         'Note: Territory Manager and Order Taker, please confirm Sell Price. Pricing Team will confirm price programming and Standard Cost, Purchasing Team will confirm MAC and Supplier Cost.',
                         'Note: Sales Rep and Order Taker, please confirm Sell Price. Pricing Team will confirm programming and GM %, Purchasing Team will confirm cost.'),
                       ' For Sales Rep assignment questions, please contact customermaintenance@allsurfaces.com.', '')
  FROM dbo.alert_message am
  JOIN dbo.alert_implementation ai ON ai.alert_implementation_uid = am.alert_implementation_uid
  WHERE ai.alert_implementation_name IN ('Low Margin Alert - Team','Low PAD Margin Alert - Team');

=========================== EVAN'S OTHER ITEMS =============================
  #1 Contract pricing in the alert — already tracked (Todo-BusApps #15). Measured:
     16% of "(no price page)" lines (35,986 / 228,898 over 120d) have an active
     contract price behind them. Real work: job_price_hdr / job_price_line are a
     separate mechanism the alert does not look at. Not a text change.

  #3 New routing rule (Std Cost > Supplier Cost AND GM% off MAC above threshold
     -> only Alex + Erik) — P21 alerts have ONE recipient set per alert, so this
     is almost certainly a FIFTH alert, not a filter on an existing one. A
     conditional-recipient token was evaluated earlier on this project and
     rejected: it works, but fires a bogus <email_not_found/> row into
     alert_queued_mail every time it does not escalate.

  #4 Add Jami Klitzman to the PAD alerts (106 + 107) —
     *** DO NOT ADD VIA THE CLIENT ON uid 106 *** — same trap 10 hazard as above.
     Use a scoped INSERT into alert_recipient, then realign the counter with
     Sql-Scripts\Alerts\Check-Fix-Alert-Table-Counters-Play.sql
     (alert_recipient_uid is counter-managed; a raw insert drifts it).
===========================================================================*/

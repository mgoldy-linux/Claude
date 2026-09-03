/*======================================================================================
  Toggle-Resource-Monitor.sql        Per Epicor KB0020763.

  WHAT IT ACTUALLY SAMPLES (from the resource_monitor schema, which is more specific
  than the KB text):

      session_uid, monitor_date, user_id, computer_name,
      memory_kb, sheet_count, sheet_list, menu_count, uo_count, gui_resources

  computer_name, uo_count (PowerBuilder user objects), menu_count and gui_resources
  (Windows GDI handles) are all DESKTOP CLIENT measures. This monitors the PowerBuilder
  rich client per workstation, on an interval measured in MINUTES.

  WHAT THAT MEANS FOR RULE PERFORMANCE
    It will NOT measure asi_Order_Validator_t2 vs kb_Order_Validator_v2:
      * Business rules execute in the middleware SOA pools, not in the desktop client.
        Nothing the rule does appears in any of these columns.
      * The interval is minutes; a synchronous rule runs in milliseconds during one save.
        A 2-minute sample cannot resolve a single save at all.
      * A save made in the WEB client produces no row whatsoever -- there is no
        PowerBuilder process to sample.
    Use Measure-Validator-Cost.sql for rule cost (plan-cache DMVs + DataSet payload bytes).

  THE ONE ANGLE WHERE IT DOES TOUCH THIS WORK
    sheet_list and uo_count are the exception worth knowing about. P21 assembles a rule's
    DataSet from DataWindows, and kb_ registers 11 of them against _t2's 5. If that
    difference costs the desktop client materialized objects, uo_count / gui_resources is
    the only place it would ever show. Getting signal needs SUSTAINED desktop work under
    each rule -- an hour of ordinary order entry, not one save -- and even then it is a
    weak instrument. Treat any result as a hint, not a measurement.

  SCOPE WARNING
    resource_monitor_interval is a SYSTEM setting: it turns sampling on for every desktop
    user of that database, not just the person who enabled it. Confirmed 2026-09-03: both
    BRR and PROD sit at 0, untouched since 2015-07-17 (P21_DBA). Enable in BRR only.

  Epicor: "not recommended that the resource monitor remain on at all times ... The table
  can fill up with data quickly." Volume is roughly (active desktop users) x
  (minutes on / interval). Turn it back off when done.
======================================================================================*/

USE P21BusinessRules;
GO

/*-- 1. CURRENT STATE ------------------------------------------------------------------*/
SELECT  setting = name, value, date_last_modified, last_maintained_by
FROM    system_setting
WHERE   name = 'resource_monitor_interval';

SELECT  rows_captured = COUNT(*),
        distinct_users = COUNT(DISTINCT user_id),
        earliest = MIN(monitor_date), latest = MAX(monitor_date)
FROM    resource_monitor WITH (NOLOCK);
GO

/*-- 2. ENABLE (2-minute sampling). BRR ONLY. ------------------------------------------
exec p21_update_system_setting 'resource_monitor_interval', '2';
--------------------------------------------------------------------------------------*/

/*-- 3. INSPECT what it collected ------------------------------------------------------
   Per-sample detail. sheet_list is the interesting column: it names the windows open at
   that moment, so it is what connects memory growth to a specific screen.
--------------------------------------------------------------------------------------*/
SELECT TOP 100
        monitor_date, user_id, computer_name,
        memory_mb    = memory_kb / 1024.0,
        sheet_count, menu_count, uo_count, gui_resources,
        sheet_list
FROM    resource_monitor WITH (NOLOCK)
ORDER   BY resource_monitor_uid DESC;

/* Per-user growth across the window -- a rising floor is the leak signature, whereas a
   high but flat figure is just a heavy user. The delta matters, not the peak. */
SELECT  user_id, computer_name,
        samples     = COUNT(*),
        first_seen  = MIN(monitor_date),
        last_seen   = MAX(monitor_date),
        min_mb      = MIN(memory_kb)/1024.0,
        max_mb      = MAX(memory_kb)/1024.0,
        growth_mb   = (MAX(memory_kb) - MIN(memory_kb))/1024.0,
        max_uo      = MAX(uo_count),
        max_gui     = MAX(gui_resources)
FROM    resource_monitor WITH (NOLOCK)
GROUP   BY user_id, computer_name
ORDER   BY growth_mb DESC;

/* Which screens are open when memory is highest. Crude -- sheet_list is a list, so this
   attributes the whole footprint to every window open at the time. Directional only. */
SELECT TOP 30 sheet_list, samples = COUNT(*), avg_mb = AVG(memory_kb)/1024.0
FROM    resource_monitor WITH (NOLOCK)
WHERE   sheet_list IS NOT NULL AND sheet_list <> ''
GROUP   BY sheet_list
ORDER   BY AVG(memory_kb) DESC;
GO

/*-- 4. DISABLE + CLEAN UP -------------------------------------------------------------
exec p21_update_system_setting 'resource_monitor_interval', '0';
-- then, once you have extracted anything you want to keep:
-- TRUNCATE TABLE resource_monitor;
--------------------------------------------------------------------------------------*/

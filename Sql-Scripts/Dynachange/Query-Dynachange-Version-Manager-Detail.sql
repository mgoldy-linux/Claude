-- =============================================================================
-- Query-Dynachange-Version-Manager-Detail.sql
-- Server: P21Dev.allsurfaces.com (BusinessRules/WWMS) or P21.allsurfaces.com (Prod)
-- Database: matching P21 instance (e.g. P21BusinessRules, P21)
--
-- PURPOSE
--   Reproduces the whole DynaChange(tm) Version Manager screen for a given
--   web/WWMS version -- Details panel, Assignees panel, and the
--   Object Name / Property Name / Property Value grid -- without opening the
--   P21 client. Confirmed byte-for-byte against the live UI 2026-08-14 for
--   version 'WWMS_screen_tab_oder' (design_uid=3).
--
-- SCHEMA (see reference_p21_wwms_web_dynachange_schema memory for full notes)
--   design      -- one row per version; Version Name/Description/Type/Context
--   assignment  -- per-role (or per-user) rollout of a design_uid
--   roles       -- role_uid -> role name
--   modification-- the actual field-level TabIndex/IsDisabled/etc overrides
--   Only Menu/Popup/Screen "Screen" versions use w_<window>.tab.tabpage.dw
--   style locations; Popup/Menu versions use their own context format.
--
--   NOTE: this is the WEB/WWMS mechanism (Extensibility framework), a
--   SEPARATE system from the desktop PowerBuilder DynaChange mechanism
--   (custom_objects / custom_objects_detail / fc_dataobject*). Version Manager
--   itself cross-checks custom_objects.design_uid at load time to warn if a
--   legacy desktop record already exists for the same design -- confirmed via
--   live trace (WWMS_Dynachange_Load_Trace, 2026-08-14): Version Manager runs
--   `SELECT COUNT(1) FROM custom_objects_detail JOIN custom_objects ...
--   WHERE custom_objects.design_uid = @design_uid`. Don't conflate the two.
--
-- USAGE
--   Set @version_name to any value from the Versions grid's VERSION NAME
--   column (e.g. 'WWMS_screen_tab_oder', 'Tab_Change_Order',
--   'Screen_protect_complete', 'Change Tab Order') and run.
-- =============================================================================

DECLARE @version_name varchar(255) = 'WWMS_screen_tab_oder';

-- Details panel
SELECT design_uid, name AS version_name, description, design_type, location AS context,
       created_by, date_created, last_maintained_by, date_last_modified
FROM design WHERE name = @version_name;

-- Assignees panel
SELECT a.assignee, a.assignment_type, r.role
FROM assignment a
LEFT JOIN roles r ON r.role_uid = a.role_uid
JOIN design d ON d.design_uid = a.design_uid
WHERE d.name = @version_name
ORDER BY a.assignee;

-- Object Name / Property Name / Property Value grid
SELECT m.object_name, m.property_name, m.property_value
FROM modification m
JOIN design d ON d.design_uid = m.design_uid
WHERE d.name = @version_name
ORDER BY m.object_name, m.property_name;

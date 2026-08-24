-- Fixes confirmed counter drift on 4 alert-related tables in P21 Prod, found via
-- Check-Alert-Table-Counters-Prod-ReadOnly.sql on 2026-08-24:
--   alert_implementation        counter=103 real_max=107
--   Alert_implementation_query  counter=240 real_max=272
--   alert_message                counter=106 real_max=110
--   alert_recipient               counter=198 real_max=205  (cause of the "add recipient" PK violation)
-- Uses the supported p21_set_counter proc with @set_to_table_value=1 to resync each
-- sequence to the table's real current max. Never ALTER SEQUENCE directly.

USE [P21];
GO

EXEC p21_set_counter @counter_id = 'alert_implementation',       @set_to_table_value = 1;
EXEC p21_set_counter @counter_id = 'alert_implementation_query', @set_to_table_value = 1;
EXEC p21_set_counter @counter_id = 'alert_message',              @set_to_table_value = 1;
EXEC p21_set_counter @counter_id = 'alert_recipient',             @set_to_table_value = 1;
GO

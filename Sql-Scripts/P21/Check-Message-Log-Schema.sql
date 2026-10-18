-- =============================================================================
-- Check-Message-Log-Schema.sql
-- Ground-truth column list for message_log and messages before trusting any
-- query against them -- Order-Popup-Audit-1Yr.sql guessed window_flag onto
-- the wrong table (or it doesn't exist at all here) and errored with Msg 207.
-- =============================================================================

SELECT t.name AS table_name, c.name AS column_name, ty.name AS data_type, c.column_id
FROM   sys.columns c
JOIN   sys.tables   t  ON t.object_id = c.object_id
JOIN   sys.types    ty ON ty.user_type_id = c.user_type_id
WHERE  t.name IN ('message_log', 'messages')
ORDER  BY t.name, c.column_id;

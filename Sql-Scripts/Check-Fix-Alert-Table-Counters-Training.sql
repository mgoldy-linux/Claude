-- Checks p21_set_counter against the real MAX(uid) for every alert-related table in P21Training,
-- and advances any counter that's fallen behind (e.g. after a raw-SQL insert bypassed p21_set_counter).
-- Uses the supported p21_set_counter proc to fix drift -- never ALTER SEQUENCE directly.
-- alert_notification has no physical table in this environment -- not checked.
-- Training variant of Check-Fix-Alert-Table-Counters-Play.sql (same alert_recipient drift class,
-- triggered 2026-08-07 by SQLDBCode 2627 on pk_alert_recipient, duplicate key 197).

USE [P21Training];
GO

DECLARE @tbl TABLE (table_name SYSNAME, uid_column SYSNAME, counter_id VARCHAR(50));
INSERT @tbl (table_name, uid_column, counter_id) VALUES
    ('alert_implementation',       'alert_implementation_uid',       'alert_implementation'),
    ('Alert_implementation_query', 'alert_implementation_query_uid', 'alert_implementation_query'),
    ('alert_message',              'alert_message_uid',              'alert_message'),
    ('alert_queued_mail',          'alert_queued_mail_uid',          'alert_queued_mail'),
    ('alert_recipient',            'alert_recipient_uid',            'alert_recipient'),
    ('alert_task',                 'alert_task_uid',                 'alert_task'),
    ('alert_type',                 'alert_type_uid',                 'alert_type'),
    ('alert_type_x_token',         'alert_type_x_token_uid',         'alert_type_x_token');

DECLARE @counters TABLE (id VARCHAR(50), description VARCHAR(255), counter_num INT);
INSERT @counters EXEC p21_set_counter;

DECLARE @table_name SYSNAME, @uid_column SYSNAME, @counter_id VARCHAR(50);
DECLARE @real_max INT, @current_counter INT, @sql NVARCHAR(MAX);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT table_name, uid_column, counter_id FROM @tbl;
OPEN cur;
FETCH NEXT FROM cur INTO @table_name, @uid_column, @counter_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @m = ISNULL(MAX(' + QUOTENAME(@uid_column) + N'),0) FROM dbo.' + QUOTENAME(@table_name);
    EXEC sp_executesql @sql, N'@m INT OUTPUT', @m = @real_max OUTPUT;

    SELECT @current_counter = counter_num FROM @counters WHERE id = @counter_id;

    PRINT @table_name + ': counter = ' + CAST(ISNULL(@current_counter,-999) AS VARCHAR)
          + ', real max = ' + CAST(@real_max AS VARCHAR);

    IF @current_counter IS NULL
        PRINT '  WARNING: no counter row found for id = ''' + @counter_id + '''';
    ELSE IF @current_counter < @real_max
    BEGIN
        PRINT '  DRIFT DETECTED -- advancing counter to ' + CAST(@real_max AS VARCHAR);
        EXEC p21_set_counter @counter_id = @counter_id, @counter_num = @real_max;
    END
    ELSE
        PRINT '  OK';

    FETCH NEXT FROM cur INTO @table_name, @uid_column, @counter_id;
END
CLOSE cur;
DEALLOCATE cur;
GO

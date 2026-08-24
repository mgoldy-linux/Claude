DECLARE @log_reached_disk_size BIT = 0

SELECT 
    name LogName, 
    physical_name, 
    CONVERT(bigint, size)*8/1024 LogFile_Size_MB, 
    volume_mount_point, 
    available_bytes/1024/1024 Available_Disk_space_MB,
    (CONVERT(bigint, size)*8.0/1024)/(available_bytes/1024/1024 )*100 file_size_as_percentage_of_disk_space,
    db_name(mf.database_id) DbName
FROM sys.master_files mf CROSS APPLY sys.dm_os_volume_stats (mf.database_id, file_id)
WHERE mf.[type_desc] = 'LOG'
    AND (CONVERT(bigint, size)*8.0/1024)/(available_bytes/1024/1024 )*100 > 90 --log is 90% of disk drive
ORDER BY size DESC

if @@ROWCOUNT > 0
BEGIN

    set @log_reached_disk_size = 1

    -- Discover if any logs have are close to or completely filled disk volume they reside on.
    -- Either Add A New File To A New Drive, Or Shrink Existing File
    -- If Cannot Shrink, Go To Cannot Truncate Section

    DECLARE @db_name_filled_disk sysname, @log_name_filled_disk sysname, @go_beyond_size bigint 
    
    DECLARE log_filled_disk CURSOR FOR
        SELECT 
            db_name(mf.database_id),
            name
        FROM sys.master_files mf CROSS APPLY sys.dm_os_volume_stats (mf.database_id, file_id)
        WHERE mf.[type_desc] = 'LOG'
            AND (convert(bigint, size)*8.0/1024)/(available_bytes/1024/1024 )*100 > 90 --log is 90% of disk drive
        ORDER BY size desc

    OPEN log_filled_disk

    FETCH NEXT FROM log_filled_disk into @db_name_filled_disk , @log_name_filled_disk

    WHILE @@FETCH_STATUS = 0
    BEGIN
        
        SELECT 'Transaction log for database "' + @db_name_filled_disk + '" has nearly or completely filled disk volume it resides on!' AS Finding
        SELECT 'Consider using one of the below commands to shrink the "' + @log_name_filled_disk +'" transaction log file size or add a new file to a NEW volume' AS Recommendation
        SELECT 'DBCC SHRINKFILE(''' + @log_name_filled_disk + ''')' AS Shrinkfile_Command
        SELECT 'ALTER DATABASE ' + @db_name_filled_disk + ' ADD LOG FILE ( NAME = N''' + @log_name_filled_disk + '_new'', FILENAME = N''NEW_VOLUME_AND_FOLDER_LOCATION\' + @log_name_filled_disk + '_NEW.LDF'', SIZE = 81920KB , FILEGROWTH = 65536KB )' AS AddNewFile
        SELECT 'If shrink does not reduce the file size, likely it is because it has not been truncated. Please review next section below. See https://learn.microsoft.com/sql/t-sql/database-console-commands/dbcc-shrinkfile-transact-sql' AS TruncateFirst
        SELECT 'Can you free some disk space on this volume? If so, do this to allow for the log to continue growing when needed.' AS FreeDiskSpace

         FETCH NEXT FROM log_filled_disk into @db_name_filled_disk , @log_name_filled_disk

    END

    CLOSE log_filled_disk
    DEALLOCATE log_filled_disk

END
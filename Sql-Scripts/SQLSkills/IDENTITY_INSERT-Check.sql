DROP TABLE IF EXISTS #GetIdentityInsert
DECLARE
     @dbname sysname,
     @schemaname sysname,
     @table sysname,
     @IdentityInsert VARCHAR(20),

     @OtherTable nvarchar(max),
     @DbSchemaTable nvarchar(max),

     @ErrorMessage NVARCHAR(4000),
     @ErrorSeverity INT,
     @ErrorState INT,
     @ErrorNumber INT,
     @object_id INT;

	SET @dbname='[P21Play2021.1.4420Local]'
	SET @schemaname= 'dbo'
	SET @table='USERS'
    SET @DbSchemaTable = @dbname + '.' + @schemaname + '.' + @table

    SET @object_id = OBJECT_ID(@DbSchemaTable)

    BEGIN TRY

        SET @object_id = OBJECT_ID(@DbSchemaTable)

        IF OBJECTPROPERTY(@object_id,'TableHasIdentity') = 0
        BEGIN
            SET @IdentityInsert = 'NO_IDENTITY'
        END
        ELSE
        BEGIN
            -- Attempt to set IDENTITY_INSERT on a temp table.

            CREATE TABLE #GetIdentityInsert(ID INT IDENTITY)
            SET IDENTITY_INSERT #GetIdentityInsert ON

            -- It didn't fail, so IDENTITY_INSERT on @table must set to OFF
            SET @IdentityInsert = 'OFF'
        END
    END TRY


    BEGIN CATCH

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
            @ErrorNumber = ERROR_NUMBER();

        IF @ErrorNumber = 8107  --IDENTITY_INSERT is already set on a table
        BEGIN
            SET @OtherTable = SUBSTRING(@ErrorMessage, CHARINDEX(char(39), @ErrorMessage)+1, 2000)
            SET @OtherTable = SUBSTRING(@OtherTable, 1, CHARINDEX(char(39), @OtherTable)-1)

            IF @OtherTable = @DbSchemaTable 
            BEGIN
                -- If the table name is the same, then IDENTITY_INSERT on @table must be ON
                SET @IdentityInsert = 'ON'
            END
            ELSE
            BEGIN
                -- If the table name is different, then IDENTITY_INSERT on @table must be OFF
                SET @IdentityInsert =  'OFF'
            END
        END
        ELSE
        BEGIN
			SET @ErrorNumber=130001
            RAISERROR (@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState);
         
        END


    END CATCH
PRINT(@IdentityInsert)
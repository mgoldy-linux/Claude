/*==============================================================================
  Cancel-Test-Orders-All-Lower-Envs.sql
  Connect to: P21Dev.allsurfaces.com   (all lower envs live on this one server)

  Cancels the test orders a given taker left open, across every lower
  environment, by delegating to dbo.asi_cancel_open_orders_by_user in each DB.

  *** NEVER point this at P21.allsurfaces.com (Prod). ***
  The guard below refuses to run there, but the real protection is the
  connection you choose.

  A stored procedure exists PER DATABASE and only sees orders in its own
  database, so this has to visit each one. They are all on a single server, so
  it is one connection rather than four sessions.

  ⚠ REFRESH HAZARD: every lower env is restored FROM Prod. If the procs are not
  in Prod (and they should not be -- see the deploy guide), a refresh DELETES
  them from that environment and they must be redeployed before this will work.
  That is what the "proc NOT deployed" report below is for.

  STEP 1 runs a PREVIEW only -- nothing is changed.
  STEP 2 is commented out. Read the preview first, then uncomment.
==============================================================================*/

/*--- Prod guard ---------------------------------------------------------*/
IF @@SERVERNAME LIKE '%ASP21DB1' AND @@SERVERNAME NOT LIKE '%DEV%'
BEGIN
    RAISERROR('This looks like PRODUCTION. Aborting.', 20, 1) WITH LOG;
END
GO

SET NOCOUNT ON;

/*--- Who, and which databases -------------------------------------------
  @taker matches oe_hdr.taker, which holds the users.ID value (e.g. MGOLDYN),
  NOT the display name. Passing 'Mark Goldyn' silently matches zero orders.
  Confirm the DB list first:
      SELECT name FROM sys.databases WHERE database_id > 4 ORDER BY name;
-------------------------------------------------------------------------*/
DECLARE @taker SYSNAME = N'MGOLDYN';

DECLARE @dbs TABLE (db SYSNAME);
INSERT INTO @dbs (db) VALUES
     (N'P21Play')
    ,(N'P21Dev')
    ,(N'Training')            -- adjust if it is really P21Training
    ,(N'Business Rules');     -- adjust if it is really P21BusinessRules

/*--- STEP 1: PREVIEW across every listed database ------------------------*/
DECLARE @db SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT db FROM @dbs;
OPEN c;
FETCH NEXT FROM c INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF DB_ID(@db) IS NULL
        PRINT '=== ' + @db + ' : DATABASE NOT FOUND (check the name) ===';
    ELSE
    BEGIN
        SET @sql = N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@db)
                 + N'.sys.procedures WHERE name = ''asi_cancel_open_orders_by_user'')
                        EXEC ' + QUOTENAME(@db) + N'.dbo.asi_cancel_open_orders_by_user
                             @user_id = @t, @preview_only = ''Y'';
                     ELSE PRINT ''  -> proc NOT deployed in this database'';';

        PRINT '=== ' + @db + ' ===';
        EXEC sp_executesql @sql, N'@t SYSNAME', @t = @taker;
    END

    FETCH NEXT FROM c INTO @db;
END

CLOSE c;
DEALLOCATE c;
GO

/*--- STEP 2: THE REAL THING ----------------------------------------------
  Only after reading the preview. This cancels EVERY open order for the taker
  in each database -- not just today's -- so confirm the list is what you want.

  Nothing is deleted: cancel_flag='Y', completed='Y', disposition='C',
  qty_canceled = qty_ordered. delete_flag stays 'N' and the rows remain, which
  is the same end state as clicking Cancel Order in the P21 client.

DECLARE @taker SYSNAME = N'MGOLDYN';
DECLARE @dbs TABLE (db SYSNAME);
INSERT INTO @dbs (db) VALUES
     (N'P21Play'), (N'P21Dev'), (N'Training'), (N'Business Rules');

DECLARE @db SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT db FROM @dbs;
OPEN c; FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF DB_ID(@db) IS NOT NULL
    BEGIN
        SET @sql = N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@db)
                 + N'.sys.procedures WHERE name = ''asi_cancel_open_orders_by_user'')
                        EXEC ' + QUOTENAME(@db) + N'.dbo.asi_cancel_open_orders_by_user
                             @user_id = @t, @preview_only = ''N'';';
        PRINT '=== ' + @db + ' ===';
        EXEC sp_executesql @sql, N'@t SYSNAME', @t = @taker;
    END
    FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
-------------------------------------------------------------------------*/

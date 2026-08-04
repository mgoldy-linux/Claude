-- Fix: user_description and job_title were set directly from their parameters
-- (both default to NULL) instead of falling back to the source user's values,
-- unlike every other copied users_ud column (see power_bi_user's ISNULL pattern).
-- Bug pre-dates this proc — same flaw exists in kb_proc_copy_user, carried over
-- during the asi_ rewrite.
-- Fix #13: the summary PRINT's "Role:" was actually printing job_title (e.g. "Sr
-- Buyer"), not the security role (e.g. "Purchasing") — now looks up roles.role via
-- role_uid. Also added Buyer ID (contact_id) to the line, alongside Salesrep ID.
CREATE OR ALTER PROCEDURE [dbo].[asi_proc_copy_p21_user]
    @strUserToCopy          VARCHAR(30)
    ,@strNewUserID          VARCHAR(30)
    ,@strFirstName          VARCHAR(20)  = NULL
    ,@strLastName           VARCHAR(19)  = NULL
    ,@strEmail              VARCHAR(255) = NULL
    ,@decLocation           DEC(19, 0)   = 100
    ,@strBranch             VARCHAR(8)   = '100'
    ,@salesrep_id           VARCHAR(16)  = NULL
    ,@user_description      VARCHAR(255) = NULL
    ,@job_title             VARCHAR(100) = NULL
    ,@delete_flag           VARCHAR(1)   = 'N'
    ,@power_bi_user         VARCHAR(1)   = NULL
    ,@overwrite_existing_user VARCHAR(1) = 'N'
AS
BEGIN
    SET NOCOUNT ON

    -- Fix #2: initialize @intReturn so RETURN is never NULL
    DECLARE @intReturn          INTEGER      = -1
    DECLARE @li_MaxColumn       INTEGER
    DECLARE @li_CurrentColumn   INTEGER
    DECLARE @intCounter         INTEGER
    DECLARE @intUserExists      INTEGER
    DECLARE @intUserXCompanyExists INTEGER

    -- Fix #1: NVARCHAR(MAX) allows sp_executesql parameterization without the 4000-char limit concern
    DECLARE @ls_SQL             NVARCHAR(MAX)
    DECLARE @ls_InsertSQL       NVARCHAR(MAX)
    DECLARE @ls_UpdateSQL       NVARCHAR(MAX)
    DECLARE @ls_SelectSQL       NVARCHAR(MAX)
    DECLARE @ls_ColName         NVARCHAR(255)

    DECLARE @ld_current_timestamp DATETIME

    -- Fix #6: capture once, reuse everywhere
    DECLARE @strMaintainedBy    VARCHAR(40)

    -- Fix #13: for the summary PRINT — role_uid's role name, not job_title, and Buyer ID
    DECLARE @strRoleName        VARCHAR(50)
    DECLARE @strContactID       VARCHAR(30)

    BEGIN TRY

        SET @ld_current_timestamp = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL)
        SET @strNewUserID    = UPPER(@strNewUserID)
        SET @strMaintainedBy = CONVERT(VARCHAR(40), SUSER_NAME())

        DECLARE @strCompany VARCHAR(8) = '1'

        SET @strEmail = LOWER(ISNULL(@strEmail, SUBSTRING(@strFirstName, 1, 1) + @strLastName + '@allsurfaces.com'))

        -- Validate source user exists
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = @strUserToCopy)
        BEGIN
            PRINT 'User to copy ' + @strUserToCopy + ' does not exist. Cancelling procedure.'
            RETURN -10
        END

        -- Temp table for dynamic column list (used in both INSERT and UPDATE paths)
        CREATE TABLE #temp_users_columns_update (
            tucu_uid    INTEGER IDENTITY
            ,column_name VARCHAR(255) NOT NULL
        )

        -- Determine if users_x_company record is needed
        IF @strCompany IS NULL OR EXISTS (
            SELECT 1 FROM users_x_company
            WHERE company_id = @strCompany AND [user_id] = @strNewUserID
        )
            SET @intUserXCompanyExists = 1
        ELSE
            SET @intUserXCompanyExists = 0

        -- Determine if the new user ID already exists
        IF EXISTS (SELECT 1 FROM users WHERE id = @strNewUserID)
        BEGIN
            IF @overwrite_existing_user = 'Y'
            BEGIN
                SET @intUserExists = 1
                PRINT 'User already exists and overwrite is allowed; settings will be updated.'
                -- Preserve the existing user's personal settings
                SET @job_title        = (SELECT job_title        FROM users_ud WHERE id = @strNewUserID)
                SET @user_description = (SELECT user_description FROM users_ud WHERE id = @strNewUserID)
            END
            ELSE
            BEGIN
                DECLARE @existing_user_name VARCHAR(120) = (SELECT name        FROM p21_view_users WHERE id = @strNewUserID)
                DECLARE @is_deleted         VARCHAR(1)   = (SELECT delete_flag FROM p21_view_users WHERE id = @strNewUserID)
                PRINT 'User ID already exists for ' + @existing_user_name + ', who is '
                    + CASE WHEN @is_deleted = 'N' THEN 'NOT ' ELSE '' END
                    + 'deleted. Overwrite is not allowed. Pass ''Y'' to @overwrite_existing_user to proceed.'
                RETURN -11
            END
        END
        ELSE
        BEGIN
            SET @intUserExists = 0
            PRINT 'User does not exist and will be created.'
            EXEC @intCounter = p21_get_counter N'USER', 1
        END

        -- Begin logical unit of work
        BEGIN TRANSACTION OverallTransaction


        -- ============================================================
        -- users table
        -- ============================================================
        IF @intUserExists = 1
        BEGIN
            -- UPDATE path
            -- Column names come from p21_fnt_ColumnList (system function, not user input — safe)
            -- User-supplied values are passed as parameters to sp_executesql (Fix #1)
            SET @ls_SQL = N'
                UPDATE users
                SET    date_last_modified = @p_timestamp
                      ,last_maintained_by = @p_maintained_by'

            INSERT INTO #temp_users_columns_update (column_name)
            SELECT column_name
            FROM dbo.p21_fnt_ColumnList('users', 'N', 'N')
            WHERE column_name NOT IN (
                'id', 'name', 'password', 'active', 'delete_flag', 'default_company',
                'email_address', 'default_location_id', 'default_branch', 'date_created',
                'active_directory_role', 'date_last_modified', 'last_maintained_by', 'contact_id'
            )

            SELECT @li_CurrentColumn = MIN(tucu_uid), @li_MaxColumn = MAX(tucu_uid)
            FROM #temp_users_columns_update

            WHILE @li_CurrentColumn <= @li_MaxColumn
            BEGIN
                SELECT @ls_ColName = column_name
                FROM #temp_users_columns_update
                WHERE tucu_uid = @li_CurrentColumn

                SET @ls_SQL = @ls_SQL + N'
                      ,' + @ls_ColName + ' = acts_like_user.' + @ls_ColName

                -- Fix #9: simple increment (IDENTITY has no gaps in this proc)
                SET @li_CurrentColumn += 1
            END

            SET @ls_SQL = @ls_SQL + N'
                      ,active_directory_role = NULL
                FROM   users
                INNER JOIN users acts_like_user ON acts_like_user.id = @p_user_to_copy
                WHERE  users.id = @p_new_user_id'

            EXEC sp_executesql @ls_SQL,
                N'@p_timestamp     DATETIME,
                  @p_maintained_by VARCHAR(40),
                  @p_user_to_copy  VARCHAR(30),
                  @p_new_user_id   VARCHAR(30)',
                @ld_current_timestamp, @strMaintainedBy, @strUserToCopy, @strNewUserID
        END
        ELSE
        BEGIN
            -- INSERT path
            SET @ls_InsertSQL = N'
                INSERT INTO users (
                     id, name, date_created, date_last_modified, last_maintained_by,
                     delete_flag, default_company, default_branch, default_location_id,
                     email_address, active_directory_role'

            SET @ls_SelectSQL = N'
                SELECT @p_new_user_id
                      ,@p_full_name
                      ,@p_timestamp
                      ,@p_timestamp
                      ,SYSTEM_USER
                      ,''N''
                      ,@p_company
                      ,@p_branch
                      ,@p_location
                      ,@p_email
                      ,NULL'

            INSERT INTO #temp_users_columns_update (column_name)
            SELECT column_name
            FROM dbo.p21_fnt_ColumnList('users', 'N', 'N')
            WHERE column_name NOT IN (
                'id', 'name', 'date_created', 'date_last_modified', 'last_maintained_by',
                'delete_flag', 'default_company', 'default_branch', 'default_location_id',
                'email_address', 'active_directory_role', 'contact_id'
            )
            ORDER BY col_order

            SELECT @li_CurrentColumn = MIN(tucu_uid), @li_MaxColumn = MAX(tucu_uid)
            FROM #temp_users_columns_update

            WHILE @li_CurrentColumn <= @li_MaxColumn
            BEGIN
                SELECT @ls_ColName = column_name
                FROM #temp_users_columns_update
                WHERE tucu_uid = @li_CurrentColumn

                SET @ls_InsertSQL = @ls_InsertSQL + N',' + @ls_ColName
                -- Column name in SELECT pulls value from the source user row (safe — not user input)
                SET @ls_SelectSQL = @ls_SelectSQL + N',' + @ls_ColName

                SET @li_CurrentColumn += 1
            END

            SET @ls_InsertSQL = @ls_InsertSQL + N')'
            SET @ls_SelectSQL = @ls_SelectSQL + N'
                FROM  users
                WHERE id = @p_user_to_copy'

            SET @ls_SQL = @ls_InsertSQL + @ls_SelectSQL

            DECLARE @strFullName VARCHAR(41) = @strFirstName + ' ' + @strLastName
            EXEC sp_executesql @ls_SQL,
                N'@p_new_user_id  VARCHAR(30),
                  @p_full_name    VARCHAR(41),
                  @p_timestamp    DATETIME,
                  @p_company      VARCHAR(8),
                  @p_branch       VARCHAR(8),
                  @p_location     DECIMAL(19,0),
                  @p_email        VARCHAR(255),
                  @p_user_to_copy VARCHAR(30)',
                @strNewUserID,
                @strFullName,
                @ld_current_timestamp,
                @strCompany,
                @strBranch,
                @decLocation,
                @strEmail,
                @strUserToCopy

            INSERT INTO pc_user_def (profile_skey, first_name, last_name, user_skey, [user_id], active_ind)
            VALUES (NULL, @strFirstName, @strLastName, @intCounter, @strNewUserID, 'a')
        END

        -- Apply delete flag (applies to both insert and update paths)
        UPDATE users
        SET    delete_flag = @delete_flag
        WHERE  id = @strNewUserID
          AND  delete_flag <> @delete_flag

        -- Fix #8: explicitly drop temp table now that it is no longer needed
        DROP TABLE #temp_users_columns_update


        -- ============================================================
        -- users_ud table
        -- Fix #7: single JOIN replaces multiple subqueries
        -- ============================================================
        IF EXISTS (SELECT 1 FROM users_ud WHERE id = @strNewUserID)
        BEGIN
            UPDATE users_ud
            SET    ar_terr            = src.ar_terr
                  ,claims_terr        = src.claims_terr
                  ,salesrep_id        = @salesrep_id
                  ,price_family_id    = src.price_family_id
                  ,power_bi_user      = ISNULL(@power_bi_user, src.power_bi_user)
                  -- Fix #12: fall back to source user's description/job title, matching power_bi_user's pattern above
                  ,user_description   = ISNULL(@user_description, src.user_description)
                  ,job_title          = ISNULL(@job_title, src.job_title)
                  ,date_last_modified = @ld_current_timestamp   -- Fix #5: consistent timestamp
                  ,last_maintained_by = @strMaintainedBy
            FROM   users_ud
            LEFT JOIN users_ud AS src ON src.id = @strUserToCopy
            WHERE  users_ud.id = @strNewUserID
        END
        ELSE
        BEGIN
            INSERT INTO users_ud (
                id, ar_terr, claims_terr, salesrep_id, price_family_id,
                power_bi_user, user_description, job_title,
                date_last_modified, last_maintained_by, date_created, created_by
            )
            SELECT  @strNewUserID
                   ,src.ar_terr
                   ,src.claims_terr
                   ,@salesrep_id
                   ,src.price_family_id
                   ,ISNULL(@power_bi_user, src.power_bi_user)
                   -- Fix #12: fall back to source user's description/job title, matching power_bi_user's pattern above
                   ,ISNULL(@user_description, src.user_description)
                   ,ISNULL(@job_title, src.job_title)
                   ,@ld_current_timestamp    -- Fix #5
                   ,@strMaintainedBy
                   ,@ld_current_timestamp    -- Fix #5
                   ,@strMaintainedBy
            FROM   users_ud src
            WHERE  src.id = @strUserToCopy
        END


        -- ============================================================
        -- Application Security (users_x_application_security)
        -- ============================================================
        CREATE TABLE #appsec_settings (
            users_id                  VARCHAR(30)
            ,application_security_uid INT
            ,code_value               INT
            ,decimal_value            DECIMAL(19,9)
            ,string_value             VARCHAR(255)
            ,date_created             DATETIME
            ,created_by               VARCHAR(255)
            ,date_last_modified       DATETIME
            ,last_maintained_by       VARCHAR(255)
        )
        CREATE INDEX idx_appsec_settings ON #appsec_settings (users_id, application_security_uid)

        INSERT INTO #appsec_settings (
            users_id, application_security_uid, code_value, decimal_value, string_value,
            date_created, created_by, date_last_modified, last_maintained_by
        )
        SELECT  @strNewUserID
               ,application_security_uid
               ,code_value
               ,decimal_value
               ,string_value
               ,@ld_current_timestamp    -- Fix #5
               ,@strMaintainedBy
               ,@ld_current_timestamp    -- Fix #5
               ,@strMaintainedBy
        FROM   users_x_application_security
        WHERE  users_id = @strUserToCopy

        -- Update existing security settings
        UPDATE uas
        SET    uas.code_value         = s.code_value
              ,uas.decimal_value      = s.decimal_value
              ,uas.string_value       = s.string_value
              ,uas.date_last_modified = s.date_last_modified
              ,uas.last_maintained_by = s.last_maintained_by
        FROM   users_x_application_security uas
        INNER JOIN #appsec_settings s
            ON  s.users_id = uas.users_id
            AND s.application_security_uid = uas.application_security_uid

        -- Insert missing security settings
        INSERT INTO users_x_application_security (
            users_id, application_security_uid, code_value, decimal_value, string_value,
            date_created, created_by, date_last_modified, last_maintained_by
        )
        SELECT  s.users_id, s.application_security_uid, s.code_value, s.decimal_value,
                s.string_value, s.date_created, s.created_by, s.date_last_modified, s.last_maintained_by
        FROM   #appsec_settings s
        -- Fix #11: removed NOLOCK — inside a transaction, dirty reads are inappropriate here
        LEFT JOIN users_x_application_security uas
            ON  s.users_id = uas.users_id
            AND s.application_security_uid = uas.application_security_uid
        WHERE  uas.application_security_uid IS NULL

        DROP TABLE #appsec_settings


        -- ============================================================
        -- Portal assignments
        -- DESIGN CHOICE: only add portals the new user is missing;
        -- do not remove portals already assigned to @strNewUserID
        -- ============================================================
        DECLARE @intPortalAddCount INTEGER = (
            SELECT COUNT(pa.portal_uid)
            FROM   portal_assignment pa
            LEFT JOIN portal_assignment existing
                ON  pa.portal_uid  = existing.portal_uid
                AND existing.[user_id] = @strNewUserID
            WHERE  pa.[user_id]        = @strUserToCopy
              AND  pa.row_status_flag  = 704
              AND  existing.portal_uid IS NULL
        )

        IF @intPortalAddCount > 0
        BEGIN
            -- p21_get_counter returns the last filled UID after insertion.
            -- Subtract count and add 1 to get the first available UID.
            DECLARE @intPortalUID INTEGER
            EXEC @intPortalUID = p21_get_counter N'portal_assignment', @intPortalAddCount
            SET @intPortalUID = @intPortalUID - @intPortalAddCount + 1

            INSERT INTO portal_assignment (
                portal_assignment_uid, portal_uid, [user_id],
                date_created, created_by, date_last_modified, last_maintained_by, row_status_flag
            )
            SELECT  (ROW_NUMBER() OVER (PARTITION BY pa.[user_id] ORDER BY pa.portal_assignment_uid) - 1 + @intPortalUID)
                   ,pa.portal_uid
                   ,@strNewUserID
                   ,@ld_current_timestamp    -- Fix #5
                   ,@strMaintainedBy
                   ,@ld_current_timestamp    -- Fix #5
                   ,@strMaintainedBy
                   ,704
            FROM   portal_assignment pa
            LEFT JOIN portal_assignment existing
                ON  pa.portal_uid  = existing.portal_uid
                AND existing.[user_id] = @strNewUserID
            WHERE  pa.[user_id]       = @strUserToCopy
              AND  pa.row_status_flag = 704
              AND  existing.portal_uid IS NULL
        END

        -- Reactivate portals the new user already has but that are not status 704
        -- Fix: INNER JOIN is cleaner and equivalent — LEFT JOIN with NULL check not needed here
        UPDATE existing
        SET    existing.row_status_flag    = 704
              ,existing.date_last_modified = @ld_current_timestamp    -- Fix #5
              ,existing.last_maintained_by = @strMaintainedBy
        FROM   portal_assignment pa
        INNER JOIN portal_assignment existing
            ON  pa.portal_uid      = existing.portal_uid
            AND existing.[user_id] = @strNewUserID
        WHERE  pa.[user_id]           = @strUserToCopy
          AND  pa.row_status_flag     = 704
          AND  existing.row_status_flag <> 704


        -- ============================================================
        -- users_x_company
        -- ============================================================
        IF @intUserXCompanyExists = 0
        BEGIN
            INSERT INTO users_x_company (
                company_id, user_id, date_created, date_last_modified, last_maintained_by
            )
            VALUES (
                @strCompany, @strNewUserID,
                @ld_current_timestamp, @ld_current_timestamp, SYSTEM_USER
            )
        END


        COMMIT TRANSACTION OverallTransaction

        -- Fix #13: role_uid's role name (roles.role) for the summary line, not job_title —
        -- they are different fields (e.g. Role "Purchasing" vs. job_title "Sr Buyer").
        -- contact_id ("Buyer ID") is intentionally never set by this proc (see the
        -- users/users_ud column exclusions above), so it will usually be blank on a
        -- fresh copy — only populated here if it was already present (overwrite case).
        SELECT  @strRoleName  = r.role
               ,@strContactID = u.contact_id
        FROM    users u
        LEFT JOIN roles r ON r.role_uid = u.role_uid
        WHERE   u.id = @strNewUserID

        -- Fix #14: treat blank the same as NULL — callers (e.g. the copy-user runbook)
        -- routinely pass '' for @salesrep_id when it doesn't apply, not NULL
        PRINT 'Created in ' + DB_NAME()
            + ' | User ID: '     + @strNewUserID
            + ' | Role: '        + ISNULL(@strRoleName, '')
            + ' | Location ID: ' + CAST(@decLocation AS VARCHAR(20))
            + CASE WHEN NULLIF(@salesrep_id,  '') IS NOT NULL THEN ' | Salesrep ID: ' + @salesrep_id  ELSE '' END
            + CASE WHEN NULLIF(@strContactID, '') IS NOT NULL THEN ' | Buyer ID: '    + @strContactID ELSE '' END
        RETURN 0

    END TRY
    BEGIN CATCH
        -- Fix #3: single error-handling path via TRY/CATCH (removed @@ERROR + GOTO pattern)
        -- Fix #4: removed unreachable RETURN after THROW
        PRINT 'Error in asi_copy_p21_user: ' + ERROR_MESSAGE()
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION OverallTransaction;
        THROW;
    END CATCH

END

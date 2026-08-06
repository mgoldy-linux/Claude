-- Read-only diagnostic: compares two P21 users across every table asi_proc_copy_p21_user
-- touches (users, users_ud, users_x_application_security, portal_assignment, users_x_company).
-- Built for access-mirroring requests (e.g. "give User B the same access as User A") --
-- surfaces exactly what differs instead of eyeballing ~150 columns and two security tables by hand.
--
-- Design note vs. asi_proc_copy_p21_user: that proc used a WHILE loop over a temp table to build
-- column lists because it needed positional control over an UPDATE...FROM. Here we're just
-- concatenating UNION ALL branches, so STRING_AGG (SQL Server 2017+; this instance is 2019) replaces
-- the loop — same p21_fnt_ColumnList column source, fewer moving parts, no temp table/cursor overhead.
--
-- No kb_/js_ references — built entirely on native P21 tables/functions (p21_fnt_ColumnList,
-- application_security, portal, roles).
CREATE OR ALTER PROCEDURE [dbo].[asi_proc_compare_p21_users]
    @strUserA               VARCHAR(30)
    ,@strUserB              VARCHAR(30)
    ,@bit_ShowAllColumns    BIT = 0     -- 0 = only differing columns (default); 1 = every column, matches included
AS
BEGIN
    SET NOCOUNT ON

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @strUserA)
    BEGIN
        PRINT 'User ' + @strUserA + ' does not exist.'
        RETURN -10
    END
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @strUserB)
    BEGIN
        PRINT 'User ' + @strUserB + ' does not exist.'
        RETURN -10
    END

    DECLARE @ls_SQL NVARCHAR(MAX)

    -- ============================================================
    -- 1) users table — column-by-column diff, plus resolved role name
    --    (role_uid alone is meaningless without joining to roles)
    -- ============================================================
    SELECT @ls_SQL = STRING_AGG(CAST(
        'SELECT ' + CAST(col_order AS VARCHAR(10)) + ' AS col_order, ''' + column_name + ''' AS column_name'
        + ', CAST(a.' + column_name + ' AS NVARCHAR(MAX)) AS value_a'
        + ', CAST(b.' + column_name + ' AS NVARCHAR(MAX)) AS value_b'
        + ' FROM users a CROSS JOIN users b WHERE a.id = @p_a AND b.id = @p_b'
        AS NVARCHAR(MAX)), N' UNION ALL ') WITHIN GROUP (ORDER BY col_order)
    FROM dbo.p21_fnt_ColumnList('users', 'N', 'N')
    WHERE column_name NOT IN ('password', 'date_created', 'date_last_modified', 'last_maintained_by')

    SET @ls_SQL = @ls_SQL + N' UNION ALL
        SELECT 99999, ''role_name (resolved)'', ra.role, rb.role
        FROM users a CROSS JOIN users b
        LEFT JOIN roles ra ON ra.role_uid = a.role_uid
        LEFT JOIN roles rb ON rb.role_uid = b.role_uid
        WHERE a.id = @p_a AND b.id = @p_b'

    SET @ls_SQL = N'SELECT column_name, value_a, value_b FROM (' + @ls_SQL + N') diff
        WHERE @p_show_all = 1 OR ISNULL(value_a, N''~NULL~'') <> ISNULL(value_b, N''~NULL~'')
        ORDER BY col_order'

    EXEC sp_executesql @ls_SQL,
        N'@p_a VARCHAR(30), @p_b VARCHAR(30), @p_show_all BIT',
        @strUserA, @strUserB, @bit_ShowAllColumns


    -- ============================================================
    -- 2) users_ud table — same pattern (job_title, territories, region, etc.)
    --    A user is not guaranteed to have a users_ud row, so seed a single
    --    dummy row and LEFT JOIN both users onto it (unlike `users` above,
    --    which every P21 user row is guaranteed to have — CROSS JOIN is safe there).
    -- ============================================================
    SELECT @ls_SQL = STRING_AGG(CAST(
        'SELECT ' + CAST(col_order AS VARCHAR(10)) + ' AS col_order, ''' + column_name + ''' AS column_name'
        + ', CAST(a.' + column_name + ' AS NVARCHAR(MAX)) AS value_a'
        + ', CAST(b.' + column_name + ' AS NVARCHAR(MAX)) AS value_b'
        + ' FROM (SELECT 1 AS x) seed'
        + ' LEFT JOIN users_ud a ON a.id = @p_a'
        + ' LEFT JOIN users_ud b ON b.id = @p_b'
        AS NVARCHAR(MAX)), N' UNION ALL ') WITHIN GROUP (ORDER BY col_order)
    FROM dbo.p21_fnt_ColumnList('users_ud', 'N', 'N')
    WHERE column_name NOT IN ('users_ud_uid', 'id', 'date_created', 'created_by', 'date_last_modified', 'last_maintained_by')

    SET @ls_SQL = N'SELECT column_name, value_a, value_b FROM (' + @ls_SQL + N') diff
        WHERE @p_show_all = 1 OR ISNULL(value_a, N''~NULL~'') <> ISNULL(value_b, N''~NULL~'')
        ORDER BY col_order'

    EXEC sp_executesql @ls_SQL,
        N'@p_a VARCHAR(30), @p_b VARCHAR(30), @p_show_all BIT',
        @strUserA, @strUserB, @bit_ShowAllColumns


    -- ============================================================
    -- 3) Application security — full outer join per user, only rows that
    --    differ or exist for one user only (the actual "access" delta)
    -- ============================================================
    ;WITH secA AS (
        SELECT application_security_uid, code_value, decimal_value, string_value
        FROM   users_x_application_security
        WHERE  users_id = @strUserA
    ),
    secB AS (
        SELECT application_security_uid, code_value, decimal_value, string_value
        FROM   users_x_application_security
        WHERE  users_id = @strUserB
    )
    SELECT  aps.display_name
           ,aps.internal_name
           ,COALESCE(secA.application_security_uid, secB.application_security_uid) AS application_security_uid
           ,secA.code_value AS a_code_value, secA.decimal_value AS a_decimal_value, secA.string_value AS a_string_value
           ,secB.code_value AS b_code_value, secB.decimal_value AS b_decimal_value, secB.string_value AS b_string_value
           ,CASE
                WHEN secA.application_security_uid IS NULL THEN @strUserB + ' only'
                WHEN secB.application_security_uid IS NULL THEN @strUserA + ' only'
                ELSE 'Value differs'
            END AS diff_type
    FROM    secA
    FULL OUTER JOIN secB ON secA.application_security_uid = secB.application_security_uid
    INNER JOIN application_security aps ON aps.application_security_uid = COALESCE(secA.application_security_uid, secB.application_security_uid)
    WHERE   @bit_ShowAllColumns = 1
       OR   secA.application_security_uid IS NULL
       OR   secB.application_security_uid IS NULL
       OR   ISNULL(secA.code_value, -1)      <> ISNULL(secB.code_value, -1)
       OR   ISNULL(secA.decimal_value, -1)   <> ISNULL(secB.decimal_value, -1)
       OR   ISNULL(secA.string_value, '')    <> ISNULL(secB.string_value, '')
    ORDER BY aps.display_name


    -- ============================================================
    -- 4) Portal assignments — active (704) portals each user has that
    --    the other doesn't
    -- ============================================================
    ;WITH portA AS (
        SELECT portal_uid FROM portal_assignment WHERE user_id = @strUserA AND row_status_flag = 704
    ),
    portB AS (
        SELECT portal_uid FROM portal_assignment WHERE user_id = @strUserB AND row_status_flag = 704
    )
    SELECT  p.portal_name
           ,p.portal_uid
           ,CASE WHEN portB.portal_uid IS NULL THEN @strUserA ELSE @strUserB END AS has_only
    FROM    portA
    FULL OUTER JOIN portB ON portA.portal_uid = portB.portal_uid
    INNER JOIN portal p ON p.portal_uid = COALESCE(portA.portal_uid, portB.portal_uid)
    WHERE   portA.portal_uid IS NULL OR portB.portal_uid IS NULL
    ORDER BY has_only, p.portal_name


    -- ============================================================
    -- 5) users_x_company — company/branch access
    -- ============================================================
    ;WITH compA AS (
        SELECT company_id FROM users_x_company WHERE user_id = @strUserA
    ),
    compB AS (
        SELECT company_id FROM users_x_company WHERE user_id = @strUserB
    )
    SELECT  COALESCE(compA.company_id, compB.company_id) AS company_id
           ,CASE WHEN compB.company_id IS NULL THEN @strUserA ELSE @strUserB END AS has_only
    FROM    compA
    FULL OUTER JOIN compB ON compA.company_id = compB.company_id
    WHERE   compA.company_id IS NULL OR compB.company_id IS NULL

END

# Export-KBUsageReport.ps1
# Runs three KB usage SQL scripts against P21 and exports each result set
# to its own worksheet in a single Excel workbook.
#
# Tabs produced:
#   1. KB Tables         -- Check-KB-Table-Last-Used.sql
#   2. KB Objects        -- Check-KB-Object-Last-Used.sql
#   3. QS Settings       -- Check-KB-View-Usage-QueryStore.sql  (Section 0)
#   4. View Usage        -- Check-KB-View-Usage-QueryStore.sql  (Section 1)
#   5. Views Not In QS   -- Check-KB-View-Usage-QueryStore.sql  (Section 2)
#
# Requirements:
#   Install-Module ImportExcel -Scope CurrentUser
#   Install-Module SqlServer   -Scope CurrentUser

[CmdletBinding()]
param(
    [string]$ServerInstance = "P21.allsurfaces.com",
    [string]$Database       = "P21",
    [string]$OutputPath     = "C:\Claude\Reports\P21-Custom-Objects-Usage-$(Get-Date -Format 'yyyy-MM-dd').xlsx"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    throw "Invoke-Sqlcmd not found. Install: Install-Module SqlServer -Scope CurrentUser"
}
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    throw "ImportExcel not found. Install: Install-Module ImportExcel -Scope CurrentUser"
}
Import-Module ImportExcel

$outDir = Split-Path $OutputPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
if (Test-Path $OutputPath)    { Remove-Item $OutputPath -Force }

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
$headerBg    = [System.Drawing.Color]::FromArgb(68,  114, 196)   # Excel blue
$headerFg    = [System.Drawing.Color]::White
$amberBg     = [System.Drawing.Color]::FromArgb(255, 192,   0)   # amber  (read null, write present)
$redBg       = [System.Drawing.Color]::FromArgb(255, 149, 149)   # light red (both null)

# Junk columns Invoke-Sqlcmd adds from the underlying DataRow
$junkCols = 'RowError','RowState','Table','ItemArray','HasErrors'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Invoke-KB {
    param([string]$Query, [int]$Retries = 5)
    $attempt = 0
    while ($true) {
        try {
            return Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database `
                                 -Query $Query -TrustServerCertificate -QueryTimeout 300
        } catch {
            $attempt++
            if ($attempt -ge $Retries -or $_.Exception.Message -notmatch '601') { throw }
            Write-Host "    Msg 601 (data movement), retrying in 5s ($attempt of $($Retries - 1))..."
            Start-Sleep -Seconds 5
        }
    }
}

function Remove-JunkColumns {
    param($Rows)
    $arr = @($Rows)
    if ($arr.Count -eq 0) { return $null }
    $keep = $arr[0].PSObject.Properties.Name | Where-Object { $_ -notin $junkCols }
    $arr | Select-Object -Property $keep
}

# Writes data to a worksheet, styles the header, aligns left, then highlights rows:
#   $NullCheckColumn   : amber if that column is NULL  (Objects / View Usage tabs)
#   $ReadCol + $WriteCol: both NULL = red, only ReadCol NULL = amber  (Tables tab)
#   $HighlightAll      : amber every data row  (Views Not In QS tab)
function Export-KBSheet {
    param(
        $Data,
        [string]$WorksheetName,
        [string]$NullCheckColumn = '',
        [string]$ReadCol         = '',
        [string]$WriteCol        = '',
        [switch]$HighlightAll
    )

    if (-not $Data) {
        [PSCustomObject]@{ Info = "No rows returned" } |
            Export-Excel -Path $OutputPath -WorksheetName $WorksheetName `
                         -AutoFilter -FreezeTopRow -AutoSize
        return
    }

    $clean = Remove-JunkColumns $Data

    $xl = $clean | Export-Excel -Path $OutputPath -WorksheetName $WorksheetName `
                                -AutoFilter -FreezeTopRow -AutoSize -PassThru

    $ws      = $xl.Workbook.Worksheets[$WorksheetName]
    $lastCol = $ws.Dimension.End.Column
    $lastRow = $ws.Dimension.End.Row

    # --- Bold header: blue background / white text ---
    $headerRange = $ws.Cells[1, 1, 1, $lastCol]
    $headerRange.Style.Font.Bold = $true
    $headerRange.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
    $headerRange.Style.Fill.BackgroundColor.SetColor($headerBg)
    $headerRange.Style.Font.Color.SetColor($headerFg)

    # --- Left-align all cells (header + data) ---
    $ws.Cells[1, 1, $lastRow, $lastCol].Style.HorizontalAlignment =
        [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Left

    # --- Row highlighting ---
    if ($lastRow -gt 1) {

        # Resolve column indexes for dual-column (Tables) mode
        $readColIdx  = 0
        $writeColIdx = 0
        $checkColIdx = 0

        for ($c = 1; $c -le $lastCol; $c++) {
            $h = $ws.Cells[1, $c].Text
            if ($ReadCol  -and $h -eq $ReadCol)         { $readColIdx  = $c }
            if ($WriteCol -and $h -eq $WriteCol)        { $writeColIdx = $c }
            if ($NullCheckColumn -and $h -eq $NullCheckColumn) { $checkColIdx = $c }
        }

        for ($r = 2; $r -le $lastRow; $r++) {
            $color = $null

            if ($HighlightAll) {
                $color = $amberBg

            } elseif ($readColIdx -gt 0 -and $writeColIdx -gt 0) {
                # Tables tab: dual-column logic
                $readNull  = ($null -eq $ws.Cells[$r, $readColIdx].Value)
                $writeNull = ($null -eq $ws.Cells[$r, $writeColIdx].Value)
                if   ($readNull -and $writeNull) { $color = $redBg   }
                elseif ($readNull)               { $color = $amberBg }

            } elseif ($checkColIdx -gt 0) {
                # Single-column: amber if null
                if ($null -eq $ws.Cells[$r, $checkColIdx].Value) { $color = $amberBg }
            }

            if ($color) {
                $rowRange = $ws.Cells[$r, 1, $r, $lastCol]
                $rowRange.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                $rowRange.Style.Fill.BackgroundColor.SetColor($color)
            }
        }
    }

    Close-ExcelPackage $xl
    Write-Host "    -> ${WorksheetName}: $($lastRow - 1) rows"
}

# ---------------------------------------------------------------------------
Write-Host "Connecting to $ServerInstance \ $Database ..."

# ===========================================================================
# Tab 1: KB Tables
# ===========================================================================
Write-Host "  Running: KB Tables ..."

$sqlTables = @'
DECLARE @serverStart datetime = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info);

SELECT
    t.name                                          AS table_name,
    p.rows                                          AS row_count,
    NULLIF((SELECT MAX(v) FROM (VALUES
        (MAX(u.last_user_seek)),
        (MAX(u.last_user_scan)),
        (MAX(u.last_user_lookup))
    ) x(v)), NULL)                                  AS last_read,
    MAX(u.last_user_update)                         AS last_write,
    CASE
        WHEN MAX(u.last_user_update) IS NULL THEN '(none since restart)'
        ELSE CAST(DATEDIFF(day, MAX(u.last_user_update), GETDATE()) AS varchar) + ' day(s) ago'
    END                                             AS last_write_age,
    @serverStart                                    AS server_start_time
FROM sys.tables t
JOIN sys.partitions p
    ON  p.object_id = t.object_id
    AND p.index_id IN (0, 1)
LEFT JOIN sys.dm_db_index_usage_stats u
    ON  u.object_id   = t.object_id
    AND u.database_id = DB_ID()
WHERE (t.name LIKE 'kb_%' OR t.name LIKE 'asi_%' OR t.name LIKE 'ds_%' OR t.name LIKE 'js_%')
GROUP BY t.name, p.rows
ORDER BY last_write DESC, last_read DESC, t.name;
'@

# Highlight rows where BOTH last_read and last_write are null.
# We do this by checking last_read (if that's null the row has had zero reads or writes).
Export-KBSheet -Data (Invoke-KB $sqlTables) -WorksheetName 'Tables' `
               -ReadCol 'last_read' -WriteCol 'last_write'

# ===========================================================================
# Tab 2: KB Objects  (procs, functions, triggers)
# ===========================================================================
Write-Host "  Running: KB Objects ..."

$sqlObjects = @'
DECLARE @serverStart datetime = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info);

-- Plan-cache DMVs (dm_exec_*_stats) reset on plan eviction/recompile -- they do NOT
-- mean "unused since restart," just "no cached plan right now." Objects with heavy
-- internal #temp table churn (CREATE/DROP per call) recompile on every execution and
-- can show blank stats here even when they run every night. Cross-reference SQL Agent
-- job steps so a scheduled object is never mistaken for a dead one.
IF OBJECT_ID('tempdb..#scheduled_jobs') IS NOT NULL DROP TABLE #scheduled_jobs;
SELECT js.command, j.name AS job_name, j.enabled AS job_enabled
INTO #scheduled_jobs
FROM msdb.dbo.sysjobsteps js
INNER JOIN msdb.dbo.sysjobs j ON j.job_id = js.job_id
WHERE js.command LIKE '%kb[_]%' OR js.command LIKE '%asi[_]%' OR js.command LIKE '%ds[_]%' OR js.command LIKE '%js[_]%';

SELECT 'PROC' AS object_type, o.name AS object_name, o.modify_date AS last_modified,
       ps.execution_count AS exec_count, ps.last_execution_time,
       CASE WHEN ps.last_execution_time IS NULL THEN '(none since restart)'
            ELSE CAST(DATEDIFF(day, ps.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
       END AS last_exec_age,
       @serverStart AS server_start_time,
       STUFF((
           SELECT ', ' + sj.job_name + CASE WHEN sj.job_enabled = 0 THEN ' (disabled)' ELSE '' END
           FROM #scheduled_jobs sj
           WHERE sj.command LIKE '%' + o.name + '%'
           FOR XML PATH('')
       ), 1, 2, '') AS scheduled_job
FROM sys.objects o
LEFT JOIN sys.dm_exec_procedure_stats ps
    ON ps.object_id = o.object_id AND ps.database_id = DB_ID()
WHERE o.type = 'P' AND (o.name LIKE 'kb_%' OR o.name LIKE 'asi_%' OR o.name LIKE 'ds_%' OR o.name LIKE 'js_%')

UNION ALL

SELECT 'SCALAR FUNC', o.name, o.modify_date,
       fs.execution_count, fs.last_execution_time,
       CASE WHEN fs.last_execution_time IS NULL THEN '(none since restart)'
            ELSE CAST(DATEDIFF(day, fs.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
       END, @serverStart,
       STUFF((
           SELECT ', ' + sj.job_name + CASE WHEN sj.job_enabled = 0 THEN ' (disabled)' ELSE '' END
           FROM #scheduled_jobs sj
           WHERE sj.command LIKE '%' + o.name + '%'
           FOR XML PATH('')
       ), 1, 2, '')
FROM sys.objects o
LEFT JOIN sys.dm_exec_function_stats fs
    ON fs.object_id = o.object_id AND fs.database_id = DB_ID()
WHERE o.type = 'FN' AND (o.name LIKE 'kb_%' OR o.name LIKE 'asi_%' OR o.name LIKE 'ds_%' OR o.name LIKE 'js_%')

UNION ALL

SELECT 'TVF', o.name, o.modify_date,
       fs.execution_count, fs.last_execution_time,
       CASE WHEN fs.last_execution_time IS NULL THEN '(none since restart)'
            ELSE CAST(DATEDIFF(day, fs.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
       END, @serverStart,
       STUFF((
           SELECT ', ' + sj.job_name + CASE WHEN sj.job_enabled = 0 THEN ' (disabled)' ELSE '' END
           FROM #scheduled_jobs sj
           WHERE sj.command LIKE '%' + o.name + '%'
           FOR XML PATH('')
       ), 1, 2, '')
FROM sys.objects o
LEFT JOIN sys.dm_exec_function_stats fs
    ON fs.object_id = o.object_id AND fs.database_id = DB_ID()
WHERE o.type IN ('IF', 'TF') AND (o.name LIKE 'kb_%' OR o.name LIKE 'asi_%' OR o.name LIKE 'ds_%' OR o.name LIKE 'js_%')

UNION ALL

SELECT 'TRIGGER', o.name, o.modify_date,
       ts.execution_count, ts.last_execution_time,
       CASE WHEN ts.last_execution_time IS NULL THEN '(none since restart)'
            ELSE CAST(DATEDIFF(day, ts.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
       END, @serverStart,
       STUFF((
           SELECT ', ' + sj.job_name + CASE WHEN sj.job_enabled = 0 THEN ' (disabled)' ELSE '' END
           FROM #scheduled_jobs sj
           WHERE sj.command LIKE '%' + o.name + '%'
           FOR XML PATH('')
       ), 1, 2, '')
FROM sys.objects o
LEFT JOIN sys.dm_exec_trigger_stats ts
    ON ts.object_id = o.object_id AND ts.database_id = DB_ID()
WHERE o.type = 'TR' AND (o.name LIKE 'kb_%' OR o.name LIKE 'asi_%' OR o.name LIKE 'ds_%' OR o.name LIKE 'js_%')

ORDER BY object_type, last_execution_time DESC, object_name;

DROP TABLE #scheduled_jobs;
'@

# Dual-column logic: red = no exec stats AND no scheduled job (genuinely looks unused);
# amber = no exec stats but IS referenced by a job step (plan-cache blind spot -- do not
# treat as safe to retire without checking the job first).
Export-KBSheet -Data (Invoke-KB $sqlObjects) -WorksheetName 'Objects' `
               -ReadCol 'last_execution_time' -WriteCol 'scheduled_job'

# ===========================================================================
# Tab 3: QS Settings  (no highlighting needed)
# ===========================================================================
Write-Host "  Running: QS Settings ..."

$sqlQsSettings = @'
SELECT actual_state_desc AS qs_state, query_capture_mode_desc AS capture_mode,
       size_based_cleanup_mode_desc AS cleanup_mode, max_storage_size_mb,
       stale_query_threshold_days AS retention_days, current_storage_size_mb
FROM sys.database_query_store_options;
'@

Export-KBSheet -Data (Invoke-KB $sqlQsSettings) -WorksheetName 'QS Settings'

# ===========================================================================
# Tab 4: View Usage
# ===========================================================================
Write-Host "  Running: View Usage ..."

$sqlViewUsage = @'
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
IF OBJECT_ID('tempdb..#qs') IS NOT NULL DROP TABLE #qs;

SELECT qt.query_sql_text,
       MAX(rs.last_execution_time) AS last_execution_time,
       SUM(rs.count_executions)    AS count_executions,
       AVG(rs.avg_duration)        AS avg_duration
INTO #qs
FROM sys.query_store_query_text   qt
JOIN sys.query_store_query         q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan          qp ON qp.query_id     = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id      = qp.plan_id
WHERE (qt.query_sql_text LIKE '%kb_%' OR qt.query_sql_text LIKE '%asi_%' OR qt.query_sql_text LIKE '%ds_%' OR qt.query_sql_text LIKE '%js_%')
GROUP BY qt.query_sql_text;

SELECT v.name AS view_name, v.modify_date AS last_modified,
       MAX(qs.last_execution_time) AS last_seen_in_qs,
       SUM(qs.count_executions)    AS total_executions,
       CAST(AVG(qs.avg_duration) / 1000.0 AS decimal(10,2)) AS avg_duration_ms,
       CASE WHEN MAX(qs.last_execution_time) IS NULL THEN '(not in Query Store)'
            ELSE CAST(DATEDIFF(day, MAX(qs.last_execution_time), GETDATE()) AS varchar) + ' day(s) ago'
       END AS last_seen_age
FROM sys.views v
LEFT JOIN #qs qs ON qs.query_sql_text LIKE '%' + v.name + '%'
WHERE (v.name LIKE 'kb_%' OR v.name LIKE 'asi_%' OR v.name LIKE 'ds_%' OR v.name LIKE 'js_%')
GROUP BY v.name, v.modify_date
ORDER BY last_seen_in_qs DESC, v.modify_date DESC;

DROP TABLE #qs;
'@

Export-KBSheet -Data (Invoke-KB $sqlViewUsage) -WorksheetName 'View Usage' `
               -NullCheckColumn 'last_seen_in_qs'

# ===========================================================================
# Tab 5: Views Not In QS  (every row = not accessed -- highlight all)
# ===========================================================================
Write-Host "  Running: Views Not In QS ..."

$sqlViewsNotInQs = @'
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
IF OBJECT_ID('tempdb..#qs') IS NOT NULL DROP TABLE #qs;

SELECT qt.query_sql_text,
       MAX(rs.last_execution_time) AS last_execution_time,
       SUM(rs.count_executions)    AS count_executions,
       AVG(rs.avg_duration)        AS avg_duration
INTO #qs
FROM sys.query_store_query_text   qt
JOIN sys.query_store_query         q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan          qp ON qp.query_id     = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id      = qp.plan_id
WHERE (qt.query_sql_text LIKE '%kb_%' OR qt.query_sql_text LIKE '%asi_%' OR qt.query_sql_text LIKE '%ds_%' OR qt.query_sql_text LIKE '%js_%')
GROUP BY qt.query_sql_text;

SELECT v.name AS view_name, v.modify_date AS last_modified,
       DATEDIFF(year, v.modify_date, GETDATE()) AS years_since_modified
FROM sys.views v
WHERE (v.name LIKE 'kb_%' OR v.name LIKE 'asi_%' OR v.name LIKE 'ds_%' OR v.name LIKE 'js_%')
  AND NOT EXISTS (SELECT 1 FROM #qs WHERE query_sql_text LIKE '%' + v.name + '%')
ORDER BY v.modify_date;

DROP TABLE #qs;
'@

Export-KBSheet -Data (Invoke-KB $sqlViewsNotInQs) -WorksheetName 'Views Not In QS' `
               -HighlightAll

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Report saved: $OutputPath" -ForegroundColor Green

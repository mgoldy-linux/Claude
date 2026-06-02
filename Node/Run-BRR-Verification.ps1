<#
.SYNOPSIS
    BRR Refresh Verification Report  –  outputs a formatted .docx
.DESCRIPTION
    Runs verification queries against P21Dev.allsurfaces.com, serialises
    the results to a temporary JSON file, then calls a Node.js helper
    (build-brr-docx.js, in the same folder) to produce the final .docx.
.NOTES
    Prerequisites:
      • SqlServer PowerShell module  → Install-Module SqlServer -Scope CurrentUser
      • Node.js + docx npm package   → npm install -g docx
      • build-brr-docx.js            → must sit in the same folder as this script
#>

Clear-Host

#region ── Configuration ────────────────────────────────────────────────────────
$SqlServer   = "P21Dev.allsurfaces.com"
$MsdbDb      = "msdb"
$P21Db       = "P21BusinessRules"
$ScriptDir   = $PSScriptRoot
$NodeHelper  = Join-Path $ScriptDir "build-brr-docx.js"
$TempJson    = Join-Path $env:TEMP ("brr-data-{0}.json" -f [guid]::NewGuid().ToString("N"))
$OutputDocx  = Join-Path $ScriptDir ("BRR-Verification_{0}.docx" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$BrrJobId    = "5FADA1E7-D89A-41E6-B984-2EC2DA4FEEB8"
#endregion

#region ── Guard: verify dependencies ──────────────────────────────────────────
Write-Host "BRR Refresh Verification" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

if (-not (Test-Path $NodeHelper)) {
    Write-Error "build-brr-docx.js not found at: $NodeHelper`nPlace it in the same folder as this script."
    exit 1
}

if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Error "Invoke-Sqlcmd not found. Run: Install-Module SqlServer -Scope CurrentUser"
    exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js not found. Install from https://nodejs.org"
    exit 1
}

# Ensure docx package is available locally in the script folder
$NodeModules = Join-Path $ScriptDir "node_modules\docx"
if (-not (Test-Path $NodeModules)) {
    Write-Host "Installing 'docx' npm package in script folder ..." -ForegroundColor Yellow
    Push-Location $ScriptDir
    & npm install docx --save 2>&1 | Out-Null
    Pop-Location
    if (-not (Test-Path $NodeModules)) {
        Write-Error "Failed to install 'docx' package. Run manually: cd '$ScriptDir' && npm install docx"
        exit 1
    }
    Write-Host "  [+] docx package installed." -ForegroundColor Green
}
#endregion

#region ── Helper: run a query, return ordered results ──────────────────────────
function Invoke-Query {
    param(
        [string]$Database,
        [string]$Query
    )
    try {
        $rows = Invoke-Sqlcmd -ServerInstance $SqlServer `
                              -Database $Database `
                              -Query $Query `
                              -TrustServerCertificate `
                              -ErrorAction Stop

        if (-not $rows) { return @{ Columns = @(); Rows = @() } }

        $rowArray = @($rows)
        # Derive clean column list (exclude PS DataRow noise)
        $skipCols = @('RowError','RowState','Table','HasErrors','ItemArray')
        $cols = $rowArray[0].PSObject.Properties |
                Where-Object { $_.Name -notin $skipCols } |
                Select-Object -ExpandProperty Name

        $data = $rowArray | ForEach-Object {
            $r = $_
            $cols | ForEach-Object -Begin { $arr = @() } `
                                   -Process { $arr += if ($null -eq $r.$_) { $null } else { [string]$r.$_ } } `
                                   -End { ,$arr }
        }

        return @{ Columns = $cols; Rows = $data }
    }
    catch {
        Write-Warning "  Query error on [$Database]: $_"
        return @{ Columns = @(); Rows = @(); Error = $_.Exception.Message }
    }
}
#endregion

#region ── Queries ──────────────────────────────────────────────────────────────
$TodayInt = Get-Date -Format "yyyyMMdd"

$queries = [ordered]@{

    "BRR Agent Job History (Today)" = @{
        Db  = $MsdbDb
        Sql = @"
DECLARE @TodayDateInt INT = $TodayInt;
SELECT
    j.name AS JobName,
    CAST(CAST(jh.run_date AS CHAR(8)) + ' ' +
         STUFF(STUFF(RIGHT('000000' + CAST(jh.run_time AS VARCHAR(6)),6),3,0,':'),6,0,':')
         AS DATETIME) AS StartTime,
    CASE jh.run_status
        WHEN 0 THEN 'Failed'      WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'       WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress' WHEN 5 THEN 'Unknown'
    END AS RunStatus,
    CAST(STUFF(STUFF(RIGHT('000000' + CAST(jh.run_duration AS VARCHAR(6)),6),3,0,':'),6,0,':') AS TIME) AS Duration_HHMMSS,
    jh.message AS Message
FROM dbo.sysjobhistory jh
INNER JOIN dbo.sysjobs j ON jh.job_id = j.job_id
WHERE jh.run_date = @TodayDateInt
  AND j.job_id = '$BrrJobId'
  AND jh.step_id = 0
ORDER BY StartTime DESC;
"@
    }

    "Recent Orders (Last 24 h)" = @{
        Db         = $P21Db
        MaxColumns = 7
        NoWrap     = $true
        Sql        = @"
SELECT TOP 7 *
FROM oe_hdr
WHERE order_date >= DATEADD(day, -1, GETDATE())
ORDER BY order_date DESC;
"@
    }

    "Branch Sample (5 Random Active)" = @{
        Db         = $P21Db
        MaxColumns = 7
        NoWrap     = $true
        Sql        = @"
SELECT TOP 5 *
FROM branch
WHERE delete_flag = 'N'
ORDER BY NEWID();
"@
    }

    "Location Names Sample (5 Random Active)" = @{
        Db  = $P21Db
        Sql = @"
SELECT TOP 5 location_name
FROM location
WHERE delete_flag = 'N'
ORDER BY NEWID();
"@
    }

    "Pick Tickets – Location 380 (Last 72 h)" = @{
        Db  = $P21Db
        Sql = @"
SELECT TOP 5 *
FROM oe_pick_ticket
WHERE location_id = 380
  AND (
        (print_date >= DATEADD(hour, -72, GETDATE()) AND tracking_no != '* * CANCELLED * *')
     OR (print_date >= DATEADD(hour, -72, GETDATE()) AND tracking_no IS NULL)
      )
ORDER BY NEWID();
"@
    }

    "Invoices – Source Location 380 (Last 72 h)" = @{
        Db  = $P21Db
        Sql = @"
SELECT TOP 7 ih.invoice_no, ih.order_no, ih.ship_date
FROM invoice_hdr ih
JOIN oe_hdr oh ON ih.order_no = oh.order_no AND oh.source_location_id = 380
WHERE ih.invoice_date >= DATEADD(hour, -72, GETDATE())
ORDER BY NEWID();
"@
    }

    "Users with Default Label Printer – Branch 183" = @{
        Db  = $P21Db
        Sql = @"
SELECT id, name, default_branch, default_location_id,
       role_uid, email_address, default_label_printer
FROM users
WHERE delete_flag = 'N'
  AND default_label_printer IS NOT NULL
  AND default_branch = 183;
"@
    }
}
#endregion

#region ── Run queries & collect results ────────────────────────────────────────
Write-Host ""
Write-Host "Running queries against $SqlServer ..." -ForegroundColor Yellow
Write-Host ""

$sections = [System.Collections.Generic.List[hashtable]]::new()

foreach ($title in $queries.Keys) {
    $q      = $queries[$title]
    $result = Invoke-Query -Database $q.Db -Query $q.Sql
    $rc     = $result.Rows.Count

    $statusIcon = if ($result.Error) { "[!]" } else { "[+]" }
    $color      = if ($result.Error) { "Red" }  else { "Green" }
    Write-Host ("  {0}  {1,-50}  {2} rows" -f $statusIcon, $title, $rc) -ForegroundColor $color

    # Trim to MaxColumns if specified
    $cols = $result.Columns
    $dataRows = $result.Rows
    if ($q.MaxColumns -and $cols.Count -gt $q.MaxColumns) {
        $cols    = $cols[0..($q.MaxColumns - 1)]
        $dataRows = @($dataRows | ForEach-Object { ,($_[0..($q.MaxColumns - 1)]) })
    }

    $sections.Add(@{
        title    = $title
        db       = $q.Db
        rowCount = $rc
        columns  = $cols
        rows     = $dataRows
        noWrap   = ($q.ContainsKey('NoWrap') -and $q.NoWrap -eq $true)
        error    = $result.Error
    })
}
#endregion

#region ── Serialise to temp JSON ────────────────────────────────────────────────
Write-Host ""
Write-Host "Serialising results ..." -ForegroundColor Yellow

$payload = @{
    generatedAt = (Get-Date -Format "dddd, MMMM dd yyyy  HH:mm:ss")
    server      = $SqlServer
    sections    = $sections
}

$payload | ConvertTo-Json -Depth 10 | Out-File -FilePath $TempJson -Encoding UTF8
#endregion

#region ── Call Node.js to build the .docx ───────────────────────────────────────
Write-Host "Building .docx ..." -ForegroundColor Yellow

$nodeOut = & node $NodeHelper $TempJson $OutputDocx 2>&1

if ($LASTEXITCODE -ne 0 -or $nodeOut -notmatch '^OK:') {
    Write-Error "Node.js builder failed:`n$nodeOut"
    exit 1
}

# Clean up temp file
Remove-Item $TempJson -ErrorAction SilentlyContinue
#endregion

#region ── Done ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Done! Report saved to:" -ForegroundColor Cyan
Write-Host "  $OutputDocx" -ForegroundColor White
Write-Host ""

# Auto-open the document
Start-Process $OutputDocx
#endregion

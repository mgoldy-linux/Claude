# Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1
# One-time forced rerun of the 90 Day Usage Report's per-location subscriptions,
# requested by Jami Klitzman to validate the 2026-07-27 mfg "Use Default Value"
# fix before the normal Sunday schedule.
#
# Uses ReportingService2010.FireEvent(EventType="TimedSubscription", EventData=<ScheduleID>, SiteUrl="").
# NOTE: this environment's FireEvent signature takes 3 string args, not 2 --
# SiteUrl is a SharePoint-integration-mode parameter, unused/blank in native mode
# but still required positionally (confirmed 2026-07-28 via reflection on $rs).
# This fires the REAL subscription -- real email, real recipients, same as if
# its Sunday schedule had triggered it. It does NOT touch or move the schedule
# itself, so Sunday's normal run is unaffected; recipients just get a second
# copy of their report this week.
#
# Each of the 44 per-location subscriptions has its own PRIVATE Schedule
# (verified 2026-07-27 via dbo.ReportSchedule / dbo.Schedule), so firing one
# cannot spill into another subscription or another report.
#
# Default is a dry run (lists what would fire) -- pass -Apply to actually fire.
#
# NOTE: New-WebServiceProxy against SSRS's ReportService2010.asmx WSDL only
# builds a working client under Windows PowerShell 5.1 (powershell.exe) --
# under PowerShell 7 (pwsh) it silently returns a hollow object with none of
# the WSDL-defined methods. Run this script with:
#   powershell.exe -NoProfile -File Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1 -Apply

[CmdletBinding()]
param(
    [string]$ReportServerUri = "https://reports.allsurfaces.com/ReportServer",
    [string]$SqlInstance     = "ASDWDB01.ahi.local",
    [string]$CatalogDb       = "ReportServer",
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Pull subscription + schedule pairs live, rather than hardcoding GUIDs.
# Same per-location scope as Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1.
# ---------------------------------------------------------------------------
Write-Host "Pulling subscription/schedule list from $SqlInstance \ $CatalogDb ..."

$subQuery = @'
SELECT s.SubscriptionID, s.Description, sch.ScheduleID
FROM dbo.Subscriptions s
JOIN dbo.Catalog c ON s.Report_OID = c.ItemID
JOIN dbo.ReportSchedule rs ON rs.SubscriptionID = s.SubscriptionID
JOIN dbo.Schedule sch ON sch.ScheduleID = rs.ScheduleID
WHERE c.Name LIKE '%Usage%'
ORDER BY s.Description
'@

$connStr = "Server=$SqlInstance;Database=$CatalogDb;Integrated Security=True;TrustServerCertificate=True"
$allSubs = New-Object System.Collections.Generic.List[object]
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
try {
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand $subQuery, $conn
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $allSubs.Add([pscustomobject]@{
            SubId    = [string]$reader['SubscriptionID']
            Desc     = [string]$reader['Description']
            SchedId  = [string]$reader['ScheduleID']
        })
    }
    $reader.Close()
} finally {
    $conn.Close()
}

$locationSubs = @($allSubs | Where-Object { $_.Desc -match '^\s*\d{3}\b' })
$skippedSubs  = @($allSubs | Where-Object { $_.Desc -notmatch '^\s*\d{3}\b' })

Write-Host "  -> $($allSubs.Count) total subscriptions on this report"
Write-Host "  -> $($locationSubs.Count) per-location subscriptions in scope to fire"
if ($skippedSubs.Count -gt 0) {
    Write-Host "  -> Excluded (not per-location, left alone):"
    $skippedSubs | ForEach-Object { Write-Host "       $($_.Desc)" }
}

if ($locationSubs.Count -eq 0) {
    throw "No per-location subscriptions found -- aborting."
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "DRY RUN -- the following would be fired (real email to real recipients):" -ForegroundColor Yellow
    $locationSubs | Select-Object Desc, SubId, SchedId | Format-Table -AutoSize
    Write-Host "Re-run with -Apply to actually fire them." -ForegroundColor Yellow
    return
}

# ---------------------------------------------------------------------------
# Connect to the SSRS SOAP API and fire each schedule
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Connecting to $ReportServerUri/ReportService2010.asmx ..."
$rs = New-WebServiceProxy -Uri "$ReportServerUri/ReportService2010.asmx?wsdl" -UseDefaultCredential

if (@($rs.GetType().GetMethods() | Where-Object Name -eq 'FireEvent').Count -eq 0) {
    throw "Proxy has no FireEvent method -- hollow proxy. Re-run under powershell.exe (Windows PowerShell 5.1), not pwsh."
}

$summary = @()

foreach ($sub in $locationSubs) {
    Write-Host ""
    Write-Host "=== Firing $($sub.Desc) ($($sub.SchedId)) ===" -ForegroundColor Cyan
    try {
        $rs.FireEvent("TimedSubscription", $sub.SchedId, "")
        Write-Host "  FIRED." -ForegroundColor Green
        $summary += [pscustomobject]@{ Location = $sub.Desc; Result = "Fired" }
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $summary += [pscustomobject]@{ Location = $sub.Desc; Result = "FAILED: $($_.Exception.Message)" }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$summary | Format-Table -AutoSize

Write-Host ""
Write-Host "Done. SSRS queues these asynchronously -- check dbo.Subscriptions.LastRunTime / LastStatus" -ForegroundColor Green
Write-Host "or ExecutionLog3 in a few minutes to confirm each one actually ran and rendered non-empty."

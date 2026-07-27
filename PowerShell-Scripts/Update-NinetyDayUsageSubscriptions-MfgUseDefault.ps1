# Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1
# Switches the "mfg" (manufacturer) parameter on the 90 Day Usage Report's
# per-location subscriptions from a static "Enter value" list to
# "Use Default Value", by removing the stored mfg ParameterValue entries.
#
# Why: the deployed report's mfg parameter is now defined MultiValue=False,
# but subscriptions still carry 300+ individual mfg entries each -- a leftover
# from when the parameter was multi-value. Its default resolves to NULL, and
# the report's query is `(@mfg IS NULL OR ic.manufacturer_id = @mfg)`, so
# "Use Default" means "no manufacturer filter" -- safe, not lossy. This
# removes both the stale-list problem and the type-mismatch problem.
# See: C:\Users\mgoldyn\.claude\projects\C--Claude\memory\project_2026_07_23_ssrs_90day_usage_blank.md
#
# Scope: only subscriptions whose Description starts with a branch/location
# number (e.g. "140 - 90 Day Usage Report"). Deliberately EXCLUDES the
# specialty subscriptions on this same report (Karndean 90 Day Global Report,
# Lotte Weekly 90 Day Report, 90 Day, Test of missing Paramater, Weekly Global
# 90 Day Usage) since those intentionally filter to specific manufacturer(s)
# and are not per-location.
#
# Default is a dry run -- pass -Apply to actually commit the change.
#
# NOTE: New-WebServiceProxy against SSRS's ReportService2010.asmx WSDL only
# builds a working client under Windows PowerShell 5.1 (powershell.exe) --
# under PowerShell 7 (pwsh) it silently returns a hollow object with none of
# the WSDL-defined methods. Run this script with:
#   powershell.exe -NoProfile -File Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1
# Uses plain ADO.NET for the SQL lookup (no dbatools/SqlServer module
# dependency), since 5.1 may not have the same modules installed as pwsh.

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
# Pull the current subscription list for this report directly from the
# catalog DB, then keep only the per-location ones (Description starts
# with digits). Pulling live rather than hardcoding ~44 GUIDs.
# ---------------------------------------------------------------------------
Write-Host "Pulling subscription list from $SqlInstance \ $CatalogDb ..."

$subQuery = @'
SELECT s.SubscriptionID, s.Description
FROM dbo.Subscriptions s
JOIN dbo.Catalog c ON s.Report_OID = c.ItemID
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
            Id   = [string]$reader['SubscriptionID']
            Desc = [string]$reader['Description']
        })
    }
    $reader.Close()
} finally {
    $conn.Close()
}

# Branch codes on this report are all 3-digit (100-400+). Matching \d{3}
# specifically (not just \d+) avoids false-positives like "90 Day", which
# starts with a number but is not a per-location subscription.
$locationSubs = @($allSubs | Where-Object { $_.Desc -match '^\s*\d{3}\b' })
$skippedSubs  = @($allSubs | Where-Object { $_.Desc -notmatch '^\s*\d{3}\b' })

Write-Host "  -> $($allSubs.Count) total subscriptions on this report"
Write-Host "  -> $($locationSubs.Count) per-location subscriptions in scope"
if ($skippedSubs.Count -gt 0) {
    Write-Host "  -> Excluded (not per-location, left untouched):"
    $skippedSubs | ForEach-Object { Write-Host "       $($_.Desc)" }
}

if ($locationSubs.Count -eq 0) {
    throw "No per-location subscriptions found -- aborting."
}

# ---------------------------------------------------------------------------
# Connect to the SSRS SOAP API
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Connecting to $ReportServerUri/ReportService2010.asmx ..."
$rs = New-WebServiceProxy -Uri "$ReportServerUri/ReportService2010.asmx?wsdl" -UseDefaultCredential

if (@($rs.GetType().GetMethods() | Where-Object Name -eq 'GetSubscriptionProperties').Count -eq 0) {
    throw "Proxy has no GetSubscriptionProperties method -- hollow proxy. Re-run under powershell.exe (Windows PowerShell 5.1), not pwsh."
}

# ---------------------------------------------------------------------------
# Update each in-scope subscription
# ---------------------------------------------------------------------------
$summary = @()

foreach ($sub in $locationSubs) {

    Write-Host ""
    Write-Host "=== $($sub.Desc) ($($sub.Id)) ===" -ForegroundColor Cyan

    $extSettings = $null; $desc = $null; $active = $null
    $status = $null; $eventType = $null; $matchData = $null; $values = $null

    $rs.GetSubscriptionProperties(
        $sub.Id,
        [ref]$extSettings, [ref]$desc, [ref]$active,
        [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values
    ) | Out-Null

    $mfgEntries = @($values | Where-Object { $_.Name -eq 'mfg' })

    if ($mfgEntries.Count -eq 0) {
        Write-Host "  Already 'Use Default Value' -- skipping." -ForegroundColor Yellow
        $summary += [pscustomobject]@{ Location = $sub.Desc; Before = 0; Action = "Skipped (already default)" }
        continue
    }

    Write-Host "  Current mfg values : $($mfgEntries.Count) (static 'Enter value' list)"

    # Keep every parameter EXCEPT mfg -- omitting it entirely is what
    # makes SSRS fall back to "Use Default Value" for that parameter.
    $newValues = @($values | Where-Object { $_.Name -ne 'mfg' })

    if ($Apply) {
        $rs.SetSubscriptionProperties(
            $sub.Id, $extSettings, $desc, $eventType, $matchData, $newValues
        ) | Out-Null
        Write-Host "  APPLIED -- switched to Use Default Value." -ForegroundColor Green
        $summary += [pscustomobject]@{ Location = $sub.Desc; Before = $mfgEntries.Count; Action = "Applied" }
    } else {
        Write-Host "  Dry run only -- re-run with -Apply to commit this change." -ForegroundColor Yellow
        $summary += [pscustomobject]@{ Location = $sub.Desc; Before = $mfgEntries.Count; Action = "Dry run (would apply)" }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$summary | Format-Table -AutoSize

Write-Host ""
if ($Apply) {
    Write-Host "Done. Changes committed." -ForegroundColor Green
} else {
    Write-Host "Dry run complete. Re-run with -Apply to commit." -ForegroundColor Yellow
}

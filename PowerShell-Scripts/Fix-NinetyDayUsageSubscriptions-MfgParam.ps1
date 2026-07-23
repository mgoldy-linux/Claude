# Fix-NinetyDayUsageSubscriptions-MfgParam.ps1
# Repairs the "mfg" (manufacturer) multi-value parameter on the 90 Day Usage Report
# subscriptions that were found with a collapsed/near-empty manufacturer list,
# which produces a legitimately blank report every run (not intermittent).
#
# Affected subscriptions (SA-50249 investigation, 2026-07-23):
#   162 - 90 Day Usage Report   (MfgCount was 1)
#   241 - 90 Day Usage Report   (MfgCount was 0)
#   261 - 90 Day Usage          (MfgCount was 1)
#   400 - 90 Day Usage Report   (MfgCount was 1)
#
# Uses the ReportingService2010 SOAP API (the supported way to edit subscriptions),
# not direct writes to the ReportServer catalog tables.
#
# Default is a dry run -- pass -Apply to actually commit the change.
#
# Requirements: Windows auth to reports.allsurfaces.com; read access to
# ASDWDB01.ahi.local\P21 (same source the report's Manufacturers dataset uses).
#
# NOTE: New-WebServiceProxy against SSRS's ReportService2010.asmx WSDL only
# builds a working client under Windows PowerShell 5.1 (powershell.exe) --
# under PowerShell 7 (pwsh) it silently returns a hollow object with none of
# the WSDL-defined methods. Run this script with:
#   powershell.exe -NoProfile -File Fix-NinetyDayUsageSubscriptions-MfgParam.ps1
# Uses plain ADO.NET (no dbatools/SqlServer module dependency) since 5.1 may
# not have the same modules installed as the pwsh 7 profile.

[CmdletBinding()]
param(
    [string]$ReportServerUri = "https://reports.allsurfaces.com/ReportServer",
    [string]$SqlInstance     = "ASDWDB01.ahi.local",
    [string]$Database        = "P21",
    [string[]]$SubscriptionIds = @(
        '9eb84393-e8ec-4187-b34f-0276bea6e1a2'  # 162 - 90 Day Usage Report
        '028098ab-75eb-475c-879b-c5d230163471'  # 241 - 90 Day Usage Report
        '73499735-e806-44f4-a718-7acb34a63e9e'  # 261 - 90 Day Usage
        'efe22f47-e5dc-44f0-b999-6b2af0a2c551'  # 400 - 90 Day Usage Report
    ),
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Get the CURRENT full manufacturer list -- same source query as the
# report's "Manufacturers" shared dataset (/Datasets/Manufacturers), so the
# fixed subscriptions match what a fresh "select all" would produce today.
# Plain ADO.NET -- no module dependency, since this must run under
# Windows PowerShell 5.1 (see NOTE above), which may not have the same
# modules installed as the pwsh 7 profile.
# ---------------------------------------------------------------------------
Write-Host "Pulling current manufacturer list from $SqlInstance \ $Database ..."

$mfgQuery = @'
SELECT class_id AS mfg_id
FROM p21_view_class
WHERE class_type = 'IV' AND class_number = 1 AND delete_flag = 'N'
ORDER BY class_description ASC
'@

$connStr = "Server=$SqlInstance;Database=$Database;Integrated Security=True;TrustServerCertificate=True"
$currentMfgIds = New-Object System.Collections.Generic.List[string]
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
try {
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand $mfgQuery, $conn
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) { $currentMfgIds.Add([string]$reader['mfg_id']) }
    $reader.Close()
} finally {
    $conn.Close()
}
Write-Host "  -> $($currentMfgIds.Count) manufacturers currently active"

if ($currentMfgIds.Count -eq 0) {
    throw "Manufacturer list came back empty -- aborting, this would make things worse, not better."
}

# ---------------------------------------------------------------------------
# Connect to the SSRS SOAP API
# ---------------------------------------------------------------------------
Write-Host "Connecting to $ReportServerUri/ReportService2010.asmx ..."
$rs = New-WebServiceProxy -Uri "$ReportServerUri/ReportService2010.asmx?wsdl" -UseDefaultCredential

# The ParameterValue type lives in the dynamically-generated proxy namespace
$paramValueType = ($rs.GetType().Namespace) + '.ParameterValue'

# ---------------------------------------------------------------------------
# Fix each subscription
# ---------------------------------------------------------------------------
foreach ($subId in $SubscriptionIds) {

    Write-Host ""
    Write-Host "=== Subscription $subId ===" -ForegroundColor Cyan

    $extSettings = $null
    $desc        = $null
    $active      = $null
    $status      = $null
    $eventType   = $null
    $matchData   = $null
    $values      = $null

    $rs.GetSubscriptionProperties(
        $subId,
        [ref]$extSettings, [ref]$desc, [ref]$active,
        [ref]$status, [ref]$eventType, [ref]$matchData, [ref]$values
    ) | Out-Null

    Write-Host "  Description : $desc"

    $before = @($values | Where-Object { $_.Name -eq 'mfg' })
    Write-Host "  Current mfg values : $($before.Count)"

    if ($before.Count -eq $currentMfgIds.Count) {
        Write-Host "  Already has the full manufacturer list -- skipping." -ForegroundColor Yellow
        continue
    }

    # Keep every parameter EXCEPT the broken mfg entries
    $keptValues = @($values | Where-Object { $_.Name -ne 'mfg' })

    # Rebuild mfg with the current full list
    $newMfgValues = foreach ($id in $currentMfgIds) {
        $pv = New-Object $paramValueType
        $pv.Name  = 'mfg'
        $pv.Value = $id
        $pv
    }

    $newValues = @($keptValues) + @($newMfgValues)

    Write-Host "  New mfg values      : $($newMfgValues.Count)"

    if ($Apply) {
        $rs.SetSubscriptionProperties(
            $subId, $extSettings, $desc, $eventType, $matchData, $newValues
        ) | Out-Null
        Write-Host "  APPLIED." -ForegroundColor Green
    } else {
        Write-Host "  Dry run only -- re-run with -Apply to commit this change." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green

#region Header
<#
Post-refresh parity check for the BusinessRules (BRR) environment against Prod.

Three independent checks, since they have different ground truth:

1. business_rule table (BRR vs Prod). A BRR refresh is a full DB RESTORE from Prod, so
   immediately after the restore this table is byte-identical to Prod by construction --
   any diff you see is either (a) something you manually re-registered post-restore
   (e.g. the SA-53475 Order Ack pair) or (b) something left over that shouldn't be there.
   Run this AFTER you've finished re-registering whatever BRR-only rules you intend to
   keep, not immediately after the restore.

2. Portals share (\\ASP21FS1\BusinessRules\Portals vs \\ASP21FS1\Prod\Portals). NOT touched
   by the SQL restore at all -- these are files on disk. Per 2026-09-11 direction: every
   Prod portal should exist in BRR too, byte-for-byte. No "in development" exceptions
   expected here -- any diff is worth investigating.

3. CrystalReports share (\\asp21fs1.ahi.local\BusinessRules\CrystalReports vs \...\Prod\...).
   Same reasoning and same expectation (zero diff) as portals.

Rule-level exceptions (business_rule only) are business calls, not something this script
can infer -- it just surfaces BRR-only / Prod-only / mismatched rule_name rows so you can
eyeball them against what you know is intentionally under development.

Server/DB names per reference_p21_sql_servers memory:
    BusinessRules -> P21Dev.allsurfaces.com / P21BusinessRules
    Prod          -> P21.allsurfaces.com    / P21
Do NOT append a port to either -- that's the middleware port, not SQL.

NOTE: raw SQL Server (TDS) connections from inside Claude Code's tool sandbox are known to
fail mid-handshake (see feedback_claude_code_sandbox_blocks_sql_tds memory). Run this script
yourself in your own PowerShell/SSMS session, or via the `!`-prefixed passthrough in the
Claude Code prompt -- not by asking Claude to run it through the Bash/PowerShell tool.
#>
[CmdletBinding()]
param(
    [switch]$SkipBusinessRules,
    [switch]$SkipPortals,
    [switch]$SkipReports
)

if (-not $PC_Name) { $PC_Name = $env:COMPUTERNAME }
if (-not $fDate)   { $fDate   = (Get-Date).ToString('-yyyyMMdd') }
$Path  = "C:\_P25\Logs\Record-of-" + $PC_Name + "-VC-Scripts-Ran-" + (Get-Date).ToString("yyyyMM") + ".txt"
(Get-Date -Format 'yyyy-MM-dd').ToString() + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $Path -Append
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
$ofrec = "C:\_P25\Logs\PS-Rec-Of\" + $MyInvocation.MyCommand.Name + $fDate + ".txt"

Clear-Host
$MyInvocation.MyCommand.Name
Import-Module dbatools -ErrorAction Stop
"Start Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
#endregion Header

#region Config
$BrrSqlInstance  = 'P21Dev.allsurfaces.com'
$BrrSqlDb        = 'P21BusinessRules'
$ProdSqlInstance = 'P21.allsurfaces.com'
$ProdSqlDb       = 'P21'

$BrrPortals   = '\\ASP21FS1.ahi.local\BusinessRules\Portals'
$ProdPortals  = '\\ASP21FS1.ahi.local\Prod\Portals'
$BrrReports   = '\\ASP21FS1.ahi.local\BusinessRules\CrystalReports'
$ProdReports  = '\\ASP21FS1.ahi.local\Prod\CrystalReports'

$total_errors = 0
$ofcsvPrefix = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name.Replace('.ps1','') + $fDate
#endregion Config

#region 1. business_rule parity
if (-not $SkipBusinessRules) {
    "`n===== business_rule: BRR vs Prod =====" | Tee-Object -FilePath $ofrec -Append

    $q = @"
SELECT   rule_name,
         COUNT(*)                                                    AS binding_rows,
         SUM(CASE WHEN row_status_flag = 704 THEN 1 ELSE 0 END)      AS active_rows,
         SUM(CASE WHEN row_status_flag = 705 THEN 1 ELSE 0 END)      AS inactive_rows,
         MAX(rule_type_cd)                                           AS rule_type_cd
FROM     business_rule
GROUP BY rule_name
"@

    try {
        $brrRules  = Invoke-DbaQuery -SqlInstance $BrrSqlInstance  -Database $BrrSqlDb  -Query $q -As PSObject
        $prodRules = Invoke-DbaQuery -SqlInstance $ProdSqlInstance -Database $ProdSqlDb -Query $q -As PSObject
    } catch {
        "ERROR querying business_rule: " + $_.Exception.Message | Tee-Object -FilePath $ofrec -Append
        $total_errors++
        $brrRules  = @()
        $prodRules = @()
    }

    $brrByName  = @{}
    foreach ($r in $brrRules)  { $brrByName[$r.rule_name]  = $r }
    $prodByName = @{}
    foreach ($r in $prodRules) { $prodByName[$r.rule_name] = $r }

    $allNames = @($brrByName.Keys) + @($prodByName.Keys) | Select-Object -Unique | Sort-Object

    $ruleDiff = foreach ($name in $allNames) {
        $b = $brrByName[$name]
        $p = $prodByName[$name]

        $status =
            if ($b -and -not $p)  { 'BRR-only (confirm this is intentionally under development)' }
            elseif ($p -and -not $b) { 'PROD-only (unexpected -- BRR should have this after a restore)' }
            elseif ($b.binding_rows -ne $p.binding_rows -or $b.active_rows -ne $p.active_rows -or
                    $b.inactive_rows -ne $p.inactive_rows -or $b.rule_type_cd -ne $p.rule_type_cd) { 'MISMATCH' }
            else { 'match' }

        if ($status -ne 'match') {
            [PSCustomObject]@{
                rule_name        = $name
                Status           = $status
                BRR_binding_rows = if ($b) { $b.binding_rows } else { $null }
                BRR_active       = if ($b) { $b.active_rows }  else { $null }
                BRR_inactive     = if ($b) { $b.inactive_rows } else { $null }
                Prod_binding_rows= if ($p) { $p.binding_rows } else { $null }
                Prod_active      = if ($p) { $p.active_rows }  else { $null }
                Prod_inactive    = if ($p) { $p.inactive_rows } else { $null }
            }
        }
    }

    $ruleDiff = $ruleDiff | Sort-Object Status, rule_name
    $ruleDiff | Format-Table -AutoSize -Wrap
    "Rule-name differences found: " + (@($ruleDiff)).Count | Tee-Object -FilePath $ofrec -Append

    $ofcsv = $ofcsvPrefix + '-BusinessRules.csv'
    $ruleDiff | Export-Csv -Path $ofcsv -NoTypeInformation
    "CSV written: " + $ofcsv | Out-File -FilePath $ofrec -Append
}
#endregion 1. business_rule parity

#region 2/3. File-share parity (Portals, CrystalReports)
function Compare-FileShare {
    param(
        [string]$Label,
        [string]$BrrPath,
        [string]$ProdPath,
        [string]$OutCsv
    )

    "`n===== $Label`: BRR vs Prod =====" | Tee-Object -FilePath $ofrec -Append

    if (-not (Test-Path $BrrPath))  { "ERROR: BRR path not reachable: $BrrPath"   | Tee-Object -FilePath $ofrec -Append; $script:total_errors++; return }
    if (-not (Test-Path $ProdPath)) { "ERROR: Prod path not reachable: $ProdPath" | Tee-Object -FilePath $ofrec -Append; $script:total_errors++; return }

    $brrFiles  = Get-ChildItem -Path $BrrPath  -File | ForEach-Object {
        [PSCustomObject]@{ Name = $_.Name; Hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash }
    }
    $prodFiles = Get-ChildItem -Path $ProdPath -File | ForEach-Object {
        [PSCustomObject]@{ Name = $_.Name; Hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash }
    }

    $brrByName  = @{}
    foreach ($f in $brrFiles)  { $brrByName[$f.Name]  = $f.Hash }
    $prodByName = @{}
    foreach ($f in $prodFiles) { $prodByName[$f.Name] = $f.Hash }

    $allNames = @($brrByName.Keys) + @($prodByName.Keys) | Select-Object -Unique | Sort-Object

    $diff = foreach ($name in $allNames) {
        $bHash = $brrByName[$name]
        $pHash = $prodByName[$name]

        $status =
            if ($bHash -and -not $pHash) { 'BRR-only' }
            elseif ($pHash -and -not $bHash) { 'PROD-only (missing from BRR)' }
            elseif ($bHash -ne $pHash) { 'DIFFERENT CONTENT' }
            else { 'match' }

        if ($status -ne 'match') {
            [PSCustomObject]@{ FileName = $name; Status = $status }
        }
    }

    $diff = $diff | Sort-Object Status, FileName
    $diff | Format-Table -AutoSize -Wrap
    "$Label differences found: " + (@($diff)).Count | Tee-Object -FilePath $ofrec -Append

    $diff | Export-Csv -Path $OutCsv -NoTypeInformation
    "CSV written: " + $OutCsv | Out-File -FilePath $ofrec -Append
}

if (-not $SkipPortals) {
    Compare-FileShare -Label 'Portals' -BrrPath $BrrPortals -ProdPath $ProdPortals -OutCsv ($ofcsvPrefix + '-Portals.csv')
}
if (-not $SkipReports) {
    Compare-FileShare -Label 'CrystalReports' -BrrPath $BrrReports -ProdPath $ProdReports -OutCsv ($ofcsvPrefix + '-Reports.csv')
}
#endregion 2/3. File-share parity

#region Footer
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec
#endregion Footer

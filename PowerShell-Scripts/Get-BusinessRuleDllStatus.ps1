#region Header
<#
Audits the P21 "BusinessRules" environment's live BusinessRulesDLL share against the
business_rule table and classifies every custom DLL as Active / Inactive-only (archive
candidate) / Protected (inactive-only but tied to other active work) / Unresolved.

Ground truth problem: business_rule has NO column linking rule_name to a DLL filename
(confirmed 2026-08-07 -- searched every table for %assembly%/%dll%/%type_name% columns;
the only hit, business_rule_log.rule_assembly_name, is only populated when a rule actually
fires, which never happens for Inactive rows). So this script reflects each live DLL's
compiled string table and checks which exact rule_name values are embedded as literals --
real evidence, not filename guessing. Most P21 rule classes embed their own registered
name as a string literal (e.g. a RuleName property), so this catches most cases, but not
all -- a file with ZERO rule_name matches is UNRESOLVED, not confirmed safe. Never treat
"no match" as "safe to archive."

Default run is report-only. Pass -MoveInactive to actually move confirmed-safe files to
_Archive (never deletes -- same convention as Archive-BusinessRulesDLL-Duplicates.ps1).
Files matching a PROTECTED rule-name family are never auto-moved even with -MoveInactive.

-Instance selects which environment's business_rule table and DLL share to audit. Each
environment is a SEPARATE database with its own active/inactive state -- confirmed 2026-08-07
that Prod still has rows (kb_Order_RequiredDate_r3, kb_Order_Validator_v2) ACTIVE that are
purely legacy predecessors of in-progress SA-46321/kb_Order_Validator_v2 work elsewhere, so
NEVER assume another environment's classification carries over. Only BusinessRules and Prod
SQL DB names are confirmed as of this writing; verify Dev/Play/Training/Upgrade's actual
database name before trusting this script against them.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('BusinessRules','Prod')]
    [string]$Instance = 'BusinessRules',
    [switch]$MoveInactive
)

if (-not $PC_Name) { $PC_Name = $env:COMPUTERNAME }
if (-not $fDate)   { $fDate   = (Get-Date).ToString('-yyyyMMdd') }
$Path  = "C:\_P25\Logs\Record-of-" + $PC_Name + "-VC-Scripts-Ran-" + (Get-Date).ToString("yyyyMM") + ".txt"
(Get-Date -Format 'yyyy-MM-dd').ToString() + " " + $MyInvocation.MyCommand.Name + " -MoveInactive:$MoveInactive" | Out-File -FilePath $Path -Append
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
$ofrec = "C:\_P25\Logs\PS-Rec-Of\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + ".txt"

Clear-Host
$MyInvocation.MyCommand.Name + " -Instance $Instance -MoveInactive:$MoveInactive"
Import-Module dbatools -ErrorAction Stop
"Start Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
#endregion Header

#region Config
switch ($Instance) {
    'BusinessRules' { $SqlInstance = 'P21Dev.allsurfaces.com'; $SqlDb = 'P21BusinessRules' }
    'Prod'          { $SqlInstance = 'P21.allsurfaces.com';    $SqlDb = 'P21' }
}
$dllShare    = "\\ASP21FS1.ahi.local\$Instance\BusinessRulesDLL"
$archivePath = Join-Path $dllShare '_Archive'

# Third-party/framework/vendor dependency DLLs -- never P21 business-rule assemblies,
# reflecting them for rule_name strings is pointless noise.
$exclude = @(
    'Activant.P21.Extensions.Examples.dll','Atlas.CrownLogging.dll','Atlas.CrownRuleHandler.dll',
    'Atlas.CrownSurcharge5011348.dll','BusinessRulesExample.dll','Dapper.dll','EPFBusinessRules.dll',
    'ElectronicPaymentsFramework.dll','GongSolutions.Wpf.DragDrop.dll','P21.Extensions.Examples.dll',
    'P21.Rules.dll','log4net.dll'
)

# Rule-name prefixes that are inactive-only by evidence but must NOT be auto-archived --
# still tied to other active, in-progress work. Remove an entry once that work closes out.
$protectedPrefixes = @(
    'kb_Order_RequiredDate'  # active SA-46321 build in progress -- see project_2026_07_31_sa46321_po_required_date
    'kb_Order_Validator'     # active kb_Order_Validator_v2 project -- see project_2026_06_23_kb_order_validator_v2
)
#endregion Config

#region Pull rule_name status from business_rule
$q = @"
SELECT rule_name,
       MAX(CASE WHEN row_status_flag = 704 THEN 1 ELSE 0 END) AS has_active,
       MAX(CASE WHEN row_status_flag = 705 THEN 1 ELSE 0 END) AS has_inactive
FROM $SqlDb.dbo.business_rule
GROUP BY rule_name
"@
$ruleStatus = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $SqlDb -Query $q -As PSObject
"Rule names pulled from ${SqlDb}: " + $ruleStatus.Count | Out-File -FilePath $ofrec -Append
#endregion Pull rule_name status from business_rule

#region Reflect every live DLL and classify
$files = Get-ChildItem -Path $dllShare -Filter *.dll -File | Where-Object { $exclude -notcontains $_.Name }

$results = foreach ($f in $files) {
    $bytes   = [System.IO.File]::ReadAllBytes($f.FullName)
    # Two passes: UTF-16 catches string LITERALS (e.g. GetName()/GetDescription() return values,
    # embedded via ldstr in the #US heap); ASCII/UTF-8 catches TYPE/NAMESPACE names (compiled into
    # the #Strings metadata heap as UTF-8, not UTF-16). Confirmed 2026-08-07 via rewardFormat.cs --
    # its namespace "rewardFormat" exactly matches the DB rule_name but was invisible to a
    # Unicode-only scan. Scanning only one encoding under-classifies real matches as UNRESOLVED.
    $textUnicode = [System.Text.Encoding]::Unicode.GetString($bytes)
    $textAscii   = [System.Text.Encoding]::ASCII.GetString($bytes)
    # Case-insensitive: confirmed 2026-08-07 the RMAFundTracker.dll namespace ("RMAFundTracker")
    # matches DB rule_name "Rmafundtrack" in everything but case.
    $matched = $ruleStatus | Where-Object {
        $textUnicode.IndexOf($_.rule_name, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $textAscii.IndexOf($_.rule_name, [StringComparison]::OrdinalIgnoreCase) -ge 0
    }

    $isProtected = ($matched | Where-Object { $r = $_.rule_name; $protectedPrefixes | Where-Object { $r -like "$_*" } }) | Measure-Object
    $anyActive   = ($matched | Where-Object has_active -eq 1) | Measure-Object
    $anyInactive = ($matched | Where-Object has_inactive -eq 1) | Measure-Object

    $classification =
        if ($matched.Count -eq 0)        { 'UNRESOLVED - no rule_name match, needs manual review' }
        elseif ($anyActive.Count -gt 0)  { 'ACTIVE - keep' }
        elseif ($isProtected.Count -gt 0) { 'PROTECTED - inactive-only but tied to other active work' }
        elseif ($anyInactive.Count -gt 0) { 'INACTIVE-ONLY - safe to archive' }
        else                              { 'UNRESOLVED - no rule_name match, needs manual review' }

    [PSCustomObject]@{
        File           = $f.Name
        MatchedRules   = ($matched.rule_name -join '; ')
        Classification = $classification
    }
}

$results = $results | Sort-Object Classification, File
$results | Format-Table -AutoSize -Wrap

$ofcsv = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + ".csv"
$results | Export-Csv -Path $ofcsv -NoTypeInformation
"CSV written: " + $ofcsv | Out-File -FilePath $ofrec -Append
"Classification counts:" | Out-File -FilePath $ofrec -Append
$results | Group-Object Classification | ForEach-Object { "  $($_.Count)  $($_.Name)" | Out-File -FilePath $ofrec -Append }
#endregion Reflect every live DLL and classify

#region Optional move
$toArchive = $results | Where-Object Classification -eq 'INACTIVE-ONLY - safe to archive'
$total_errors = 0
$i = 0

if (-not $MoveInactive) {
    "`n$($toArchive.Count) file(s) classified INACTIVE-ONLY - safe to archive. Re-run with -MoveInactive to move them to _Archive."
} else {
    if (-not (Test-Path $archivePath)) { New-Item -ItemType Directory -Path $archivePath | Out-Null }
    foreach ($row in $toArchive) {
        $source = Join-Path $dllShare $row.File
        if ($PSCmdlet.ShouldProcess($source, "Move to _Archive")) {
            try {
                Move-Item -Path $source -Destination $archivePath -ErrorAction Stop
                "Archived: " + $row.File | Out-File -FilePath $ofrec -Append
                $i++
            } catch {
                "Error archiving $($row.File): " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
                $total_errors++
            }
        }
    }
    "Files archived: " + $i + " of " + $toArchive.Count | Out-File -FilePath $ofrec -Append
}
#endregion Optional move

#region Footer
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $Path
#endregion Footer

#region Header
<#
Companion to Get-BusinessRuleDllStatus.ps1. That script approximates rule<->DLL evidence by
searching each DLL's raw bytes (UTF-16 + ASCII) for business_rule.rule_name substrings --
a reasonable proxy, but a proxy. This script gets the real thing: it reflects each DLL the
same way P21.Extensions.BusinessRule.RuleWorker.LoadRules does on the actual P21 app server
(confirmed via decompile, C:\Claude\Docs\P21-Extensions-BusinessRule-SDK-Analysis.md) --
load the assembly, find every public non-abstract class where
typeof(P21.Extensions.BusinessRule.Rule).IsAssignableFrom(type), instantiate it, and call
its own GetName()/GetDescription(). No P21 database connection is needed for this part --
LoadRules never touches SQL, only ExecuteRule does, and this script never calls Execute().

This gives two things byte-scanning cannot guarantee:
 1. The COMPLETE list of every rule class a DLL contains, in one deterministic pass -- this
    alone would have caught the kb_Shipping_IBFSurcharge.dll / kb_RMA_IBFSurcharge_Add
    near-miss (2026-08-07, see feedback_p21_rule_name_no_dll_link) automatically, instead of
    by accident on a second environment's scan.
 2. The literal GetName()/GetDescription() return values -- exact evidence, not a substring
    that happened to appear somewhere in the compiled bytes.

Limitation carried over regardless of method: business_rule.rule_name is a free-text label a
person typed once at import time and can legitimately drift from GetName()'s return value
(proven case: RebatePriceTracker.cs's real class GetName() and the DB's rule_name are three
different spellings of the same rule). Exact-match here will correctly flag that case
UNRESOLVED rather than guess -- the win is that you're now pattern-matching against a clean,
complete, deduplicated list of real declared names instead of noisy byte-search hits.

REQUIRES WINDOWS POWERSHELL 5.1 (powershell.exe), NOT pwsh 7 -- these are classic .NET
Framework assemblies (System.Web.Mvc, System.Configuration references seen in the SDK
decompile) and old-Framework binary loading is unreliable under .NET Core/5+, same lesson as
New-WebServiceProxy (see feedback_new_webserviceproxy_pwsh7). Script hard-stops under Core.

Requires a local copy of the real P21.Extensions.dll to resolve the Rule base type against --
NOT present on the BusinessRulesDLL share itself (only the vendor "Examples" stub is there).
Confirmed 2026-08-10 at C:\Business_Rules\P21.Extensions.dll on this machine; override via
-P21ExtensionsPath if running elsewhere.

Some DLLs may legitimately fail to reflect here (e.g. a rule referencing System.Web.Mvc or
another assembly not present/GAC-registered on this machine) -- these are reported as
LOAD-ERROR, not silently dropped, and should fall back to the byte-scan script's evidence.

Every DLL is loaded via Assembly.Load(bytes), NOT Assembly.LoadFrom(path) -- confirmed
2026-08-10 that LoadFrom against the \\ASP21FS1.ahi.local UNC share throws
COR_E_LOADFROMREMOTESOURCES (0x80131515, 100% failure rate on first real run): .NET
Framework tags anything loaded from a network path as "remote" and blocks it from running by
default. Loading the bytes into memory has no originating URI, so it never gets that zone
tag. Same family of issue as the Atlas surcharge DLL CAS error noted in
project_2026_06_23_kb_order_validator_v2.

Always report-only -- unlike its sibling, this script has NO -MoveInactive. Its job is to be
the higher-confidence oracle you cross-check the byte-scan script's classification against,
not a second independent way to move production files. If both scripts agree a file is
INACTIVE-ONLY, that's strong evidence; if they disagree, that disagreement is the signal to
open Edit Business Rule and check by hand -- don't auto-resolve disagreements either script.
#>
[CmdletBinding()]
param(
    [ValidateSet('BusinessRules','Prod')]
    [string]$Instance = 'BusinessRules',
    [string]$P21ExtensionsPath = 'C:\Business_Rules\P21.Extensions.dll'
)

if ($PSVersionTable.PSEdition -eq 'Core') {
    Write-Error "This script must run under Windows PowerShell 5.1 (powershell.exe), not PowerShell 7/Core -- the rule DLLs are classic .NET Framework assemblies that don't reliably load under .NET Core/5+. Re-run with: powershell.exe -File `"$($MyInvocation.MyCommand.Path)`" -Instance $Instance"
    exit 1
}
if (-not (Test-Path $P21ExtensionsPath)) {
    Write-Error "P21.Extensions.dll not found at $P21ExtensionsPath -- pass -P21ExtensionsPath pointing at a real copy. The Rule base type can't be resolved without it."
    exit 1
}

if (-not $PC_Name) { $PC_Name = $env:COMPUTERNAME }
if (-not $fDate)   { $fDate   = (Get-Date).ToString('-yyyyMMdd') }
$Path  = "C:\_P25\Logs\Record-of-" + $PC_Name + "-VC-Scripts-Ran-" + (Get-Date).ToString("yyyyMM") + ".txt"
(Get-Date -Format 'yyyy-MM-dd').ToString() + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $Path -Append
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
$ofrec = "C:\_P25\Logs\PS-Rec-Of\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + ".txt"

Clear-Host
$MyInvocation.MyCommand.Name + " -Instance $Instance -P21ExtensionsPath $P21ExtensionsPath"
Import-Module dbatools -ErrorAction Stop
$total_errors = 0
"Start Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
#endregion Header

#region Config
switch ($Instance) {
    'BusinessRules' { $SqlInstance = 'P21Dev.allsurfaces.com'; $SqlDb = 'P21BusinessRules' }
    'Prod'          { $SqlInstance = 'P21.allsurfaces.com';    $SqlDb = 'P21' }
}
$dllShare = "\\ASP21FS1.ahi.local\$Instance\BusinessRulesDLL"

# Same exclusion list as Get-BusinessRuleDllStatus.ps1 -- kept in sync manually. Vendor/
# framework/example DLLs, never P21 custom business-rule assemblies.
$exclude = @(
    'Activant.P21.Extensions.Examples.dll','Atlas.CrownLogging.dll','Atlas.CrownRuleHandler.dll',
    'Atlas.CrownSurcharge5011348.dll','BusinessRulesExample.dll','Dapper.dll','EPFBusinessRules.dll',
    'ElectronicPaymentsFramework.dll','GongSolutions.Wpf.DragDrop.dll','P21.Extensions.Examples.dll',
    'P21.Rules.dll','log4net.dll'
)

# Same protected list as Get-BusinessRuleDllStatus.ps1 -- labeling only here (this script
# never moves files), kept for classification parity between the two reports.
$protectedPrefixes = @(
    'kb_Order_RequiredDate'  # active SA-46321 build in progress -- see project_2026_07_31_sa46321_po_required_date
    'kb_Order_Validator'     # active kb_Order_Validator_v2 project -- see project_2026_06_23_kb_order_validator_v2
)
#endregion Config

#region Load P21.Extensions.dll and set up dependency resolution
# Assembly.Load(byte[]) rather than LoadFrom(path): LoadFrom against a UNC path throws
# COR_E_LOADFROMREMOTESOURCES (0x80131515) -- .NET Framework tags anything loaded from a
# network path as "remote" and blocks it from running by default (confirmed 2026-08-10,
# same family of issue as the Atlas surcharge DLL CAS error noted in
# project_2026_06_23_kb_order_validator_v2). Loading into memory from bytes has no
# originating URI at all, so it never gets that zone tag. Used for every DLL below,
# including this local one, for consistency in case -P21ExtensionsPath is ever a UNC path.
$p21ExtAsm     = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($P21ExtensionsPath))
$ruleBaseType  = $p21ExtAsm.GetType('P21.Extensions.BusinessRule.Rule')
$privateAttrType = $p21ExtAsm.GetType('P21.Extensions.BusinessRule.PrivateRule')
if (-not $ruleBaseType) {
    Write-Error "Could not resolve P21.Extensions.BusinessRule.Rule from $P21ExtensionsPath -- wrong DLL or wrong version?"
    exit 1
}
"P21.Extensions.dll loaded: " + $p21ExtAsm.FullName | Out-File -FilePath $ofrec -Append

# Mirrors RuleWorker.domain_AssemblyResolve: probe the folder the DLL being scanned came
# from, then the folder holding P21.Extensions.dll, for any dependency the CLR can't
# resolve on its own (GAC/framework assemblies resolve normally without this).
$script:currentScanFolder = $dllShare
$p21ExtFolder = Split-Path $P21ExtensionsPath -Parent
$resolveHandler = [System.ResolveEventHandler] {
    param($resolveSender, $resolveArgs)
    $asmSimpleName = ($resolveArgs.Name -split ',')[0]
    foreach ($folder in @($script:currentScanFolder, $p21ExtFolder)) {
        $candidate = Join-Path $folder "$asmSimpleName.dll"
        if (Test-Path $candidate) {
            try { return [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($candidate)) } catch { }
        }
    }
    return $null
}
[System.AppDomain]::CurrentDomain.add_AssemblyResolve($resolveHandler)
#endregion Load P21.Extensions.dll and set up dependency resolution

#region Pull rule_name status from business_rule
$q = @"
SELECT rule_name,
       MAX(CASE WHEN row_status_flag = 704 THEN 1 ELSE 0 END) AS has_active,
       MAX(CASE WHEN row_status_flag = 705 THEN 1 ELSE 0 END) AS has_inactive
FROM $SqlDb.dbo.business_rule
GROUP BY rule_name
"@
$ruleStatus = @(Invoke-DbaQuery -SqlInstance $SqlInstance -Database $SqlDb -Query $q -As PSObject)
"Rule names pulled from ${SqlDb}: " + $ruleStatus.Count | Out-File -FilePath $ofrec -Append
#endregion Pull rule_name status from business_rule

#region Reflect every live DLL
$files = @(Get-ChildItem -Path $dllShare -Filter *.dll -File | Where-Object { $exclude -notcontains $_.Name })
"DLLs to scan: " + $files.Count | Out-File -FilePath $ofrec -Append

$classDetail = @()
$loadErrors  = @()
$i = 0

foreach ($f in $files) {
    $i++
    $script:currentScanFolder = $f.DirectoryName
    $asm = $null
    try {
        $asm = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($f.FullName))
    } catch {
        $loadErrors += [PSCustomObject]@{ File = $f.Name; Stage = 'Load'; Error = $_.Exception.Message }
        "LOAD-ERROR (Load) $($f.Name): " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
        $total_errors++
        continue
    }

    $types = $null
    try {
        $types = $asm.GetTypes()
    } catch [System.Reflection.ReflectionTypeLoadException] {
        # Partial load is common (missing optional dependency) -- keep whichever types did
        # resolve rather than discarding the whole assembly, same tolerance RuleWorker itself
        # applies (it logs LoaderExceptions but still proceeds type-by-type where it can).
        $types = @($_.Exception.Types | Where-Object { $_ })
        $loadErrors += [PSCustomObject]@{ File = $f.Name; Stage = 'GetTypes (partial)'; Error = ($_.Exception.LoaderExceptions | Select-Object -First 1 -ExpandProperty Message) }
    } catch {
        $loadErrors += [PSCustomObject]@{ File = $f.Name; Stage = 'GetTypes'; Error = $_.Exception.Message }
        "LOAD-ERROR (GetTypes) $($f.Name): " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
        $total_errors++
        continue
    }

    $ruleTypes = @($types | Where-Object {
        $_.IsClass -and $_.IsPublic -and -not $_.IsAbstract -and $ruleBaseType.IsAssignableFrom($_)
    })

    foreach ($t in $ruleTypes) {
        try {
            # NOT $instance -- collides case-insensitively with the script's own -Instance
            # parameter (ValidateSet'd to 'BusinessRules'/'Prod'); assigning a Rule object to
            # it throws a validation error. Confirmed 2026-08-10 (100% instantiate-failure
            # first run, traced to "not a valid value for the Instance variable").
            $ruleInstance = [System.Activator]::CreateInstance($t)
            $declaredName = $t.GetMethod('GetName').Invoke($ruleInstance, $null)
            $declaredDesc = $t.GetMethod('GetDescription').Invoke($ruleInstance, $null)
            $isPrivate = $false
            if ($privateAttrType) {
                $isPrivate = ($t.GetCustomAttributes($privateAttrType, $true).Length -gt 0)
            }

            # .Trim() both sides -- confirmed 2026-08-10 that GetName() can legitimately embed
            # trailing whitespace as part of the string literal (Order_Entry_Fund_LIVE_V4.dll's
            # GetName() returns "Reward Fund Amount - Prod V4 " with a trailing space). Trimming
            # only ever turns a false UNRESOLVED into a real match -- it can't create a false
            # positive, since it's applied identically to both sides.
            $declaredNameTrimmed = if ($declaredName) { $declaredName.Trim() } else { $declaredName }
            $dbMatch = $ruleStatus | Where-Object {
                [string]::Equals(([string]$_.rule_name).Trim(), $declaredNameTrimmed, [StringComparison]::OrdinalIgnoreCase)
            } | Select-Object -First 1

            $classDetail += [PSCustomObject]@{
                File             = $f.Name
                ClassFullName    = $t.FullName
                DeclaredRuleName = $declaredName
                DeclaredDesc     = $declaredDesc
                IsPrivateRule    = $isPrivate
                DbMatch          = [bool]$dbMatch
                MatchedRuleName  = if ($dbMatch) { $dbMatch.rule_name } else { $null }
                HasActive        = if ($dbMatch) { [bool]$dbMatch.has_active } else { $false }
                HasInactive      = if ($dbMatch) { [bool]$dbMatch.has_inactive } else { $false }
            }
        } catch {
            $loadErrors += [PSCustomObject]@{ File = $f.Name; Stage = "Instantiate $($t.FullName)"; Error = $_.Exception.Message }
            "LOAD-ERROR (Instantiate) $($f.Name) :: $($t.FullName): " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
            $total_errors++
        }
    }

    if (($i % 25) -eq 0) {
        "Progress: $i / $($files.Count) DLLs - " + $StopWatch.Elapsed.Minutes + "m " + $StopWatch.Elapsed.Seconds + "s"
    }
}
"Rule classes found: " + $classDetail.Count + " across " + (@($classDetail | Select-Object -ExpandProperty File -Unique)).Count + " DLLs" | Out-File -FilePath $ofrec -Append
"DLLs with load/instantiate errors: " + (@($loadErrors | Select-Object -ExpandProperty File -Unique)).Count | Out-File -FilePath $ofrec -Append
#endregion Reflect every live DLL

#region Roll up per-file classification (same shape as Get-BusinessRuleDllStatus.ps1 for diffing)
$filesWithClasses = @($classDetail | Select-Object -ExpandProperty File -Unique)
$fileRollup = foreach ($fileName in $filesWithClasses) {
    $rows = @($classDetail | Where-Object File -eq $fileName)
    $matchedRows = @($rows | Where-Object DbMatch)

    $isProtected = @($matchedRows | Where-Object { $r = $_.MatchedRuleName; $protectedPrefixes | Where-Object { $r -like "$_*" } })
    $anyActive   = @($matchedRows | Where-Object HasActive)
    $anyInactive = @($matchedRows | Where-Object HasInactive)

    $classification =
        if ($matchedRows.Count -eq 0)     { 'UNRESOLVED - no exact GetName() match, needs manual review' }
        elseif ($anyActive.Count -gt 0)   { 'ACTIVE - keep' }
        elseif ($isProtected.Count -gt 0) { 'PROTECTED - inactive-only but tied to other active work' }
        elseif ($anyInactive.Count -gt 0) { 'INACTIVE-ONLY - archive candidate (cross-check byte-scan script)' }
        else                               { 'UNRESOLVED - no exact GetName() match, needs manual review' }

    [PSCustomObject]@{
        File            = $fileName
        RuleClassCount  = $rows.Count
        DeclaredNames   = ($rows.DeclaredRuleName -join '; ')
        MatchedRules    = ($matchedRows.MatchedRuleName -join '; ')
        Classification  = $classification
    }
}
$fileRollup += foreach ($fileName in (@($loadErrors | Select-Object -ExpandProperty File -Unique) | Where-Object { $filesWithClasses -notcontains $_ })) {
    [PSCustomObject]@{
        File            = $fileName
        RuleClassCount  = 0
        DeclaredNames   = $null
        MatchedRules    = $null
        Classification  = 'LOAD-ERROR - could not reflect, fall back to byte-scan script'
    }
}
$fileRollup = $fileRollup | Sort-Object Classification, File
$fileRollup | Format-Table -AutoSize -Wrap
#endregion Roll up per-file classification

#region Output - Write Results
$ofcsvDetail = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + "-ClassDetail.csv"
$ofcsvRollup = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + "-FileRollup.csv"
$ofcsvErrors = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + "-LoadErrors.csv"

$classDetail | Export-Csv -Path $ofcsvDetail -NoTypeInformation
$fileRollup  | Export-Csv -Path $ofcsvRollup -NoTypeInformation
$loadErrors  | Export-Csv -Path $ofcsvErrors -NoTypeInformation

"Class-detail CSV: " + $ofcsvDetail | Out-File -FilePath $ofrec -Append
"File-rollup CSV: " + $ofcsvRollup | Out-File -FilePath $ofrec -Append
"Load-errors CSV: " + $ofcsvErrors | Out-File -FilePath $ofrec -Append
"Classification counts:" | Out-File -FilePath $ofrec -Append
$fileRollup | Group-Object Classification | ForEach-Object { "  $($_.Count)  $($_.Name)" | Out-File -FilePath $ofrec -Append }
#endregion Output - Write Results

#region Footer
[System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveHandler)
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $Path
#endregion Footer

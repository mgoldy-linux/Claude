#region Header
<#
Point this at ONE specific .dll (anywhere -- local disk, a UNC share, an _Archive folder, a
file someone emailed you) and it reflects it exactly like Get-BusinessRuleDllStatus-Reflection.ps1
does for a whole folder, then reports every rule class it declares and whether business_rule
shows it Active/Inactive in each P21 environment. Built for the ad-hoc "before I touch this
file, is it live anywhere?" question -- the folder-wide audit scripts answer "what's the state
of this whole share," this answers "what's the state of THIS file."

Same ground-truth method as the folder audit (see C:\Claude\Docs\P21-Extensions-BusinessRule-SDK-Analysis.md
and Get-BusinessRuleDllStatus-Reflection.ps1's header for the full rationale/lessons):
Assembly.Load(bytes) [never LoadFrom -- UNC paths throw COR_E_LOADFROMREMOTESOURCES], find
every public non-abstract class where typeof(Rule).IsAssignableFrom(type), instantiate it,
call its own GetName()/GetDescription(), match (trimmed, case-insensitive) against
business_rule.rule_name. No DB write, no file move -- read-only in every sense.

Checks BusinessRules AND Prod by default (-Instance All) -- the whole point of an ad-hoc
single-file check is usually "is this safe to touch," and per feedback_p21_rule_name_no_dll_link,
one environment's classification must never be assumed to carry over to another. Narrow to
one with -Instance BusinessRules or -Instance Prod if that's genuinely all you need.

REQUIRES WINDOWS POWERSHELL 5.1 (powershell.exe), NOT pwsh 7 -- same reason as the folder
audit script: classic .NET Framework assemblies don't reliably load under Core.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DllPath,

    [ValidateSet('All','BusinessRules','Prod')]
    [string]$Instance = 'All',

    [string]$P21ExtensionsPath = 'C:\Business_Rules\P21.Extensions.dll'
)

if ($PSVersionTable.PSEdition -eq 'Core') {
    Write-Error "This script must run under Windows PowerShell 5.1 (powershell.exe), not PowerShell 7/Core -- classic .NET Framework assemblies don't reliably load under .NET Core/5+. Re-run with: powershell.exe -File `"$($MyInvocation.MyCommand.Path)`" -DllPath `"$DllPath`""
    exit 1
}
if (-not (Test-Path $DllPath)) {
    Write-Error "DLL not found at $DllPath"
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
$safeName  = [System.IO.Path]::GetFileNameWithoutExtension($DllPath) -replace '[\\/:*?"<>|]', '_'
$ofrec = "C:\_P25\Logs\PS-Rec-Of\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $safeName + ".txt"

Clear-Host
$MyInvocation.MyCommand.Name + " -DllPath `"$DllPath`" -Instance $Instance"
Import-Module dbatools -ErrorAction Stop
$total_errors = 0
"Start Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
"Target DLL: " + $DllPath | Out-File -FilePath $ofrec -Append
#endregion Header

#region Config
$instancesToCheck = if ($Instance -eq 'All') { @('BusinessRules','Prod') } else { @($Instance) }
$sqlConfig = @{
    'BusinessRules' = @{ SqlInstance = 'P21Dev.allsurfaces.com'; SqlDb = 'P21BusinessRules' }
    'Prod'          = @{ SqlInstance = 'P21.allsurfaces.com';    SqlDb = 'P21' }
}
$knownDllShares = @(
    '\\ASP21FS1.ahi.local\BusinessRules\BusinessRulesDLL',
    '\\ASP21FS1.ahi.local\Prod\BusinessRulesDLL'
)
#endregion Config

#region Load P21.Extensions.dll and set up dependency resolution
# Assembly.Load(bytes), not LoadFrom(path) -- LoadFrom against a UNC path throws
# COR_E_LOADFROMREMOTESOURCES (0x80131515). See Get-BusinessRuleDllStatus-Reflection.ps1's
# header for the full incident (2026-08-10, 100% failure rate until this fix).
$p21ExtAsm       = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($P21ExtensionsPath))
$ruleBaseType    = $p21ExtAsm.GetType('P21.Extensions.BusinessRule.Rule')
$privateAttrType = $p21ExtAsm.GetType('P21.Extensions.BusinessRule.PrivateRule')
if (-not $ruleBaseType) {
    Write-Error "Could not resolve P21.Extensions.BusinessRule.Rule from $P21ExtensionsPath -- wrong DLL or wrong version?"
    exit 1
}
"P21.Extensions.dll loaded: " + $p21ExtAsm.FullName | Out-File -FilePath $ofrec -Append

# Get-Item...FullName, not Resolve-Path -- Resolve-Path returns a PathInfo whose ToString()
# picks up a "Microsoft.PowerShell.Core\FileSystem::" provider prefix on UNC paths, which
# System.IO.File.ReadAllBytes then rejects with "The given path's format is not supported."
# Confirmed 2026-08-10 (first real run against a UNC path failed on exactly this).
$resolvedDllPath = (Get-Item -LiteralPath $DllPath).FullName

# Mirrors RuleWorker.domain_AssemblyResolve, plus the two known DLL shares as a fallback --
# a file pulled out of a share to be checked standalone often still depends on a shared
# vendor DLL (Dapper.dll, Atlas.*, etc.) that only lives back on the share it came from.
$p21ExtFolder = Split-Path $P21ExtensionsPath -Parent
$targetFolder = Split-Path $resolvedDllPath -Parent
$probeFolders = @($targetFolder, $p21ExtFolder) + $knownDllShares
$resolveHandler = [System.ResolveEventHandler] {
    param($resolveSender, $resolveArgs)
    $asmSimpleName = ($resolveArgs.Name -split ',')[0]
    foreach ($folder in $probeFolders) {
        $candidate = Join-Path $folder "$asmSimpleName.dll"
        if (Test-Path $candidate) {
            try { return [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($candidate)) } catch { }
        }
    }
    return $null
}
[System.AppDomain]::CurrentDomain.add_AssemblyResolve($resolveHandler)
#endregion Load P21.Extensions.dll and set up dependency resolution

#region Reflect the target DLL
$ruleClasses = @()
try {
    $asm = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($resolvedDllPath))
    $types = $null
    try {
        $types = $asm.GetTypes()
    } catch [System.Reflection.ReflectionTypeLoadException] {
        $types = @($_.Exception.Types | Where-Object { $_ })
        "Partial type load -- some dependency didn't resolve: " + ($_.Exception.LoaderExceptions | Select-Object -First 1 -ExpandProperty Message) | Out-File -FilePath $ofrec -Append
    }

    $ruleTypes = @($types | Where-Object {
        $_.IsClass -and $_.IsPublic -and -not $_.IsAbstract -and $ruleBaseType.IsAssignableFrom($_)
    })

    foreach ($t in $ruleTypes) {
        try {
            # NOT $instance -- collides case-insensitively with -Instance (ValidateSet'd),
            # throws a validation error. See Get-BusinessRuleDllStatus-Reflection.ps1's header.
            $ruleInstance = [System.Activator]::CreateInstance($t)
            $declaredName = $t.GetMethod('GetName').Invoke($ruleInstance, $null)
            $declaredDesc = $t.GetMethod('GetDescription').Invoke($ruleInstance, $null)
            $isPrivate = $false
            if ($privateAttrType) {
                $isPrivate = ($t.GetCustomAttributes($privateAttrType, $true).Length -gt 0)
            }
            $ruleClasses += [PSCustomObject]@{
                ClassFullName    = $t.FullName
                DeclaredRuleName = $declaredName
                DeclaredDesc     = $declaredDesc
                IsPrivateRule    = $isPrivate
            }
        } catch {
            "Could not instantiate $($t.FullName): " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
            $total_errors++
        }
    }
} catch {
    Write-Error "Could not load $DllPath : $($_.Exception.Message)"
    "LOAD-ERROR: " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
    [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveHandler)
    exit 1
}

if ($ruleClasses.Count -eq 0) {
    "No P21.Extensions.BusinessRule.Rule-derived classes found in this DLL." | Out-File -FilePath $ofrec -Append
    Write-Host "`nNo Rule-derived classes found in $DllPath -- not a P21 business rule assembly (or every class in it failed to instantiate; check $ofrec)."
}
"Rule classes found in DLL: " + $ruleClasses.Count | Out-File -FilePath $ofrec -Append
#endregion Reflect the target DLL

#region Check each declared rule name against each environment
$results = @()
foreach ($env in $instancesToCheck) {
    $cfg = $sqlConfig[$env]
    $q = @"
SELECT rule_name,
       MAX(CASE WHEN row_status_flag = 704 THEN 1 ELSE 0 END) AS has_active,
       MAX(CASE WHEN row_status_flag = 705 THEN 1 ELSE 0 END) AS has_inactive
FROM $($cfg.SqlDb).dbo.business_rule
GROUP BY rule_name
"@
    $ruleStatus = @(Invoke-DbaQuery -SqlInstance $cfg.SqlInstance -Database $cfg.SqlDb -Query $q -As PSObject)
    "Rule names pulled from $($cfg.SqlDb) ($env): " + $ruleStatus.Count | Out-File -FilePath $ofrec -Append

    foreach ($rc in $ruleClasses) {
        $declaredTrimmed = if ($rc.DeclaredRuleName) { $rc.DeclaredRuleName.Trim() } else { $rc.DeclaredRuleName }
        $dbMatch = $ruleStatus | Where-Object {
            [string]::Equals(([string]$_.rule_name).Trim(), $declaredTrimmed, [StringComparison]::OrdinalIgnoreCase)
        } | Select-Object -First 1

        $status =
            if (-not $dbMatch)              { 'NOT FOUND' }
            elseif ($dbMatch.has_active)     { 'ACTIVE' }
            elseif ($dbMatch.has_inactive)   { 'INACTIVE' }
            else                              { 'NOT FOUND' }

        $results += [PSCustomObject]@{
            Environment      = $env
            ClassFullName    = $rc.ClassFullName
            DeclaredRuleName = $rc.DeclaredRuleName
            IsPrivateRule    = $rc.IsPrivateRule
            Status           = $status
        }
    }
}
#endregion Check each declared rule name against each environment

#region Output
$results | Sort-Object ClassFullName, Environment | Format-Table -AutoSize -Wrap

$anyActive = @($results | Where-Object Status -eq 'ACTIVE')
if ($ruleClasses.Count -gt 0) {
    if ($anyActive.Count -gt 0) {
        Write-Host "`n>>> ACTIVE in: $((@($anyActive.Environment | Select-Object -Unique)) -join ', ') <<<" -ForegroundColor Red
    } else {
        Write-Host "`n>>> No exact-name ACTIVE match in any checked environment. Not proof of safety -- see feedback_p21_rule_name_no_dll_link; a free-text rule_name can legitimately differ from GetName(). <<<" -ForegroundColor Yellow
    }
}

$ofcsv = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $safeName + ".csv"
$results | Export-Csv -Path $ofcsv -NoTypeInformation
"CSV written: " + $ofcsv | Out-File -FilePath $ofrec -Append
#endregion Output

#region Footer
[System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveHandler)
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $Path
#endregion Footer

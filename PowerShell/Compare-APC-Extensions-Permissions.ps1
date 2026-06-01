#region Header
if (-not $PC_Name) { $PC_Name = $env:COMPUTERNAME }
if (-not $fDate)   { $fDate   = (Get-Date).ToString('-yyyyMMdd') }
$Path  = "C:\_P25\Logs\Record-of-" + $PC_Name + "-VC-Scripts-Ran-" + (Get-Date).ToString("yyyyMM") + ".txt"
(Get-Date -Format 'yyyy-MM-dd').ToString() + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $Path -Append
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
$ofrec = "C:\_P25\Logs\PS-Rec-Of\" + $MyInvocation.MyCommand.Name + $fDate + ".txt"

function Get-OrdinalSuffix([int]$n) {
    if ($n % 100 -in 11..13) { return "${n}th" }
    switch ($n % 10) {
        1 { return "${n}st" }
        2 { return "${n}nd" }
        3 { return "${n}rd" }
        default { return "${n}th" }
    }
}
$runNumber = 1
if (Test-Path $ofrec) {
    $runNumber = @(Select-String -Path $ofrec -Pattern "Initium Script").Count + 1
    "" | Out-File -FilePath $ofrec -Append
}
"=== " + (Get-OrdinalSuffix $runNumber) + " Run ===" | Out-File -FilePath $ofrec -Append
"Initium Script" | Out-File -FilePath $ofrec -Append

Clear-Host
$MyInvocation.MyCommand.Name
$Error.Clear()
$total_errors = 0
$Script:diffCount = 0
"Start Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
#endregion Header

#region Config
$envs = @(
    [ordered]@{ Name = 'P21 Prod';      Server = 'P21.allsurfaces.com';    DB = 'P21' },
    [ordered]@{ Name = 'P21 Play';      Server = 'P21Dev.allsurfaces.com'; DB = 'P21Play' },
    [ordered]@{ Name = 'P21 BusRules';  Server = 'P21Dev.allsurfaces.com'; DB = 'P21BusinessRules' }
)

$procNames = @(
    'apc_fe_conv_limit_class_surcharge',
    'apc_fe_conv_verify_surcharge_price_edit',
    'apc_fe_val_update_surcharge_price',
    'apc_od_apply_surcharge',
    'apc_od_apply_surcharge_fc',
    'apc_od_apply_surcharge_shipping',
    'apc_os_conv_validate_surcharge_oe',
    'apc_os_conv_validate_surcharge_shipping'
)

$expectedGrantees  = @('p21_application_role', 'PxxiUser')
$keyTypeColumns    = @('fieldAlias', 'fieldValue', 'fieldOriginalValue')
$procList          = "'" + ($procNames -join "','") + "'"
#endregion Config

#region SQL
$sqlTypeColumns = @"
SELECT c.name AS column_name, c.max_length,
       CASE c.max_length WHEN -1 THEN 'varchar(MAX)'
                         ELSE 'varchar(' + CAST(c.max_length AS varchar) + ')'
       END AS current_type
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
WHERE tt.name = 'apc_business_rule_extensions_xml'
ORDER BY c.column_id
"@

$sqlTypePerms = @"
SELECT pr.name AS grantee, dp.permission_name, dp.state_desc
FROM sys.database_permissions dp
JOIN sys.database_principals pr  ON pr.principal_id = dp.grantee_principal_id
JOIN sys.table_types          tt ON tt.user_type_id  = dp.major_id
WHERE tt.name = 'apc_business_rule_extensions_xml'
"@

$sqlProcs = @"
SELECT name FROM sys.objects
WHERE name IN ($procList)
ORDER BY name
"@

$sqlProcPerms = @"
SELECT o.name AS proc_name, pr.name AS grantee, dp.permission_name, dp.state_desc
FROM sys.database_permissions dp
JOIN sys.database_principals pr ON pr.principal_id = dp.grantee_principal_id
JOIN sys.objects              o  ON o.object_id    = dp.major_id
WHERE o.name IN ($procList)
ORDER BY o.name, pr.name
"@
#endregion SQL

#region Helpers
function Write-Section([string]$title) {
    $line = "=" * 110
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    "`n=== $title ===" | Out-File -FilePath $Script:ofrec -Append
}

function Write-TableHeader([string]$col1) {
    Write-Host ("{0,-50} {1,-18} {2,-18} {3,-18} {4}" -f $col1, $Script:e0, $Script:e1, $Script:e2, "Status") -ForegroundColor Cyan
    Write-Host ("-" * 110) -ForegroundColor DarkGray
    ("{0,-50} {1,-18} {2,-18} {3,-18} {4}" -f $col1, $Script:e0, $Script:e1, $Script:e2, "Status") | Out-File -FilePath $Script:ofrec -Append
}

function Write-CompRow {
    param([string]$Label, [string]$V1, [string]$V2, [string]$V3, [switch]$KeyRow)
    $allMatch = ($V1 -eq $V2) -and ($V1 -eq $V3)
    if (-not $allMatch) { $Script:diffCount++ }
    $status = if ($allMatch) { "OK" } else { "<<< DIFF" }
    $color  = if ($allMatch) {
                  if ($KeyRow) { "Green" } else { "DarkGreen" }
              } else {
                  "Red"
              }
    $line = "{0,-50} {1,-18} {2,-18} {3,-18} {4}" -f $Label, $V1, $V2, $V3, $status
    Write-Host $line -ForegroundColor $color
    $line | Out-File -FilePath $Script:ofrec -Append
}
#endregion Helpers

#region Main Logic
$i = 0

try {
    # Collect data from all three environments
    $data = @{}
    foreach ($env in $envs) {
        $msg = "Querying $($env.Name) ($($env.Server) / $($env.DB))..."
        Write-Host $msg -ForegroundColor DarkCyan
        $msg | Out-File -FilePath $ofrec -Append
        $data[$env.Name] = @{
            TypeCols  = Invoke-DbaQuery -SqlInstance $env.Server -Database $env.DB -Query $sqlTypeColumns -As PSObject -ErrorAction Stop
            TypePerms = Invoke-DbaQuery -SqlInstance $env.Server -Database $env.DB -Query $sqlTypePerms   -As PSObject -ErrorAction Stop
            Procs     = Invoke-DbaQuery -SqlInstance $env.Server -Database $env.DB -Query $sqlProcs       -As PSObject -ErrorAction Stop
            ProcPerms = Invoke-DbaQuery -SqlInstance $env.Server -Database $env.DB -Query $sqlProcPerms   -As PSObject -ErrorAction Stop
        }
        $i++
    }

    $Script:e0 = $envs[0].Name
    $Script:e1 = $envs[1].Name
    $Script:e2 = $envs[2].Name

    # -------------------------------------------------------
    # Section 1: Type column widths
    # -------------------------------------------------------
    Write-Section "Section 1: apc_business_rule_extensions_xml — Column Widths"
    Write-Host "  Key columns (being widened): $($keyTypeColumns -join ', ')" -ForegroundColor Yellow
    Write-TableHeader "Column"

    $allColNames = (
        @($data[$Script:e0].TypeCols) +
        @($data[$Script:e1].TypeCols) +
        @($data[$Script:e2].TypeCols) |
        Select-Object -ExpandProperty column_name -ErrorAction SilentlyContinue |
        Sort-Object -Unique
    )

    if (-not $allColNames) {
        Write-Host "  (type not found in any environment)" -ForegroundColor Red
    } else {
        foreach ($col in $allColNames) {
            $r0   = $data[$Script:e0].TypeCols | Where-Object { $_.column_name -eq $col }
            $r1   = $data[$Script:e1].TypeCols | Where-Object { $_.column_name -eq $col }
            $r2   = $data[$Script:e2].TypeCols | Where-Object { $_.column_name -eq $col }
            $v0   = if ($r0) { $r0.current_type }   else { '(missing)' }
            $v1   = if ($r1) { $r1.current_type }   else { '(missing)' }
            $v2   = if ($r2) { $r2.current_type }   else { '(missing)' }
            $isKey = $keyTypeColumns -contains $col
            $label = if ($isKey) { "$col *" } else { $col }
            Write-CompRow -Label $label -V1 $v0 -V2 $v1 -V3 $v2 -KeyRow:$isKey
        }
    }
    Write-Host "  * = key column targeted by the varchar fix" -ForegroundColor DarkYellow

    # -------------------------------------------------------
    # Section 2: EXECUTE permissions on the type
    # -------------------------------------------------------
    Write-Section "Section 2: apc_business_rule_extensions_xml — EXECUTE on Type (expect GRANTED in all)"
    Write-TableHeader "Grantee"

    foreach ($grantee in $expectedGrantees) {
        $v0 = if ($data[$Script:e0].TypePerms | Where-Object { $_.grantee -eq $grantee }) { 'GRANTED' } else { '(none)' }
        $v1 = if ($data[$Script:e1].TypePerms | Where-Object { $_.grantee -eq $grantee }) { 'GRANTED' } else { '(none)' }
        $v2 = if ($data[$Script:e2].TypePerms | Where-Object { $_.grantee -eq $grantee }) { 'GRANTED' } else { '(none)' }
        Write-CompRow -Label $grantee -V1 $v0 -V2 $v1 -V3 $v2 -KeyRow
    }

    # -------------------------------------------------------
    # Section 3: Procedure existence (expect 8 per env)
    # -------------------------------------------------------
    Write-Section "Section 3: Stored Procedure Existence (expect EXISTS in all)"
    Write-TableHeader "Procedure"

    foreach ($proc in $procNames) {
        $v0 = if ($data[$Script:e0].Procs | Where-Object { $_.name -eq $proc }) { 'EXISTS' } else { '(missing)' }
        $v1 = if ($data[$Script:e1].Procs | Where-Object { $_.name -eq $proc }) { 'EXISTS' } else { '(missing)' }
        $v2 = if ($data[$Script:e2].Procs | Where-Object { $_.name -eq $proc }) { 'EXISTS' } else { '(missing)' }
        Write-CompRow -Label $proc -V1 $v0 -V2 $v1 -V3 $v2 -KeyRow
    }

    # -------------------------------------------------------
    # Section 4: EXECUTE permissions on procedures
    # -------------------------------------------------------
    Write-Section "Section 4: EXECUTE on Procedures (expect GRANTED in all — 16 rows per env)"
    Write-TableHeader "Procedure — Grantee"

    foreach ($proc in $procNames) {
        foreach ($grantee in $expectedGrantees) {
            $label = "$proc — $grantee"
            $v0 = if ($data[$Script:e0].ProcPerms | Where-Object { $_.proc_name -eq $proc -and $_.grantee -eq $grantee }) { 'GRANTED' } else { '(none)' }
            $v1 = if ($data[$Script:e1].ProcPerms | Where-Object { $_.proc_name -eq $proc -and $_.grantee -eq $grantee }) { 'GRANTED' } else { '(none)' }
            $v2 = if ($data[$Script:e2].ProcPerms | Where-Object { $_.proc_name -eq $proc -and $_.grantee -eq $grantee }) { 'GRANTED' } else { '(none)' }
            Write-CompRow -Label $label -V1 $v0 -V2 $v1 -V3 $v2 -KeyRow
        }
    }

    # -------------------------------------------------------
    # Summary
    # -------------------------------------------------------
    Write-Section "Summary"
    if ($Script:diffCount -eq 0) {
        Write-Host "  All values match across all three environments." -ForegroundColor Green
        "All values match across all three environments." | Out-File -FilePath $ofrec -Append
    } else {
        Write-Host "  $($Script:diffCount) difference(s) found — see RED rows above." -ForegroundColor Red
        "$($Script:diffCount) difference(s) found." | Out-File -FilePath $ofrec -Append
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    "ERROR: $($_.Exception.Message)" | Out-File -FilePath $ofrec -Append
    $total_errors++
}

"Environments queried: " + $i | Out-File -FilePath $ofrec -Append
#endregion Main Logic

#region Footer
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $Path
#endregion Footer

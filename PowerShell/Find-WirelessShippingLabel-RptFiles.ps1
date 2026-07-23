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
"Start Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
#endregion Header

#region Output File Paths
$oftxt = "C:\_P25\Data-Out\Text\" + $MyInvocation.MyCommand.Name + $fDate + ".txt"
#endregion Output File Paths

#region Main Logic
$ServerRoot   = "\\asp21fs1.ahi.local"
$NameContains = "wireless_shipping_label"

"Server root:   $ServerRoot"   | Tee-Object -FilePath $oftxt
"Name contains: $NameContains" | Tee-Object -FilePath $oftxt -Append
"Started:       " + (Get-Date).ToString('T') | Tee-Object -FilePath $oftxt -Append
"" | Out-File -FilePath $oftxt -Append

# "Prod", "Play", etc. are SMB shares on the server, not subfolders of a common
# share, so the FileSystem provider can't list them via \\server alone
# (Get-ChildItem -Directory needs \\server\ShareName). Use net view to enumerate
# the server's shares instead, then probe each one for a CrystalReports folder.
$ServerName = $ServerRoot.TrimStart('\')
$SearchRoots = @()
$shareNames  = @()

$rawShares = & net view "\\$ServerName" 2>&1
foreach ($line in $rawShares) {
    if ($line -match '^\s*(\S+)\s+Disk(\s|$)') {
        $shareNames += $matches[1]
    }
}

if ($shareNames.Count -eq 0) {
    "ERROR: net view returned no shares for \\$ServerName - raw output below" | Tee-Object -FilePath $oftxt -Append
    $rawShares | ForEach-Object { "  " + $_ | Tee-Object -FilePath $oftxt -Append }
    $total_errors++
} else {
    "Shares found: " + ($shareNames -join ', ') | Tee-Object -FilePath $oftxt -Append
    foreach ($shareName in $shareNames) {
        $crCandidate = "\\$ServerName\$shareName\CrystalReports"
        if (Test-Path -LiteralPath $crCandidate) {
            $SearchRoots += $crCandidate
        }
    }
}

"CrystalReports folders found: " + $SearchRoots.Count | Tee-Object -FilePath $oftxt -Append
$SearchRoots | ForEach-Object { "  - $_" | Tee-Object -FilePath $oftxt -Append }
"" | Out-File -FilePath $oftxt -Append

$i           = 0
$matchCount  = 0
$fileMatches = @()
$dirErrors   = 0

# Get-ChildItem -Recurse can silently stop enumerating an entire branch the moment it
# hits one Access Denied subfolder, even with -ErrorAction SilentlyContinue (known
# FileSystem provider limitation). Walking folder-by-folder isolates errors per
# directory so one locked-down folder can't blank out the rest of the tree.
function Get-RptFilesSafe {
    param([string]$FolderPath)

    $found = @()

    try {
        $found += Get-ChildItem -Path $FolderPath -File -Filter "*.rpt" -Force -ErrorAction Stop
    } catch {
        "  [SKIP-FILES] " + $FolderPath + " - " + $_.Exception.Message | Tee-Object -FilePath $oftxt -Append
        $script:dirErrors++
    }

    try {
        $subDirs = Get-ChildItem -Path $FolderPath -Directory -Force -ErrorAction Stop
    } catch {
        "  [SKIP-DIRS] " + $FolderPath + " - " + $_.Exception.Message | Tee-Object -FilePath $oftxt -Append
        $script:dirErrors++
        return $found
    }

    foreach ($d in $subDirs) {
        $found += Get-RptFilesSafe -FolderPath $d.FullName
    }

    return $found
}

foreach ($SearchRoot in $SearchRoots) {
    "--- Scanning: $SearchRoot ---" | Tee-Object -FilePath $oftxt -Append
    try {
        $rptFiles = Get-RptFilesSafe -FolderPath $SearchRoot
        "  .rpt files found: " + $rptFiles.Count | Tee-Object -FilePath $oftxt -Append
        $total_errors += $dirErrors
        $dirErrors = 0

        foreach ($file in $rptFiles) {
            try {
                if ($file.BaseName -like "*$NameContains*") {
                    $matchCount++
                    $fileMatches += $file.FullName
                    "  FILE: " + $file.FullName + "  (" + $file.LastWriteTime.ToString('yyyy-MM-dd') + ")" | Tee-Object -FilePath $oftxt -Append
                }
            } catch {
                "  [SKIP] " + $file.FullName + " - " + $_.Exception.Message | Tee-Object -FilePath $oftxt -Append
                $total_errors++
            }

            $i++
            if (($i % 500) -eq 0) {
                "Progress: $i files scanned - " + $StopWatch.Elapsed.Minutes + "m " + $StopWatch.Elapsed.Seconds + "s"
            }
        }
    } catch {
        "ERROR accessing search root $SearchRoot - " + $_.Exception.Message | Tee-Object -FilePath $oftxt -Append
        $total_errors++
    }
    "" | Out-File -FilePath $oftxt -Append
}

"" | Out-File -FilePath $oftxt -Append
"--- Summary ---"                              | Tee-Object -FilePath $oftxt -Append
"Files scanned:  $i"                           | Tee-Object -FilePath $oftxt -Append
"Files matched:  $matchCount"                  | Tee-Object -FilePath $oftxt -Append

"Records processed: $i" | Out-File -FilePath $ofrec -Append
"Files matched: $matchCount" | Out-File -FilePath $ofrec -Append
#endregion Main Logic

#region Footer
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $oftxt
#endregion Footer

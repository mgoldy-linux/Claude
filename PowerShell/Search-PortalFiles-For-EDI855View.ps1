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
$SearchRoot   = "\\asp21fs1.ahi.local\Prod\Portals"
$SearchString = "asi_view_edi_855_po_ack"

"Search root:   $SearchRoot"   | Tee-Object -FilePath $oftxt
"Search string: $SearchString" | Tee-Object -FilePath $oftxt -Append
"Started:       " + (Get-Date).ToString('T') | Tee-Object -FilePath $oftxt -Append
""  | Out-File -FilePath $oftxt -Append

$i           = 0
$matchCount  = 0
$fileMatches = @()

try {
    $allFiles = Get-ChildItem -Path $SearchRoot -Recurse -File -ErrorAction Stop
    "Total files found: " + $allFiles.Count | Tee-Object -FilePath $oftxt -Append
    "" | Out-File -FilePath $oftxt -Append

    foreach ($file in $allFiles) {
        try {
            $hits = Select-String -Path $file.FullName -Pattern $SearchString -CaseSensitive:$false -ErrorAction Stop
            if ($hits) {
                $matchCount++
                $fileMatches += $file.FullName
                "FILE: " + $file.FullName | Tee-Object -FilePath $oftxt -Append
                foreach ($hit in $hits) {
                    "  Line " + $hit.LineNumber.ToString().PadLeft(4) + ": " + $hit.Line.Trim() | Tee-Object -FilePath $oftxt -Append
                }
                "" | Out-File -FilePath $oftxt -Append
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
    "ERROR accessing search root: " + $_.Exception.Message | Tee-Object -FilePath $oftxt -Append
    $total_errors++
}

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

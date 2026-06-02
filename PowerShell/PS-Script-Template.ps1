#region Header
# $PC_Name and $fDate are set by the PowerShell profile; fallbacks for scheduled task execution
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

#region Select Server & Database
# $returnedValues = & "C:\PowerShell-Scripts\Select-DB.ps1"
# $db     = $returnedValues.Rdb
# $server = $returnedValues.Rserver
# $text   = $returnedValues.Rtext
# "Server: " + $server + " | DB: " + $db | Out-File -FilePath $ofrec -Append
#endregion Select Server & Database

#region Input - Excel
# & 'C:\PowerShell-Scripts\PS_Skills\Excel\Find-Worksheet-Name&Rows.ps1'
# $wsn      = Read-Host "Enter the worksheet name"
# $rowCount = Read-Host "Enter number of rows to import"
# $iep  = "C:\_P25\Data-In\Excel\your-input-file.xlsx"
# $data = Import-Excel -Path $iep -WorksheetName $wsn -EndRow $rowCount
# $data | Get-Member | Out-File -FilePath $ofrec -Append -Width 1000
# "Number of input records: " + $data.Count | Out-File -FilePath $ofrec -Append
#endregion Input - Excel

#region Output File Paths
# -- CSV --
# $ofcsv = "C:\_P25\Data-Out\CSV\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $db + ".csv"

# -- Excel --
# $ofxls = "C:\_P25\Data-Out\Excel\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $db + ".xlsx"
#endregion Output File Paths

#region Main Logic
$i = 0
$results = @()

# do {
#     try {
#         # your logic here
#         $i++
#     } catch {
#         Custom-ErrorMsg -SName $MyInvocation.MyCommand.Name
#         "Error on record $i" + ": " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
#         $total_errors++
#         $i++
#     }
#
#     # Progress every 500 records
#     if (($i % 500) -eq 0) {
#         "Progress: $i records - " + $StopWatch.Elapsed.Minutes + "m " + $StopWatch.Elapsed.Seconds + "s"
#     }
# } while ($i -lt $data.Count)

"Records processed: " + $i | Out-File -FilePath $ofrec -Append
#endregion Main Logic

#region Output - Write Results
# -- CSV --
# $results | Export-Csv -Path $ofcsv -NoTypeInformation
# "CSV written: " + $ofcsv | Out-File -FilePath $ofrec -Append

# -- Excel --
# $results | Export-Excel -Path $ofxls -WorksheetName "Results" -AutoSize -FreezeTopRow -BoldTopRow
# "Excel written: " + $ofxls | Out-File -FilePath $ofrec -Append
#endregion Output - Write Results

#region Footer
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $Path
#endregion Footer

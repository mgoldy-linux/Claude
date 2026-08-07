#region Header
<#
Moves the confirmed stale/duplicate DLLs out of a P21 environment's live BusinessRulesDLL
share and into an _Archive subfolder (never deletes). Targets one environment at a time so
the fix can be proven on Dev/Play/Training/BusinessRules-test/Upgrade before touching Prod.

Root cause: business_rule_log showed "An item with the same key has already been added" on
every client login, ~45-day analysis 2026-08-04. Traced to 2016/2019-dated dev-iteration DLLs
still sitting in the live share, colliding with the DLL that actually wins the RuleManager's
class-name dictionary registration.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Dev','Play','Training','BusinessRules','Upgrade','Prod')]
    [string]$Instance
)

if (-not $PC_Name) { $PC_Name = $env:COMPUTERNAME }
if (-not $fDate)   { $fDate   = (Get-Date).ToString('-yyyyMMdd') }
$Path  = "C:\_P25\Logs\Record-of-" + $PC_Name + "-VC-Scripts-Ran-" + (Get-Date).ToString("yyyyMM") + ".txt"
(Get-Date -Format 'yyyy-MM-dd').ToString() + " " + $MyInvocation.MyCommand.Name + " -Instance $Instance" | Out-File -FilePath $Path -Append
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
$ofrec = "C:\_P25\Logs\PS-Rec-Of\" + $MyInvocation.MyCommand.Name + $fDate + "-" + $Instance + ".txt"

Clear-Host
$MyInvocation.MyCommand.Name + " -Instance $Instance"
$Error.Clear()
$total_errors = 0
"Start Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
#endregion Header

#region Target Path
$dllShare    = "\\ASP21FS1.ahi.local\$Instance\BusinessRulesDLL"
$archivePath = Join-Path $dllShare "_Archive"
"Target share: " + $dllShare | Out-File -FilePath $ofrec -Append

if (-not (Test-Path $dllShare)) {
    "ERROR: share not found - $dllShare" | Out-File -FilePath $ofrec -Append
    throw "Share not found: $dllShare"
}
if (-not (Test-Path $archivePath)) {
    New-Item -ItemType Directory -Path $archivePath | Out-Null
    "Created archive folder: " + $archivePath | Out-File -FilePath $ofrec -Append
}
#endregion Target Path

#region Main Logic
# Confirmed via business_rule_log analysis + business_rule config check (2026-08-04):
# - DirectShipPriceCheck has NO row in business_rule in any of the 6 P21 environments -> not
#   wired up anywhere, so all 15 dev-iteration files are included, not just the 4 that collide.
# - OrderLineSalesRepAddition_LIVE is row_status_flag 705 (Inactive) in all 6 environments,
#   date_last_modified 2/19/2022 everywhere -> all 3 files included.
# - P21.Accounting.MX.dll (Mexico Accounting/e-invoicing vendor module) confirmed unused (zero
#   rows in sat_invoice_auxfoliorep_mx / sat_payment_transfer_mx / journal_contabilidad_sat_mx,
#   no Mexico module row). Proven on BusinessRules 2026-08-04: archiving it cleared its 8
#   CAS/inheritance-security errors per login, per RuleManager flavor.
$filesToArchive = @(
    'P21.Accounting.MX.dll'
    'DirectShipPriceCheck_0801_0800.dll'
    'DirectShipPriceCheck_0801_0805.dll'
    'DirectShipPriceCheck_0801_0848.dll'
    'DirectShipPriceCheck_0802_1003AM.dll'
    'DirectShipPriceCheck_0802_1005.dll'
    'DirectShipPriceCheck_1028.dll'
    'DirectShipPriceCheck_1040.dll'
    'DirectShipPriceCheck_1102.dll'
    'DirectShipPriceCheck_1122.dll'
    'DirectShipPriceCheck_1136.dll'
    'DirectShipPriceCheck_1139.dll'
    'DirectShipPriceCheck_1249.dll'
    'DirectShipPriceCheck_204.dll'
    'DirectShipPriceCheck_729_120PM.dll'
    'DirectShipPriceCheck_801_729.dll'
    'OrderEntry_SalesRepAddition_update.dll'
    'OrderEntry_SalesRepAddition_live.dll'
    'OrderEntry_SalesRepAddition.dll'

    # Added 2026-08-05: DLLs matching business_rule rows deleted via P21 client + traced/confirmed
    # on BusinessRules (uids 109,110,113,114,116,117,131,132,146). The 5 uids for
    # kb_Order_SaleDay_202105 / _202105_JobName had no matching file - nothing to archive for those.
    'kb_Order_SaleDay_202005.dll'
    'kb_Order_Sale_202006.dll'
    'kb_Order_SaleDay_202009_InsApp.dll'
    'kb_Order_SaleDay_202305.dll'
    'kb_Order_SaleDay_202405.dll'

    # Added 2026-08-07: 3 orphaned files confirmed via fresh query on P21Dev to have NO
    # business_rule row in any environment, ever -- same "orphaned, safe" pattern as
    # DirectShipPriceCheck above. Held back on 8/5 pending an explicit decision; confirmed 8/7.
    'kb_Order_SaleDay_201906.dll'
    'kb_Order_SaleDay_202205.dll'
    'kb_Order_SaleDay.dll'

    # Added 2026-08-07: cross-referenced every live DLL against P21BusinessRules.dbo.business_rule
    # (grouped by rule_name) to find files that are purely Inactive (705) with no Active (704) row
    # sharing the same rule_name -- ruled out RMA_RestockAdjustment_V3.dll (has BOTH an active and
    # an inactive row) and left OrderEntry_salesrep/OrderEntryFund_LIVE_V3/RebatePriceTracker alone
    # (no confident filename match). OrderLineSalesRepAddition_LIVE was the real miss from 8/5's
    # pass -- its business_rule row (uid 44) was deleted that day but the DLL itself was never
    # archived (the file list only had the differently-named OrderEntry_SalesRepAddition* trio).
    # kb_Shipping_IBFSurcharge.dll REMOVED 2026-08-07 -- confirmed via Prod scan + re-check of the
    # archived BusinessRules copy that this file ALSO embeds "kb_RMA_IBFSurcharge_Add", an ACTIVE
    # rule (RMA Entry, On-Demand surcharge). Archived in error on BusinessRules at 12:23 PM, caught
    # and restored same day (zero business_rule_log activity during the gap, no real impact). Do
    # NOT re-add without re-verifying it has no Active match on every rule name, not just the two
    # kb_Shipping_IBFSurcharge_Add/_Update names it was originally guessed against.
    'kb_ValidateOO_BlockSave.dll'
    'kb_Customer_Closed_r1.dll'
    'kb_Customer_Closed.dll'
    'kb_Order_WelcomeBack_202006.dll'
    'OrderLineSalesRepAddition.dll'
    'OrderLineSalesRepAddition_LIVE.dll'

    # Added 2026-08-07 (2nd pass): resolved via actual .cs source in C:\Business_Rules and the
    # OneDrive dev backup tree, not filename guessing. business_rule.rule_name has NO stored link
    # to a class/assembly -- it's a free-text label typed once in P21's Import Rule picker
    # (confirmed: RebatePriceTracker.cs's class is "RebatePriceTracker_Update" in namespace
    # "RebatePricingTracker", three different spellings of the same rule). Each of these was
    # confirmed either by rule_name appearing in source (case-insensitive) or by the source's own
    # class name having zero business_rule rows under ANY name.
    'OrderEntryFund.dll'              # class OrderEntryFund_LIVE_V3 -> rule 705-only
    'RebatePricingTracker.dll'        # class RebatePriceTracker_Update -> rule 705-only
    'rewardRules.dll'                 # class/namespace rewardFormat -> rule 705-only
    'RMA_RestockAdjustment.dll'       # class RMA_RestockAdj (no version) -- zero rows, only _V3 ever wired up
    'RMA_RestockAdjustment_V2.dll'    # class RMA_RestockAdj_V2 -- zero rows, same reason
    'AddSalesRepToOrder.dll'          # zero rows under class name; source is a hardcoded-test stub, real logic commented out, sits in Archive/Old-Projects
)

$i = 0
foreach ($fileName in $filesToArchive) {
    $sourceFile = Join-Path $dllShare $fileName
    if (-not (Test-Path $sourceFile)) {
        "Skipped (not found): " + $fileName | Out-File -FilePath $ofrec -Append
        continue
    }
    try {
        Move-Item -Path $sourceFile -Destination $archivePath -ErrorAction Stop
        "Archived: " + $fileName | Out-File -FilePath $ofrec -Append
        $i++
    } catch {
        "Error archiving $fileName" + ": " + $_.Exception.Message | Out-File -FilePath $ofrec -Append
        $total_errors++
    }
}

"Files archived: " + $i + " of " + $filesToArchive.Count | Out-File -FilePath $ofrec -Append
#endregion Main Logic

#region Footer
"Number of Errors: " + $total_errors | Out-File -FilePath $ofrec -Append
"Stop Script Time: " + (Get-Date).ToString('T') + " " + $MyInvocation.MyCommand.Name | Out-File -FilePath $ofrec -Append
"`nScript runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $ofrec -Append
"Finis Script!" | Out-File -FilePath $ofrec -Append
$MyInvocation.MyCommand.Name + " - " + "Number of Errors: " + $total_errors + " - runtime: " + $StopWatch.Elapsed.Minutes.ToString() + " minutes " + $StopWatch.Elapsed.Seconds.ToString() + " seconds " + $StopWatch.ElapsedMilliseconds + " milliseconds" | Out-File -FilePath $Path -Append
Invoke-Item $ofrec, $Path
#endregion Footer

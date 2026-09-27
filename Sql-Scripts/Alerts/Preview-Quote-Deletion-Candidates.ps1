# Preview-Quote-Deletion-Candidates.ps1
# Calls P21's own p21_order_deletion proc directly (Delete Quotes only) to preview exactly
# which quotes would be deleted by the Order Deletion Criteria tool, WITHOUT deleting anything --
# the proc only populates two scratch tables (oe_deletion_oe_hdr, oe_hdr_not_delete); the actual
# DELETE lives in a separate proc (p21_deletion_master) that this script never calls.
# Exports candidates + rejects to a 2-tab Excel workbook for management review.
#
# ---- EDIT THESE CRITERIA, THEN RE-RUN ----
$Server              = 'P21.allsurfaces.com'
$Database            = 'P21'
$CompanyID           = '1'
$OrderDateCutoff     = '2026-01-01'   # quotes with order_date on/before this qualify
$QuoteExpirationCutoff = '2026-01-01' # quotes with expiration_date on/before this qualify (NULL expiration ALSO qualifies -- not protected)
$LocationFrom        = 0
$LocationTo          = 99999999
$CustomerFrom        = 0
$CustomerTo          = 99999999
$OrderNumberFrom     = 0
$OrderNumberTo       = 99999999
$OrderType           = 'B'   # B=Both, O=Standard Order, S=Service Order
$ApprovedState       = 'B'   # B=Both, Y=Approved only, N=Unapproved only
$CompleteState       = 'B'   # Y=complete quotes only (safe -- incomplete quotes excluded entirely)
                              # B or N=incomplete quotes ALSO become candidates and WILL be deleted, no warning
                              # B is also the ONLY setting that catches quotes with NO quote_hdr row at all
                              # (their complete_flag is NULL, which never equals 'Y' or 'N' -- only 'B' bypasses the check)
$CancelledState      = 'B'   # B=Both, Y=Cancelled only, N=Not cancelled only
# -------------------------------------------

Import-Module ImportExcel -ErrorAction Stop
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -Register -ErrorAction SilentlyContinue
Set-DbatoolsConfig -FullName sql.connection.encrypt   -Value $false -Register -ErrorAction SilentlyContinue

$execQuery = @"
EXEC dbo.p21_order_deletion
     @as_CompanyID = '$CompanyID'
    ,@ai_OrderNumber = $OrderNumberFrom
    ,@ai_OrderNumber2 = $OrderNumberTo
    ,@adt_OrderDate = '$OrderDateCutoff'
    ,@ai_LocationID = $LocationFrom
    ,@ai_LocationID2 = $LocationTo
    ,@ai_CustomerID = $CustomerFrom
    ,@ai_CustomerID2 = $CustomerTo
    ,@ac_DeleteOrders = 'N'
    ,@ac_DeleteQuotes = 'Y'
    ,@ac_DeleteRMAs = 'N'
    ,@adt_QuoteExpirationDate = '$QuoteExpirationCutoff'
    ,@ac_OrderType = '$OrderType'
    ,@ac_ApprovedState = '$ApprovedState'
    ,@ac_CompleteState = '$CompleteState'
    ,@ac_CancelledState = '$CancelledState';
"@

Write-Host "Running p21_order_deletion (Delete Quotes only, scan phase, no delete) against $Database on $Server ..." -ForegroundColor Cyan
Invoke-DbaQuery -SqlInstance $Server -Database $Database -Query $execQuery

$candidatesQuery = @'
SELECT
    oh.order_no AS [Order/Quote #],
    CASE
        WHEN qh.oe_hdr_uid IS NULL THEN 'Deleted Quote'
        WHEN qh.complete_flag <> 'Y' THEN 'Incomplete Quote'
        ELSE 'Complete'
    END AS [Category],
    a.name AS [Customer Name],
    oh.customer_id AS [Customer ID],
    oh.order_date AS [Order Date],
    qh.expiration_date AS [Expiration Date],
    CASE WHEN qh.oe_hdr_uid IS NOT NULL AND qh.expiration_date IS NULL THEN 'NULL - not protected' ELSE '' END AS [Note],
    qh.complete_flag AS [Complete Flag],
    oh.approved AS [Approved],
    oh.cancel_flag AS [Cancelled],
    oh.taker AS [Taker],
    (SELECT COUNT(*) FROM oe_line ol WHERE ol.order_no = oh.order_no) AS [Line Count]
FROM oe_deletion_oe_hdr d
JOIN oe_hdr oh ON oh.order_no = d.order_no
LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
LEFT JOIN address a ON a.id = oh.customer_id
WHERE d.type = 'Q'
ORDER BY [Category], oh.order_date;
'@

$summaryByYearQuery = @'
SELECT
    YEAR(oh.order_date) AS [Year],
    SUM(CASE WHEN qh.oe_hdr_uid IS NULL THEN 1 ELSE 0 END) AS [Deleted Quote],
    SUM(CASE WHEN qh.oe_hdr_uid IS NOT NULL AND qh.complete_flag <> 'Y' THEN 1 ELSE 0 END) AS [Incomplete Quote],
    SUM(CASE WHEN qh.oe_hdr_uid IS NOT NULL AND qh.complete_flag = 'Y' THEN 1 ELSE 0 END) AS [Complete],
    COUNT(*) AS [Total]
FROM oe_deletion_oe_hdr d
JOIN oe_hdr oh ON oh.order_no = d.order_no
LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
WHERE d.type = 'Q'
GROUP BY YEAR(oh.order_date)
ORDER BY [Year];
'@

$candidates = Invoke-DbaQuery -SqlInstance $Server -Database $Database -As PSObject -Query $candidatesQuery
$summaryByYear = Invoke-DbaQuery -SqlInstance $Server -Database $Database -As PSObject -Query $summaryByYearQuery

Write-Host "Candidates (would be DELETED): $($candidates.Count)" -ForegroundColor Yellow
Write-Host "--- Summary by year ---" -ForegroundColor Green
$summaryByYear | Format-Table -AutoSize

$outPath = "C:\Claude\Reports\Quote-Deletion-Preview-$Database-CompleteState-$CompleteState-$(Get-Date -Format yyyy-MM-dd).xlsx"
$candidates    | Export-Excel -Path $outPath -WorksheetName 'Would Be Deleted' -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -TableStyle Medium2
$summaryByYear | Export-Excel -Path $outPath -WorksheetName 'Summary by Year' -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -TableStyle Medium6

Write-Host "Saved: $outPath" -ForegroundColor Cyan

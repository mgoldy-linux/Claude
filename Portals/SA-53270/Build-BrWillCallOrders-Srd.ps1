<#
    Build-BrWillCallOrders-Srd.ps1
    SA 53270 - BR Will Call Orders portal

    Builds br_will_call_orders.srd from a copy of the live BR SAL WILL ADVISE portal
    (br_sal_will_advise.BASE.srd, pulled from \\ASP21FS1\Prod\Portals 2026-08-22):
      - Injects br_will_call_orders.retrieve.sql as the new retrieve= SQL
      - Drops the 3 trailing columns (Cost / duplicate Unit / Extended Cost -- commission_cost,
        pricing_unit, extended_cost) -- both their table(column=(...)) metadata entries and their
        header/detail band visual objects
      - Adds one new column (Promise Date / p21_view_oe_hdr.promise_date) in the vacated slot,
        built from the Order Date column as a template (same type/format/width)

    DataWindow columns bind by POSITION, not name -- the SELECT list order in the .sql MUST
    match the table(column=(...)) metadata order exactly, which this script enforces by
    construction (it edits both in lockstep) and then verifies by re-parsing the output.

    The .srd is UTF-16LE + BOM; retrieve= holds a plain double-quoted string with literal
    CRLFs, so the injected SQL must contain no double-quote characters.

    Baseline : br_sal_will_advise.BASE.srd  (pristine copy from Prod 2026-08-22)
    Output   : br_will_call_orders.srd
#>
[CmdletBinding()]
param(
    [string]$Dir = $PSScriptRoot
)

$base = Join-Path $Dir 'br_sal_will_advise.BASE.srd'
$sqlf = Join-Path $Dir 'br_will_call_orders.retrieve.sql'
$out  = Join-Path $Dir 'br_will_call_orders.srd'

foreach ($f in $base, $sqlf) {
    if (-not (Test-Path $f)) { throw "missing required file: $f" }
}

$txt = [System.IO.File]::ReadAllText($base, [System.Text.Encoding]::Unicode)

function Remove-Block {
    param([string]$Text, [string]$StartMarker, [string]$Terminator = '" )')
    $s = $Text.IndexOf($StartMarker)
    if ($s -lt 0) { throw "block start marker not found: $StartMarker" }
    # walk back to the object keyword that owns this marker
    $objStart = [Math]::Max($Text.LastIndexOf('text(band=header', $s), $Text.LastIndexOf('column(band=detail', $s))
    if ($objStart -lt 0 -or $objStart -lt ($s - 4000)) { $objStart = $s }
    $e = $Text.IndexOf($Terminator, $s)
    if ($e -lt 0) { throw "block terminator not found after marker: $StartMarker" }
    $e += $Terminator.Length
    return @{ Start = $objStart; End = $e; Text = $Text.Substring($objStart, $e - $objStart) }
}

# ---- 1. Remove the 3 trailing metadata column=( ) entries ----
foreach ($dbname in 'commission_cost','pricing_unit','extended_cost') {
    # pricing_unit appears twice (col 10 keep, col 17 drop) -- target only the LAST occurrence
}
$metaCommission = [regex]::Match($txt, 'column=\(type=decimal\(9\) updatewhereclause=yes name=commission_cost dbname="commission_cost" \)')
$metaPricingDup  = [regex]::Match($txt, 'column=\(type=char\(8\) updatewhereclause=yes name=pricing_unit dbname="pricing_unit" \)')
$metaExtCost     = [regex]::Match($txt, 'column=\(type=decimal\(12\) updatewhereclause=yes name=extended_cost dbname="extended_cost" \)')
foreach ($m in @($metaCommission, $metaPricingDup, $metaExtCost)) {
    if (-not $m.Success) { throw "metadata column entry not found for removal" }
}
# New metadata entry for promise_date, inserted right after the order_date entry
$metaOrderDate = [regex]::Match($txt, 'column=\(type=datetime updatewhereclause=yes name=p21_view_oe_hdr_order_date dbname="order_date" \)')
if (-not $metaOrderDate.Success) { throw "order_date metadata template not found" }
$newMetaCol = 'column=(type=datetime updatewhereclause=yes name=p21_view_oe_hdr_promise_date dbname="promise_date" )'

# Remove the 3 trailing metadata entries (process in reverse index order so earlier offsets stay valid)
$metaRemovals = @($metaCommission, $metaPricingDup, $metaExtCost) | Sort-Object { $_.Index } -Descending
foreach ($m in $metaRemovals) {
    $txt = $txt.Remove($m.Index, $m.Length)
}
# Insert the new metadata column LAST, immediately after date_last_modified's entry -- this
# must match promise_date's position (last) in the retrieve SQL SELECT list, since columns
# bind by ordinal position, not name.
$metaDateLastMod = [regex]::Match($txt, 'column=\(type=datetime updatewhereclause=yes name=date_last_modified dbname="date_last_modified" \)')
if (-not $metaDateLastMod.Success) { throw "date_last_modified metadata entry not found" }
$insertAt = $metaDateLastMod.Index + $metaDateLastMod.Length
$txt = $txt.Insert($insertAt, "`r`n $newMetaCol")

# ---- 2. Remove the 3 trailing header band text objects ----
$hdrCost    = Remove-Block -Text $txt -StartMarker 'name=commission_cost_t '
$txt = $txt.Remove($hdrCost.Start, $hdrCost.End - $hdrCost.Start)
$hdrUnitDup = Remove-Block -Text $txt -StartMarker 'name=pricing_unit_t '
$txt = $txt.Remove($hdrUnitDup.Start, $hdrUnitDup.End - $hdrUnitDup.Start)
$hdrExtCost = Remove-Block -Text $txt -StartMarker 'name=extended_cost_t '
$txt = $txt.Remove($hdrExtCost.Start, $hdrExtCost.End - $hdrExtCost.Start)

# ---- 3. Remove the 3 trailing detail band column objects ----
$detCommission = Remove-Block -Text $txt -StartMarker 'name=commission_cost visible="1"'
$txt = $txt.Remove($detCommission.Start, $detCommission.End - $detCommission.Start)
$detUnitDup = Remove-Block -Text $txt -StartMarker 'name=pricing_unit visible="1"'
$txt = $txt.Remove($detUnitDup.Start, $detUnitDup.End - $detUnitDup.Start)
$detExtCost = Remove-Block -Text $txt -StartMarker 'name=extended_cost visible="1"'
$txt = $txt.Remove($detExtCost.Start, $detExtCost.End - $detExtCost.Start)

# ---- 3b. Remove the footer "sum(extended_cost)" total -- the column it totals no longer exists ----
$footStart = $txt.IndexOf('compute(band=footer alignment="1" expression="sum( extended_cost )"')
if ($footStart -lt 0) { throw "footer extended_cost compute object not found" }
$footEnd = $txt.IndexOf('" )', $footStart) + 3
$txt = $txt.Remove($footStart, $footEnd - $footStart)

# ---- 4. Insert new Promise Date header + detail objects, built from Order Date as template ----
$hdrOrderDateMarker = 'name=p21_view_oe_hdr_order_date_t '
$hdrNi = $txt.IndexOf($hdrOrderDateMarker)
$hdrStart = $txt.LastIndexOf('text(band=header', $hdrNi)
$hdrEnd = $txt.IndexOf('" )', $hdrNi) + 3
$hdrTemplate = $txt.Substring($hdrStart, $hdrEnd - $hdrStart)
$hdrPromise = $hdrTemplate `
    -replace 'text="Order\r?\nDate"', "text=`"Promise`r`nDate`"" `
    -replace 'x="6898"', 'x="8786"' `
    -replace 'name=p21_view_oe_hdr_order_date_t', 'name=p21_view_oe_hdr_promise_date_t'
if ($hdrPromise -eq $hdrTemplate) { throw "header template substitution had no effect -- check regex" }
$txt = $txt.Insert($hdrEnd, "`r`n $hdrPromise")

$detOrderDateMarker = 'name=p21_view_oe_hdr_order_date visible="1"'
$detNi = $txt.IndexOf($detOrderDateMarker)
$detStart = $txt.LastIndexOf('column(band=detail', $detNi)
$detEnd = $txt.IndexOf('" )', $detNi) + 3
$detTemplate = $txt.Substring($detStart, $detEnd - $detStart)
$detPromise = $detTemplate `
    -replace 'id="?\d+"?', 'id=19' `
    -replace 'x="6898"', 'x="8786"' `
    -replace 'name=p21_view_oe_hdr_order_date visible', 'name=p21_view_oe_hdr_promise_date visible'
if ($detPromise -eq $detTemplate) { throw "detail template substitution had no effect -- check regex" }
$txt = $txt.Insert($detEnd, "`r`n $detPromise")

# ---- 5. Replace retrieve= SQL ----
$start = $txt.IndexOf('retrieve="')
if ($start -lt 0) { throw 'retrieve= not found in baseline .srd' }
$open  = $start + 'retrieve="'.Length
$close = $txt.IndexOf('"', $open)
if ($close -lt 0) { throw 'closing quote of retrieve= not found' }

$oldSql = $txt.Substring($open, $close - $open)
$newSql = (Get-Content $sqlf -Raw).TrimEnd() -replace "`r?`n", "`r`n"

if ($newSql.Contains('"')) { throw 'retrieve SQL contains a double-quote; this would break the .srd' }

$txt = $txt.Substring(0, $open) + $newSql + $txt.Substring($close)

[System.IO.File]::WriteAllText($out, $txt, [System.Text.UnicodeEncoding]::new($false, $true))

# ---- 6. Verify ----
Write-Host "written: $out"
Write-Host ""
Write-Host '--- column count check (expect 16 everywhere) ---'
$verify = [System.IO.File]::ReadAllText($out, [System.Text.Encoding]::Unicode)
Write-Host ("  metadata columns : {0}" -f ([regex]::Matches($verify,'column=\(type=').Count))
Write-Host ("  header objects    : {0}" -f ([regex]::Matches($verify,'text\(band=header').Count))
Write-Host ("  detail objects    : {0}" -f ([regex]::Matches($verify,'column\(band=detail').Count))
Write-Host ""
Write-Host '--- leftover cost-column check (expect 0 for all) ---'
foreach ($needle in 'commission_cost','extended_cost') {
    Write-Host ("  {0,-20} : {1}" -f $needle, ([regex]::Matches($verify,[regex]::Escape($needle)).Count))
}
Write-Host ("  pricing_unit (expect 2: kept qty col + new metadata dbname) : {0}" -f ([regex]::Matches($verify,'pricing_unit').Count))
Write-Host ""
Write-Host '--- promise_date present ---'
Write-Host ("  occurrences : {0}" -f ([regex]::Matches($verify,'promise_date').Count))
Write-Host ""
Write-Host '--- final metadata column order (positional -- must match retrieve SQL SELECT order) ---'
$metaOrder = [regex]::Matches($verify, 'column=\(type=([^\s]+) updatewhereclause=\w+ name=(\S+) dbname="([^"]*)"') |
    ForEach-Object { $_.Groups[3].Value }
$metaOrder | ForEach-Object { $i=1 } { "  {0,2}. {1}" -f $i, $_; $i++ }

$expectedOrder = 'taker','customer_id','customer_name','order_contact','ship_to_phone','order_no',
    'item_id','extended_desc','unit_price_home','pricing_unit','qty_ordered','extended_price_home',
    'order_date','job_name','date_last_modified','promise_date'
$diff = Compare-Object $expectedOrder $metaOrder -SyncWindow 0
if ($diff) {
    Write-Host ""
    Write-Host "!! METADATA ORDER MISMATCH vs expected SQL SELECT order !!" -ForegroundColor Red
    $diff | Format-Table -AutoSize
} else {
    Write-Host ""
    Write-Host "metadata order matches expected retrieve SQL SELECT order -- OK" -ForegroundColor Green
}
Write-Host ""
Write-Host '--- leftover footer total on removed column check (expect 0) ---'
Write-Host ("  compute_2 (old ext-cost total) : {0}" -f ([regex]::Matches($verify,'compute_2').Count))
Write-Host '--- kb_ dependency check (flag for KB retirement tracker) ---'
foreach ($kb in 'kb_fnt_get_user_loc','kb_view_users') {
    $hit = if ($verify -match [regex]::Escape($kb)) { 'yes' } else { 'no' }
    Write-Host ("  {0,-24} present in .srd/SQL: {1}" -f $kb, $hit)
}

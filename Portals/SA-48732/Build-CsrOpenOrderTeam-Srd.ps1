<#
    Build-CsrOpenOrderTeam-Srd.ps1
    SA 48732 - CSR Open Order Team portal

    Injects csr_open_order_team.retrieve.sql into the portal .srd, replacing the
    retrieve= DataWindow SQL. The .sql file is the source of truth; the .srd is generated.

    The .srd is UTF-16LE + BOM. Inside it, retrieve= holds a plain double-quoted string
    with literal CRLFs -- the SQL must therefore contain NO double-quote characters.

    Baseline : csr_open_order_team.BASE.srd  (pristine copy taken from Prod 2026-07-13,
               itself an unmodified clone of my_open_orders.srd)
    Output   : csr_open_order_team.srd
#>
[CmdletBinding()]
param(
    [string]$Dir = $PSScriptRoot
)

$base = Join-Path $Dir 'csr_open_order_team.BASE.srd'
$sqlf = Join-Path $Dir 'csr_open_order_team.retrieve.sql'
$out  = Join-Path $Dir 'csr_open_order_team.srd'

foreach ($f in $base, $sqlf) {
    if (-not (Test-Path $f)) { throw "missing required file: $f" }
}

$txt = [System.IO.File]::ReadAllText($base, [System.Text.Encoding]::Unicode)

$start = $txt.IndexOf('retrieve="')
if ($start -lt 0) { throw 'retrieve= not found in baseline .srd' }
$open  = $start + 'retrieve="'.Length
$close = $txt.IndexOf('"', $open)
if ($close -lt 0) { throw 'closing quote of retrieve= not found' }

$oldSql = $txt.Substring($open, $close - $open)
$newSql = (Get-Content $sqlf -Raw).TrimEnd() -replace "`r?`n", "`r`n"

if ($newSql.Contains('"')) { throw 'retrieve SQL contains a double-quote; this would break the .srd' }

$new = $txt.Substring(0, $open) + $newSql + $txt.Substring($close)
[System.IO.File]::WriteAllText($out, $new, [System.Text.UnicodeEncoding]::new($false, $true))

Write-Host "baseline retrieve SQL : $($oldSql.Length) chars"
Write-Host "injected retrieve SQL : $($newSql.Length) chars"
Write-Host "written               : $out"
Write-Host ''
Write-Host '--- kb_ dependency check ---'
foreach ($kb in 'kb_view_open_orders','kb_view_salesrep','kb_fn_get_sales_manager','kb_fn_get_product_manager') {
    $was = if ($oldSql -match [regex]::Escape($kb)) { 'yes' } else { 'no ' }
    $now = if ($newSql -match [regex]::Escape($kb)) { 'yes' } else { 'no ' }
    Write-Host ("  {0,-28} baseline={1}  now={2}" -f $kb, $was, $now)
}

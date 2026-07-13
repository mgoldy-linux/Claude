<#
    Build-CsrOpenOrderTeam-Srd.ps1
    SA 48732 - CSR Open Order Team portal

    Rewrites the retrieve= SQL inside csr_open_order_team.srd:
      - replaces the inherited "mine" viewer filter with a CSR/CSR-Manager taker filter
      - drops the inv_mast and manager_contact joins that only existed to serve that filter
        (validated on Prod: row count identical with and without the inv_mast join)

    Reads  : <scratchpad>\csr_open_order_team.srd   (untouched Prod copy, UTF-16LE)
    Writes : <scratchpad>\csr_open_order_team.NEW.srd
#>

$sp  = "C:\Users\mgoldyn\AppData\Local\Temp\claude\C--Claude\bbe39a75-6a6e-4f88-bb1e-481e274c13ff\scratchpad"
$src = Join-Path $sp 'csr_open_order_team.srd'
$dst = Join-Path $sp 'csr_open_order_team.NEW.srd'

$txt = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::Unicode)

# The retrieve= value is a plain double-quoted string; the SQL contains no embedded
# double-quotes, so the first quote after retrieve= opens it and the next one closes it.
$start = $txt.IndexOf('retrieve="')
if ($start -lt 0) { throw 'retrieve= not found' }
$open  = $start + 'retrieve="'.Length
$close = $txt.IndexOf('"', $open)
if ($close -lt 0) { throw 'closing quote not found' }

$oldSql = $txt.Substring($open, $close - $open)

$nl = "`r`n"
$newSql = @(
    'SELECT taker.name AS taker, '
    "`tsr.salesrep_name AS salesrep, "
    "`too.location_id, "
    "`too.customer_id, "
    "`too.customer_name, "
    "`too.order_no, "
    "`too.line_no, "
    "`too.item_id, "
    "`too.item_desc, "
    "`too.qty_open, oo.base_unit, "
    "`too.open_value, "
    "`too.po_no AS customer_po_no, "
    "`too.order_date, pt.print_date AS pick_ticket_print_date, oel.required_date, "
    "`too.disposition, oo.validation_status, oo.approved"
    ''
    'FROM kb_view_open_orders AS oo'
    'INNER JOIN oe_line AS oel ON oo.order_no = oel.order_no AND oo.line_no = oel.line_no'
    'INNER JOIN oe_hdr AS oeh ON oeh.order_no = oo.order_no'
    'LEFT JOIN users AS taker ON taker.id = oo.taker'
    'LEFT JOIN (SELECT oept.order_no, oeptd.oe_line_no, MAX(oept.print_date) AS print_date'
    "`tFROM oe_pick_ticket AS oept "
    "`tLEFT JOIN oe_pick_ticket_detail AS oeptd ON oeptd.pick_ticket_no = oept.pick_ticket_no"
    "`tWHERE oept.delete_flag = 'N' AND oept.printed_flag = 'Y' "
    "`tGROUP BY oept.order_no, oeptd.oe_line_no) AS pt "
    "`t`tON pt.order_no = oo.order_no AND pt.oe_line_no = oo.line_no"
    'LEFT JOIN kb_view_salesrep AS sr ON COALESCE(oo.updated_salesrep_id,oo.oe_salesrep_id,0) = CONVERT(VARCHAR(16),sr.salesrep_id)'
    ''
    'WHERE oo.taker IN ('
    "`t-- Roster resolves at query time, so role changes need no portal edit."
    "`t-- Integration accounts are excluded so web/EDI volume does not swamp the team."
    "`tSELECT u.id"
    "`tFROM users AS u WITH(NOLOCK)"
    "`tINNER JOIN roles AS r WITH(NOLOCK) ON r.role_uid = u.role_uid"
    "`tWHERE r.role IN ('Customer Service', 'Customer Service Manager')"
    "`t  AND u.delete_flag = 'N'"
    "`t  AND u.id NOT IN ('ECOMM', 'ESTORE', 'SHAGTOOLS') )"
) -join $nl

if ($newSql.Contains('"')) { throw 'new SQL contains a double-quote; would break the .srd string' }

$new = $txt.Substring(0, $open) + $newSql + $txt.Substring($close)
[System.IO.File]::WriteAllText($dst, $new, [System.Text.UnicodeEncoding]::new($false, $true))  # UTF-16LE + BOM

Write-Host "OLD retrieve SQL: $($oldSql.Length) chars"
Write-Host "NEW retrieve SQL: $($newSql.Length) chars"
Write-Host "Written: $dst"
Write-Host ''
Write-Host '--- kb_ dependency check (new SQL) ---'
foreach ($kb in 'kb_view_open_orders','kb_view_salesrep','kb_fn_get_sales_manager','kb_fn_get_product_manager') {
    $was = if ($oldSql -match [regex]::Escape($kb)) { 'yes' } else { 'no ' }
    $now = if ($newSql -match [regex]::Escape($kb)) { 'yes' } else { 'no ' }
    Write-Host ("  {0,-28} before={1}  after={2}" -f $kb, $was, $now)
}

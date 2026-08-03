#region Header
# Compares the Low Margin Alert build (view columns, alert defs, tokens) between
# P21 (Prod) and P21Play, ahead of the Monday P21Play refresh.
# Some differences are EXPECTED pre-refresh and are labeled as such, not failures:
#   - alert_implementation.row_status_flag: Prod=705 (inactive, holding for Evan's
#     sign-off), Play=704 (active, mgoldyn-only test build) until Play is refreshed.
#   - alert_recipient: Prod carries the real recipient list, Play carries mgoldyn
#     only (deliberate -- Play has live SMTP).
#   - alert_message.subject: Play carries a "[TEST-Play]" tag Prod does not.
# Anything else that differs (view columns, where_clause, filter counts, message
# header/line_item/footer bodies, token registration) is a REAL gap.
if (-not $PC_Name) { $PC_Name = $env:COMPUTERNAME }
if (-not $fDate)   { $fDate   = (Get-Date).ToString('-yyyyMMdd') }
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
Import-Module dbatools -ErrorAction Stop

$ProdSrv = 'P21.allsurfaces.com';    $ProdDb = 'P21'
$PlaySrv = 'P21Dev.allsurfaces.com'; $PlayDb = 'P21Play'

$AlertNames = @('Low Margin Alert - Team', 'Low Margin Alert - Purchasing Escalation (MAC)',
                'Low PAD Margin Alert - Team', 'Low PAD Margin Alert - Purchasing Escalation (MAC)')
$NewColumns = @('price_page_description','unit_mac','unit_standard_cost',
                'percent_profit_off_mac','percent_profit_off_standard_cost',
                'low_margin_flag','sales_location_name','ship_location_name')
$TokenNames = $NewColumns  # same 8 names are also the token names

Clear-Host
"Compare-LowMarginAlert-Prod-vs-Play  ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
"Prod: $ProdSrv/$ProdDb   Play: $PlaySrv/$PlayDb"
#endregion Header

#region A. View columns
"`n=== A. View columns on p21_view_alert_oe_OrderEntry ==="
$colQuery = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'p21_view_alert_oe_OrderEntry'"
$prodCols = (Invoke-DbaQuery -SqlInstance $ProdSrv -Database $ProdDb -Query $colQuery -As PSObject).COLUMN_NAME
$playCols = (Invoke-DbaQuery -SqlInstance $PlaySrv -Database $PlayDb -Query $colQuery -As PSObject).COLUMN_NAME

$colResults = foreach ($c in $NewColumns) {
    [PSCustomObject]@{
        Column = $c
        Prod   = if ($prodCols -contains $c) { 'present' } else { 'MISSING' }
        Play   = if ($playCols -contains $c) { 'present' } else { 'MISSING' }
        Status = if (($prodCols -contains $c) -eq ($playCols -contains $c)) { 'match' } else { 'DIFFERS' }
    }
}
$colResults | Format-Table -AutoSize
#endregion A. View columns

#region B. Alert implementation, message, recipients, filters
"`n=== B. Alert definitions ==="
foreach ($name in $AlertNames) {
    "`n--- $name ---"

    $implQuery = "SELECT alert_implementation_uid, alert_type_uid, row_status_flag, where_clause FROM alert_implementation WHERE alert_implementation_name = '$name'"
    $prodImpl = Invoke-DbaQuery -SqlInstance $ProdSrv -Database $ProdDb -Query $implQuery -As PSObject
    $playImpl = Invoke-DbaQuery -SqlInstance $PlaySrv -Database $PlayDb -Query $implQuery -As PSObject

    if (-not $prodImpl) { "  Prod: MISSING"; if ($playImpl) { "  Play: present (uid $($playImpl.alert_implementation_uid), status $($playImpl.row_status_flag))" }; continue }
    if (-not $playImpl) { "  Play: MISSING"; "  Prod: present (uid $($prodImpl.alert_implementation_uid), status $($prodImpl.row_status_flag))"; continue }

    "  row_status_flag -> Prod: $($prodImpl.row_status_flag)   Play: $($playImpl.row_status_flag)  (expected to differ pre-refresh)"
    $whereMatch = $prodImpl.where_clause -eq $playImpl.where_clause
    "  where_clause match: $whereMatch"
    if (-not $whereMatch) { "    Prod: $($prodImpl.where_clause)"; "    Play: $($playImpl.where_clause)" }

    $filterQuery = "SELECT COUNT(*) AS n FROM Alert_implementation_query WHERE alert_implementation_uid = "
    $prodFilters = (Invoke-DbaQuery -SqlInstance $ProdSrv -Database $ProdDb -Query ($filterQuery + $prodImpl.alert_implementation_uid) -As PSObject).n
    $playFilters = (Invoke-DbaQuery -SqlInstance $PlaySrv -Database $PlayDb -Query ($filterQuery + $playImpl.alert_implementation_uid) -As PSObject).n
    "  filter rows -> Prod: $prodFilters   Play: $playFilters  $(if ($prodFilters -ne $playFilters) {'-- REAL GAP'})"

    $msgQuery = "SELECT alert_message_uid, subject, header, line_item, footer FROM alert_message WHERE alert_implementation_uid = "
    $prodMsg = Invoke-DbaQuery -SqlInstance $ProdSrv -Database $ProdDb -Query ($msgQuery + $prodImpl.alert_implementation_uid) -As PSObject
    $playMsg = Invoke-DbaQuery -SqlInstance $PlaySrv -Database $PlayDb -Query ($msgQuery + $playImpl.alert_implementation_uid) -As PSObject

    $subjNorm = ($playMsg.subject -replace '^\[TEST-Play\]\s*', '')
    "  subject match (ignoring [TEST-Play] tag): $($prodMsg.subject -eq $subjNorm)"
    "  header match: $($prodMsg.header -eq $playMsg.header)"
    "  line_item match: $($prodMsg.line_item -eq $playMsg.line_item)"
    "  footer match: $($prodMsg.footer -eq $playMsg.footer)"

    $recQuery = "SELECT alert_email_name, alert_email_address FROM alert_recipient WHERE alert_message_uid = "
    $prodRec = Invoke-DbaQuery -SqlInstance $ProdSrv -Database $ProdDb -Query ($recQuery + $prodMsg.alert_message_uid) -As PSObject
    $playRec = Invoke-DbaQuery -SqlInstance $PlaySrv -Database $PlayDb -Query ($recQuery + $playMsg.alert_message_uid) -As PSObject
    "  recipients -> Prod: $(($prodRec | ForEach-Object { $_.alert_email_name }) -join ', ')"
    "  recipients -> Play: $(($playRec | ForEach-Object { $_.alert_email_name }) -join ', ')  (expected to differ pre-refresh)"
}
#endregion B. Alert implementation, message, recipients, filters

#region C. Token registration
"`n=== C. Token registration (alert_type_uid = 12) ==="
$tokQuery = @"
SELECT t.name, t.available_areas, t.data_type_cd
FROM token t JOIN alert_type_x_token x ON x.token_uid = t.token_uid
WHERE x.alert_type_uid = 12 AND t.name IN ('$($TokenNames -join "','")')
"@
$prodTok = Invoke-DbaQuery -SqlInstance $ProdSrv -Database $ProdDb -Query $tokQuery -As PSObject
$playTok = Invoke-DbaQuery -SqlInstance $PlaySrv -Database $PlayDb -Query $tokQuery -As PSObject

$tokResults = foreach ($n in $TokenNames) {
    $p = $prodTok | Where-Object { $_.name -eq $n }
    $pl = $playTok | Where-Object { $_.name -eq $n }
    [PSCustomObject]@{
        Token       = $n
        Prod_Areas  = if ($p) { $p.available_areas } else { 'MISSING' }
        Play_Areas  = if ($pl) { $pl.available_areas } else { 'MISSING' }
        Prod_Type   = if ($p) { $p.data_type_cd } else { '-' }
        Play_Type   = if ($pl) { $pl.data_type_cd } else { '-' }
        Status      = if ($p -and $pl -and $p.available_areas -eq $pl.available_areas -and $p.data_type_cd -eq $pl.data_type_cd) { 'match' } else { 'DIFFERS' }
    }
}
$tokResults | Format-Table -AutoSize
#endregion C. Token registration

#region Footer
"`nDone. Runtime: " + $StopWatch.Elapsed.Minutes + "m " + $StopWatch.Elapsed.Seconds + "s"
#endregion Footer

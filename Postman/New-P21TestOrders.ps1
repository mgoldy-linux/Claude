<#
.SYNOPSIS
    Bulk-create sales orders in a P21 environment through the V2 Transaction API,
    for load / regression / data-seeding test scenarios.

.DESCRIPTION
    Authenticates once (POST /api/security/token/), then POSTs N order
    TransactionSets to /uiserver0/api/v2/Transaction. Each order gets a random
    customer, 1-2 random line items, and a random quantity from the supplied
    pools. Every attempt is reported (order_no on success, the P21 message on a
    rule block) and optionally written to CSV.

    Defaults target the Business Rules env (BRR) and the NORMAL-credit test
    customers at location 100. Cash / prepay / COD customers and direct-ship
    lines trip the Atlas surcharge rule ("Please click the APPLY SURCHARGE
    button") and will fail - keep the customer pool to NORMAL-credit accounts.

.PARAMETER Count
    How many orders to create. Default 5.

.PARAMETER BaseUrl
    Environment root. Default https://p21businessrules.allsurfaces.com:3444
    Others: Play :3445  Dev :3448  Training :3447  (Prod is intentionally omitted)

.PARAMETER Credential
    P21 login. If omitted you are prompted. Username form: domain\user or user.

.PARAMETER AppKey
    P21 application key (appKey header). Defaults to the shared Postman key.

.PARAMETER CustomerPool
    customer_id values to draw from (ship_to_id is set equal to customer_id).

.PARAMETER ItemPool
    "item_id:unit_price" pairs to draw line items from.

.PARAMETER LocationId
    sales_loc_id for every order. Default 100.

.PARAMETER DelayMs
    Pause between orders (ms). Default 250. Raise if the middleware struggles.

.PARAMETER CsvPath
    Optional. Write the run log here.

.EXAMPLE
    .\New-P21TestOrders.ps1 -Count 25 -CsvPath .\orders-run.csv

.EXAMPLE
    .\New-P21TestOrders.ps1 -Count 5 -BaseUrl https://p21play.allsurfaces.com:3445

.NOTES
    Author: mgoldyn
    PowerShell 7+. Uses -SkipCertificateCheck (internal cert) and HTTP/1.1
    (the P21 middleware has HTTP/2 issues - NGHTTP2_CANCEL).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]    $Count        = 5,
    [string] $BaseUrl      = 'https://p21businessrules.allsurfaces.com:3444',
    [pscredential] $Credential,
    [string] $AppKey       = '73844b21-3b37-4d24-9db5-2bf9e143c53c',
    [string[]] $CustomerPool = @('1000260','1003590','1011718','3000095'),
    [string[]] $ItemPool     = @(
        'MAP1005001:7.76',
        'FDTT11-50075:3.74',
        'MAP0080025:22.45',
        'MAP1951215:129.58',
        'ROP40C81P100:0.96'
    ),
    [int]    $LocationId   = 100,
    [int]    $DelayMs      = 250,
    [string] $CsvPath
)

#region --- Config -----------------------------------------------------------
$tokenUri  = "$BaseUrl/api/security/token/"
$txnUri    = "$BaseUrl/uiserver0/api/v2/Transaction"

# Invoke-RestMethod splat reused for every call
$irmBase = @{
    SkipCertificateCheck = $true
    ErrorAction          = 'Stop'
}
if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey('HttpVersion')) {
    $irmBase['HttpVersion'] = '1.1'
}
#endregion

#region --- Functions ------------------------------------------------------------
function Get-P21Token {
    param([string]$Uri, [pscredential]$Cred, [string]$Key)

    $headers = @{
        username = $Cred.UserName
        password = $Cred.GetNetworkCredential().Password
        appKey   = $Key
    }
    $resp = Invoke-RestMethod @irmBase -Method Post -Uri $Uri -Headers $headers

    # Response is XML; AccessToken may be namespaced. Try [xml] first, then regex.
    $token = $null
    try {
        $xml = [xml]$resp
        $node = $xml.SelectSingleNode("//*[local-name()='AccessToken']")
        if ($node) { $token = $node.InnerText }
    } catch { }
    if (-not $token) {
        $m = [regex]::Match([string]$resp, '<(?:\w+:)?AccessToken>\s*([^<]+?)\s*</(?:\w+:)?AccessToken>')
        if ($m.Success) { $token = $m.Groups[1].Value }
    }
    if (-not $token) { throw "Could not parse AccessToken from token response:`n$resp" }
    $token
}

function New-OrderBody {
    param([string]$CustomerId, [int]$LocId, [array]$Lines)

    $ns  = 'http://schemas.datacontract.org/2004/07/P21.Transactions.Model.V2'
    $arr = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'

    $lineXml = foreach ($ln in $Lines) {
@"
        <DataElement>
          <Keys xmlns:a="$arr" />
          <Name>TP_ITEMS.items</Name>
          <Rows><Row><Edits>
            <Edit><Name>oe_order_item_id</Name><Value>$($ln.ItemId)</Value></Edit>
            <Edit><Name>unit_quantity</Name><Value>$($ln.Qty)</Value></Edit>
            <Edit><Name>unit_price</Name><Value>$($ln.Price)</Value></Edit>
          </Edits></Row></Rows>
          <Type>List</Type>
        </DataElement>
"@
    }

@"
<TransactionSet xmlns="$ns" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
  <Name>Order</Name>
  <Transactions>
    <Transaction>
      <DataElements>
        <DataElement>
          <Keys xmlns:a="$arr" />
          <Name>TABPAGE_1.order</Name>
          <Rows><Row><Edits>
            <Edit><Name>customer_id</Name><Value>$CustomerId</Value></Edit>
            <Edit><Name>ship_to_id</Name><Value>$CustomerId</Value></Edit>
            <Edit><Name>sales_loc_id</Name><Value>$LocId</Value></Edit>
          </Edits></Row></Rows>
          <Type>Form</Type>
        </DataElement>
$($lineXml -join "`n")
      </DataElements>
      <Status>New</Status>
    </Transaction>
  </Transactions>
  <UseCodeValues>false</UseCodeValues>
</TransactionSet>
"@
}

function Submit-Order {
    param([string]$Uri, [string]$Token, [string]$Body)

    $headers = @{
        Authorization  = "Bearer $Token"
        'Content-Type' = 'application/xml'
    }
    $raw = Invoke-RestMethod @irmBase -Method Post -Uri $Uri -Headers $headers -Body $Body
    $raw = [string]$raw

    $ok  = [regex]::IsMatch($raw, '<Succeeded>\s*1\s*</Succeeded>') -and
           [regex]::IsMatch($raw, '<Status>\s*Passed\s*</Status>')
    $no  = [regex]::Match($raw, '<Name>\s*order_no\s*</Name>\s*<Value>\s*(\d+)\s*</Value>')
    $msg = [regex]::Match($raw, '<a:string>(.*?)</a:string>', 'Singleline')

    [pscustomobject]@{
        Success = $ok
        OrderNo = $(if ($no.Success) { $no.Groups[1].Value })
        Message = $(if ($msg.Success) { $msg.Groups[1].Value.Trim() })
        Raw     = $raw
    }
}
#endregion

#region --- Main ---------------------------------------------------------------
if (-not $Credential) {
    $Credential = Get-Credential -Message "P21 login for $BaseUrl (domain\user)"
}

Write-Host "Authenticating to $tokenUri ..." -ForegroundColor Cyan
$token = Get-P21Token -Uri $tokenUri -Cred $Credential -Key $AppKey
Write-Host "  token acquired ($($token.Length) chars)" -ForegroundColor DarkGray

# Parse the item pool once
$items = foreach ($p in $ItemPool) {
    $bits = $p.Split(':')
    [pscustomobject]@{ ItemId = $bits[0]; Price = $bits[1] }
}

$results = [System.Collections.Generic.List[object]]::new()

for ($i = 1; $i -le $Count; $i++) {
    $cust      = $CustomerPool | Get-Random
    $lineCount = Get-Random -Minimum 1 -Maximum 3        # 1 or 2 lines
    $lines     = 1..$lineCount | ForEach-Object {
        $it = $items | Get-Random
        [pscustomobject]@{ ItemId = $it.ItemId; Price = $it.Price; Qty = (Get-Random -Minimum 1 -Maximum 6) }
    }
    $body = New-OrderBody -CustomerId $cust -LocId $LocationId -Lines $lines

    if (-not $PSCmdlet.ShouldProcess("$BaseUrl", "create order $i/$Count (customer $cust, $lineCount line(s))")) {
        continue
    }

    try {
        $r = Submit-Order -Uri $txnUri -Token $token -Body $body
    } catch {
        $r = [pscustomobject]@{ Success = $false; OrderNo = $null; Message = $_.Exception.Message; Raw = '' }
    }

    $row = [pscustomobject]@{
        Seq        = $i
        CustomerId = $cust
        Lines      = $lineCount
        Success    = $r.Success
        OrderNo    = $r.OrderNo
        Note       = $(if ($r.Success) { 'created' } else { $r.Message })
        At         = (Get-Date).ToString('s')
    }
    $results.Add($row)

    $color = if ($r.Success) { 'Green' } else { 'Yellow' }
    Write-Host ("[{0,3}/{1}] cust {2}  ->  {3}" -f $i, $Count, $cust,
        $(if ($r.Success) { "order $($r.OrderNo)" } else { "BLOCKED: $($r.Message)" })) -ForegroundColor $color

    if ($i -lt $Count -and $DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
}

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
$results | Format-Table Seq, CustomerId, Lines, Success, OrderNo, Note -AutoSize
$made = @($results | Where-Object Success)
Write-Host ("{0}/{1} created. Order numbers: {2}" -f $made.Count, $Count,
    ($made.OrderNo -join ', ')) -ForegroundColor Cyan

if ($CsvPath) {
    $results | Select-Object Seq, CustomerId, Lines, Success, OrderNo, Note, At |
        Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Run log written to $CsvPath" -ForegroundColor DarkGray
}

# Emit the objects so the caller can pipe them
$results
#endregion

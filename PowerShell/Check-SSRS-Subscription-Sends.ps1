#Requires -Version 7
<#
.SYNOPSIS
    Daily digest of SSRS subscription (scheduled-email / file-share) report sends.

.DESCRIPTION
    Meant to be called once per day from the PowerShell profile on first terminal
    launch. Queries the ReportServer catalog on $Script:SsrsInstance for every
    subscription-driven execution since the last time this script completed, and
    prints, grouped by calendar day:

        * report name + rendered size
        * who received it (email TO / CC / BCC, or the file-share path)
        * any error message (render failures from ExecutionLog, plus the
          point-in-time delivery status from dbo.Subscriptions.LastStatus)

    If one or more days were skipped (weekend, PTO, machine off) each missed day
    gets its own section so a report that silently stopped firing is obvious.

    State (the "last completed run" timestamp) lives in -StateFile as JSON. If the
    last run was earlier *today*, the script does nothing and returns immediately,
    so restarting PowerShell the same day does not re-run it. -Force overrides.

    NOTE ON DELIVERY vs RENDER (see the shared-mail-relay finding):
      ExecutionLog Status = 'rsSuccess' only proves the report *rendered*. The
      SMTP hand-off happens afterwards and is NOT recorded per-send anywhere in
      the catalog DB. dbo.Subscriptions.LastStatus holds the last delivery result
      but is overwritten every run (no history). The only definitive per-send
      delivery record is ReportServerService_<date>.log on the report-server box.

.PARAMETER Since
    Override the window start. Default: the last completed run (or, on the very
    first run, midnight -DaysBack days ago).

.PARAMETER DaysBack
    On the first run only (no state file yet), how many days back to look.
    Default 1.

.PARAMETER Force
    Run even if it already ran today; does not change the stored window logic
    (window still starts at the last completed run).

.PARAMETER Quiet
    Suppress the "already ran today" / "nothing to report" chatter. Intended for
    the profile call so a normal day adds no noise.

.PARAMETER Instance
    ReportServer catalog SQL instance. Defaults to $Script:SsrsInstance, then to
    'ASDWDB01.ahi.local' when run outside the profile.

.PARAMETER StateFile
    Path to the JSON state file. Default C:\_P25\State\SSRS-Subscription-Sends.state.json

.EXAMPLE
    Check-SSRS-Subscription-Sends.ps1
    Normal daily call from the profile.

.EXAMPLE
    Check-SSRS-Subscription-Sends.ps1 -Force -Since '2026-08-20'
    Re-run and show everything back to Aug 20 regardless of state.
#>
[CmdletBinding()]
param(
    [datetime]$Since,
    [int]$DaysBack = 1,
    [switch]$Force,
    [switch]$Quiet,
    [string]$Instance,
    [string]$StateFile = 'C:\_P25\State\SSRS-Subscription-Sends.state.json'
)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
$scriptName = if ($MyInvocation.MyCommand.Name) { $MyInvocation.MyCommand.Name } else { 'Check-SSRS-Subscription-Sends.ps1' }

# Read a variable the profile *may* have set (SsrsInstance, Colors) without
# tripping Set-StrictMode when it hasn't been - works whether this script is
# run with &, dot-sourced, or called from the profile.
function Get-OptionalVar {
    param([string]$Name)
    Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue
}

if (-not $Instance) {
    $fromProfile = Get-OptionalVar 'SsrsInstance'
    $Instance = if ($fromProfile) { [string]$fromProfile } else { 'ASDWDB01.ahi.local' }
}

$profileColors = Get-OptionalVar 'Colors'
$palette = @{ Success = 'Green'; Warning = 'Yellow'; Error = 'Red'; Info = 'Cyan'; Accent = 'Magenta' }
if ($profileColors -is [hashtable]) {
    foreach ($k in $profileColors.Keys) { if ($profileColors[$k]) { $palette[$k] = $profileColors[$k] } }
}
function Say {
    param([string]$Text, [string]$Level = 'Info', [switch]$NoNewline)
    $color = switch ($Level) {
        'Error'   { $palette.Error }
        'Warning' { $palette.Warning }
        'Success' { $palette.Success }
        'Accent'  { $palette.Accent }
        'Muted'   { 'DarkGray' }
        default   { $palette.Info }
    }
    Write-Host $Text -ForegroundColor $color -NoNewline:$NoNewline
}

function Write-RecordLine {
    param([string]$Line)
    try {
        $recDir = 'C:\_P25\Logs\PS-Rec-Of'
        if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir -Force | Out-Null }
        $rec = Join-Path $recDir ($scriptName + (Get-Date).ToString('-yyyyMMdd') + '.txt')
        ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $Line) | Out-File -FilePath $rec -Append -Encoding UTF8
    } catch { }
}

# ---------------------------------------------------------------------------
# Once-per-day guard
# ---------------------------------------------------------------------------
$state = $null
if (Test-Path $StateFile) {
    try { $state = Get-Content -Path $StateFile -Raw | ConvertFrom-Json } catch { $state = $null }
}
# Pull values out defensively so a missing key can't trip Set-StrictMode.
$stateLastRun = $null
$stateWindowStart = $null
if ($state) {
    if ($state.PSObject.Properties['LastRun']     -and $state.LastRun)     { try { $stateLastRun     = [datetime]$state.LastRun }     catch { } }
    if ($state.PSObject.Properties['WindowStart'] -and $state.WindowStart) { try { $stateWindowStart = [datetime]$state.WindowStart } catch { } }
}

$now   = Get-Date
$today = $now.Date

if (-not $Force -and $stateLastRun -and $stateLastRun.Date -eq $today) {
    if (-not $Quiet) {
        Say "SSRS subscription check already ran today ($($stateLastRun.ToString('HH:mm'))). Use -Force to re-run." 'Muted'
    }
    return
}

# ---------------------------------------------------------------------------
# Window
#   normal run   : last completed run  -> now   (then advance state)
#   -Force       : re-show the SAME window as the last run, and do NOT advance
#                  state (so a manual re-run never disturbs the daily cadence
#                  or collapses to an empty window)
#   -Since <dt>  : explicit start, wins over everything; never advances state
# ---------------------------------------------------------------------------
$firstRun     = -not $stateLastRun
$advanceState = $true
if ($Since) {
    $windowStart  = $Since
    $advanceState = $false
} elseif ($Force -and -not $firstRun) {
    $windowStart  = if ($stateWindowStart) { $stateWindowStart } else { $stateLastRun }
    $advanceState = $false
} elseif (-not $firstRun) {
    $windowStart = $stateLastRun
} else {
    $windowStart = $today.AddDays(-[math]::Abs($DaysBack))
}
$windowEnd = $now

if ($windowStart -ge $windowEnd) {
    if (-not $Quiet) { Say "SSRS subscription check: window start is in the future, nothing to do." 'Muted' }
    return
}

$sinceStr = $windowStart.ToString('yyyy-MM-dd HH:mm:ss')
$untilStr = $windowEnd.ToString('yyyy-MM-dd HH:mm:ss')

# ---------------------------------------------------------------------------
# dbatools
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name dbatools)) {
    Say "dbatools module not installed - cannot check SSRS subscriptions. Install-Module dbatools -Scope CurrentUser" 'Warning'
    return
}
Import-Module dbatools -ErrorAction Stop
Set-DbatoolsConfig -FullName sql.connection.encrypt   -Value $false -ErrorAction SilentlyContinue | Out-Null
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true  -ErrorAction SilentlyContinue | Out-Null

# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------
# RequestType 1 = Subscription in dbo.ExecutionLogStorage (the view ExecutionLog3
# spells it 'Subscription'). ExtensionSettings / AdditionalInfo are returned as
# nvarchar so they arrive as plain strings for [xml] parsing on this side.
$sendsQuery = @"
SET NOCOUNT ON;
SELECT
    els.LogEntryId,
    CAST(els.TimeStart AS date)                  AS SendDate,
    c.Path                                       AS ReportPath,
    c.Name                                       AS ReportName,
    els.UserName                                 AS RunAsUser,
    els.Format,
    els.ByteCount,
    els.[RowCount]                               AS RowsInReport,
    els.TimeStart,
    els.TimeEnd,
    DATEDIFF(SECOND, els.TimeStart, els.TimeEnd) AS DurationSec,
    els.Status,
    CONVERT(nvarchar(max), els.AdditionalInfo)   AS AdditionalInfo,
    s.SubscriptionID,
    s.Description                                AS SubscriptionDesc,
    s.DeliveryExtension,
    s.LastStatus                                 AS SubLastStatus,
    s.LastRunTime                               AS SubLastRunTime,
    s.InactiveFlags                             AS SubInactiveFlags,
    CONVERT(nvarchar(max), s.ExtensionSettings)  AS ExtensionSettings,
    ownr.UserName                               AS SubscriptionOwner
FROM dbo.ExecutionLogStorage els
INNER JOIN dbo.Catalog c       ON c.ItemID = els.ReportID
LEFT  JOIN dbo.Subscriptions s ON s.Report_OID = els.ReportID
LEFT  JOIN dbo.Users ownr      ON ownr.UserID = s.OwnerID
WHERE els.RequestType = 1
  AND els.TimeStart >= '$sinceStr'
  AND els.TimeStart <  '$untilStr'
  AND c.Path NOT LIKE '/Datasets/%'
ORDER BY SendDate, els.TimeStart, c.Path, s.SubscriptionID;
"@

# Fallback: supported view, no recipient columns.
$fallbackQuery = @"
SET NOCOUNT ON;
SELECT
    CAST(TimeStart AS date) AS SendDate,
    ItemPath               AS ReportPath,
    ItemPath               AS ReportName,
    UserName              AS RunAsUser,
    Format,
    ByteCount,
    [RowCount]            AS RowsInReport,
    TimeStart,
    TimeEnd,
    Status
FROM dbo.ExecutionLog3
WHERE RequestType = 'Subscription'
  AND TimeStart >= '$sinceStr'
  AND TimeStart <  '$untilStr'
  AND ItemPath NOT LIKE '/Datasets/%'
ORDER BY SendDate, TimeStart, ItemPath;
"@

# Point-in-time delivery status (LastStatus has no history - it is overwritten
# every run). Negative match on the known "good" prefixes so anything unusual
# surfaces.
$statusQuery = @"
SET NOCOUNT ON;
SELECT
    c.Path                                      AS ReportPath,
    c.Name                                      AS ReportName,
    s.Description                               AS SubscriptionDesc,
    s.DeliveryExtension,
    s.LastStatus,
    s.LastRunTime,
    s.InactiveFlags,
    ownr.UserName                              AS SubscriptionOwner
FROM dbo.Subscriptions s
INNER JOIN dbo.Catalog c  ON c.ItemID = s.Report_OID
LEFT  JOIN dbo.Users ownr ON ownr.UserID = s.OwnerID
WHERE ISNULL(s.LastStatus, N'') <> N''
  AND s.LastStatus NOT LIKE N'Mail sent%'
  AND s.LastStatus NOT LIKE N'The file%saved to the file share%'
  AND s.LastStatus NOT LIKE N'New Subscription%'
  AND s.LastStatus NOT LIKE N'%disabled%'
  AND s.LastRunTime >= '$sinceStr'
ORDER BY s.LastRunTime DESC;
"@

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
$recipientsAvailable = $true
$rows = $null
try {
    $rows = Invoke-DbaQuery -SqlInstance $Instance -Database ReportServer -Query $sendsQuery -As PSObject -EnableException
} catch {
    Say "Detailed query failed ($($_.Exception.Message.Trim())) - falling back to ExecutionLog3 without recipients." 'Warning'
    Write-RecordLine "Detailed query failed: $($_.Exception.Message.Trim())"
    $recipientsAvailable = $false
    try {
        $rows = Invoke-DbaQuery -SqlInstance $Instance -Database ReportServer -Query $fallbackQuery -As PSObject -EnableException
    } catch {
        Say "SSRS subscription check failed: $($_.Exception.Message.Trim())" 'Error'
        Write-RecordLine "FAILED (fallback too): $($_.Exception.Message.Trim())"
        return   # do not advance state - the window is retried next launch
    }
}

$statusRows = @()
try {
    $statusRows = @(Invoke-DbaQuery -SqlInstance $Instance -Database ReportServer -Query $statusQuery -As PSObject -EnableException)
} catch { }

$queuedNote = $null
try {
    $q = Invoke-DbaQuery -SqlInstance $Instance -Database ReportServer -As PSObject -EnableException `
         -Query "SET NOCOUNT ON; SELECT COUNT(*) AS Queued FROM dbo.Notifications;"
    if ($q -and [int]$q.Queued -gt 0) { $queuedNote = [int]$q.Queued }
} catch { }

# ---------------------------------------------------------------------------
# Helpers for shaping output
# ---------------------------------------------------------------------------
function Format-Size {
    param($Bytes)
    if ($null -eq $Bytes -or $Bytes -eq [DBNull]::Value) { return '     -   ' }
    $b = [double]$Bytes
    if ($b -ge 1MB) { return ('{0,7:N2} MB' -f ($b / 1MB)) }
    if ($b -ge 1KB) { return ('{0,7:N1} KB' -f ($b / 1KB)) }
    return ('{0,7} B ' -f [long]$b)
}

function Format-AddrList {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $parts = $Text -split '[;,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if (-not $parts) { return $null }
    return ($parts -join '; ')
}

function Get-Recipients {
    param([string]$Xml, [string]$DeliveryExtension)
    if ([string]::IsNullOrWhiteSpace($Xml)) { return $null }
    $doc = $null
    try { $doc = [xml]$Xml } catch { return $null }

    $pv = @{}
    foreach ($n in $doc.SelectNodes('//ParameterValue')) {
        if ($n.Name) { $pv[[string]$n.Name] = [string]$n.Value }
    }
    # Data-driven subscriptions store <Field> mappings, not literal values.
    if ($pv.Count -eq 0 -and $doc.SelectSingleNode('//Field')) {
        return [pscustomobject]@{ Kind = 'DataDriven'; RenderFormat = $null }
    }
    if ($pv.ContainsKey('TO') -or $pv.ContainsKey('CC') -or $pv.ContainsKey('BCC')) {
        return [pscustomobject]@{
            Kind         = 'Email'
            To           = (Format-AddrList $pv['TO'])
            Cc           = (Format-AddrList $pv['CC'])
            Bcc          = (Format-AddrList $pv['BCC'])
            RenderFormat = $pv['RenderFormat']
        }
    }
    if ($pv.ContainsKey('PATH')) {
        $full = $pv['PATH']
        if ($pv['FILENAME']) { $full = ($pv['PATH'].TrimEnd('\') + '\' + $pv['FILENAME']) }
        return [pscustomobject]@{ Kind = 'FileShare'; Path = $full; RenderFormat = $pv['RENDER_FORMAT'] }
    }
    if ($DeliveryExtension -eq 'Report Server NULL Delivery Provider' -or $DeliveryExtension -match 'NULL') {
        return [pscustomobject]@{ Kind = 'Null' }
    }
    return [pscustomobject]@{ Kind = 'Other'; Keys = ($pv.Keys -join ', ') }
}

function Get-RenderException {
    param([string]$Xml)
    if ([string]::IsNullOrWhiteSpace($Xml)) { return $null }
    try { $doc = [xml]$Xml } catch { return $null }
    $ex = $doc.SelectSingleNode('//Exception')
    if ($ex) {
        $txt = if ($ex.InnerText) { $ex.InnerText } else { $ex.OuterXml }
        return ($txt -replace '\s+', ' ').Trim()
    }
    return $null
}

function Test-StatusOk {
    param([string]$Status)
    return ($Status -eq 'rsSuccess' -or [string]::IsNullOrWhiteSpace($Status))
}

# ExecutionLogStorage has no SubscriptionID, so a report's runs can't be tied to
# an exact subscription. Narrow the candidate list: drop disabled subscriptions,
# then keep only those whose delivery render format matches this execution's
# format. Returns the narrowed list plus a confidence label.
function Select-FiringSubs {
    param($AllSubs, [string]$ExecFormat)
    $result = [pscustomobject]@{ Subs = @(); Confidence = 'none' }
    if (-not $AllSubs -or @($AllSubs).Count -eq 0) { return $result }

    $active = @($AllSubs | Where-Object { -not $_.Inactive })
    $pool   = if ($active.Count -gt 0) { $active } else { @($AllSubs) }

    if ($ExecFormat) {
        $fmt = @($pool | Where-Object {
            $_.Recipients -and $_.Recipients.RenderFormat -and
            ($_.Recipients.RenderFormat -replace '\s','') -ieq ($ExecFormat -replace '\s','')
        })
        if ($fmt.Count -eq 1) { $result.Subs = $fmt;  $result.Confidence = 'exact';  return $result }
        if ($fmt.Count -gt 1) { $result.Subs = $fmt;  $result.Confidence = 'format'; return $result }
    }
    if ($pool.Count -eq 1) { $result.Subs = $pool; $result.Confidence = 'single'; return $result }
    $result.Subs = $pool
    $result.Confidence = 'all'
    return $result
}

# ---------------------------------------------------------------------------
# Collapse rows -> one object per execution (a report can have >1 subscription)
# ---------------------------------------------------------------------------
$execs = foreach ($grp in ($rows | Group-Object LogEntryId)) {
    $r = $grp.Group[0]

    $subs = @()
    if ($recipientsAvailable) {
        $subs = $grp.Group |
            Where-Object { $_.SubscriptionID -and $_.SubscriptionID -ne [DBNull]::Value } |
            Sort-Object SubscriptionID -Unique |
            ForEach-Object {
                [pscustomobject]@{
                    SubscriptionID = $_.SubscriptionID
                    Description    = ("$($_.SubscriptionDesc)").Trim()
                    Owner          = "$($_.SubscriptionOwner)"
                    Delivery       = "$($_.DeliveryExtension)"
                    Inactive       = ($_.SubInactiveFlags -and "$($_.SubInactiveFlags)" -ne '0')
                    Recipients     = (Get-Recipients -Xml $_.ExtensionSettings -DeliveryExtension "$($_.DeliveryExtension)")
                }
            }
    }

    [pscustomobject]@{
        SendDate   = [datetime]$r.SendDate
        ReportName = if ("$($r.ReportName)".StartsWith('/')) { Split-Path "$($r.ReportName)" -Leaf } else { "$($r.ReportName)" }
        ReportPath = "$($r.ReportPath)"
        RunAsUser  = "$($r.RunAsUser)"
        Format     = "$($r.Format)"
        ByteCount  = if ($r.ByteCount -eq [DBNull]::Value) { $null } else { $r.ByteCount }
        Rows       = if ($r.RowsInReport -eq [DBNull]::Value) { $null } else { $r.RowsInReport }
        TimeStart  = [datetime]$r.TimeStart
        DurationSec = if ($r.PSObject.Properties['DurationSec']) { $r.DurationSec } else { $null }
        Status     = "$($r.Status)"
        RenderError = if ($r.PSObject.Properties['AdditionalInfo']) { Get-RenderException -Xml $r.AdditionalInfo } else { $null }
        Subs       = $subs
    }
}
$execs = @($execs | Sort-Object TimeStart)

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
$errCount = @($execs | Where-Object { -not (Test-StatusOk $_.Status) }).Count
$dayCount = [int]([math]::Floor(($today - $windowStart.Date).TotalDays)) + 1
$bar = ('=' * 70)

if ($execs.Count -eq 0 -and $statusRows.Count -eq 0 -and $Quiet) {
    # Nothing at all and running silently from the profile: still advance state.
} else {
    Write-Host ''
    Say $bar 'Accent'
    Say ' SSRS Subscription Sends' 'Accent'
    $gap = if ($dayCount -gt 1) { "   ($dayCount days)" } else { '' }
    Say (' Window : {0}  ->  {1}{2}' -f $windowStart.ToString('yyyy-MM-dd HH:mm'), $windowEnd.ToString('yyyy-MM-dd HH:mm'), $gap)
    if ($firstRun) {
        Say (' Last   : first run - showing the last {0} day(s)' -f [math]::Abs($DaysBack))
    } else {
        Say (' Last   : {0}' -f $stateLastRun.ToString('yyyy-MM-dd HH:mm'))
    }
    Say (' Source : {0}\ReportServer   ({1} send(s), {2} render error(s))' -f $Instance, $execs.Count, $errCount)
    if (-not $recipientsAvailable) {
        Say ' NOTE   : recipient columns unavailable - fell back to ExecutionLog3' 'Warning'
    }
    Say $bar 'Accent'

    # One section per calendar day in the window, missed days included.
    for ($d = $windowStart.Date; $d -le $today; $d = $d.AddDays(1)) {
        $dayExecs = @($execs | Where-Object { $_.SendDate -eq $d })
        Write-Host ''
        Say ('-- {0} {1}' -f $d.ToString('dddd'), $d.ToString('yyyy-MM-dd')) 'Accent'

        if ($dayExecs.Count -eq 0) {
            if ($d -eq $today) {
                Say '   (nothing yet today - scheduled reports may still be pending)' 'Muted'
            } else {
                Say '   (no subscription sends recorded - if a report was expected, its schedule may not have fired)' 'Warning'
            }
            continue
        }

        foreach ($e in $dayExecs) {
            $ok = Test-StatusOk $e.Status
            $nameCol = if ($e.ReportName.Length -gt 42) { $e.ReportName.Substring(0, 41) + [char]0x2026 } else { $e.ReportName.PadRight(42) }
            $statusLbl = if ($ok) { 'OK' } else { "ERROR $($e.Status)" }

            Say ('  {0} {1}  {2,-14} {3}  ' -f $nameCol, (Format-Size $e.ByteCount), $e.Format, $e.TimeStart.ToString('HH:mm:ss')) -NoNewline
            Say $statusLbl $(if ($ok) { 'Success' } else { 'Error' })

            # mail-relay risk (a >20 MB attachment has hung the corporate relay before)
            if ($ok -and $e.ByteCount -and [double]$e.ByteCount -ge 20MB) {
                Say ('       (!) {0:N1} MB rendered - large enough to stall the mail relay; the email attachment is ~33% bigger again' -f ([double]$e.ByteCount / 1MB)) 'Warning'
            }
            # empty render
            if ($ok -and ($null -eq $e.ByteCount -or [double]$e.ByteCount -eq 0)) {
                Say '       (!) rendered 0 bytes - check the report is not returning an empty set' 'Warning'
            }

            # recipients
            if (-not $recipientsAvailable) {
                # fallback query - no subscription/recipient data at all
            }
            elseif ($e.Subs.Count -eq 0) {
                Say '       -> (no subscription row found for this report - it may have been deleted since the send)' 'Muted'
            }
            else {
                $pick = Select-FiringSubs -AllSubs $e.Subs -ExecFormat $e.Format

                # Collapse subscriptions that deliver to the same place so an
                # identical recipient set is not printed two or three times.
                $dedup = $pick.Subs | Group-Object {
                    $rc = $_.Recipients
                    if     ($null -eq $rc)            { 'x' }
                    elseif ($rc.Kind -eq 'Email')     { "E|$($rc.To)|$($rc.Cc)|$($rc.Bcc)" }
                    elseif ($rc.Kind -eq 'FileShare') { "F|$($rc.Path)" }
                    else                              { $rc.Kind }
                }

                $ambiguous = $pick.Confidence -in @('format', 'all')

                # A per-location report can have dozens of subscriptions on one
                # format; only one fired but the log can't say which. Don't dump
                # the whole roster into a daily digest - summarise instead.
                if ($ambiguous -and $dedup.Count -gt 6) {
                    # A per-location report can have dozens of subscriptions on one
                    # format; only one fired but the log can't say which. Summarise
                    # rather than dumping the whole roster into a daily digest.
                    $allNames = @($pick.Subs | ForEach-Object { $_.Description } | Where-Object { $_ } | Select-Object -Unique)
                    Say ("       -> one of {0} subscriptions on this report fired ({1} distinct recipient sets) - the log doesn't record which." -f @($pick.Subs).Count, $dedup.Count) 'Muted'
                    Say ("          e.g. {0}{1}" -f (($allNames | Select-Object -First 3) -join ' / '), $(if ($allNames.Count -gt 3) { " (+$($allNames.Count - 3) more)" } else { '' })) 'Muted'
                    Say '          full roster: SSRS portal > Manage > Subscriptions' 'Muted'
                }
                else {
                    if ($pick.Confidence -eq 'format' -and $dedup.Count -gt 1) {
                        Say ("       ({0} candidate subscriptions render this format - the exact one that fired isn't recorded)" -f $dedup.Count) 'Muted'
                    }
                    elseif ($pick.Confidence -eq 'all' -and $dedup.Count -gt 1) {
                        Say ("       ({0} subscriptions on this report, none matched the send format - showing all)" -f $dedup.Count) 'Muted'
                    }

                    foreach ($g in $dedup) {
                        $s  = $g.Group[0]
                        $rc = $s.Recipients
                        $names = @($g.Group | ForEach-Object { if ($_.Description) { $_.Description } elseif ($_.Owner) { "owner $($_.Owner)" } } | Where-Object { $_ } | Select-Object -Unique)
                        $tag = if ($names) { ' [' + ($names -join ' / ') + ']' } else { '' }

                        if ($null -eq $rc) {
                            Say ("       -> (recipients not readable){0}" -f $tag) 'Muted'
                        }
                        elseif ($rc.Kind -eq 'Email') {
                            $line = "       -> $($rc.To)"
                            if ($rc.Cc)  { $line += "  (cc: $($rc.Cc))" }
                            if ($rc.Bcc) { $line += "  (bcc: $($rc.Bcc))" }
                            Say ($line + $tag)
                        }
                        elseif ($rc.Kind -eq 'FileShare') {
                            Say ("       -> file share: $($rc.Path)$tag")
                        }
                        elseif ($rc.Kind -eq 'DataDriven') {
                            Say ("       -> data-driven subscription - recipients resolved at run time from its query$tag") 'Muted'
                        }
                        elseif ($rc.Kind -eq 'Null') {
                            Say ("       -> null delivery (no email/file - cache or trigger only)$tag") 'Muted'
                        }
                        else {
                            Say ("       -> $($s.Delivery)$tag") 'Muted'
                        }
                        if ($g.Group[0].Inactive -and @($g.Group | Where-Object { -not $_.Inactive }).Count -eq 0) {
                            Say '          (subscription currently disabled)' 'Muted'
                        }
                    }
                }
            }

            # render error detail
            if (-not $ok) {
                $detail = if ($e.RenderError) { $e.RenderError } else { "Status $($e.Status) (no exception text in the log)" }
                Say ("       error: {0}" -f $detail) 'Error'
            }
        }
    }

    # summary line
    if ($execs.Count -gt 0) {
        $largest = $execs | Sort-Object { [double]($_.ByteCount) } -Descending | Select-Object -First 1
        Write-Host ''
        Say ('   {0} send(s) over {1} day(s); {2} render error(s); largest {3} ({4})' -f `
             $execs.Count, $dayCount, $errCount, (Format-Size $largest.ByteCount).Trim(), $largest.ReportName) 'Muted'
    }

    # -------------------------------------------------------------------
    # Delivery status (point-in-time) - catches SMTP failures the
    # ExecutionLog never sees. LastStatus is overwritten every run.
    # -------------------------------------------------------------------
    if ($statusRows.Count -gt 0) {
        Write-Host ''
        Say '-- Delivery status flags (dbo.Subscriptions.LastStatus - point-in-time, overwritten each run)' 'Accent'
        foreach ($sr in $statusRows) {
            $nm = if ("$($sr.ReportName)") { "$($sr.ReportName)" } else { Split-Path "$($sr.ReportPath)" -Leaf }
            $desc = ("$($sr.SubscriptionDesc)").Trim()
            $when = if ($sr.LastRunTime -and $sr.LastRunTime -ne [DBNull]::Value) { ([datetime]$sr.LastRunTime).ToString('yyyy-MM-dd HH:mm') } else { '?' }
            Say ("  {0}{1}" -f $nm, $(if ($desc) { " [$desc]" } else { '' })) 'Warning'
            Say ("     {0}   (last run {1}, owner {2})" -f ("$($sr.LastStatus)").Trim(), $when, $sr.SubscriptionOwner)
        }
        Say '  (verify a genuine failure against ReportServerService_<date>.log on the report-server box)' 'Muted'
    }

    if ($queuedNote) {
        Write-Host ''
        Say ("$queuedNote notification(s) are currently sitting in dbo.Notifications (delivery queue) - may indicate a stalled relay.") 'Warning'
    }

    Write-Host ''
}

# ---------------------------------------------------------------------------
# Advance state - only when the query succeeded AND this was a real daily run
# (a -Force / -Since run reproduces a window and must not move the cadence).
# ---------------------------------------------------------------------------
if ($advanceState) {
    try {
        $stateDir = Split-Path -Path $StateFile -Parent
        if ($stateDir -and -not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
        [pscustomobject]@{
            LastRun      = $windowEnd.ToString('o')
            WindowStart  = $windowStart.ToString('o')
            SendsSeen    = $execs.Count
            RenderErrors = $errCount
            StatusFlags  = $statusRows.Count
            Instance     = $Instance
            Host         = $env:COMPUTERNAME
            Script       = $scriptName
        } | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
    } catch {
        Say "SSRS check ran but could not write state file ($StateFile): $($_.Exception.Message.Trim())" 'Warning'
    }
}

Write-RecordLine ("window {0} -> {1} | {2} send(s), {3} render error(s), {4} status flag(s)" -f $sinceStr, $untilStr, $execs.Count, $errCount, $statusRows.Count)

try {
    $master = 'C:\_P25\Logs\Record-of-' + $env:COMPUTERNAME + '-VC-Scripts-Ran-' + (Get-Date).ToString('yyyyMM') + '.txt'
    ((Get-Date -Format 'yyyy-MM-dd HH:mm') + ' ' + $scriptName + " ($($execs.Count) sends, $errCount errors)") | Out-File -FilePath $master -Append -Encoding UTF8
} catch { }

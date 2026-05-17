#Requires -Version 7.0
<#
.SYNOPSIS
    Polls Ticketmaster for Panthers vs Seahawks ticket availability on 2027-01-03.
.DESCRIPTION
    Searches the Ticketmaster Discovery API v2 for the game, reports status and
    price ranges, and re-polls on a configurable interval. Alerts to console
    (and optionally a log file) whenever status changes.
.PARAMETER ApiKey
    Your Ticketmaster Discovery API key.
.PARAMETER PollIntervalMinutes
    How often to re-poll (default: 60 minutes).
.PARAMETER LogPath
    Optional path for a log file. Defaults to no file logging.
.PARAMETER RunOnce
    Switch — poll once and exit. Useful for testing or scheduled tasks.
.EXAMPLE
    .\Get-NFLTicketAvailability.ps1 -ApiKey "abc123" -PollIntervalMinutes 30
.EXAMPLE
    .\Get-NFLTicketAvailability.ps1 -ApiKey "abc123" -RunOnce
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ApiKey,

    [int]$PollIntervalMinutes = 60,

    [string]$LogPath = "",

    [switch]$RunOnce
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$GameDate     = '2027-01-03'
$StartDT      = "${GameDate}T00:00:00Z"
$EndDT        = "${GameDate}T23:59:59Z"
$BaseUrl      = 'https://app.ticketmaster.com/discovery/v2/events.json'
$StatusFile   = Join-Path $PSScriptRoot 'nfl_poll_laststate.json'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    switch ($Level) {
        'ALERT' { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red    }
        default { Write-Host $line -ForegroundColor Cyan   }
    }
    if ($LogPath) { Add-Content -Path $LogPath -Value $line }
}

function Get-GameEvent {
    $params = @{
        apikey             = $ApiKey
        keyword            = 'Panthers Seahawks'
        classificationName = 'Football'
        countryCode        = 'US'
        startDateTime      = $StartDT
        endDateTime        = $EndDT
        size               = 5
    }
    $query = ($params.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$([Uri]::EscapeDataString($_.Value))"
    }) -join '&'

    $uri      = "${BaseUrl}?${query}"
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 15

    $events = $response._embedded.events
    if (-not $events) { return $null }

    # Prefer an event whose name contains both team names
    $game = $events | Where-Object {
        $_.name -match 'Panthers' -and $_.name -match 'Seahawks'
    } | Select-Object -First 1

    # Fall back to any Panthers or Seahawks event on that date
    if (-not $game) {
        $game = $events | Where-Object {
            $_.name -match 'Panthers' -or $_.name -match 'Seahawks'
        } | Select-Object -First 1
    }

    return $game
}

function Format-EventSummary {
    param($Event)

    $status     = if ($Event.PSObject.Properties['dates'])         { $Event.dates.status.code }                          else { 'unknown' }
    $salStart   = if ($Event.PSObject.Properties['sales'])         { $Event.sales.public.startDateTime }                 else { 'N/A' }
    $salEnd     = if ($Event.PSObject.Properties['sales'])         { $Event.sales.public.endDateTime }                   else { 'N/A' }
    $priceRange = if ($Event.PSObject.Properties['priceRanges'])   { $Event.priceRanges | Select-Object -First 1 }       else { $null }
    $priceMin   = if ($priceRange) { $priceRange.min }      else { 'N/A' }
    $priceMax   = if ($priceRange) { $priceRange.max }      else { 'N/A' }
    $currency   = if ($priceRange) { $priceRange.currency } else { '' }
    $url        = if ($Event.PSObject.Properties['url'])           { $Event.url }                                        else { 'N/A' }

    return [PSCustomObject]@{
        EventId    = $Event.id
        Name       = $Event.name
        Status     = $status
        SaleStart  = $salStart
        SaleEnd    = $salEnd
        PriceMin   = if ($priceMin -ne 'N/A') { "$currency $priceMin" } else { 'N/A' }
        PriceMax   = if ($priceMax -ne 'N/A') { "$currency $priceMax" } else { 'N/A' }
        Url        = $url
        PolledAt   = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
}

function Get-LastState {
    if (Test-Path $StatusFile) {
        return Get-Content $StatusFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-State {
    param($Summary)
    $Summary | ConvertTo-Json | Set-Content $StatusFile
}

function Show-Summary {
    param($Summary)
    Write-Log "--- Event Found ---"
    Write-Log "  Name      : $($Summary.Name)"
    Write-Log "  Status    : $($Summary.Status)"
    Write-Log "  Sale Open : $($Summary.SaleStart)"
    Write-Log "  Sale Close: $($Summary.SaleEnd)"
    Write-Log "  Price     : $($Summary.PriceMin) - $($Summary.PriceMax)"
    Write-Log "  Buy URL   : $($Summary.Url)"
    Write-Log "-------------------"
}

function Invoke-Poll {
    Write-Log "Polling Ticketmaster for Panthers vs Seahawks ($GameDate)..."

    try {
        $event = Get-GameEvent
    } catch {
        Write-Log "API call failed: $_" -Level ERROR
        return
    }

    if (-not $event) {
        Write-Log "No matching event found yet. The game may not be listed yet." -Level ALERT
        return
    }

    $summary   = Format-EventSummary -Event $event
    $lastState = Get-LastState

    # Detect changes
    if ($lastState) {
        if ($lastState.Status -ne $summary.Status) {
            Write-Log "STATUS CHANGED: $($lastState.Status) --> $($summary.Status)" -Level ALERT
        }
        if ($lastState.PriceMin -ne $summary.PriceMin -or $lastState.PriceMax -ne $summary.PriceMax) {
            Write-Log "PRICE CHANGED: [$($lastState.PriceMin) - $($lastState.PriceMax)] --> [$($summary.PriceMin) - $($summary.PriceMax)]" -Level ALERT
        }
    } else {
        Write-Log "First poll — establishing baseline state."
    }

    Show-Summary -Summary $summary
    Save-State -Summary $summary
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
Write-Log "NFL Ticket Availability Poller started. Game: Panthers vs Seahawks, $GameDate"
Write-Log "Interval: $PollIntervalMinutes min | RunOnce: $RunOnce | Log: $(if ($LogPath) { $LogPath } else { 'none' })"

if ($RunOnce) {
    Invoke-Poll
    exit 0
}

while ($true) {
    Invoke-Poll
    Write-Log "Next poll in $PollIntervalMinutes minutes. Press Ctrl+C to stop."
    Start-Sleep -Seconds ($PollIntervalMinutes * 60)
}

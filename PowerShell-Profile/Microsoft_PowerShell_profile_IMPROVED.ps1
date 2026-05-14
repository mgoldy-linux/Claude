<#
.SYNOPSIS
    PowerShell Terminal Profile for user mgoldyn
    
.DESCRIPTION
    Custom PowerShell profile with utilities, functions, and environment setup
    Automatically loads on PowerShell Terminal startup
    
.NOTES
    Author: mgoldyn
    Last Updated: $(Get-Date -Format 'yyyy-MM-dd')
    Profile Type: Terminal
#>

#region Profile Configuration
# Use strict mode for better error detection
Set-StrictMode -Version Latest

# Profile metadata
$Script:ProfileVersion = "2.0"
$Script:ProfileLoadStart = Get-Date

# Suppress progress bars for faster module loading
$ProgressPreference = 'SilentlyContinue'
#endregion

#region Environment Variables
try {
    # Core variables
    $Script:PC_Name = $env:COMPUTERNAME
    $Script:User = $env:USERNAME
    $Script:myPsHome = Split-Path -Path $PROFILE -Parent
    $Script:fDate = (Get-Date).ToString("-yyyyMMdd")
    if ($Script:fDate -ne (Get-Date).ToString("-yyyyMMdd")) {
        Write-Warning "fDate mismatch: $Script:fDate vs expected $((Get-Date).ToString('-yyyyMMdd'))"
    }
    $Script:PSVer = $PSVersionTable.PSVersion.ToString()
    $Script:app = 'Terminal'
    
    # Path configurations
    $Script:BaseTranscriptPath = "C:\_P25\PST\Script-Transcripts"
    $Script:TranscriptPath = Join-Path $BaseTranscriptPath "$PSVer\$app"
    $Script:RecordPath = Join-Path $BaseTranscriptPath "Record-of-$PC_Name-Terminal-Scripts-Ran.txt"
    
    # SQL Server instances
    $Script:SqlInst22 = 'DESKTOP-2ELUN3U'
    $Script:SqlInst19 = 'DESKTOP-2ELUN3U\SQLEXPRESS'
    
    # Color scheme for console
    $Script:Colors = @{
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
        Info    = 'Cyan'
        Accent  = 'Magenta'
    }
}
catch {
    Write-Warning "Error initializing profile variables: $_"
}
#endregion

#region Helper Functions

function Write-ProfileLog {
    <#
    .SYNOPSIS
        Writes a message to the profile log with timestamp
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        'Error'   { $Script:Colors.Error }
        'Warning' { $Script:Colors.Warning }
        'Success' { $Script:Colors.Success }
        default   { $Script:Colors.Info }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # File output (safe - don't fail profile if logging fails)
    try {
        if ($Script:RecordPath) {
            $logEntry | Out-File -FilePath $Script:RecordPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Silently continue if logging fails
    }
}

function Test-IsAdministrator {
    <#
    .SYNOPSIS
        Checks if the current session has administrator privileges
    #>
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-GitBranch {
    <#
    .SYNOPSIS
        Gets the current Git branch if in a Git repository
    #>
    try {
        $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($gitBranch) {
            return " [$gitBranch]"
        }
    }
    catch {
        # Not in a git repo or git not available
    }
    return ""
}

#endregion

#region Custom Functions

function Set-Profile {
    <#
    .SYNOPSIS
        Opens the PowerShell profile in the default editor
    .DESCRIPTION
        Opens the current PowerShell profile for editing in Notepad++ if available,
        otherwise uses notepad or VSCode
    #>
    [CmdletBinding()]
    param()
    
    $editors = @(
        @{Path = 'C:\Program Files\Notepad++\notepad++.exe'; Args = $PROFILE},
        @{Path = 'code'; Args = $PROFILE},
        @{Path = 'notepad.exe'; Args = $PROFILE}
    )
    
    foreach ($editor in $editors) {
        if (Get-Command $editor.Path -ErrorAction SilentlyContinue) {
            & $editor.Path $editor.Args
            return
        }
    }
    
    Write-Warning "No suitable editor found. Opening with default application."
    Invoke-Item $PROFILE
}

function Prompt {
    <#
    .SYNOPSIS
        Custom prompt with computer name, path, and Git branch
    #>
    $isAdmin = Test-IsAdministrator
    $adminMarker = if ($isAdmin) { " [ADMIN]" } else { "" }
    $gitBranch = Get-GitBranch
    $currentPath = $executionContext.SessionState.Path.CurrentLocation
    
    # Shorten long paths
    $pathDisplay = if ($currentPath.Path.Length -gt 50) {
        "...\" + (Split-Path $currentPath.Path -Leaf)
    } else {
        $currentPath.Path
    }
    
    # Color-code based on admin status
    $promptColor = if ($isAdmin) { $Script:Colors.Error } else { $Script:Colors.Success }
    
    Write-Host "PS" -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$adminMarker" -NoNewline -ForegroundColor $Script:Colors.Warning
    Write-Host " [$env:COMPUTERNAME]" -NoNewline -ForegroundColor $promptColor
    Write-Host "$gitBranch " -NoNewline -ForegroundColor $Script:Colors.Accent
    Write-Host "$pathDisplay" -ForegroundColor $Script:Colors.Info
    
    return "> "
}

function Get-ErrorDetails {
    <#
    .SYNOPSIS
        Displays detailed information about the last error
    .DESCRIPTION
        Enhanced error reporting with line numbers, script path, and full exception details
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ScriptName = "Unknown Script",
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $Error[0]
    )
    
    if (-not $ErrorRecord) {
        Write-Host "No errors in the error buffer" -ForegroundColor Green
        return
    }
    
    $separator = "=" * 80
    
    Write-Host "`n$separator" -ForegroundColor $Script:Colors.Error
    Write-Host "ERROR DETAILS" -ForegroundColor $Script:Colors.Error
    Write-Host $separator -ForegroundColor $Script:Colors.Error
    
    Write-Host "`nScript Name:    " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host $ScriptName
    
    if ($ErrorRecord.InvocationInfo.ScriptName) {
        Write-Host "Script Path:    " -NoNewline -ForegroundColor $Script:Colors.Info
        Write-Host $ErrorRecord.InvocationInfo.ScriptName
    }
    
    Write-Host "Line Number:    " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host $ErrorRecord.InvocationInfo.ScriptLineNumber
    
    Write-Host "Error Message:  " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host $ErrorRecord.Exception.Message
    
    Write-Host "`nException Type: " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host $ErrorRecord.Exception.GetType().FullName
    
    if ($ErrorRecord.ScriptStackTrace) {
        Write-Host "`nStack Trace:" -ForegroundColor $Script:Colors.Info
        Write-Host $ErrorRecord.ScriptStackTrace -ForegroundColor Gray
    }
    
    Write-Host "`n$separator`n" -ForegroundColor $Script:Colors.Error
}

# Alias for backward compatibility
function Custom-ErrorMsg([string]$SName) {
    Get-ErrorDetails -ScriptName $SName
}

function Get-WeekNumber {
    <#
    .SYNOPSIS
        Gets the ISO week number for a given date
    .DESCRIPTION
        Returns the week number (1-53) according to ISO 8601 standard
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [datetime]$DateTime = (Get-Date)
    )
    
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $weekNumber = $cultureInfo.Calendar.GetWeekOfYear(
        $DateTime,
        $cultureInfo.DateTimeFormat.CalendarWeekRule,
        $cultureInfo.DateTimeFormat.FirstDayOfWeek
    )
    
    return $weekNumber
}

function Get-TotalWeekDays {
    <#
    .SYNOPSIS
        Get total number of week days between two dates
    .DESCRIPTION
        Return the number of days between two dates not counting Saturday and Sunday.
    .PARAMETER Start
        The starting date
    .PARAMETER End
        The ending date
    .EXAMPLE
        Get-TotalWeekDays -Start '7/1/2024' -End '7/31/2024'
        23
    .OUTPUTS
        Integer - Number of weekdays
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, HelpMessage="What is the start date?")]
        [ValidateNotNullOrEmpty()]
        [DateTime]$Start,
        
        [Parameter(Position=1, Mandatory=$true, HelpMessage="What is the end date?")]
        [ValidateNotNullOrEmpty()]
        [DateTime]$End
    )
    
    Write-Verbose "Starting $($myinvocation.mycommand)"
    Write-Verbose "Calculating number of week days between $Start and $End"
    
    # Validate date order
    if ($End -lt $Start) {
        Write-Error "End date must be greater than or equal to Start date"
        return
    }
    
    $weekdayCount = 0
    
    for ($date = $Start; $date -le $End; $date = $date.AddDays(1)) {
        if ($date.DayOfWeek -notin @('Saturday', 'Sunday')) {
            $weekdayCount++
        }
        else {
            Write-Verbose ("{0:yyyy-MM-dd} is {1}" -f $date, $date.DayOfWeek)
        }
    }
    
    Write-Verbose "Total weekdays: $weekdayCount"
    Write-Verbose "Ending $($myinvocation.mycommand)"
    
    return $weekdayCount
}

function Get-DirectorySize {
    <#
    .SYNOPSIS
        Gets the total size of a directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = (Get-Location).Path
    )
    
    $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum).Sum
    
    # Format size
    $sizes = 'Bytes', 'KB', 'MB', 'GB', 'TB'
    $order = 0
    $value = $size
    
    while ($value -ge 1024 -and $order -lt ($sizes.Count - 1)) {
        $value = $value / 1024
        $order++
    }
    
    return "{0:N2} {1}" -f $value, $sizes[$order]
}

function Connect-SQLServer {
    <#
    .SYNOPSIS
        Connects to SQL Server using dbatools
    .PARAMETER Instance
        SQL Server instance name
    .EXAMPLE
        Connect-SQLServer -Instance $SqlInst22
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Instance = $Script:SqlInst22
    )
    
    try {
        $server = Connect-DbaInstance -SqlInstance $Instance
        Write-Host "Connected to SQL Server: $Instance" -ForegroundColor Green
        return $server
    }
    catch {
        Write-Error "Failed to connect to SQL Server: $_"
    }
}

function Update-ProfileModules {
    <#
    .SYNOPSIS
        Updates commonly used modules
    #>
    [CmdletBinding()]
    param()
    
    $modules = @('dbatools', 'SqlServer', 'ImportExcel', 'PSReadLine')
    
    Write-Host "`nChecking for module updates..." -ForegroundColor Cyan
    
    foreach ($module in $modules) {
        try {
            $installed = Get-InstalledModule -Name $module -ErrorAction SilentlyContinue
            if ($installed) {
                $online = Find-Module -Name $module -ErrorAction Stop
                
                if ($online.Version -gt $installed.Version) {
                    Write-Host "  $module : $($installed.Version) -> $($online.Version) [Update Available]" -ForegroundColor Yellow
                }
                else {
                    Write-Host "  $module : $($installed.Version) [Up to date]" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  $module : Not installed" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "  $module : Error checking version" -ForegroundColor Red
        }
    }
}

function Show-ProfileHelp {
    <#
    .SYNOPSIS
        Shows available custom functions and aliases
    #>
    Write-Host "`n=== Custom PowerShell Profile Functions ===" -ForegroundColor Cyan
    Write-Host "`nProfile Management:" -ForegroundColor Yellow
    Write-Host "  Set-Profile              - Edit this profile"
    Write-Host "  Show-ProfileHelp         - Display this help"
    Write-Host "  Update-ProfileModules    - Check for module updates"
    
    Write-Host "`nError Handling:" -ForegroundColor Yellow
    Write-Host "  Get-ErrorDetails         - Show detailed error information"
    Write-Host "  Custom-ErrorMsg          - Legacy error message function"
    
    Write-Host "`nDate/Time Utilities:" -ForegroundColor Yellow
    Write-Host "  Get-WeekNumber           - Get ISO week number"
    Write-Host "  Get-TotalWeekDays        - Count weekdays between dates"
    
    Write-Host "`nFile/Directory:" -ForegroundColor Yellow
    Write-Host "  Get-DirectorySize        - Get total directory size"
    
    Write-Host "`nSQL Server:" -ForegroundColor Yellow
    Write-Host "  Connect-SQLServer        - Connect to SQL Server instance"
    Write-Host "  `$SqlInst22              - SQL Server 2022 instance"
    Write-Host "  `$SqlInst19              - SQL Server 2019 instance"
    
    Write-Host "`nAliases:" -ForegroundColor Yellow
    Write-Host "  npp                      - Notepad++"
    Write-Host "  ll                       - Get-ChildItem (Linux-style)"
    Write-Host "  which                    - Get command location"
    Write-Host "  touch                    - Create new file"
    
    Write-Host "`nVariables:" -ForegroundColor Yellow
    Write-Host "  `$PC_Name                - Computer name"
    Write-Host "  `$User                   - Current user"
    Write-Host "  `$fDate                  - Current date (-yyyyMMdd)"
    Write-Host "`n"
}

#endregion

#region Initialization

try {
    # Change to working directory
    Set-Location "C:\_P25" -ErrorAction SilentlyContinue
    
    # Ensure transcript directory exists
    if (-not (Test-Path $Script:TranscriptPath)) {
        New-Item -Path $Script:TranscriptPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Start transcript (with error handling)
    try {
        Start-Transcript -OutputDirectory $Script:TranscriptPath -ErrorAction Stop | Out-Null
    }
    catch {
        # Transcript may already be running or directory doesn't exist
        Write-Verbose "Could not start transcript: $_"
    }
    
    # Create record file if it doesn't exist
    if (-not (Test-Path $Script:RecordPath)) {
        $null = New-Item -Path $Script:RecordPath -ItemType File -Force -ErrorAction SilentlyContinue
    }
    
    # Run initialization scripts (with error handling)
    $initScripts = @(
        'C:\PowerShell-Scripts\Check-For-Transcript-Folder.ps1',
        'C:\PowerShell-Scripts\auto-update-modules.ps1'
    )
    
    foreach ($script in $initScripts) {
        if (Test-Path $script) {
            try {
                & $script
            }
            catch {
                Write-ProfileLog "Failed to run initialization script $script : $_" -Level Warning
            }
        }
    }
    
    # Configure dbatools (suppress encryption warnings)
    if (Get-Module -ListAvailable -Name dbatools) {
        Import-Module dbatools -ErrorAction SilentlyContinue
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false -Register -ErrorAction SilentlyContinue
    }
    
    # Configure PSReadLine (if available) for better command-line editing
    if (Get-Module -Name PSReadLine) {
        # Set prediction source to history
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        
        # Set colors
        Set-PSReadLineOption -Colors @{
            Command   = 'Green'
            Parameter = 'Cyan'
            String    = 'Yellow'
        } -ErrorAction SilentlyContinue
        
        # Better history search
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction SilentlyContinue
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction SilentlyContinue
    }
}
catch {
    Write-ProfileLog "Error during profile initialization: $_" -Level Error
}

#endregion

#region Aliases

# Editor aliases
Set-Alias -Name npp -Value 'C:\Program Files\Notepad++\notepad++.exe' -ErrorAction SilentlyContinue

# Unix-like aliases
Set-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name which -Value Get-Command -ErrorAction SilentlyContinue

# Quick file creation
function touch { New-Item -ItemType File -Path $args }

#endregion

#region Profile Load Complete

$Script:ProfileLoadEnd = Get-Date
$loadTime = ($Script:ProfileLoadEnd - $Script:ProfileLoadStart).TotalMilliseconds

# Display welcome message
Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PowerShell Terminal Profile v$Script:ProfileVersion" -ForegroundColor Cyan
Write-Host "║  User: $Script:User @ $Script:PC_Name" -ForegroundColor Cyan
Write-Host "║  PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "║  Loaded in: $([math]::Round($loadTime, 2))ms" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if (Test-IsAdministrator) {
    Write-Host "⚠️  Running with ADMINISTRATOR privileges" -ForegroundColor Yellow
}

Write-Host "`nType " -NoNewline
Write-Host "Show-ProfileHelp" -ForegroundColor Green -NoNewline
Write-Host " to see available custom functions`n"

# Log profile load
Write-ProfileLog "Profile loaded successfully in $([math]::Round($loadTime, 2))ms" -Level Success

# Restore progress preference
$ProgressPreference = 'Continue'

# Run Check-Job-History once per day on first terminal launch
$Script:CheckJobScript = 'C:\PowerShell-Scripts\DBATools\Jobs\Check-Job-History.ps1'
$Script:CheckJobLog    = 'C:\_P25\Logs\PS-Rec-Of\Check-Job-History.ps1' + (Get-Date).ToString('-yyyyMMdd') + '.txt'

if (Test-Path $Script:CheckJobScript) {
    if (-not (Test-Path $Script:CheckJobLog)) {
        Write-Host "Running job history check script"
        try {
            & $Script:CheckJobScript
        }
        catch {
            Write-ProfileLog "Check-Job-History.ps1 failed: $_" -Level Warning
        }
    }
    else {
        Write-Host "Job history already checked today, skipping."
    }
}

#endregion

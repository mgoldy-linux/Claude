<#
.SYNOPSIS
    Shared SQL Server helpers for the Terminal and VSCode PowerShell profiles.

.DESCRIPTION
    Dot-sourced from Microsoft_PowerShell_profile_IMPROVED.ps1 and
    Microsoft_VSCode_profile_IMPROVED.ps1 so the SQL-specific configuration
    lives in one place instead of being duplicated in both profiles.

    Provides:
      - $Script:SqlInst22 / $Script:SqlInst19  - SQL Server instance names
      - Connect-SQLServer                       - dbatools quick-connect helper

    Update the instance names below when moving to a new machine (these were
    previously the $Script:SqlInst22 / $Script:SqlInst19 lines in each profile).

.NOTES
    Author: mgoldyn
#>

#region SQL Server instances
$Script:SqlInst22 = 'DESKTOP-2ELUN3U'
$Script:SqlInst19 = 'DESKTOP-2ELUN3U\SQLEXPRESS'
#endregion

#region SQL Server functions

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

#endregion

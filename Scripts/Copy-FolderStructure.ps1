<#
.SYNOPSIS
    Copy folder structure (no files) between PCs via USB drive.
.DESCRIPTION
    Export: Copies the folder tree from a source path to a USB drive (no files).
    Import: Recreates the folder tree on this PC from a USB drive.
.EXAMPLE
    .\Copy-FolderStructure.ps1 -Mode Export -SourcePath "C:\MyFolders" -UsbPath "E:\FolderStructure"
    .\Copy-FolderStructure.ps1 -Mode Import -UsbPath "E:\FolderStructure" -DestinationPath "C:\MyFolders"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Export', 'Import')]
    [string]$Mode,

    [string]$SourcePath,
    [string]$UsbPath,
    [string]$DestinationPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Status {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

if ($Mode -eq 'Export') {
    if (-not $SourcePath) { $SourcePath = Read-Host 'Source folder path (on this PC)' }
    if (-not $UsbPath)    { $UsbPath    = Read-Host 'USB destination path (e.g. E:\FolderStructure)' }

    if (-not (Test-Path $SourcePath)) {
        Write-Error "Source path not found: $SourcePath"
        exit 1
    }

    Write-Status "Exporting folder structure from '$SourcePath' to '$UsbPath'..."

    robocopy $SourcePath $UsbPath /E /T /NJH /NJS /NFL /NDL | Out-Null

    if ($LASTEXITCODE -le 7) {
        $count = (Get-ChildItem $UsbPath -Recurse -Directory -ErrorAction SilentlyContinue).Count
        Write-Status "$count folders exported to '$UsbPath'." 'Green'
        Write-Status "Plug USB into destination PC and run Import mode." 'Yellow'
    } else {
        Write-Error "robocopy failed with exit code $LASTEXITCODE"
    }
}
elseif ($Mode -eq 'Import') {
    if (-not $UsbPath)         { $UsbPath         = Read-Host 'USB source path (e.g. E:\FolderStructure)' }
    if (-not $DestinationPath) { $DestinationPath = Read-Host 'Destination folder path (on this PC)' }

    if (-not (Test-Path $UsbPath)) {
        Write-Error "USB path not found: $UsbPath"
        exit 1
    }

    Write-Status "Importing folder structure from '$UsbPath' to '$DestinationPath'..."

    robocopy $UsbPath $DestinationPath /E /T /NJH /NJS /NFL /NDL | Out-Null

    if ($LASTEXITCODE -le 7) {
        $count = (Get-ChildItem $DestinationPath -Recurse -Directory -ErrorAction SilentlyContinue).Count
        Write-Status "$count folders created at '$DestinationPath'." 'Green'
    } else {
        Write-Error "robocopy failed with exit code $LASTEXITCODE"
    }
}

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A personal developer productivity workspace containing:
- Enhanced PowerShell 7 profiles (Terminal + VSCode variants)
- C# business rules for Prophet21/ERP EDI integration
- Utility scripts for SQL Server and document processing

## Working with PowerShell Profiles

The primary artifacts are in `PowerShell-Profile/`:

- `Microsoft_PowerShell_profile_IMPROVED.ps1` — Terminal profile (564 lines)
- `Microsoft_VSCode_profile_IMPROVED.ps1` — VSCode-specific profile (668 lines)

**Deploying profiles:**
```powershell
# Copy to active profile location, then reload
Copy-Item "PowerShell-Profile\Microsoft_PowerShell_profile_IMPROVED.ps1" $PROFILE.CurrentUserAllHosts -Force
. $PROFILE
```

**Testing after changes:**
```powershell
Show-ProfileHelp          # Verify all functions loaded
Get-ErrorDetails          # Test error handling
```

**Installing required modules:**
```powershell
Install-Module dbatools, ImportExcel, SqlServer, PSReadLine -Scope CurrentUser
```

## Profile Architecture

Both profiles share the same structure and features but differ in VSCode-specific additions:

- **Initialization**: `$Script:` scoped config variables (paths, SQL instances, colors, version)
- **Logging**: `Write-Log` function — color-coded console + transcript file output
- **Error handling**: All initialization wrapped in try-catch; `Get-ErrorDetails` for enhanced error reporting
- **Prompt**: Shows `[ADMIN]` when elevated, Git branch when in a repo, shortened path
- **SQL helpers**: Quick-connect functions for `$Script:SqlInst22` (MSSQL 2022) and `$Script:SqlInst19` (SQLEXPRESS)
- **VSCode-only**: Clickable error links, adjusted colors, `New-Script` template generator

**Key config variables** (update these for new systems):
```powershell
$Script:BaseTranscriptPath = "C:\_P25\PST\Script-Transcripts"
$Script:SqlInst22 = 'DESKTOP-2ELUN3U'
$Script:SqlInst19 = 'DESKTOP-2ELUN3U\SQLEXPRESS'
```

## C# Business Rule

`ASI_IM_Gen_Discontinued_Check.cs` is a Prophet21 validator that enforces a 4-step workflow when marking items as discontinued in the EDI system. It references Prophet21 SDK types — it cannot be compiled standalone.

## Permissions

`.claude/settings.local.json` allows `Bash(python:*)` and `Bash(powershell:*)` execution. Claude can run PowerShell and Python commands directly.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A personal developer productivity workspace containing:
- Enhanced PowerShell 7 profiles (Terminal + VSCode variants)
- C# business rules for Prophet21/ERP EDI integration
- Utility scripts for SQL Server and document processing

## Working with PowerShell Profiles

The primary artifacts are in `PowerShell-Profile/`:

- `Microsoft_PowerShell_profile_IMPROVED.ps1` — Terminal profile
- `Microsoft_VSCode_profile_IMPROVED.ps1` — VSCode-specific profile
- `SqlHelpers.ps1` — shared SQL instance names + `Connect-SQLServer`, dot-sourced by both profiles

**Deploying profiles:**
```powershell
# Copy to active profile location, then reload. SqlHelpers.ps1 must land in the
# SAME directory as the profile (the profiles dot-source it via $PSScriptRoot).
$dest = Split-Path $PROFILE.CurrentUserAllHosts
Copy-Item "PowerShell-Profile\Microsoft_PowerShell_profile_IMPROVED.ps1" $PROFILE.CurrentUserAllHosts -Force
Copy-Item "PowerShell-Profile\SqlHelpers.ps1" $dest -Force
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
- **SQL helpers**: `SqlHelpers.ps1` (dot-sourced by both profiles) defines `$Script:SqlInst22` (MSSQL 2022), `$Script:SqlInst19` (SQLEXPRESS), and the `Connect-SQLServer` quick-connect function. dbatools encryption config stays in each profile's Initialization region.
- **VSCode-only**: Clickable error links, adjusted colors, `New-Script` template generator

**Key config variables** (update these for new systems):
```powershell
# in each profile:
$Script:BaseTranscriptPath = "C:\_P25\PST\Script-Transcripts"
# in SqlHelpers.ps1:
$Script:SqlInst22 = 'DESKTOP-2ELUN3U'
$Script:SqlInst19 = 'DESKTOP-2ELUN3U\SQLEXPRESS'
```

## Standing Rule — flag `kb_` / `js_` and always recommend performance

On **any** code touched here (SQL, business rules, portal `.srd`, reports, PowerShell):

1. **Flag every `kb_` and `js_` reference** — unprompted, by name, even when it is outside the task at hand. KB and JS both left the company; retiring their objects is a 2026 goal, and code already open for edit is the cheapest moment to fix it. Check the *dependency chain*, not just the file — a clean-looking query over `kb_view_x` is not clean. Recommend, then let the user decide scope; do not silently expand the change.
2. **Always recommend performance improvements** — volunteer them.

**Measure, never assert.** Prove equivalence first (`EXCEPT` in both directions), then quote **logical reads / CPU from the plan-cache DMVs — not wall-clock**, which on Prod has reported the exact opposite of the truth. Report honestly when a rewrite is *not* faster.

Run `/kbjs` for the full checklist, established replacements, and the P21 traps (split commissions, DataWindow SQL, positional column binding). Details in `.claude/skills/kbjs/SKILL.md`.

## C# Business Rule

`ASI_IM_Gen_Discontinued_Check.cs` is a Prophet21 validator that enforces a 4-step workflow when marking items as discontinued in the EDI system. It references Prophet21 SDK types — it cannot be compiled standalone.

## Permissions

`.claude/settings.local.json` allows `Bash(python:*)` and `Bash(powershell:*)` execution. Claude can run PowerShell and Python commands directly.

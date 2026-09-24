# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A personal developer productivity workspace containing:
- C# business rules for Prophet21/ERP EDI integration
- Ad hoc SQL scripts (`Sql-Scripts/`, `SQL-Schema/`) and P21 deploy guides/docs

General-purpose PowerShell utility scripts, and — as of 2026-09-24 — the active PowerShell
profile logic itself, live in the separate `C:\PowerShell-Scripts` git repo, not here (moved
out 2026-09-20, see `Docs/PowerShell-Reorganization-2026-09-20.md`). `PowerShell-Profile/` in
this repo now holds only historical docs (`Profile-Analysis-Report.md`,
`Profile-Migration-Guide.md`) and a stale orphaned copy of `SqlHelpers.ps1` — not the live
source.

## Working with PowerShell Profiles

**The profile now lives in `C:\PowerShell-Scripts\Core\`, not this repo.** Driven by SentinelOne
ticket #331962 (Arete flagged behavioral detections tied to PowerShell activity in
Downloads/Documents) — the real logic was moved out of OneDrive-redirected
`Documents\PowerShell\` into a plain local folder, and the `auto-update-modules.ps1` init call
was dropped entirely (confirmed trigger for a kill/quarantine, 2026-09-18).

- `C:\PowerShell-Scripts\Core\Profile-Core.ps1` — the real profile: all functions, prompt,
  aliases, SQL helpers dot-source, and initialization (Check-Job-History, SSRS digest,
  shortcut scan). Shared across every host.
- `C:\PowerShell-Scripts\Core\SqlHelpers.ps1` — `$Script:SqlInst22`/`$Script:SqlInst19` +
  `Connect-SQLServer`, dot-sourced by Profile-Core.ps1 via `$PSScriptRoot` (must stay
  co-located with it).
- `C:\PowerShell-Scripts\Core\Check-For-Transcript-Folder.ps1` — init helper, also relocated
  out of Documents.
- `C:\PowerShell-Scripts\Core\auto-update-modules.ps1` — still on disk, but deliberately **not**
  called from `$initScripts` anymore. Run module-update checks manually via `Update-ProfileModules`
  instead.

The three actual `$PROFILE` files (PowerShell computes their location itself — this can't be
changed) are kept as thin stubs in
`C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents\PowerShell\`, each just dot-sourcing
`Profile-Core.ps1`:
- `profile.ps1` (CurrentUserAllHosts) — also has the `Start-Claude`/`cc` launcher
- `Microsoft.PowerShell_profile.ps1` (Terminal-only) — empty stub, nothing Terminal-specific yet
- `Microsoft.VSCode_profile.ps1` (VSCode-only) — just `New-Script`, the one genuinely
  VSCode-only addition

**Editing the profile:** edit `C:\PowerShell-Scripts\Core\Profile-Core.ps1` directly and reload
— there's no copy/deploy step anymore, since it's not tracked as a repo artifact you build and
push out.

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

- **Initialization**: `$Script:` scoped config variables (paths, SQL instances, colors, version)
- **Logging**: `Write-ProfileLog` function — color-coded console + transcript file output
- **Error handling**: All initialization wrapped in try-catch; `Get-ErrorDetails` for enhanced error reporting
- **Prompt**: Shows `[ADMIN]` when elevated, Git branch when in a repo, shortened path
- **SQL helpers**: `SqlHelpers.ps1` defines `$Script:SqlInst22`/`$Script:SqlInst19` and
  `Connect-SQLServer`. **Machine-aware as of 2026-09-24** — these are local SQL Server instance
  names that only exist on the home PC; the work laptop has no local SQL Server service at all
  (confirmed via `Get-Service MSSQL*`), so they resolve to `$null` there and `Connect-SQLServer`
  warns instead of failing if called with no `-Instance`. Work SQL targets
  (`P21.allsurfaces.com` / `P21Dev.allsurfaces.com`) are passed explicitly, not through these
  vars. dbatools encryption config stays in Profile-Core.ps1's Initialization region.
- **VSCode-only**: Clickable error links (actually shared in Profile-Core.ps1, gated by
  `Test-IsVSCodeTerminal`), `New-Script` template generator (genuinely VSCode-only, lives in
  `Microsoft.VSCode_profile.ps1`)

**Key config variables** (update these for new systems):
```powershell
# in Profile-Core.ps1:
$Script:BaseTranscriptPath = "C:\_P25\PST\Script-Transcripts"
# in SqlHelpers.ps1 - keyed off $env:COMPUTERNAME, add new machines to the switch:
'DESKTOP-2ELUN3U' { $Script:SqlInst22 = 'DESKTOP-2ELUN3U'; $Script:SqlInst19 = 'DESKTOP-2ELUN3U\SQLEXPRESS' }
default            { $Script:SqlInst22 = $null; $Script:SqlInst19 = $null }
```

## Standing Rule — flag `kb_` / `js_` / `ds_` and always recommend performance

On **any** code touched here (SQL, business rules, portal `.srd`, reports, PowerShell):

1. **Flag every `kb_`, `js_`, and `ds_` reference** — unprompted, by name, even when it is outside the task at hand. KB and JS both left the company; retiring their objects is a 2026 goal, and code already open for edit is the cheapest moment to fix it. `ds_` marks old DataWindow-sourced views (e.g. `ds_view_transfers`) that predate later conversions to `p21_view_*`/`v_*` objects — same retirement logic applies. Check the *dependency chain*, not just the file — a clean-looking query over `kb_view_x` (or `ds_view_x`) is not clean. Recommend, then let the user decide scope; do not silently expand the change.
2. **Always recommend performance improvements** — volunteer them.

**Measure, never assert.** Prove equivalence first (`EXCEPT` in both directions), then quote **logical reads / CPU from the plan-cache DMVs — not wall-clock**, which on Prod has reported the exact opposite of the truth. Report honestly when a rewrite is *not* faster.

Run `/kbjs` for the full checklist, established replacements, and the P21 traps (split commissions, DataWindow SQL, positional column binding). Details in `.claude/skills/kbjs/SKILL.md`.

## C# Business Rule

`ASI_IM_Gen_Discontinued_Check.cs` is a Prophet21 validator that enforces a 4-step workflow when marking items as discontinued in the EDI system. It references Prophet21 SDK types — it cannot be compiled standalone.

## Permissions

`.claude/settings.local.json` allows `Bash(python:*)` and `Bash(powershell:*)` execution. Claude can run PowerShell and Python commands directly.

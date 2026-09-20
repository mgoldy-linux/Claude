# PowerShell Reorganization — 2026-09-20

Two-part cleanup: (1) sort loose root-level files in `C:\PowerShell-Scripts` into subfolders,
(2) move every `.ps1` script sitting in `C:\Claude` (git repo) into its proper home in
`C:\PowerShell-Scripts` (separate git repo). Triggered after SentinelOne quarantined the live
PowerShell profile files, prompting a broader "get everything in a proper place" pass.

## Part 1 — `C:\PowerShell-Scripts` root cleanup

All 52 loose `.ps1` files (plus a stray `.bak` and a stray `.txt` log) moved out of the repo
root via `git mv`, preserving history.

| Old path (root) | New path |
|---|---|
| Select-DB.ps1 | Core/Select-DB.ps1 |
| auto-update-modules.ps1 (+ `.last-update-check` state files) | Core/ |
| auto-update-modules.ps1.bak | _Archive/auto-update-modules.ps1.bak |
| Enable-Firewall.ps1 | System/ |
| Fix-PS1-Association.ps1 | System/ |
| Modify-Module-Path.ps1 | System/ |
| Get-WorkPC-Info.ps1 | System/ |
| Get-Folder-Permissions.ps1 | System/ |
| Register-VSCode-Shortcut-Task.ps1 | System/ |
| Set-VSCode-Shortcut.ps1 | System/ |
| Test-Terminal-Null.ps1 | *(deleted — identical to a pre-existing copy already in `Practice/`)* |
| Test-new-transcript-path.ps1 | PS-Test/ |
| Check-Bing-Names.ps1, Rename-Bing-Pics-V2.ps1, Rename-BingPics.ps1, Invoke-USBDedup.ps1 | Media/ (new) |
| export_xlsx.ps1 | Create-Excel/ |
| Create-SQL-Update-ship_to.default_branch.ps1 | Create-SQL/…-simple-v2.ps1 *(renamed — collided with an existing, different script of the same name already in Create-SQL; both kept, see Conflicts below)* |
| Copy-ProdToTraining.ps1, Copy-ProdToTraining-2nd.ps1 | *(deleted — identical to pre-existing copies already in `PS_Skills/File-Ops/`)* |
| Check-Stale-Tickets.ps1, Cleanup-ClaudeFolder.ps1, Find-MiddlewareFiles.ps1 | PS_Skills/ |
| Compare-PortalElementsToFiles.ps1, Find-DuplicateFiles.ps1, Remove-DuplicateFiles.ps1, Remove-EmptyFolders.ps1, Remove-EmptyFolders-Loop.ps1 | PS_Skills/File-Ops/ |
| get_db_from_trace.ps1, get_functions[2-4].ps1, get_remote_functions.ps1, get_trace_server.ps1, try_connections.ps1, read_trace[2-8].ps1, read_credit_hold.ps1 | _Archive/Trace-Scratch/ (new — one-off `kb_fnt_br_` investigation scripts, see note below) |
| Find_Shortcut_Keys.ps1 | _Archive/Trace-Scratch/ *(superseded by `PS_Skills\Find-all-shortcut-keys.ps1`)* |
| Check-For-Transcript-Folder.ps1 | _Archive/Trace-Scratch/ *(stale — diverged from and superseded by the deployed copy in `Documents\PowerShell\`, which the profile actually calls)* |
| Update-ScriptRecordPath.ps1 | _Archive/Trace-Scratch/ *(one-time migration tool, already applied)* |
| Record-of-ASPF54QP2K-VC-Scripts-Ran.txt | _Archive/ *(stray log, predates the current `C:\_P25\Logs\` convention)* |

**Load-bearing reference fixed:** `Select-DB.ps1` is dot-invoked by absolute path
(`& "C:\PowerShell-Scripts\Select-DB.ps1"`) from **112 other scripts** across
`Create-Excel`, `Create-SQL`, `PS-Insert-SQL`, `PS-Update-SQL`, `DBATools`, `SQL`,
`PS_Skills`, and `_Archive`. All 112 were bulk-updated to
`C:\PowerShell-Scripts\Core\Select-DB.ps1`. Verified zero stale references remain.

**`Cleanup-ClaudeFolder.ps1`** (the scheduled daily job that sweeps loose files out of
`C:\Claude` root) was itself dumping `.ps1` files flat into `C:\PowerShell-Scripts` root —
the actual mechanism that created this mess. Its routing now lands new loose scripts in
`C:\PowerShell-Scripts\_Inbox\` for manual triage instead of the repo root. Note: no
matching Windows Scheduled Task was found on this machine during this session despite the
script's own header claiming a daily 5 PM run — worth checking separately.

## Part 2 — `C:\Claude` → `C:\PowerShell-Scripts`

| From (C:\Claude) | To (C:\PowerShell-Scripts) |
|---|---|
| Node/Run-BRR-Verification.ps1 + build-brr-docx.js | _Archive/Stale-Duplicates/ *(known-broken duplicate per 2026-07-29 survey; the fixed pair already lives in `Reports/`)* |
| Portals/SA-48732/Build-CsrOpenOrderTeam-Srd.ps1 | Portals/SA-48732/ (new) |
| Portals/SA-53270/Build-BrWillCallOrders-Srd.ps1 | Portals/SA-53270/ (new) |
| Postman/New-P21TestOrders.ps1 | Postman/ (new) |
| PowerShell/Check-SSRS-Subscription-Sends.ps1 | SSRS/ *(replaced the existing, diverged copy — kept the C:\Claude version per user's call)* |
| PowerShell/Compare-LowMarginAlert-Prod-vs-Play.ps1 | Alerts/ (new) |
| PowerShell/Find-WirelessShippingLabel-RptFiles.ps1 | Reports/ |
| PowerShell/PS-Script-Template.ps1 | Templates/ (new) |
| PowerShell/Search-PortalFiles-For-EDI855View.ps1 | PS_Skills/File-Ops/ |
| PowerShell-Scripts/Archive-BusinessRulesDLL-Duplicates.ps1, Compare-BusinessRules-Prod-Parity.ps1, Export-KBUsageReport.ps1, Fix-NinetyDayUsageSubscriptions-MfgParam.ps1, Get-BusinessRuleDllStatus.ps1, Get-BusinessRuleDllStatus-Reflection.ps1, Invoke-NinetyDayUsageSubscriptions-FireTonight.ps1, Test-BusinessRuleDll.ps1, Update-NinetyDayUsageSubscriptions-MfgUseDefault.ps1 | BusinessRules/ (new) |
| Scripts/Copy-FolderStructure.ps1 | PS_Skills/File-Ops/ |
| PowerShell-Profile/SqlHelpers.ps1 | **stayed** — core repo artifact, dot-sourced by both profiles per CLAUDE.md |
| PowerShell-Profile/Microsoft_*_profile_IMPROVED.ps1 | **stayed** — profile source copies, not general utility scripts (currently missing from disk, unrelated open thread — see below) |

Cross-repo moves: copied into `C:\PowerShell-Scripts` (git history starts fresh there —
different repo, no shared history possible) and `git rm`'d from `C:\Claude`.

## Conflicts found and resolved

- **`Check-SSRS-Subscription-Sends.ps1`** existed in both locations as genuinely different
  rewrites (not drift). Kept the `C:\Claude` version per explicit user decision.
- **`Create-SQL-Update-ship_to.default_branch.ps1`** existed in both the root (Excel column
  names `Customer ID`/`Default Branch ID`, no record-file logging) and `Create-SQL\` (the
  standard header/footer/record-file template, column names `customer_id`/`default_branch`).
  Neither looked stale — kept both, root copy renamed `…-simple-v2.ps1`. **Needs a manual
  look** to confirm which one is actually current.
- **`Run-BRR-Verification.ps1`** — per the 2026-07-29 file-organization survey
  (`project_2026_07_29_file_organization.md`), the `C:\Claude\Node` copy self-documents as
  broken (`does not work .docx is always corrupted`); archived rather than treated as new.
- **`Copy-ProdToTraining.ps1`/`-2nd.ps1`** and **`Test-Terminal-Null.ps1`** — the root copies
  turned out to be byte-identical to copies already correctly filed in `PS_Skills/File-Ops/`
  and `Practice/` respectively. Deleted the redundant root copies instead of creating a
  second home for them; a post-move duplicate-basename scan of the whole tree found no
  other collisions.

## Not done / flagged, not acted on

- `kb_`/`js_` flag: the archived `_Archive/Trace-Scratch/get_functions*.ps1` and
  `read_trace*.ps1` scripts investigate `kb_fnt_br_` functions — relevant to the 2026 `kb_`/`js_`
  retirement goal. Archived as-is, not reviewed for retirement-tracker content.
- `Microsoft_PowerShell_profile_IMPROVED.ps1` / `Microsoft_VSCode_profile_IMPROVED.ps1` are
  still missing from disk (SentinelOne quarantine, separate open thread — pending a decision
  on looping in Cary/Arete before restoring). Not restored as part of this reorg.
- CLAUDE.md's "Utility scripts for SQL Server and document processing" line is now stale
  (no more loose utility scripts live under `C:\Claude`) — not updated yet, flagged for the user.
- Nothing has been committed in either repo yet — both `C:\Claude` and `C:\PowerShell-Scripts`
  have staged/unstaged changes pending review.

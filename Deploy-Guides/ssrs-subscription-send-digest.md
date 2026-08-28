# Deployment Guide — SSRS Subscription-Send Daily Digest

> Produced during development. Update as the artifact changes; commit with the code.

> **Status 2026-08-29:** script built and live-verified against the Prod catalog; **not deployed**.
> Tony Neuman confirmed the relay attachment limit is **35 MB** (on the base64-encoded
> size) — the script's `-AttachmentLimitMB` param now defaults to 35 and flags a rendered
> send in **red as OVER LIMIT** when `rendered × 4/3 ≥ 35 MB`. Two subscriptions are
> already over and not being delivered: `Inventory Value Report` / "EAV Weekly Inventory
> Value" (MHTML ~92 MB) and `Inventory Usage 90 Days` (MHTML ~73 MB) — fix is Render
> Format MHTML → Excel on each (owner: jklitzman). Reply with the SSRS navigation drafted
> to Tony 2026-08-29 (in Drafts). The three deploy actions below are all the user's to run.

## Artifact(s)
- `PowerShell/Check-SSRS-Subscription-Sends.ps1` — PowerShell 7 script. Once-per-day
  digest of SSRS subscription (scheduled email / file-share) report sends: per day,
  each report's name + rendered size, who received it (email TO/CC/BCC or file-share
  path), and any render error. Also surfaces point-in-time delivery-status flags and
  a >20 MB mail-relay-risk warning.
- `PowerShell-Profile/Microsoft_PowerShell_profile_IMPROVED.ps1` — **repo copy only** —
  added a call to the script on first terminal launch (after the Check-Job-History block).
- `PowerShell-Profile/Microsoft_VSCode_profile_IMPROVED.ps1` — **repo copy only** — same
  call, inside the "skip in VSCode debug sessions" guard.
- Ticket: *(none — personal productivity request)*

## Target environments
- The user's workstation only. No P21 / SQL object is created or changed — the script
  is **read-only** against `ASDWDB01.ahi.local\ReportServer` (`dbo.ExecutionLogStorage`,
  `dbo.Catalog`, `dbo.Subscriptions`, `dbo.Users`, `dbo.Notifications`).

## Dependencies
1. `dbatools` PowerShell module (already required by the profiles).
2. Read access to the `ReportServer` catalog DB on `ASDWDB01` with the user's Windows
   login (already used by `Get-SSRSSubscriptionSummary`). The detailed query also needs
   read on `dbo.Subscriptions` / `dbo.Users`; if denied, the script falls back to
   `ExecutionLog3` without recipient data.
3. The script is self-contained — it does **not** require the profile. It reads
   `$SsrsInstance` / `$Colors` from the profile if present and otherwise falls back to
   `ASDWDB01.ahi.local` and a built-in colour set, so it runs standalone under
   `Set-StrictMode` whether invoked with `&` or dot-sourced.

## Deploy steps

### Step 1 — put the script where the profile block looks for it
```powershell
New-Item -ItemType Directory -Force 'C:\PowerShell-Scripts\SSRS' | Out-Null
Copy-Item 'C:\Claude\PowerShell\Check-SSRS-Subscription-Sends.ps1' `
          'C:\PowerShell-Scripts\SSRS\Check-SSRS-Subscription-Sends.ps1' -Force
```
(Convention match: `Check-Job-History.ps1` lives under `C:\PowerShell-Scripts\...` too.
Alternatively point the block at the repo path and skip this copy.)

### Step 2 — add the call block to the LIVE profiles (surgical paste, NOT a redeploy)
⚠️ **Do not copy `Microsoft_*_profile_IMPROVED.ps1` over the live profiles.** As of
2026-08-28 the live profiles have drifted ~140 lines from the repo `_IMPROVED` copies
(repo has `$Script:SsrsInstance` / `Get-DiskSpace` / `Update-KBIndex` the live ones lack;
the live ones have a `#region Claude Code Guard` — `if ($env:CLAUDE_CODE_ENTRYPOINT) { return }`
— the repo lacks). A blanket copy would pull in unreviewed changes and drop the guard.

Paste this block into each live profile, right after the **Check-Job-History** block and
before `# Configure dbatools`:
```powershell
    # Daily SSRS subscription-send digest (script self-guards to once per day)
    $Script:SsrsSendCheckScript = 'C:\PowerShell-Scripts\SSRS\Check-SSRS-Subscription-Sends.ps1'
    if (Test-Path $Script:SsrsSendCheckScript) {
        try {
            & $Script:SsrsSendCheckScript -Quiet
        }
        catch {
            Write-ProfileLog "Check-SSRS-Subscription-Sends.ps1 failed: $_" -Level Warning
        }
    }
```
Live files:
- Terminal: `C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- VS Code:  `C:\Users\mgoldyn\OneDrive - All Surfaces Inc\Documents\PowerShell\Microsoft.VSCode_profile.ps1`

Then `. $PROFILE` or open a new terminal. Note: because of the Claude Code guard, the
check runs in the user's real terminals only, not inside Claude Code sessions.

### Step 3 — size threshold (done)
`-AttachmentLimitMB` defaults to **35** (Tony Neuman, 2026-08-29). The check compares the
base64-encoded size (`rendered × 4/3`): ≥ limit → red "OVER LIMIT", ≥ 80% → amber warning.
Override per-run with `-AttachmentLimitMB <n>` if the relay cap changes.

## How the once-per-day / since-last-run logic works
- State file: `C:\_P25\State\SSRS-Subscription-Sends.state.json` (auto-created). Holds
  `LastRun` (the moment the last successful check finished) and `WindowStart`.
- On launch: if `LastRun` is earlier **today**, the script prints nothing and returns —
  restarting PowerShell the same day does not re-run it. `-Force` overrides (and
  reproduces the *last* window rather than advancing state).
- Otherwise the window is `LastRun → now`. A multi-day gap (weekend, PTO, machine off)
  produces one section per calendar day, and any day with zero sends is called out
  explicitly so a report that silently stopped firing is obvious.
- First ever run (no state file): looks back `-DaysBack` days (default 1).
- State is written **only** when the catalog query succeeded and only on a real daily
  run (a `-Force` / `-Since` run never advances it), so a transient DB outage at
  startup doesn't consume the window.

## Backward-compatibility notes
- No shared objects. Removing the script or reverting the profile edits fully undoes it.
- `dbo.ExecutionLogStorage` has no `SubscriptionID`, so a report's run cannot be tied to
  one exact subscription. The script narrows candidates by active state + matching
  render format and labels the confidence ("the exact one that fired isn't recorded")
  rather than guessing. A large per-location subscription fan-out is summarised, not dumped.
- `ExecutionLog Status = 'rsSuccess'` proves only that the report **rendered**. The SMTP
  hand-off is not recorded per-send in the catalog DB. `dbo.Subscriptions.LastStatus`
  is the only delivery record and is overwritten every run — the "Delivery status flags"
  section is point-in-time. The definitive per-send record is
  `ReportServerService_<date>.log` on `ASDWDB01` (no UNC access from the workstation —
  IT has to pull it). See `feedback_ssrs_p21_shared_mail_relay`.
- Earlier bug (fixed): the script referenced `$Script:SsrsInstance` / `$Script:Colors`
  directly, which throws under the profile's `Set-StrictMode` when dot-sourced. Now read
  defensively via `Get-Variable -ErrorAction SilentlyContinue`. A global
  `$ErrorActionPreference='Stop'` that leaked into the session on dot-source was removed.

## Verification
Run on demand without waiting for a new day / without touching real state:
```powershell
& 'C:\Claude\PowerShell\Check-SSRS-Subscription-Sends.ps1' -Force -DaysBack 3 `
    -StateFile "$env:TEMP\ssrs-digest-test.json"
```
Expected: a dated section per day; each send shows report name, size, format, time,
`OK`/`ERROR`, and `-> recipients`; a summary line; then any delivery-status flags.

Confirmed 2026-08-28 against `ASDWDB01\ReportServer`:
- 3-day window: 17 sends, 0 render errors.
- 7-day window: 67 sends, 1 render error. Surfaced two real problems:
  - `Changes to Orders by Sales Reps` — `rsAccessDenied` render (0 bytes) on 8/24, and
    `LastStatus` = "the permissions granted to user 'AHI\kbenish' are insufficient…
    Mail will not be resent" (subscription owned by departed `kbenish`).
  - `Inventory Value Report` MHTML subscription ≈ 92 MB weekly; `Inventory Usage 90 Days`
    MHTML ≈ 73 MB — both flagged as mail-relay risk.
- Also verified under `Set-StrictMode -Version Latest` with `&`, dot-source, and a
  legacy (no-`WindowStart`) state file.

Same-day guard: run the script twice with the real state file — the second run prints
`already ran today (HH:mm). Use -Force to re-run.` and exits.

## Rollback
- Delete `C:\PowerShell-Scripts\SSRS\Check-SSRS-Subscription-Sends.ps1`.
- Remove the pasted `$Script:SsrsSendCheckScript` block from the two live profiles.
- Revert the block in the repo `*_IMPROVED.ps1` copies (`git checkout`).
- Delete `C:\_P25\State\SSRS-Subscription-Sends.state.json` (harmless either way).

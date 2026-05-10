# PowerShell Profile Migration - Quick Start Guide

## 🚀 5-Minute Migration

### Step 1: Backup (30 seconds)
```powershell
# Run this in PowerShell
$backupDate = Get-Date -Format 'yyyyMMdd-HHmmss'

# Backup Terminal profile
Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" `
          "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1.backup.$backupDate"

# Backup VSCode profile
Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1" `
          "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1.backup.$backupDate"

Write-Host "✓ Profiles backed up" -ForegroundColor Green
```

### Step 2: Check Your Profile Locations (30 seconds)
```powershell
# See where your profiles are
$PROFILE | Select-Object *

# Expected output:
# CurrentUserAllHosts    : C:\Users\mgoldyn\Documents\PowerShell\profile.ps1
# CurrentUserCurrentHost : C:\Users\mgoldyn\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# AllUsersAllHosts      : C:\Program Files\PowerShell\7\profile.ps1
# AllUsersCurrentHost   : C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1
```

**What you need:**
- **Terminal Profile**: `Microsoft.PowerShell_profile.ps1`
- **VSCode Profile**: `Microsoft.VSCode_profile.ps1`

### Step 3: Install Required Modules (2 minutes)
```powershell
# Install the essential modules if not already present
$requiredModules = @('dbatools', 'ImportExcel', 'SqlServer', 'PSReadLine')

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module..." -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force
    } else {
        Write-Host "✓ $module already installed" -ForegroundColor Green
    }
}
```

### Step 4: Copy Improved Profiles (1 minute)

**Option A: Manual Copy**
1. Download the improved profile files I created
2. Copy `Microsoft_PowerShell_profile_IMPROVED.ps1` to `C:\Users\mgoldyn\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
3. Copy `Microsoft_VSCode_profile_IMPROVED.ps1` to `C:\Users\mgoldyn\Documents\PowerShell\Microsoft.VSCode_profile.ps1`

**Option B: PowerShell Copy (if files are in Downloads)**
```powershell
$downloadsPath = "$env:USERPROFILE\Downloads"
$profilePath = "$env:USERPROFILE\Documents\PowerShell"

# Copy Terminal profile
Copy-Item "$downloadsPath\Microsoft_PowerShell_profile_IMPROVED.ps1" `
          "$profilePath\Microsoft.PowerShell_profile.ps1" -Force

# Copy VSCode profile
Copy-Item "$downloadsPath\Microsoft_VSCode_profile_IMPROVED.ps1" `
          "$profilePath\Microsoft.VSCode_profile.ps1" -Force

Write-Host "✓ Profiles copied" -ForegroundColor Green
```

### Step 5: Verify Paths in New Profiles (1 minute)

Open the new profiles and check these settings match your system:

**In both profiles, verify:**
```powershell
# Around line 25-35, check these paths:
$Script:BaseTranscriptPath = "C:\_P25\PST\Script-Transcripts"  # ← Verify this exists
$Script:SqlInst22 = 'DESKTOP-2ELUN3U'                          # ← Update if different
$Script:SqlInst19 = 'DESKTOP-2ELUN3U\SQLEXPRESS'               # ← Update if different

# Around line 95-100, check:
Set-Location "C:\_P25" -ErrorAction SilentlyContinue           # ← Your working directory

# Around line 160-170, check initialization scripts exist:
$initScripts = @(
    'C:\PowerShell-Scripts\Check-For-Transcript-Folder.ps1',   # ← Verify path
    'C:\PowerShell-Scripts\auto-update-modules.ps1'            # ← Verify path
)
```

### Step 6: Test! (30 seconds)
```powershell
# Close and reopen PowerShell Terminal
# You should see:
╔════════════════════════════════════════════════════╗
║  PowerShell Terminal Profile v2.0
║  User: mgoldyn @ DESKTOP-2ELUN3U
║  PowerShell: 7.4.1
║  Loaded in: 187.43ms
╚════════════════════════════════════════════════════╝

Type Show-ProfileHelp to see available custom functions

# Test a function
Show-ProfileHelp

# Check for errors
$Error[0]  # Should show "No errors" or at least nothing critical
```

---

## 🔧 Customization Options

### Change Colors
```powershell
# Edit around line 35 in your profile:
$Script:Colors = @{
    Success = 'Green'      # ← Change to 'Blue', 'Cyan', etc.
    Warning = 'Yellow'     # ← Your preference
    Error   = 'Red'        # ← Keep as Red for visibility
    Info    = 'Cyan'       # ← Change if desired
    Accent  = 'Magenta'    # ← For Git branch color
}
```

### Add Your Own Aliases
```powershell
# Add to the Aliases section (around line 360):
Set-Alias -Name myalias -Value 'C:\Path\To\Program.exe'
Set-Alias -Name sql22 -Value 'Connect-DbaInstance -SqlInstance $SqlInst22'
```

### Add Your Own Functions
```powershell
# Add before the "Initialization" region (around line 320):
function My-CustomFunction {
    param([string]$Parameter)
    
    # Your code here
    Write-Host "Running my custom function with $Parameter"
}
```

### Disable Features You Don't Want

**Disable Git Branch in Prompt:**
```powershell
# In the Prompt function, comment out this line:
# $gitBranch = Get-GitBranch
$gitBranch = ""  # ← Force it to empty
```

**Disable Transcript Logging:**
```powershell
# Comment out the Start-Transcript section (around line 100):
<#
try {
    Start-Transcript -OutputDirectory $Script:TranscriptPath -ErrorAction Stop | Out-Null
}
catch {
    Write-Verbose "Could not start transcript: $_"
}
#>
```

**Disable Auto-Update Check:**
```powershell
# Comment out this line in initialization (around line 110):
# & "C:\PowerShell-Scripts\auto-update-modules.ps1"
```

---

## ⚠️ Troubleshooting

### Error: "Execution Policy Restricted"
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: "Module not found"
```powershell
# Install the missing module
Install-Module -Name ModuleName -Scope CurrentUser
```

### Error: "Path not found" during profile load
```powershell
# The profile is trying to access a directory that doesn't exist
# Open the profile and comment out or fix the path:
# Set-Location "C:\_P25" -ErrorAction SilentlyContinue
```

### Profile loads slowly (>500ms)
```powershell
# Disable module auto-updates:
# Comment out: & "C:\PowerShell-Scripts\auto-update-modules.ps1"

# Or measure what's slow:
Measure-Command { & "C:\PowerShell-Scripts\auto-update-modules.ps1" }
```

### Transcript errors
```powershell
# Stop all transcripts
try { Stop-Transcript } catch {}

# Recreate transcript directory
$transcriptPath = "C:\_P25\PST\Script-Transcripts"
if (Test-Path $transcriptPath) {
    Remove-Item $transcriptPath -Recurse -Force
}
New-Item -Path $transcriptPath -ItemType Directory -Force
```

### Want to revert to old profile?
```powershell
# Find your backup (look for .backup.YYYYMMDD-HHMMSS)
Get-ChildItem "$env:USERPROFILE\Documents\PowerShell\*.backup.*"

# Restore it
Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1.backup.20240208-143022" `
          "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force

# Restart PowerShell
```

---

## 📊 Before & After Comparison

### BEFORE:
```
PS [DESKTOP-2ELUN3U] >
```
- Basic prompt
- No error handling
- No Git integration
- String concatenation for paths
- No performance monitoring
- Limited functions

### AFTER:
```
╔════════════════════════════════════════════════════╗
║  PowerShell Terminal Profile v2.0
║  User: mgoldyn @ DESKTOP-2ELUN3U
║  PowerShell: 7.4.1
║  Loaded in: 187.43ms
╚════════════════════════════════════════════════════╝

Type Show-ProfileHelp to see available custom functions

PS [ADMIN] [DESKTOP-2ELUN3U] [main] C:\_P25\Projects
>
```
- Enhanced prompt with Git branch
- Admin indicator
- Error handling throughout
- Performance monitoring
- 20+ utility functions
- PSReadLine improvements
- Color-coded output
- Help system

---

## 🎯 What You Get

### New Functions Available:
- `Show-ProfileHelp` - See all available functions
- `Get-ErrorDetails` - Enhanced error reporting
- `Update-ProfileModules` - Check for module updates
- `Get-DirectorySize` - Get folder size
- `Connect-SQLServer` - Quick SQL connection
- `Get-WeekNumber` - ISO week number
- `Get-TotalWeekDays` - Count weekdays
- `New-Script` (VSCode only) - Create script from template
- `Set-Profile` - Edit profile

### New Aliases:
- `ll` → Get-ChildItem
- `which` → Get-Command
- `grep` → Select-String
- `touch` → Create file
- `npp` → Notepad++

### Enhanced Features:
- ✓ Git branch in prompt
- ✓ Admin detection
- ✓ Path shortening
- ✓ Color-coded output
- ✓ Error handling
- ✓ Performance monitoring
- ✓ PSReadLine optimization
- ✓ VSCode integration

---

## 📝 Post-Migration Checklist

- [ ] Profiles backed up
- [ ] Required modules installed
- [ ] New profiles copied to correct locations
- [ ] Paths verified and updated
- [ ] PowerShell restarted and tested
- [ ] No errors on profile load
- [ ] `Show-ProfileHelp` works
- [ ] Custom functions work
- [ ] Transcript logging works (if enabled)
- [ ] Git branch shows in prompt (if in Git repo)
- [ ] Admin indicator shows when elevated

---

## 🆘 Need Help?

### Check Profile Load Errors
```powershell
# See if profile loaded with errors
$Error | Select-Object -First 5

# Force reload profile with error details
. $PROFILE -ErrorAction Stop
```

### View Current Profile Path
```powershell
# See which profile is active
$PROFILE.CurrentUserCurrentHost

# Open current profile
notepad $PROFILE
# or
code $PROFILE
```

### Test Individual Functions
```powershell
# Test error details
Get-ErrorDetails

# Test week calculation
Get-TotalWeekDays -Start '2024-01-01' -End '2024-01-31'

# Test directory size
Get-DirectorySize

# Check module updates
Update-ProfileModules
```

---

## ✨ Pro Tips

1. **Customize the prompt** - Edit the `Prompt` function to your liking
2. **Add your SQL instances** - Update `$SqlInst22` and `$SqlInst19` variables
3. **Create shortcuts** - Add aliases for your most-used commands
4. **Organize scripts** - Move init scripts to dedicated folder
5. **Use modules** - Convert common functions to modules for reusability
6. **Version control** - Keep your profile in Git for history
7. **Share with team** - Export your custom functions as modules

---

## 🔄 Updating Your Profile Later

```powershell
# Edit profile
code $PROFILE
# or
Set-Profile

# Reload without restarting PowerShell
. $PROFILE

# Or reload with this alias (add to your profile):
function Reload-Profile { . $PROFILE }
Set-Alias -Name reload -Value Reload-Profile
```

Happy PowerShell-ing! 🚀

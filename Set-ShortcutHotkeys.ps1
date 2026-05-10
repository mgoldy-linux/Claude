# Creates/updates desktop shortcuts with custom hotkeys.
# WScript.Shell can't parse all keys (e.g. "/" or arrow keys), so the hotkey
# WORD at offset 0x40 in the ShellLinkHeader is binary-patched directly (MS-SHLLINK spec).
# Windows only honors shortcut hotkeys for shortcuts on the Desktop or Start Menu.

function Set-ShortcutWithHotkey {
    param(
        [string] $ShortcutPath,
        [string] $TargetPath,
        [string] $WorkingDir,
        [byte]   $VirtualKey,   # low byte  — virtual key code
        [byte]   $Modifiers     # high byte — HOTKEYF_SHIFT=0x01, CONTROL=0x02, ALT=0x04
    )

    if (-not (Test-Path $TargetPath)) {
        Write-Warning "Target not found: $TargetPath"
        return
    }

    $shell    = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath       = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDir
    $shortcut.WindowStyle      = 1
    $shortcut.Save()

    $bytes = [System.IO.File]::ReadAllBytes($ShortcutPath)
    $bytes[0x40] = $VirtualKey
    $bytes[0x41] = $Modifiers
    [System.IO.File]::WriteAllBytes($ShortcutPath, $bytes)
}

$desktop = "$env:USERPROFILE\Desktop"
$ctrlAlt = 0x06   # HOTKEYF_CONTROL (0x02) | HOTKEYF_ALT (0x04)

# Visual Studio Code — Ctrl + Alt + /
Set-ShortcutWithHotkey `
    -ShortcutPath "$desktop\Visual Studio Code.lnk" `
    -TargetPath   "C:\Program Files\Microsoft VS Code\Code.exe" `
    -WorkingDir   "C:\Program Files\Microsoft VS Code" `
    -VirtualKey   0xBF `
    -Modifiers    $ctrlAlt
Write-Host "VS Code     -> Ctrl + Alt + /" -ForegroundColor Cyan

# Notepad++ — Ctrl + Alt + Right
Set-ShortcutWithHotkey `
    -ShortcutPath "$desktop\Notepad++.lnk" `
    -TargetPath   "C:\Program Files\Notepad++\notepad++.exe" `
    -WorkingDir   "C:\Program Files\Notepad++" `
    -VirtualKey   0x27 `
    -Modifiers    $ctrlAlt
Write-Host "Notepad++   -> Ctrl + Alt + Right" -ForegroundColor Cyan

Write-Host ""
Write-Host "Note: Sign out/in or restart Explorer if hotkeys don't respond immediately." -ForegroundColor Yellow

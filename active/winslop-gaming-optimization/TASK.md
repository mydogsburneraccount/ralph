# Task: Winslop Gaming Optimization - Diagnosis & Resolution

## Task Overview

**Goal**: Diagnose and resolve 25 Winslop-flagged issues to optimize Windows 11 for gaming performance

**Context**: User ran Winslop (https://github.com/builtbybel/Winslop) scan with gaming optimization plugins. 31/51 settings OK, 20 system settings + 5 plugin issues require attention. All fixes are registry-based.

**Success Indicator**: Winslop re-scan shows all selected items as green/configured

---

## Success Criteria

### Phase 0: VERIFICATION GATE
- [x] Task creator completed discovery (see progress.md)
- [ ] Ralph worker verifies issue list matches user's scan

### Phase 1: Generate Fix Commands
- [ ] All 25 issues have corresponding PowerShell/reg commands
- [ ] Commands grouped by category for batch execution
- [ ] Safety notes added for gaming-critical tweaks

### Phase 2: User Executes Fixes
- [ ] User runs commands in Admin PowerShell (MANUAL STEP)
- [ ] Any errors documented and alternative provided

### Phase 3: Verification
- [ ] User re-runs Winslop scan
- [ ] All 25 issues show as resolved (green)

---

## Manual Steps Required

**ALL fixes require human execution in Admin PowerShell on Windows.**

### Pre-Flight: Create Restore Point
```powershell
# Run in Admin PowerShell FIRST
Checkpoint-Computer -Description "Pre-Winslop-Optimization" -RestorePointType "MODIFY_SETTINGS"
```

---

## Fix Commands by Category

### 1. MS Edge Policies (11 issues) - SAFE

All Edge policies go to same key. Run this batch:

```powershell
# Create Edge policy key if missing
New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge" -Force | Out-Null

# Apply all Edge policies
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "BrowserSignin" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "NewTabPageHideDefaultTopSites" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "DefaultBrowserSettingEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "EdgeCollectionsEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "GamerModeEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ImportOnEachLaunch" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "NewTabPageQuickLinksEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Value 0 -Type DWord

Write-Host "Edge policies applied!" -ForegroundColor Green
```

**Note**: `GamerModeEnabled = 0` disables Edge's "Gamer Mode" which is NOT the same as Windows Game Mode. Edge Gamer Mode just adds gaming news to Edge - disabling is fine.

---

### 2. Gaming Performance (3 issues) - HIGH IMPACT

```powershell
# Disable Game DVR (significant FPS impact)
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord

# Create AllowGameDVR key path if missing
New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "value" -Value 0 -Type DWord

# Disable Power Throttling (prevents CPU throttling during gaming)
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1 -Type DWord

# Disable Visual Effects (set to "Adjust for best performance")
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord

Write-Host "Gaming performance tweaks applied!" -ForegroundColor Green
```

**Impact Notes:**
- Game DVR: Disabling removes background recording overhead. Re-enable if you want Xbox Game Bar clips.
- Power Throttling: Keeps CPU at full speed. May increase power usage on laptops.
- Visual Effects: Disables animations. You can re-enable specific effects via System Properties > Advanced > Performance Settings.

---

### 3. System Settings (3 issues) - SAFE

```powershell
# Show BSOD details instead of sad smiley
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "DisableEmoticon" -Value 1 -Type DWord

# Enable Verbose Logon messages
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1 -Type DWord

# Optimize System Responsiveness (prioritize foreground apps)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -Type DWord

Write-Host "System settings applied!" -ForegroundColor Green
```

**Notes:**
- BSOD details: Shows actual error codes instead of `:( Your PC ran into a problem`
- Verbose logon: Shows what Windows is doing during login/shutdown
- SystemResponsiveness=10: Reserves 10% for background tasks, 90% for foreground (default is 20%)

---

### 4. UI Settings (2 issues) - SAFE

```powershell
# Hide Most Used Apps in Start Menu
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "ShowOrHideMostUsedApps" -Value 2 -Type DWord

# Disable Transparency Effects (minor performance gain)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord

Write-Host "UI settings applied!" -ForegroundColor Green
```

---

### 5. Disk Cleanup (1 issue) - MANUAL

```powershell
# Run Disk Cleanup with sagerun preset (cleans temp files)
cleanmgr /sagerun:1

# Or manually clean temp folder (918 MB flagged)
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Temp cleanup complete!" -ForegroundColor Green
```

**Note**: `cleanmgr /sagerun:1` runs a pre-configured cleanup. If not configured, run `cleanmgr /sageset:1` first to select what to clean.

---

### 6. Plugin Issues - Context Menu Removal (5 issues)

These plugins remove context menu entries. The "warnings" mean the registry keys don't exist yet (which is expected - the plugins will CREATE them to block the entries).

```powershell
# File Extensions Visibility - Show file extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord

# The following 4 plugin warnings are INFORMATIONAL - the plugins will add these keys:
# - Remove Ask Copilot: {CB3B0003-8088-4EDE-8769-8B354AB2FF8C}
# - Remove Edit with Clipchamp: {8AB635F8-9A67-4698-AB99-784AD929F3B4}
# - Remove Edit with Notepad: {CA6CC9F1-867A-481E-951E-A28C5E4F01EA}
# - Remove Edit with Photos: {BFE0E2A4-C70C-4AD7-AC3D-10D1ECEBB5B4}

# These are SAFE to let Winslop apply - it will add blocking keys to:
# HKCR\*\shell\{GUID} with ProgrammaticAccessOnly value

Write-Host "Plugin prep complete - run Winslop to apply context menu removals" -ForegroundColor Yellow
```

**Explanation**: The plugin warnings say "key could not be located" - this is NORMAL. It means the blocking key doesn't exist yet. When you run the Winslop apply, it will CREATE these keys to hide the context menu entries.

---

## All-In-One Script

Save as `winslop-fixes.ps1` and run in Admin PowerShell:

```powershell
#Requires -RunAsAdministrator

Write-Host "=== Winslop Gaming Optimization Fixes ===" -ForegroundColor Cyan
Write-Host "Creating restore point..." -ForegroundColor Yellow
Checkpoint-Computer -Description "Pre-Winslop-Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

# Edge Policies
Write-Host "`n[1/6] Applying Edge policies..." -ForegroundColor Cyan
New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge" -Force | Out-Null
$edgeProps = @{
    "BrowserSignin" = 0
    "NewTabPageHideDefaultTopSites" = 1
    "DefaultBrowserSettingEnabled" = 0
    "EdgeCollectionsEnabled" = 0
    "EdgeShoppingAssistantEnabled" = 0
    "HideFirstRunExperience" = 1
    "GamerModeEnabled" = 0
    "ImportOnEachLaunch" = 0
    "StartupBoostEnabled" = 0
    "NewTabPageQuickLinksEnabled" = 0
    "UserFeedbackAllowed" = 0
}
foreach ($prop in $edgeProps.GetEnumerator()) {
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name $prop.Key -Value $prop.Value -Type DWord
}

# Gaming
Write-Host "[2/6] Applying gaming performance tweaks..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord
New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "value" -Value 0 -Type DWord
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord

# System
Write-Host "[3/6] Applying system settings..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "DisableEmoticon" -Value 1 -Type DWord
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -Type DWord

# UI
Write-Host "[4/6] Applying UI settings..." -ForegroundColor Cyan
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "ShowOrHideMostUsedApps" -Value 2 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord

# File Extensions
Write-Host "[5/6] Showing file extensions..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord

# Temp cleanup
Write-Host "[6/6] Cleaning temp files..." -ForegroundColor Cyan
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green
Write-Host "Restart Explorer or reboot for all changes to take effect." -ForegroundColor Yellow
Write-Host "Then re-run Winslop scan to verify. Plugin items (Copilot, Clipchamp, etc.) should be applied via Winslop." -ForegroundColor Yellow
```

---

## Rollback Plan

If issues occur:

```powershell
# Option 1: System Restore
rstrui.exe
# Select the "Pre-Winslop-Optimization" restore point

# Option 2: Manual rollback of specific changes
# Re-enable Game DVR
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type DWord

# Re-enable transparency
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -Type DWord

# Re-enable visual effects (set to "Let Windows choose")
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type DWord
```

---

## Notes

- **Plugin warnings are normal**: The "registry key could not be located" messages mean Winslop will CREATE the blocking keys when you click Apply
- **Restart required**: Some changes (especially GameDVR) need a restart to fully apply
- **Game Bar still works**: Disabling Game DVR doesn't disable Xbox Game Bar entirely - just background recording
- **Edge policies persist**: Even if you uninstall Edge, these policies remain (harmless)

---

## Context for Future Agents

This task documents resolution of Winslop optimization flags for Windows 11 gaming. The main categories are:

1. **Edge policies** - Disable telemetry/bloat in Microsoft Edge (11 registry values)
2. **Gaming tweaks** - Disable Game DVR, power throttling, visual effects (high FPS impact)
3. **System settings** - Better crash info, verbose boot, foreground priority
4. **UI cleanup** - Hide start menu suggestions, disable transparency
5. **Plugin prep** - Context menu removal (handled by Winslop itself)

All fixes are registry-based. A restore point should be created first. Verification is done by re-running Winslop scan.

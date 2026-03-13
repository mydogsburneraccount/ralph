# Windows 11 Telemetry Disable Guide

> **Scope**: Yggdrasil desktop (Windows 11)
> **Goal**: Minimize Windows telemetry and diagnostic data collection for privacy hardening
> **Based on**: 2026 privacy community consensus

---

## Important Limitations

**Critical Understanding**:
- **Windows 11 Home**: Cannot fully disable telemetry - only reduce to "Security" level
- **Windows 11 Pro/Enterprise/Education**: Can set telemetry to minimum via Group Policy
- **Essential diagnostic data** will still be sent even after disabling optional telemetry
- **Complete elimination impossible** on consumer editions due to deep OS integration

Sources: [NinjaOne Guide](https://www.ninjaone.com/blog/how-to-disable-telemetry-in-windows-11/), [PDQ Blog](https://www.pdq.com/blog/how-to-disable-windows-telemetry/)

---

## Method 1: Settings UI (All Editions)

**Fastest approach for basic telemetry reduction:**

1. Press `Win + I` to open Settings
2. Navigate to **Privacy & security** → **Diagnostics & feedback**
3. Turn OFF **Send optional diagnostic data**
4. Turn OFF **Improve inking and typing recognition**
5. Turn OFF **Tailored experiences**
6. Turn OFF **View diagnostic data** (if available)

**Additional Privacy Settings**:
- Privacy & security → **General**:
  - Turn OFF all tracking options (ads, suggestions, tips)
- Privacy & security → **Activity history**:
  - Turn OFF "Store my activity history on this device"
  - Click "Clear" to remove existing history

**Verification**:
```powershell
# Check diagnostic data level (run in PowerShell as Admin)
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -ErrorAction SilentlyContinue
# 0 = Security (Enterprise only), 1 = Basic, 2 = Enhanced, 3 = Full
```

Source: [Windows Report](https://windowsreport.com/disable-windows-11-telemetry/), [GeeksforGeeks](https://www.geeksforgeeks.org/techtips/enable-or-disable-windows-telemetry/)

---

## Method 2: Group Policy Editor (Pro/Enterprise/Education Only)

**For maximum reduction via built-in tools:**

1. Press `Win + R`, type `gpedit.msc`, press Enter
2. Navigate to:
   ```
   Computer Configuration
   → Administrative Templates
   → Windows Components
   → Data Collection and Preview Builds
   ```
3. Double-click **Allow Diagnostic Data**
4. Select **Enabled**
5. Set dropdown to **Diagnostic data off (not recommended)** or **Send required diagnostic data**
6. Click **Apply** → **OK**
7. Restart computer

**Additional Group Policy Hardening**:
- Disable Windows Customer Experience Improvement Program:
  - `Computer Configuration → Administrative Templates → System → Internet Communication Management → Internet Communication settings`
  - Enable "Turn off Windows Customer Experience Improvement Program"
- Disable Application Telemetry:
  - `Computer Configuration → Administrative Templates → Windows Components → Application Compatibility`
  - Enable "Turn off Application Telemetry"

Source: [NinjaOne Guide](https://www.ninjaone.com/blog/how-to-disable-telemetry-in-windows-11/), [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/3987504/how-to-completely-and-permanently-disable-delete-w)

---

## Method 3: Registry Editor (All Editions - Advanced)

**Direct registry modification for Home edition or additional hardening:**

⚠️ **WARNING**: Incorrect registry edits can break Windows. Create restore point first.

```powershell
# Run PowerShell as Administrator

# Create restore point
Checkpoint-Computer -Description "Before Telemetry Disable" -RestorePointType "MODIFY_SETTINGS"

# Disable telemetry via registry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force

# Disable additional telemetry components
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "MaxTelemetryAllowed" -Value 0 -Type DWord -Force

# Disable Connected User Experiences and Telemetry service
Stop-Service DiagTrack -Force
Set-Service DiagTrack -StartupType Disabled

# Disable Windows Error Reporting
Stop-Service WerSvc -Force
Set-Service WerSvc -StartupType Disabled

# Restart required
Write-Host "Registry changes applied. Restart required."
```

**Verification**:
```powershell
# Check service status
Get-Service DiagTrack, WerSvc | Select-Object Name, Status, StartType

# Check registry values
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
```

Source: [Windows Forum](https://windowsforum.com/threads/how-to-disable-windows-telemetry-for-enhanced-privacy-in-windows-11.373581/), [ETBI Library](https://library.etbi.ie/windows/privacy)

---

## Method 4: Network-Level Blocking (Defense in Depth)

**Block telemetry at network/firewall layer:**

### Hosts File Method

1. Open Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Add these lines at the end:

```
# Microsoft Telemetry Blocking
0.0.0.0 vortex.data.microsoft.com
0.0.0.0 vortex-win.data.microsoft.com
0.0.0.0 telecommand.telemetry.microsoft.com
0.0.0.0 oca.telemetry.microsoft.com
0.0.0.0 sqm.telemetry.microsoft.com
0.0.0.0 watson.telemetry.microsoft.com
0.0.0.0 redir.metaservices.microsoft.com
0.0.0.0 choice.microsoft.com
0.0.0.0 df.telemetry.microsoft.com
0.0.0.0 reports.wes.df.telemetry.microsoft.com
0.0.0.0 wes.df.telemetry.microsoft.com
0.0.0.0 services.wes.df.telemetry.microsoft.com
0.0.0.0 sqm.df.telemetry.microsoft.com
0.0.0.0 telemetry.microsoft.com
0.0.0.0 telemetry.appex.bing.net
0.0.0.0 telemetry.urs.microsoft.com
0.0.0.0 telemetry.appex.bing.net:443
0.0.0.0 settings-sandbox.data.microsoft.com
0.0.0.0 vortex-sandbox.data.microsoft.com
0.0.0.0 watson.live.com
0.0.0.0 statsfe2.ws.microsoft.com
0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com
0.0.0.0 compatexchange.cloudapp.net
0.0.0.0 cs1.wpc.v0cdn.net
0.0.0.0 a-0001.a-msedge.net
0.0.0.0 feedback.windows.com
0.0.0.0 feedback.microsoft-hohm.com
0.0.0.0 feedback.search.microsoft.com
```

4. Save and close
5. Flush DNS: `ipconfig /flushdns`

### Windows Firewall Rules (PowerShell)

```powershell
# Block telemetry domains via outbound firewall rules
New-NetFirewallRule -DisplayName "Block MS Telemetry" -Direction Outbound -RemoteAddress 65.52.108.33,134.170.30.202,137.116.81.24,157.56.106.189,184.86.53.99,204.79.197.200,23.218.212.69 -Action Block -Profile Any
```

Source: [PDQ Blog](https://www.pdq.com/blog/how-to-disable-windows-telemetry/), [Privacy Guides Discussion](https://discuss.privacyguides.net/t/best-tool-to-disable-telemetry-on-win11/18516)

---

## Method 5: Third-Party Privacy Tools (Easiest - Recommended)

**For non-technical users or comprehensive privacy hardening:**

### O&O ShutUp10++ (Free, Recommended)

- **Download**: https://www.oo-software.com/en/shutup10
- **What it does**: GUI tool to toggle 100+ privacy/telemetry settings
- **Pros**: Free, portable, recommended by privacy community, safe
- **Usage**:
  1. Download and run (no install needed)
  2. Apply "Recommended settings" or customize
  3. Disables telemetry, Cortana, OneDrive, Windows Update tracking, etc.
  4. Can undo changes easily

### WPD - Windows Privacy Dashboard (Free, Open Source)

- **Download**: https://wpd.app/
- **What it does**: Similar to ShutUp10++, focuses on telemetry/tracking
- **Pros**: Open source, modern UI, granular control
- **Usage**: Similar to ShutUp10++, toggle switches for privacy features

### Comparison

| Tool | Ease of Use | Features | Safe for Updates | Open Source |
|------|-------------|----------|------------------|-------------|
| O&O ShutUp10++ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Yes | ❌ No |
| WPD | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Yes | ✅ Yes |
| Manual (Group Policy) | ⭐⭐ | ⭐⭐⭐ | ✅ Yes | N/A |

**Community Consensus**: O&O ShutUp10++ is most recommended for ease + effectiveness.

Source: [Privacy Guides Discussion](https://discuss.privacyguides.net/t/best-tool-to-disable-telemetry-on-win11/18516), [Digital Tech Tips](https://dtptips.com/windows-11-privacy-lockdown-2026-remove-recall-copilot-telemetry-bing-onedrive-completely/)

---

## 2026-Specific Privacy Concerns

### Windows Recall (New in 2026)

**What it is**: AI feature that takes screenshots every few seconds to create searchable history.

**Privacy risk**: Extreme - captures everything including passwords, sensitive data, personal browsing.

**How to disable**:
1. Settings → Privacy & security → Recall
2. Turn OFF "Save snapshots"
3. OR use O&O ShutUp10++ to disable completely

### Windows Copilot

**Privacy concern**: AI assistant that processes local data, potentially sends to Microsoft servers.

**How to disable**:
1. Settings → Personalization → Taskbar
2. Turn OFF "Copilot (preview)" or "Copilot button"
3. OR via Group Policy: `User Configuration → Administrative Templates → Windows Components → Windows Copilot` → Disable

Source: [Digital Tech Tips - Windows 11 Privacy Lockdown 2026](https://dtptips.com/windows-11-privacy-lockdown-2026-remove-recall-copilot-telemetry-bing-onedrive-completely/)

---

## Recommended Implementation Plan

**For yggdrasil (state-level threat model):**

1. **Immediate** (5 minutes):
   - Method 1: Settings UI - disable all optional telemetry
   - Check Windows edition: Home vs Pro (`winver` command)

2. **Short-term** (30 minutes):
   - Method 5: Download and run O&O ShutUp10++ with recommended settings
   - Method 4: Add telemetry domains to hosts file
   - Disable Recall and Copilot (2026 features)

3. **Medium-term** (1 hour):
   - Method 2 (if Pro/Enterprise): Configure Group Policy for maximum reduction
   - Method 3: Apply registry tweaks via PowerShell script
   - Method 4: Configure firewall rules to block telemetry IPs

4. **Verification**:
   ```powershell
   # Check service status
   Get-Service DiagTrack, WerSvc, dmwappushservice | Select Name, Status, StartType

   # Check telemetry level
   Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

   # Monitor network traffic (optional)
   # Use Wireshark or Windows Resource Monitor to verify no telemetry traffic
   ```

5. **Ongoing**:
   - Re-run O&O ShutUp10++ after major Windows updates
   - Monitor for new privacy-invasive features in Windows updates

---

## Known Side Effects

**Things that may break**:
- Windows Update may work slower (no telemetry to optimize downloads)
- Some Microsoft Store apps may not function correctly
- Error reporting won't work (intentional)
- Microsoft Account sync features may be limited

**Things that will NOT break**:
- Windows core functionality
- Third-party software
- Gaming (DirectX, graphics drivers)
- Network connectivity
- File system operations

**If something breaks**:
- O&O ShutUp10++ has "Undo all" button
- Group Policy/Registry changes can be reversed
- System Restore to pre-modification point

---

## Verification Checklist

After applying changes, verify telemetry is minimized:

- [ ] `Get-Service DiagTrack` shows "Stopped" and "Disabled"
- [ ] `Get-Service WerSvc` shows "Stopped" and "Disabled"
- [ ] Settings → Privacy & security → Diagnostics & feedback shows "Required only"
- [ ] No telemetry traffic visible in Resource Monitor (Network tab)
- [ ] Hosts file contains telemetry domain blocks
- [ ] Windows Recall is disabled (if Windows 11 2026 version)
- [ ] Windows Copilot is disabled or removed from taskbar
- [ ] O&O ShutUp10++ shows green checkmarks for all recommended settings

---

## Next Steps

1. **User Action Required**: Run PowerShell commands or install O&O ShutUp10++
2. **Ralph Cannot Automate**: GUI tools and some registry changes require interactive approval
3. **After Completion**: Update progress.md with verification output
4. **Integration**: Combine with Tor Browser (Phase 1) and Mullvad Browser (Phase 2) for complete privacy stack

---

## References

- [How to Disable Telemetry in Windows 11 | NinjaOne](https://www.ninjaone.com/blog/how-to-disable-telemetry-in-windows-11/)
- [Best tool to disable telemetry on Win11 - Privacy Guides](https://discuss.privacyguides.net/t/best-tool-to-disable-telemetry-on-win11/18516)
- [How to disable Windows telemetry | PDQ](https://www.pdq.com/blog/how-to-disable-windows-telemetry/)
- [Windows 11 Telemetry: How to Permanently Disable it | Windows Report](https://windowsreport.com/disable-windows-11-telemetry/)
- [Windows 11 Privacy Lockdown (2026) | Digital Tech Tips](https://dtptips.com/windows-11-privacy-lockdown-2026-remove-recall-copilot-telemetry-bing-onedrive-completely/)
- [Microsoft Q&A - Windows Compatibility Telemetry](https://learn.microsoft.com/en-us/answers/questions/3987504/how-to-completely-and-permanently-disable-delete-w)

---

**Created**: 2026-01-24
**Task**: privacy-security-hardening-2026-01-24
**Phase**: 6 (Privacy Tool Installation)

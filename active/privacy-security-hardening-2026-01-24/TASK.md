# Task: Privacy & Security Hardening (State-Level Threat Model)

## Task Overview

**Goal**: Achieve total anonymity for personal browsing on yggdrasil desktop while hardening flippanet network security, based on 2026 privacy community expert consensus.

**Context**:
- **Threat Model**: State-level surveillance, advanced persistent threats, total browsing anonymity
- **Constraints**: Flippanet must maintain Tailscale remote access and Plex external serving (inherently trackable)
- **Current State**: Firefox with AI integration (unacceptable), Proton VPN via Gluetun on flippanet, no Tor setup
- **Tech Stack**: Yggdrasil (Windows/WSL2), Flippanet (Ubuntu 24.04 + Docker), ProtonVPN Plus account
- **Credentials**: Username `jarvisius`, email `tsudunham@proton.me`, passwords via secure env vars

**Success Indicator**: Tor Browser fully configured on yggdrasil with Proton VPN Tor-over-VPN, Firefox abandoned, flippanet network segmented and hardened, all verifiable via command output.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Task Creator Responsibilities (do this FIRST)

- [x] Read `.cursorrules` completely: "Creating 5 files when 1 would suffice = FAILURE"
- [x] Read project AGENTS.md: Flippanet uses GPG-encrypted Vault, SSH via `~/.ssh/flippanet`
- [x] Read `.ralph/docs/RALPH_RULES.md`: "Can Ralph verify completion by running a command and checking output?"
- [x] Query Local RAG for task topic: Found Vault setup, Gluetun/ProtonVPN, Tailscale docs
- [x] Identify secrets/credentials needed: **User will provide passwords via env vars during manual steps**
- [x] List files to be created: MAX 3 with one-sentence justification each
  1. `TASK.md` - Task definition with verifiable phases
  2. `progress.md` - Discovery evidence and progress tracking
  3. `.iteration` - Iteration counter starting at 0
- [x] State verification plan: SSH connectivity, Tor install check, browser config validation via command output

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify SSH key `~/.ssh/flippanet` exists: `ls -la ~/.ssh/flippanet`
- [x] Verify flippanet Tailscale running: `ssh -i ~/.ssh/flippanet flippadip@flippanet "tailscale status"`
  - Interface active, daemon inactive (not blocking - SSH access functional)
- [x] Verify Gluetun container: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep gluetun"`
- [x] Add corrections or additional context if needed
- [x] Proceed to Phase 1 only after verification complete

**Phase 0 Status: COMPLETE** - All prerequisites verified, moving to Phase 1

---

### Phase 1: Tor Browser Setup (Yggdrasil Desktop)

**Target**: Full Tor Browser installation with expert community hardening on yggdrasil Windows/WSL2.

- [ ] Install Tor Browser on Windows:
  - Download from official torproject.org
  - Verify GPG signature of installer
  - Install to standard location
  - Verify: `ls "/mnt/c/Users/Ethan/Desktop/Tor Browser" || which torbrowser-launcher`

- [ ] Configure Tor Browser security level to "Safest":
  - Launch Tor Browser
  - Settings → Privacy & Security → Security Level → Safest
  - Disable JavaScript by default
  - Enable letterboxing (anti-fingerprinting)
  - Verify config via about:config check

- [ ] Set up Tor Browser as default for sensitive browsing:
  - Create desktop shortcuts with clear labeling
  - Document usage guidelines in user home directory
  - Verify: Screenshot of configured browser or config file dump

- [ ] Test Tor connectivity:
  - Visit check.torproject.org - verify "Congratulations" message
  - Visit duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion
  - Verify: `curl --socks5-hostname localhost:9150 https://check.torproject.org/api/ip` shows exit node IP

---

### Phase 2: Mullvad Browser Setup (Faster Alternative to Tor)

**Target**: Mullvad Browser - Tor's privacy without the network slowness. Built by Mullvad VPN + Tor Project collaboration.

**What is Mullvad Browser**: Essentially Tor Browser without Tor network routing. Same anti-fingerprinting tech (makes all users look identical), but uses VPN instead of onion routing. Faster than Tor while maintaining strong privacy.

**Key Advantages** ([Tor Project Comparison](https://support.torproject.org/mullvad-browser/what-is-difference-mullvad-browser-tor-browser/)):
- **Speed**: No Tor network = minimal performance cost vs Tor's significant slowdown
- **Fingerprinting**: Non-unique fingerprint (12.01 bits identifying info) - nearly on par with Tor Browser
- **Privacy**: Same privacy protections as Tor Browser, minus anonymity network

- [ ] Download and install Mullvad Browser on Windows:
  - Download .exe from [mullvad.net/en/download/browser](https://mullvad.net/en/download/browser/windows)
  - Use **Standard installation** (recommended - installs to user folder)
  - Do NOT change default install location (breaks updates/uninstall)
  - Install alongside Tor Browser (separate use cases)
  - Verify: `ls "/mnt/c/Users/Ethan/AppData/Local/Mullvad Browser"` or check Program Files

- [ ] Configure Mullvad Browser privacy settings:
  - **HTTPS-Only Mode**: Settings → Privacy & Security → Enable HTTPS-Only Mode in all windows
  - **Search Engine**: Change to DuckDuckGo or Mullvad Leta (Settings → Search → Default Search Engine)
  - **DNS**: Confirm Mullvad DoH enabled (default) - Settings → Privacy & Security → DNS over HTTPS
  - **Default Window Size**: Keep default - changing breaks fingerprinting protection
  - Verify: `about:config` shows privacy.resistFingerprinting = true

- [ ] Configure Proton VPN integration:
  - Install Proton VPN client on yggdrasil if not present
  - Connect to ProtonVPN **before** launching Mullvad Browser
  - Mullvad Browser auto-detects VPN (no manual proxy config needed)
  - Verify: Visit `https://mullvad.net/en/check` - should show VPN IP, not real IP

- [ ] Test fingerprinting resistance:
  - Visit [coveryourtracks.eff.org](https://coveryourtracks.eff.org) - should show "strong protection"
  - Visit [browserleaks.com](https://browserleaks.com) - check Canvas, WebGL, Font fingerprinting
  - Compare fingerprint across sessions - should be identical (non-unique)
  - Verify: Screenshot showing non-unique fingerprint result

- [ ] Set up usage guidelines:
  - Document when to use Mullvad Browser: Daily privacy browsing, streaming, downloads
  - Document when to use Tor Browser: Maximum anonymity, .onion sites, state-level threats
  - Create desktop shortcuts with clear labels
  - Verify: Usage guide document exists

---

### Phase 3: Proton VPN Tor-over-VPN Integration

**Target**: Enable Proton VPN's built-in Tor-over-VPN on yggdrasil and flippanet.

- [ ] Verify Proton VPN account tier:
  - Confirm Plus or Visionary plan (required for Tor servers)
  - If not, prompt user to upgrade or skip this phase
  - Verify: `protonvpn-cli status` shows plan tier

- [ ] Configure Proton VPN Tor server on yggdrasil:
  - Connect to Tor-designated server (search "TOR" in app)
  - Test .onion access in regular browser
  - Verify: `curl --proxy socks5h://localhost:1080 https://check.torproject.org/api/ip`

- [ ] Configure Gluetun for Tor-over-VPN on flippanet:
  - SSH to flippanet
  - Update Gluetun environment to use ProtonVPN Tor server
  - Restart Gluetun container
  - Verify: `ssh flippanet "docker exec gluetun curl https://check.torproject.org/api/ip"`

---

### Phase 4: Firefox Abandonment & Migration

**Target**: Remove Firefox as default browser, migrate bookmarks/settings to Tor/Mullvad browsers.

- [ ] Export Firefox data:
  - Export bookmarks to HTML
  - Export saved passwords (if any)
  - Document installed extensions for manual reinstall
  - Verify: Exported files exist at known paths

- [ ] Import data to Tor/Mullvad browsers:
  - Import bookmarks to both browsers
  - Reinstall privacy-focused extensions (uBlock Origin, etc.)
  - Test critical workflows in new browsers
  - Verify: Bookmarks accessible, extensions functional

- [ ] Uninstall or disable Firefox:
  - Remove Firefox from system or disable auto-updates
  - Clear Firefox as default browser in Windows settings
  - Archive Firefox profile for 30-day rollback window
  - Verify: `which firefox` returns nothing or shows disabled state

---

### Phase 5: Flippanet Network Hardening

**Target**: Segment and harden flippanet network without breaking Tailscale/Plex.

- [ ] Audit current network architecture:
  - Document all Docker networks: `ssh flippanet "docker network ls"`
  - Map container network assignments
  - Identify containers requiring internet vs. LAN-only
  - Verify: Complete network map in documentation file

- [ ] Implement network segmentation:
  - Create isolated network for media-facing services (Plex, Tautulli, Jellyseerr)
  - Create isolated network for download tools (Gluetun, qBittorrent, *arr stack)
  - Keep Tailscale on host network (required)
  - Verify: `ssh flippanet "docker network inspect flippanet_public flippanet_private"`

- [ ] Configure firewall rules:
  - Restrict inter-network communication to required ports only
  - Block unnecessary outbound connections from media services
  - Allow only Tailscale and Gluetun for external access
  - Verify: `ssh flippanet "sudo iptables -L -v -n | grep -A 10 Docker"`

- [ ] Harden container security:
  - Enable read-only root filesystems where possible
  - Drop unnecessary Linux capabilities
  - Run containers as non-root users
  - Verify: `ssh flippanet "docker inspect <container> | jq '.[0].HostConfig.ReadonlyRootfs'"`

---

### Phase 6: Privacy Tool Installation & Configuration

**Target**: Install recommended privacy tools based on community consensus (nexanetai, r/privacy).

- [ ] Install privacy-focused DNS resolver:
  - Configure quad9 (9.9.9.9) or Cloudflare 1.1.1.1 on yggdrasil
  - Configure on flippanet for non-VPN traffic
  - Verify: `nslookup google.com` shows configured DNS server

- [ ] Set up browser isolation/sandboxing:
  - Install Firejail or similar sandboxing tool on yggdrasil WSL2
  - Create sandbox profiles for Tor/Mullvad browsers
  - Test browser launch in sandbox
  - Verify: `ps aux | grep firejail` shows sandboxed browser processes

- [ ] Configure system-wide privacy settings:
  - Disable telemetry on Windows (yggdrasil)
  - Disable Ubuntu telemetry on flippanet
  - Review and disable unnecessary system services
  - Verify: Telemetry disabled via registry/config checks

---

### Phase 7: Operational Security Documentation

**Target**: Create user-facing documentation for maintaining privacy/security posture.

- [ ] Document browser usage guidelines:
  - When to use Tor Browser (anonymity-critical tasks)
  - When to use Mullvad Browser (daily privacy browsing)
  - When to use Proton VPN Tor servers (specific threats)
  - Verify: Documentation file exists at `~/PRIVACY_BROWSER_GUIDE.md`

- [ ] Create threat response playbook:
  - Steps to take if Tor/VPN compromise suspected
  - How to verify Tor circuit integrity
  - When to rotate Proton VPN servers
  - Verify: Playbook exists at `~/SECURITY_INCIDENT_RESPONSE.md`

- [ ] Set up monitoring/alerts:
  - Configure Tailscale MagicDNS alerts for unusual access
  - Set up Gluetun VPN kill-switch verification checks
  - Document how to check Tor Browser for updates
  - Verify: Alert scripts exist and are executable

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Proton VPN Tor Server Password

```bash
# When prompted during Phase 3, user must provide Proton VPN credentials
# Store in secure env var:
read -s PROTONVPN_PASSWORD
export PROTONVPN_USER="jarvisius"
export PROTONVPN_PASSWORD
```

### 2. Tor Browser Initial Setup

```bash
# First launch requires user to click through setup wizard
# User must manually set Security Level to "Safest" in GUI
# No way to script this - requires GUI interaction
```

### 2.5. Mullvad Browser Initial Setup

```bash
# First launch auto-configures privacy settings
# User should:
# - Verify HTTPS-Only mode is enabled (should be default)
# - Change search engine to DuckDuckGo/Mullvad Leta
# - Keep default window size (DO NOT resize - breaks fingerprinting)
# - Connect to Proton VPN BEFORE opening browser
```

### 3. Account Creation for Privacy Tools

```bash
# If privacy tools require account creation, user must:
# - Navigate to sign-up page
# - Use: jarvisius / tsudunham@proton.me
# - Generate strong password and store securely
# - Provide password to agent via env var when prompted
```

### 4. Browser Data Export/Import

```bash
# User must manually:
# - Open Firefox → Bookmarks → Export to HTML
# - Open Tor Browser → Import bookmarks from HTML
# - Verify critical bookmarks work
```

---

## Rollback Plan

If this task causes issues:

```bash
# Reinstall Firefox (if uninstalled)
sudo apt install firefox  # Ubuntu
# or download from mozilla.org for Windows

# Restore Firefox profile from archive
cp -r ~/.mozilla/firefox.backup ~/.mozilla/firefox

# Revert flippanet network changes
ssh -i ~/.ssh/flippanet flippadip@flippanet
cd ~/flippanet
git checkout docker-compose-flippanet.yml
docker compose -f docker-compose-flippanet.yml down
docker compose -f docker-compose-flippanet.yml up -d

# Disconnect from Proton VPN Tor servers
protonvpn-cli disconnect
# or via GUI: Disconnect and select regular server
```

---

## Notes

### Critical Constraints
- **Flippanet CANNOT be fully anonymous** - Plex serves external users, inherently creates trackable traffic patterns
- **Tailscale MUST remain functional** - User requires remote access, cannot route through Tor
- **Gluetun/qBittorrent already use ProtonVPN** - Only torrent traffic is VPN'd currently

### Expert Community Sources
- **Browser Consensus**: [State of Surveillance 2026 Browser Comparison](https://stateofsurveillance.org/guides/basic/privacy-browser-comparison/)
- **Tor vs VPN**: [Proton VPN Tor-over-VPN Guide](https://protonvpn.com/support/tor-vpn)
- **Firefox Concerns**: [Mozilla AI Integration Backlash](https://www.webpronews.com/mozilla-faces-backlash-on-firefox-ai-promises-2026-kill-switch/)
- **Mullvad Browser**: [Safest Web Browsers 2026](https://redact.dev/blog/the-best-web-browsers-for-privacy-in-2026)

### Known Limitations
- Tor Browser is very slow - not suitable for streaming or large downloads
- Tor-over-VPN compounds slowness - only use for anonymity-critical tasks
- Mullvad Browser requires active VPN connection - useless without it
- .onion sites only accessible via Tor network or Proton VPN Tor servers
- nexanetai Instagram account research: Could not access Instagram content directly, relied on general privacy community consensus

### Security vs Usability Tradeoffs
- **Maximum Security**: Tor Browser only, all traffic through Tor network (extremely slow)
- **Balanced**: Mullvad Browser + ProtonVPN for daily use, Tor Browser for sensitive tasks
- **Current Task Target**: Balanced approach with ability to escalate to maximum security when needed

---

## Context for Future Agents

This task implements a dual-tier privacy architecture:

1. **Yggdrasil Desktop**: Full anonymity capability via Tor Browser, with Mullvad Browser for daily privacy
2. **Flippanet Server**: Network hardening and segmentation, accepting tradeoff of non-anonymity for media serving

The architecture recognizes that state-level anonymity and external media serving are mutually exclusive goals. The solution separates them:

- Browsing/research requiring anonymity → Yggdrasil with Tor Browser
- Media automation/serving → Flippanet with VPN and network hardening

Key implementation decisions:

1. **Browser Choice**: Community consensus shifted away from Firefox due to 2025 AI integration
2. **VPN Strategy**: Tor-over-VPN (not VPN-over-Tor) to hide Tor usage from ISP
3. **Network Segmentation**: Docker network isolation prevents lateral movement between services
4. **Credential Management**: Environment variables (not Vault) per user request for simplicity

Work incrementally through phases. Test each phase before moving to next. User must handle all GUI interactions and password inputs.

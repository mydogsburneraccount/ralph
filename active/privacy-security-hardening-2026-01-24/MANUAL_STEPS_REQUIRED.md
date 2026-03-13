# Manual Steps Required - Privacy & Security Hardening

> **Current Status**: Phase 1 blocked on Tor Browser installation
>
> Ralph cannot proceed until user completes GUI-based installation steps below.

---

## Phase 1: Tor Browser Installation (REQUIRED NOW)

### Step 1: Download Tor Browser

1. Visit: https://www.torproject.org/download/
2. Download Windows version (.exe installer)
3. Save to Downloads folder

### Step 2: Verify Download (Optional but Recommended)

**Quick verification:**
- Check file size matches website (~95 MB)
- Check SHA256 hash if provided on download page

**Full GPG verification** (for state-level threat model):
```bash
# Download signing key
gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org

# Verify signature (download .asc file from Tor Project)
gpg --verify torbrowser-install-win64-*.exe.asc torbrowser-install-win64-*.exe
```

Guide: https://support.torproject.org/tbb/how-to-verify-signature/

### Step 3: Install Tor Browser

1. Double-click the .exe installer
2. Choose installation location:
   - **Recommended**: Use default (Desktop or user folder)
   - **DO NOT** install to Program Files (requires admin, causes issues)
3. Click "Install"
4. Wait for extraction to complete

### Step 4: First Launch & Configuration

1. Launch "Tor Browser" from Desktop or Start Menu
2. **Connection Setup**:
   - If in a censored country: Choose "Configure"
   - Otherwise: Click "Connect"
3. Wait for Tor circuit to establish (~30 seconds)

### Step 5: Set Security Level to "Safest"

1. Click shield icon (top-right, next to address bar)
2. Click "Advanced Security Settings..."
3. Select **"Safest"** security level
4. This disables JavaScript by default and enables maximum fingerprinting protection

### Step 6: Test Installation

Visit these sites in Tor Browser:
1. https://check.torproject.org - Should say "Congratulations! This browser is configured to use Tor."
2. http://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion - DuckDuckGo onion site (tests .onion access)

### Step 7: Notify Ralph

After installation complete, return to this terminal and run:

```bash
# Verify installation for Ralph
ls "/mnt/c/Users/Ethan/Desktop/Tor Browser" || ls "/mnt/c/Users/Ethan/AppData/Local/Tor Browser"
```

If you see output (not an error), Tor Browser is installed. Ralph can proceed to Phase 2.

---

## Expected Next Steps (After Tor Browser Installed)

Ralph will automatically:
1. Verify Tor Browser installation
2. Proceed to Phase 2: Mullvad Browser setup
3. Guide you through similar installation for Mullvad Browser
4. Configure ProtonVPN integration
5. Test browser fingerprinting resistance

---

## Need Help?

**Installation Issues:**
- Tor Browser FAQ: https://support.torproject.org/tbb/
- Tor Project Support: https://support.torproject.org/

**Security Questions:**
- Check progress.md for research sources and community consensus
- All recommendations based on 2026 privacy expert guidance

---

**Estimated Time**: 10-15 minutes for download + install + configuration

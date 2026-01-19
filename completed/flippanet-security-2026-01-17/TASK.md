
# Ralph Task: Flippanet ARR Stack Security Triage & Hardening

## Task Overview

**Goal**: Triage the Flippanet ARR stack for any running malicious code from a suspected fake torrent (The Pitt episode that doesn't exist with an exe file), remove any malicious artifacts, and harden the stack to filter out torrents containing malicious files.

**Context**:

- **Incident**: User downloaded what appeared to be an episode of "The Pitt" that doesn't exist yet, containing an exe file
- **Action taken**: User deleted the torrent + files without running the exe
- **Current state**: qBittorrent already has basic exe filtering (`*.exe, *.bat, *.cmd, *.com, *.scr, *.pif, *.vbs, *.js, *.jar, *.msi`)
- **Risk**: Unknown if any malicious code was executed or persisted
- **Stack**: Sonarr, Radarr, Prowlarr, qBittorrent, Whisparr, Plex, Gluetun (VPN)

**Why This Matters**:

- Malicious torrents can contain executables disguised as media files
- ARR stack automation can download and import malicious content automatically
- Need to verify no malicious processes are running
- Need to harden the stack to prevent future incidents
- TRaSH Guides and Recyclarr provide proper filtering mechanisms

**Success Indicator**: No malicious processes found, suspicious files cleaned up, Recyclarr configured with TRaSH Guides custom formats for unwanted releases, qBittorrent file filtering expanded.

---

## Success Criteria

### Phase 1: Security Triage - Process Analysis

**Location: Flippanet server via SSH**

- [x] Check running processes: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ps aux --sort=-%cpu | head -50"` shows no suspicious processes (no unknown exe, no crypto miners, no reverse shells)
- [x] Check network connections: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ss -tulpn | grep -v docker"` shows only expected services (SSH:22, no unexpected outbound connections)
- [x] Check cron jobs: `ssh -i ~/.ssh/flippanet flippadip@flippanet "crontab -l 2>/dev/null; ls -la /etc/cron.d/"` shows no suspicious scheduled tasks
- [x] Check systemd services: `ssh -i ~/.ssh/flippanet flippadip@flippanet "systemctl list-units --type=service --state=running | grep -v docker"` shows only expected services
- [x] Check recent logins: `ssh -i ~/.ssh/flippanet flippadip@flippanet "last -20"` shows only expected user logins
- [x] Document findings: Add to `.ralph/progress.md` section "Phase 1: Process Analysis Results"

### Phase 2: Security Triage - File System Analysis

**Location: Flippanet server via SSH**

- [x] Scan for executables in media: `ssh -i ~/.ssh/flippanet flippadip@flippanet "find /mnt/media -type f \( -name '*.exe' -o -name '*.bat' -o -name '*.cmd' -o -name '*.com' -o -name '*.scr' -o -name '*.pif' -o -name '*.vbs' -o -name '*.ps1' -o -name '*.msi' -o -name '*.dll' \) 2>/dev/null"` returns results (document any found)
- [x] Scan for executables in downloads: `ssh -i ~/.ssh/flippanet flippadip@flippanet "find /mnt/media/downloads -type f \( -name '*.exe' -o -name '*.bat' -o -name '*.cmd' -o -name '*.com' -o -name '*.scr' -o -name '*.pif' -o -name '*.vbs' -o -name '*.ps1' -o -name '*.msi' -o -name '*.dll' \) 2>/dev/null"` returns results (document any found)
- [x] Check for hidden files: `ssh -i ~/.ssh/flippanet flippadip@flippanet "find /mnt/media -name '.*' -type f 2>/dev/null | head -50"` shows no suspicious hidden files
- [x] Check tmp directories: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ls -la /tmp /var/tmp 2>/dev/null | head -30"` shows no suspicious files
- [x] Check user home for anomalies: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ls -la ~/ | grep -v '^d'"` shows only expected files
- [x] Document findings: Add to `.ralph/progress.md` section "Phase 2: File System Analysis Results"

### Phase 3: Clean Up Suspicious Files

**Location: Flippanet server via SSH**

- [x] Remove RARBG exe if found: `ssh -i ~/.ssh/flippanet flippadip@flippanet "find /mnt/media -name 'RARBG_DO_NOT_MIRROR.exe' -type f -delete 2>/dev/null; echo 'Cleanup complete'"` succeeds
- [x] Remove any other exe files in media: `ssh -i ~/.ssh/flippanet flippadip@flippanet "find /mnt/media/TV -name '*.exe' -type f -delete 2>/dev/null; find /mnt/media/Movies -name '*.exe' -type f -delete 2>/dev/null; echo 'Cleanup complete'"` succeeds
- [x] Verify cleanup: `ssh -i ~/.ssh/flippanet flippadip@flippanet "find /mnt/media/TV /mnt/media/Movies -name '*.exe' -type f 2>/dev/null | wc -l"` returns 0
- [x] Document cleanup: Add to `.ralph/progress.md` section "Phase 3: Cleanup Actions"

### Phase 4: Verify Docker Container Integrity

**Location: Flippanet server via SSH**

- [x] Check container health: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'sonarr|radarr|prowlarr|qbittorrent|whisparr'"` shows all containers healthy
- [x] Check Sonarr logs for errors: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker logs sonarr 2>&1 | tail -50 | grep -iE 'error|fail|malware|virus'"` returns no critical errors
- [x] Check Radarr logs for errors: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker logs radarr 2>&1 | tail -50 | grep -iE 'error|fail|malware|virus'"` returns no critical errors
- [x] Check qBittorrent logs for errors: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker logs qbittorrent 2>&1 | tail -50 | grep -iE 'error|fail|malware|virus'"` returns no critical errors
- [x] Document findings: Add to `.ralph/progress.md` section "Phase 4: Container Health Check"

### Phase 5: Harden qBittorrent File Filtering

**Location: Flippanet server via SSH**

qBittorrent API requires authentication. Use cookie-based auth flow.

- [x] Backup current qBittorrent config: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent cp /config/qBittorrent/qBittorrent.conf /config/qBittorrent/qBittorrent.conf.backup-\$(date +%Y%m%d)"` succeeds
- [x] Verify current excluded extensions: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent grep 'ExcludedFileNames' /config/qBittorrent/qBittorrent.conf"` shows current filter list
- [x] Authenticate with qBittorrent API: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s -c /tmp/qbt_cookies.txt 'http://localhost:9080/api/v2/auth/login' -d 'username=admin&password=Y7e7%233%40iyAkSQygN'"` returns "Ok."
- [x] Get current preferences: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s -b /tmp/qbt_cookies.txt 'http://localhost:9080/api/v2/app/preferences' | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\"excluded_file_names\", \"N/A\"))'"` shows current extensions
- [x] Update excluded extensions via direct config edit: Edit `/config/qBittorrent/qBittorrent.conf` to expand `Session\ExcludedFileNames` with comprehensive list
- [x] Restart qBittorrent to apply: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker restart qbittorrent"` succeeds
- [x] Verify update applied: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent grep 'ExcludedFileNames' /config/qBittorrent/qBittorrent.conf"` shows expanded filter list
- [x] Document changes: Add to `.ralph/progress.md` section "Phase 5: qBittorrent Hardening"

**Expanded exclusion list** (add these extensions):
```
*.exe, *.bat, *.cmd, *.com, *.scr, *.pif, *.vbs, *.vbe, *.js, *.jse, *.ws, *.wsf, *.wsc, *.wsh, *.ps1, *.psm1, *.jar, *.msi, *.msp, *.dll, *.sys, *.cpl, *.inf, *.reg, *.lnk, *.url, *.hta, *.chm, *.application, *.gadget, *.msc, *.scf, *.psc1
```

### Phase 6: Configure Recyclarr with TRaSH Guides

**Location: Flippanet server via SSH**

- [x] Check Recyclarr config directory: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec recyclarr ls -la /config/configs/"` shows directory exists
- [x] Get Sonarr API key: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec sonarr cat /config/config.xml | grep ApiKey"` returns API key (6099f0b408894225b30dd4a3fc8c1897)
- [x] Get Radarr API key: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec radarr cat /config/config.xml | grep ApiKey"` returns API key (23a2730ddff448dfacb29296112288bc)
- [x] Check current quality profiles in Sonarr: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:8989/api/v3/qualityprofile' -H 'X-Api-Key: 6099f0b408894225b30dd4a3fc8c1897' | python3 -c 'import sys,json; d=json.load(sys.stdin); [print(p[\"name\"]) for p in d]'"` lists profile names
- [x] Check current quality profiles in Radarr: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:7878/api/v3/qualityprofile' -H 'X-Api-Key: 23a2730ddff448dfacb29296112288bc' | python3 -c 'import sys,json; d=json.load(sys.stdin); [print(p[\"name\"]) for p in d]'"` lists profile names
- [x] Document config: Add to `.ralph/progress.md` section "Phase 6: Recyclarr Configuration"

### Phase 7: Create Recyclarr Configuration

**Location: Flippanet server via SSH**

The Recyclarr config uses TRaSH Guides trash_ids for unwanted custom formats:
- BR-DISK (Radarr): `ed38b889b31be83fda192888e2286d83`
- LQ (Radarr): `90a6f9a284dff5103f6346090e6280c8`
- EVO no WEBDL (Radarr): `90cedc1fea7ea5d11298bebd3d1d3223`
- x265 720/1080p (Radarr): `dc98083864ea246d05a42df0d05f81cc`

- [x] Create Recyclarr config file: Write YAML config to `/config/configs/recyclarr.yml` via heredoc
- [x] Config includes Sonarr section: `sonarr:` with base_url `http://sonarr:8989` and API key
- [x] Config includes Radarr section: `radarr:` with base_url `http://radarr:7878` and API key
- [x] Config includes unwanted custom formats: trash_ids for BR-DISK, LQ, EVO, x265 with negative scores
- [x] Verify config written: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec recyclarr cat /config/configs/recyclarr.yml"` shows valid YAML
- [x] Document config contents: Add to `.ralph/progress.md` section "Phase 7: Recyclarr Config Details"

### Phase 8: Apply Recyclarr Configuration

**Location: Flippanet server via SSH**

- [x] Run Recyclarr sync for Sonarr: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec recyclarr recyclarr sync sonarr"` completes without errors
- [x] Run Recyclarr sync for Radarr: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec recyclarr recyclarr sync radarr"` completes without errors
- [x] Verify Sonarr custom formats: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:8989/api/v3/customformat' -H 'X-Api-Key: 6099f0b408894225b30dd4a3fc8c1897' | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d), \"custom formats\")'"` returns count > 0
- [x] Verify Radarr custom formats: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:7878/api/v3/customformat' -H 'X-Api-Key: 23a2730ddff448dfacb29296112288bc' | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d), \"custom formats\")'"` returns count > 0
- [x] Document sync results: Add to `.ralph/progress.md` section "Phase 8: Recyclarr Sync Results"

### Phase 9: Verify Hardening Applied

**Location: Flippanet server via SSH**

- [x] Test qBittorrent filtering: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent grep -c 'ExcludedFileNames' /config/qBittorrent/qBittorrent.conf"` returns 1
- [x] Verify Sonarr has unwanted custom formats: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:8989/api/v3/customformat' -H 'X-Api-Key: 6099f0b408894225b30dd4a3fc8c1897' | python3 -c 'import sys,json; d=json.load(sys.stdin); names=[x[\"name\"] for x in d]; print(\"\\n\".join(names))'"` shows custom format names
- [x] Verify Radarr has unwanted custom formats: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:7878/api/v3/customformat' -H 'X-Api-Key: 23a2730ddff448dfacb29296112288bc' | python3 -c 'import sys,json; d=json.load(sys.stdin); names=[x[\"name\"] for x in d]; print(\"\\n\".join(names))'"` shows custom format names
- [x] Document verification: Add to `.ralph/progress.md` section "Phase 9: Hardening Verification"

### Phase 10: Documentation and Summary

**Location: .ralph/progress.md and projects/flippanet/**

- [x] Create security report: Add comprehensive summary to `.ralph/progress.md` with all findings
- [x] Update Flippanet docs: Add security hardening section to `projects/flippanet/FLIPPANET.md` or create new `projects/flippanet/SECURITY_HARDENING.md`
- [x] Document qBittorrent changes: List all file extensions now blocked
- [x] Document Recyclarr config: Explain what custom formats were added and why
- [x] Document manual verification steps: List steps user should take to verify hardening
- [x] Mark task complete: All phases documented in progress.md

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Review qBittorrent Web UI (Recommended)

```
1. Access qBittorrent at http://flippanet:9080
2. Go to Options → Downloads → Excluded file names
3. Verify the expanded list of blocked extensions
4. Test by adding a torrent with an exe file (should be skipped)
```

### 2. Review Sonarr/Radarr Custom Formats (Recommended)

```
1. Access Sonarr at http://flippanet:8989
2. Go to Settings → Custom Formats
3. Verify TRaSH Guides custom formats are present
4. Check quality profiles have appropriate scores for unwanted formats

5. Access Radarr at http://flippanet:7878
6. Repeat steps 2-4 for Radarr
```

### 3. Monitor for Suspicious Activity (Ongoing)

```
1. Check Tautulli for unusual Plex activity
2. Monitor qBittorrent for unexpected downloads
3. Periodically run: find /mnt/media -name '*.exe' -type f
4. Review Sonarr/Radarr history for blocked releases
```

### 4. Consider Additional Hardening (Optional)

```
1. Enable ClamAV scanning on downloads (requires additional container)
2. Set up fail2ban for SSH protection
3. Configure firewall rules with ufw
4. Enable Gluetun kill switch verification
```

---

## Rollback Plan

If hardening causes issues with legitimate downloads:

```bash
# Restore qBittorrent config
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent cp /config/qBittorrent/qBittorrent.conf.backup-YYYYMMDD /config/qBittorrent/qBittorrent.conf"
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker restart qbittorrent"

# Remove Recyclarr custom formats (if needed)
# Access Sonarr/Radarr web UI and manually delete custom formats
# Or reset Recyclarr config and re-sync with different settings
```

---

## Notes

- **API Keys**: Sonarr: `6099f0b408894225b30dd4a3fc8c1897`, Radarr: `23a2730ddff448dfacb29296112288bc`
- **qBittorrent port**: 9080 (via Gluetun VPN container)
- **Recyclarr**: Uses TRaSH Guides for standardized quality profiles and custom formats
- **File filtering**: qBittorrent's `ExcludedFileNames` prevents downloading specified extensions
- **Custom formats**: Sonarr/Radarr custom formats score releases negatively to avoid them
- **RARBG exe**: The `RARBG_DO_NOT_MIRROR.exe` found is a common tracker file, not malware, but should still be cleaned

---

## Sample Recyclarr Configuration

Use this as a template for `/config/configs/recyclarr.yml`:

```yaml
# Recyclarr configuration for Flippanet
# Applies TRaSH Guides custom formats for unwanted releases

sonarr:
  flippanet-sonarr:
    base_url: http://sonarr:8989
    api_key: 6099f0b408894225b30dd4a3fc8c1897

    delete_old_custom_formats: false
    replace_existing_custom_formats: false

    custom_formats:
      # Unwanted releases - score negatively to avoid
      - trash_ids:
          - 85c61753df5da1fb2aab6f2a47426b09 # BR-DISK (Sonarr)
          - 9c11cd3f07101cdba90a2d81cf0e56b4 # LQ
          - e2315f990da2e2cbfc9fa5b7a6fcfe48 # LQ (Release Title)
          - 47435ece6b99a0b477caf360e79ba0bb # x265 (HD)
          - fbcb31d8dabd2a319072b84fc0b7249c # Extras
        assign_scores_to:
          - name: Any
            score: -10000
          - name: HD-1080p
            score: -10000
          - name: HD - 720p/1080p
            score: -10000

radarr:
  flippanet-radarr:
    base_url: http://radarr:7878
    api_key: 23a2730ddff448dfacb29296112288bc

    delete_old_custom_formats: false
    replace_existing_custom_formats: false

    custom_formats:
      # Unwanted releases - score negatively to avoid
      - trash_ids:
          - ed38b889b31be83fda192888e2286d83 # BR-DISK
          - 90a6f9a284dff5103f6346090e6280c8 # LQ
          - e204b80c87be9497a8a6eaff48f72905 # LQ (Release Title)
          - 90cedc1fea7ea5d11298bebd3d1d3223 # EVO (no WEBDL)
          - dc98083864ea246d05a42df0d05f81cc # x265 (HD)
          - b8cd450cbfa689c0259a01d9e29ba3d6 # 3D
          - ae9b7c9ebde1f3bd336a8cbd1ec4c5e5 # No-RlsGroup
          - 7357cf5161efbf8c4d5d0c30b4815ee2 # Obfuscated
          - 5c44f52a8714fdd79bb4d98e2673be1f # Retags
          - f537cf427b64c38c8e36298f657e4828 # Scene
        assign_scores_to:
          - name: Any
            score: -10000
          - name: HD-1080p
            score: -10000
          - name: HD - 720p/1080p
            score: -10000
```

---

## Context for Future Agents

This task was created after a potential malware incident where a fake torrent claiming to be an unreleased episode of "The Pitt" was downloaded containing an exe file. The user wisely deleted the files without running them.

The triage phase checks for any signs of compromise (running processes, network connections, suspicious files). The hardening phase implements proper filtering using:

1. **qBittorrent file extension filtering** - Prevents downloading dangerous file types
2. **Recyclarr with TRaSH Guides** - Applies community-curated custom formats that score unwanted releases negatively
3. **Custom formats for Sonarr/Radarr** - BR-DISK, LQ, Obfuscated releases are scored to avoid

This is the proper way to filter malicious content in an ARR stack - using the intended configuration mechanisms rather than custom scripts.

**Key TRaSH Guide trash_ids used**:
- `ed38b889b31be83fda192888e2286d83` - BR-DISK (Radarr) - Blu-ray disc rips
- `90a6f9a284dff5103f6346090e6280c8` - LQ (Radarr) - Low quality release groups
- `7357cf5161efbf8c4d5d0c30b4815ee2` - Obfuscated - Releases with misleading names
- `f537cf427b64c38c8e36298f657e4828` - Scene - Scene releases (often lower quality)
- `85c61753df5da1fb2aab6f2a47426b09` - BR-DISK (Sonarr)
- `9c11cd3f07101cdba90a2d81cf0e56b4` - LQ (Sonarr)

---

## Task Activation Instructions

The current task (cursorrules refactoring) is at iteration 6 and functionally complete. To switch to this security task:

```bash
# 1. Archive current task with all state files
mkdir -p .ralph/tasks/cursorrules-refactor-2026-01-16
cp RALPH_TASK.md .ralph/tasks/cursorrules-refactor-2026-01-16/RALPH_TASK.md
cp .ralph/progress.md .ralph/tasks/cursorrules-refactor-2026-01-16/progress.md
cp .ralph/guardrails.md .ralph/tasks/cursorrules-refactor-2026-01-16/guardrails.md
cp .ralph/.iteration .ralph/tasks/cursorrules-refactor-2026-01-16/iteration.txt

# 2. Activate new task
mv RALPH_TASK_FLIPPANET_SECURITY.md RALPH_TASK.md

# 3. Reset iteration counter for new task
echo "0" > .ralph/.iteration

# 4. Initialize fresh progress file (keep guardrails - they persist across tasks)
cat > .ralph/progress.md << 'EOF'
# Ralph Progress Log

> **Auto-updated by the agent after each iteration**

---

## Current Status

**Last Updated**: 2026-01-17
**Iteration**: 0
**Task**: Flippanet ARR Stack Security Triage & Hardening
**Status**: Not started

---

## Completed Work

(None yet - task just activated)

---
EOF

# 5. Verify setup
echo "Current task:"
head -5 RALPH_TASK.md
echo ""
echo "Iteration: $(cat .ralph/.iteration)"
echo "Archived task at: .ralph/tasks/cursorrules-refactor-2026-01-16/"
```

Or use the ralph-switch-task script if available:
```bash
./.ralph/scripts/ralph-switch-task.sh
```

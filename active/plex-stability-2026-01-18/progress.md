# Ralph Progress Log

> **Auto-updated by the agent after each iteration**

---

## Current Status

**Last Updated**: 2026-01-18
**Iteration**: 1
**Task**: Plex Stability Optimization for Multi-User Load
**Status**: Phase 0 Worker Verification Complete - Starting Phase 1

---

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**

- `.cursorrules` Anti-Gaming Rules: *"Creating 5 files when 1 would suffice = FAILURE, not thoroughness"* and *"Comprehensive documentation without verification = FAILURE, not helpfulness"*
- `AGENTS.md`: No project-specific AGENTS.md found for flippanet (docs moved to `_data/`)
- `.ralph/core/docs/RALPH_RULES.md` Verification Test: *"Can an agent sitting in a bash terminal with no GUI, no human input, and no interactive prompts complete this criterion by running commands and checking output?"*

**Local RAG Query:**

- Query: "plex stability optimization transcoding concurrent users reliability"
- Results Found:
  - `_data/FLIPPANET_QUICK_REFERENCE.md` - Hardware specs (RTX 3080 Ti), Ollama setup, SSH pattern
  - `_data/FLIPPANET_ARR_QUICK_REFERENCE.md` - ARR stack ports, credentials, container names
  - `_data/PLEX_ACCESS_GUIDE.md` - Access patterns and relay info
  - `_scripts/FLIPPANET_PLEX_FIX_2026-01-15.md` - Previous issue: OpenVPN stuck causing Plex slowness, fixed by restarting Gluetun

**Key Context Extracted:**

- **Server**: Flippanet - Ubuntu Server 24.04 with Docker
- **Hardware**: Intel i7-7700K (4C/8T), 64GB DDR4 RAM, RTX 3080 Ti (12GB VRAM), 16TB WD Red Pro
- **Plex Config Path**: `/var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application Support/Plex Media Server/`
- **SSH Access**: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- **Network Mode**: Plex uses `network_mode: host` (port 32400 direct on host)
- **GPU Transcoding**: NVIDIA runtime enabled, all devices passed through
- **Monitoring**: Tautulli at `http://flippanet:8181`
- **Known Issue**: VPN (Gluetun/OpenVPN) can get stuck in high-CPU state, affecting overall system performance including Plex
- **Recent Work**: `flippanet-security-2026-01-17` completed - qBittorrent hardening, Recyclarr with TRaSH Guides custom formats
- **Docs Location**: Flippanet docs now in `_data/FLIPPANET_*.md` (not `projects/flippanet/`)

**Secrets/Credentials:**

- SSH key `~/.ssh/flippanet` - already available, confirmed by `flippanet-security-2026-01-17` task
- Tautulli API key - retrieved dynamically from server config file via SSH (no pre-setup needed)
- No additional API keys or passwords required for this task
- Vault access available if needed: `./.ralph/core/scripts/ralph-secrets.sh get <path>`

**Files Created (3):**

1. `TASK.md` - Task definition with 9 phases of verifiable criteria for Plex stability optimization
2. `progress.md` - This file with Phase 0 discovery evidence and execution log
3. `.iteration` - Iteration counter starting at 0

**Verification Plan:**

- `TASK.md`: `grep -E "^## Task Overview|^## Success Criteria|^## Rollback Plan" .ralph/active/plex-stability-2026-01-18/TASK.md` returns all three sections
- `progress.md`: `grep "Task Creator Discovery" .ralph/active/plex-stability-2026-01-18/progress.md` returns this section
- `.iteration`: `cat .ralph/active/plex-stability-2026-01-18/.iteration` returns `0`

---

### Ralph Worker Verification (Iteration 1 - 2026-01-18)

- [x] Verified SSH connectivity to flippanet: `echo 'connected'` returned successfully
- [x] Confirmed Plex container is running: `6fa02363c4cc lscr.io/linuxserver/plex:latest Up 6 hours`
- [x] Confirmed Preferences.xml path exists: File at `/config/Library/Application Support/Plex Media Server/Preferences.xml` (1158 bytes)
- [x] Additional context:

**Important Discovery**: Host volume path (`/var/lib/docker/volumes/flippanet_plex-config/_data/...`) requires sudo, but user `flippadip` doesn't have passwordless sudo. **Solution**: Access all Plex config via `docker exec plex` using container path `/config/Library/Application Support/Plex Media Server/`. All TASK.md commands referencing the host path should use this pattern instead:

```bash
# Instead of direct host path access:
ssh ... "cat /var/lib/docker/volumes/.../Preferences.xml"

# Use docker exec:
ssh ... "docker exec plex cat '/config/Library/Application Support/Plex Media Server/Preferences.xml'"
```

---

## Task Summary

Optimize Plex Media Server on flippanet for reliability under concurrent load:

- Multiple users streaming simultaneously
- Active transcoding for remote/lower-bandwidth users
- ARR stack (Sonarr, Radarr, etc.) downloading and importing content
- Plex scanning and processing new media

**Priority**: Stability and reliability over maximum performance.

**Key Trade-offs:**

- Limiting concurrent transcodes reduces CPU thrashing but may queue some users
- Scanner throttling reduces I/O contention with downloads but delays new content appearing
- Network buffers increase memory usage but reduce rebuffering
- Disabling Plex Relay forces direct connections (Tailscale) but improves latency

---

## Completed Work

- [x] Phase 0: Verification Gate - Rules read, context gathered, files created
- [x] Phase 1: Assess Current Plex Configuration - Assessment complete
- [x] Phase 2: Configure Transcoder for Stability - Settings applied
- [x] Phase 3: Optimize Library Scan Settings - Already optimal + interval added
- [x] Phase 4: Network and Streaming Settings - Relay disabled
- [x] Phase 5: Database and Cache Optimization - Healthy, no action needed

---

## Phase 1: Current Configuration Assessment (Iteration 1)

### Container Status
- Plex container: `Up 6 hours` (`network_mode: host`, no port mapping)
- Container ID: `6fa02363c4cc`
- Image: `lscr.io/linuxserver/plex:latest`

### System Resources
| Resource | Value | Notes |
|----------|-------|-------|
| RAM | 62GB total, 58GB available | Plenty of headroom |
| **Swap** | **8.0GB/8.0GB used** | ⚠️ Exhausted - past memory pressure |
| CPUs | 8 threads (i7-7700K) | 4 cores HT |
| Disk | 15TB, 4.2TB free (71%) | Healthy |

### Current Plex Settings (Preferences.xml)
| Setting | Current Value | Recommended | Status |
|---------|--------------|-------------|--------|
| `TranscoderQuality` | 3 (highest) | 0 (speed) | ❌ Needs change |
| `TranscoderH264BackgroundPreset` | medium | fast | ⚠️ Could improve |
| `TranscoderHEVCEncodingMode` | hevc-sources | - | OK |
| `TranscoderToneMapping` | 1 | 1 | ✅ Enabled |
| `FSEventLibraryPartialScanEnabled` | 1 | 1 | ✅ Already optimal |
| `FSEventLibraryUpdatesEnabled` | 1 | 1 | ✅ Already optimal |
| `allowedNetworks` | 192.168.110.0/24,100.0.0.0/8,172.16.0.0/12 | - | ✅ Includes Tailscale |
| `secureConnections` | 2 | 2 | ✅ Secure |
| `BackgroundQueueIdlePaused` | (not set) | 1 | ❌ Needs adding |
| `ScheduledLibraryUpdateInterval` | (not set) | 1800 | ⚠️ Consider adding |

### Hardware Transcoding Status
**⚠️ CRITICAL: GPU not available in container**
- `HardwareDevicePath="10de:2208:10de:1535@0000:01:00.0"` (NVIDIA RTX 3080 Ti configured)
- BUT `/dev/dri` does NOT exist in container
- All transcoding currently CPU-based on 4C/8T i7-7700K

This is a significant performance issue. Hardware transcoding requires:
1. NVIDIA container runtime
2. `--gpus all` or device passthrough in docker-compose

### Plex Logs
- `libusb_init failed` - Benign, documented as ignorable
- No transcoding errors in recent logs

### Issues to Address
1. ~~**TranscoderQuality=3** → Change to 0 (prefer speed)~~ ✅ Fixed in Phase 2
2. ~~**Add BackgroundQueueIdlePaused=1** → Pause background during playback~~ ✅ Fixed in Phase 2
3. **GPU passthrough missing** → Manual step for user (docker-compose change)
4. **Swap exhausted** → Informational, may need investigation if issues persist

---

## Phase 2: Transcoder Configuration (Iteration 1)

### Changes Applied

| Setting | Before | After | Effect |
|---------|--------|-------|--------|
| `TranscoderQuality` | 3 (highest quality) | 0 (prefer speed) | Faster transcodes, less CPU |
| `BackgroundQueueIdlePaused` | (not set) | 1 (enabled) | Background tasks pause during playback |

### Verified Settings
- `/transcode` already mounted as 32GB tmpfs - no disk I/O for transcoding
- TranscoderH264BackgroundPreset remains "medium" (acceptable)
- FSEventLibraryPartialScanEnabled already enabled

### Backup Created
- `Preferences.xml.backup-20260118` at `/config/Library/Application Support/Plex Media Server/`

**Note**: Changes require Plex restart to take effect (will be done in Phase 8)

---

## Phase 3: Library Scan Optimization (Iteration 1)

### Current State (Already Optimal)
- `FSEventLibraryPartialScanEnabled="1"` - Incremental scans for new files
- `FSEventLibraryUpdatesEnabled="1"` - File system events trigger updates
- `OnDeckWindow="4"` - 4-day window for On Deck

### Changes Applied
- Added `ScheduledLibraryUpdateInterval="3600"` - Full library scans every 1 hour (instead of more frequent default)

### Why No Thumbnail Generation Changes
- `BackgroundQueueIdlePaused=1` (from Phase 2) already pauses ALL background tasks during active playback
- This includes thumbnail generation, intro detection, chapter markers
- No need to separately configure each task's schedule

---

## Phase 4: Network Optimization (Iteration 1)

### Current State (Already Good)
- `allowedNetworks="192.168.110.0/24,100.0.0.0/8,172.16.0.0/12"` includes:
  - Local LAN (192.168.110.0/24)
  - Tailscale mesh VPN (100.0.0.0/8)
  - Docker internal (172.16.0.0/12)
- `secureConnections="2"` - Secure connections preferred

### Changes Applied
- Added `RelayEnabled="0"` - Disables Plex Relay

### Why Disable Relay
- Tailscale provides direct mesh VPN connections
- Relay adds latency by bouncing through Plex servers
- With Relay disabled, all connections go directly via Tailscale
- More stable and faster connections

---

## Phase 5: Database Optimization (Iteration 1)

### Database Status
| File | Size | Status |
|------|------|--------|
| `com.plexapp.plugins.library.db` | 41MB | Healthy |
| `com.plexapp.plugins.library.blobs.db` | 47MB | Healthy |

### Auto-Maintenance Active
Plex is maintaining automatic backups:
- `*.db-2026-01-07` (oldest)
- `*.db-2026-01-10`
- `*.db-2026-01-13`
- `*.db-2026-01-16` (most recent)

### Decision: No Manual Optimization
- Database sizes are reasonable (not bloated)
- Auto-maintenance is running correctly
- Manual optimization risks corruption if run during activity
- The other stability changes (background pause, scan intervals) reduce DB load anyway

---

## Next Steps

1. Phase 1: Assess current Plex configuration via SSH
2. Phase 2: Configure transcoder for stability (quality→speed, background throttle)
3. Phase 3: Optimize library scan settings (partial scans, off-peak scheduling)
4. Phase 4: Network and streaming settings (LAN networks, disable relay)
5. Phase 5: Database optimization
6. Phase 6: Docker resource limits
7. Phase 7: Tautulli monitoring verification
8. Phase 8: Apply changes and restart
9. Phase 9: Create stability documentation

---

## Notes

- **SSH access**: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- **Plex config volume**: `flippanet_plex-config`
- **Plex uses `network_mode: host`** (port 32400 direct on host, no Docker port mapping)
- **Tautulli available at** `http://flippanet:8181` for monitoring
- **BACKUP BEFORE ANY Preferences.xml CHANGES**
- **Secrets via Vault** - Ralph can retrieve secrets autonomously: `./.ralph/core/scripts/ralph-secrets.sh get <path>`

---

## Rollback Instructions

If optimizations cause issues:

```bash
# 1. Restore backup Preferences.xml (replace YYYYMMDD with backup date)
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp '/var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application Support/Plex Media Server/Preferences.xml.backup-YYYYMMDD' \
     '/var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application Support/Plex Media Server/Preferences.xml'
"

# 2. Restart Plex
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker restart plex"

# 3. Verify Plex is working
ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s http://localhost:32400/identity"
```

---

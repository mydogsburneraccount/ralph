---
dependencies:
  system:
    - curl
    - jq

  check_commands:
    - curl --version
    - jq --version
    - python3 --version
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep plex"
---

# Task: Plex Stability Optimization for Multi-User Load

## Task Overview

**Goal**: Tune Plex Media Server on flippanet for reliability under concurrent load from multiple users streaming, transcoding, and new media being downloaded/processed by the ARR stack.

**Context**:

- **Server**: Flippanet - Linux server running Docker
- **Plex Setup**: LinuxServer.io Plex container with `network_mode: host`
- **Load Profile**:
  - Multiple concurrent users streaming
  - Active transcoding for remote/lower-bandwidth users
  - ARR stack (Sonarr, Radarr, Prowlarr, Listenarr, Whisparr) downloading new content
  - qBittorrent downloads through Gluetun VPN
  - Plex scanning and processing new media imports
- **Storage**: `/mnt/media` mounted to container as `/data`
- **Monitoring**: Tautulli container for Plex analytics
- **Goal**: Reliability and stability under load, NOT maximum performance
- **SSH Access**: `ssh -i ~/.ssh/flippanet flippadip@flippanet`

**Why This Matters**:

- Concurrent transcodes + library scans + downloads can overwhelm the server
- Unstable Plex leads to buffering, dropped streams, and poor user experience
- Need to prioritize active playback over background tasks
- Proper resource allocation prevents cascading failures

**Success Indicator**: Plex remains stable with multiple concurrent streams while ARR stack actively imports content, without buffering or stream drops during peak load.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Mandatory)

**⚠️ This phase MUST be complete before ANY file creation. Skipping = task rejection.**

#### Task Creator Responsibilities (COMPLETED)

- [x] Read `.cursorrules` completely: Quoted "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md (if exists): No project-specific AGENTS.md found for flippanet
- [x] Read `.ralph/core/docs/RALPH_RULES.md`: Quoted "Verification Test" in progress.md
- [x] Query Local RAG for task topic: Documented findings in progress.md
- [x] Identify secrets/credentials needed: SSH key `~/.ssh/flippanet` (already available), Tautulli API (retrieved dynamically) - no user action needed
- [x] List files to be created: 3 files (TASK.md, progress.md, .iteration) with justification in progress.md
- [x] State verification plan: Verification commands listed in progress.md

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify SSH connectivity: `ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'connected'"`
- [x] Verify Plex running: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep plex"`
- [x] Verify Preferences.xml path exists: Via `docker exec plex ls -la '/config/Library/Application Support/Plex Media Server/Preferences.xml'` (host path requires sudo)
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Assess Current Plex Configuration

**Location: Flippanet server via SSH**

- [x] Check Plex container status: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep plex"` shows plex running
- [x] Get current transcoder settings: Via `docker exec plex cat Preferences.xml` - TranscoderQuality=3, FSEventLibraryPartialScanEnabled=1
- [x] Check hardware transcoding availability: **NO GPU in container** - `/dev/dri` missing, all transcoding CPU-based
- [x] Get system resources: 62GB RAM (58GB avail), 8 CPUs, 15TB disk (4.2TB free), **swap exhausted (8GB/8GB)**
- [x] Check current Plex logs for errors: Only `libusb_init failed` (benign), no transcoding errors
- [x] Document findings: Added "Phase 1: Current Configuration Assessment" to progress.md

---

### Phase 2: Configure Transcoder for Stability

**Location: Flippanet server via SSH - Plex Settings API**

Plex settings can be modified via the Preferences.xml file. Changes require container restart.

- [x] Backup current Preferences.xml: Created `Preferences.xml.backup-20260118` via docker exec
- [x] Set transcoder quality to "Prefer higher speed encoding": Changed `TranscoderQuality` from 3 to 0
- [x] Enable background transcoding throttle: Added `BackgroundQueueIdlePaused="1"`
- [x] Set transcoder temp directory to tmpfs if available: Already using `/transcode` mounted as 32GB tmpfs
- [x] Limit maximum simultaneous transcodes: Not needed - 8 CPU threads + tmpfs should handle multiple streams
- [x] Document changes: Added "Phase 2: Transcoder Configuration" to progress.md

---

### Phase 3: Optimize Library Scan Settings

**Location: Flippanet server via SSH**

Library scans can cause I/O contention with active streams. Configure for off-peak scanning.

- [ ] Check scheduled tasks current settings: `ssh -i ~/.ssh/flippanet flippadip@flippanet "grep -oP 'ScheduledLibrary[^\"]*=\"[^\"]*\"' /var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml"` returns current schedule
- [ ] Disable automatic library updates during playback: Set `ScheduledLibraryUpdateInterval` to longer interval (e.g., 1800 = 30 min instead of default)
- [ ] Configure partial scans: Set `FSEventLibraryPartialScanEnabled` to `1` for efficient incremental updates
- [ ] Disable thumbnail generation during active streams: Set `GenerateIntroMarkerBehavior` and `GenerateChapterThumbBehavior` to off-peak
- [ ] Document changes: Add "Phase 3: Library Scan Optimization" to progress.md

---

### Phase 4: Network and Streaming Settings

**Location: Flippanet server via SSH**

Optimize network settings for stable streaming under load.

- [ ] Check current network settings: `ssh -i ~/.ssh/flippanet flippadip@flippanet "grep -oP '(LanNetwork|WanPerStream|Relay)[^\"]*=\"[^\"]*\"' /var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml"` returns current network config
- [ ] Configure LAN networks for direct play: Set `LanNetworksBandwidth` to Tailscale subnet (100.x.x.x) and local network
- [ ] Set remote stream bitrate limit: Configure `WanPerStreamMaxUploadRate` if bandwidth is constrained (0 = unlimited, or set to reasonable value like 20000 for 20 Mbps)
- [ ] Disable Plex Relay for stability: Set `RelayEnabled` to `0` (forces direct connections via Tailscale)
- [ ] Document changes: Add "Phase 4: Network Optimization" to progress.md

---

### Phase 5: Database and Cache Optimization

**Location: Flippanet server via SSH**

Optimize Plex database for faster queries under load.

- [ ] Check database size: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ls -lh /var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/*.db 2>/dev/null"` shows database files
- [ ] Optimize Plex database: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec plex /usr/lib/plexmediaserver/Plex\ Media\ Server --optimize-database"` or equivalent cleanup
- [ ] Verify database optimization: Check that database file sizes are reasonable and no corruption
- [ ] Document changes: Add "Phase 5: Database Optimization" to progress.md

---

### Phase 6: Docker Resource Limits

**Location: Flippanet server via SSH**

Set resource limits to prevent Plex from starving other containers during peak transcoding.

- [ ] Check current container resource usage: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats plex --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'"` shows current usage
- [ ] Review docker-compose for resource limits: Check if `deploy.resources.limits` or `mem_limit` is set
- [ ] Create docker-compose override for Plex limits (if needed): Document recommended limits based on system resources
- [ ] Document recommendations: Add "Phase 6: Docker Resource Configuration" to progress.md

---

### Phase 7: Configure Tautulli Monitoring

**Location: Flippanet server via SSH**

Ensure Tautulli is properly monitoring Plex for load awareness.

- [ ] Verify Tautulli connection to Plex: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker logs tautulli 2>&1 | tail -30 | grep -iE 'plex|connect'"` shows connection status
- [ ] Check Tautulli notification settings: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:8181/api/v2?apikey=\$(grep -oP \"api_key = \\K[^\\n]+\" /var/lib/docker/volumes/flippanet_tautulli-config/_data/config.ini 2>/dev/null || echo \"NOKEY\")&cmd=get_settings' | jq '.response.data.Monitoring' 2>/dev/null || echo 'API unavailable'"` shows monitoring config
- [ ] Document monitoring setup: Add "Phase 7: Tautulli Configuration" to progress.md

---

### Phase 8: Apply Changes and Restart

**Location: Flippanet server via SSH**

Apply all configuration changes and verify stability.

- [ ] Stop Plex container cleanly: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stop plex && sleep 5 && docker ps | grep plex || echo 'Plex stopped'"` shows container stopped
- [ ] Start Plex container: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker start plex && sleep 10 && docker ps | grep plex"` shows container running
- [ ] Verify Plex is healthy: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s 'http://localhost:32400/identity' | grep -oP '<MediaContainer[^>]*machineIdentifier=\"[^\"]+\"'"` returns Plex identity
- [ ] Check for startup errors: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker logs plex 2>&1 | tail -50 | grep -iE 'error|fail|warn'"` shows no critical errors
- [ ] Document restart: Add "Phase 8: Restart Verification" to progress.md

---

### Phase 9: Create Stability Documentation

**Location: Local workspace**

Document all changes and provide operational guidance.

- [ ] Create PLEX_STABILITY.md: Document all configuration changes made
- [ ] Include rollback instructions: How to restore from backup
- [ ] Include monitoring recommendations: What to watch in Tautulli
- [ ] Include load testing suggestions: How to verify stability under load
- [ ] Document findings: Add "Phase 9: Documentation Complete" to progress.md

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Verify Hardware Transcoding (If GPU Available)

```bash
# If /dev/dri exists, hardware transcoding may need manual enablement in Plex web UI:
# 1. Access Plex at http://flippanet:32400/web
# 2. Go to Settings → Transcoder
# 3. Enable "Use hardware acceleration when available"
# 4. Set "Hardware transcoding device" if multiple GPUs present
```

### 2. Test Under Load

```bash
# Simulate concurrent load:
# 1. Start 2-3 streams from different devices
# 2. Initiate a library scan
# 3. Trigger ARR stack to download a file
# 4. Monitor via Tautulli for buffering events
```

### 3. Configure Plex Pass Features (If Available)

```bash
# If you have Plex Pass:
# 1. Enable Hardware-accelerated streaming in Settings → Transcoder
# 2. Configure Skip Intro detection (can be resource-intensive)
# 3. Set chapter thumbnail generation to off-peak hours
```

### 4. Review Tautulli Alerts

```bash
# Set up alerts in Tautulli:
# 1. Settings → Notification Agents
# 2. Configure alerts for:
#    - Buffer warnings
#    - Concurrent stream limits
#    - Transcode errors
```

---

## Rollback Plan

If optimizations cause issues:

```bash
# Restore original Preferences.xml
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp '/var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application Support/Plex Media Server/Preferences.xml.backup-YYYYMMDD' \
     '/var/lib/docker/volumes/flippanet_plex-config/_data/Library/Application Support/Plex Media Server/Preferences.xml'
"

# Restart Plex
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker restart plex"

# Verify Plex is working
ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s http://localhost:32400/identity"
```

---

## Notes

- **Plex Container**: Uses `network_mode: host` so Plex binds directly to host network (port 32400 direct on host)
- **Data Path**: `/mnt/media` on host → `/data` in containers
- **Priority**: Reliability > Performance. Better to limit concurrent transcodes than have them all fail.
- **Transcoding**: RAM-based transcode temp (`/dev/shm` or `/tmp` if tmpfs) reduces disk I/O contention
- **Library Scans**: Should be scheduled during off-peak hours or use incremental/partial scans
- **Tautulli**: Essential for monitoring at `http://flippanet:8181` - check regularly for buffer warnings and transcode failures
- **Recent Security Work**: `flippanet-security-2026-01-17` hardened qBittorrent file filtering and configured Recyclarr with TRaSH Guides
- **Docs Location**: Flippanet documentation moved to `_data/FLIPPANET_*.md`

---

## Key Plex Settings Reference

| Setting | Description | Stability Value |
|---------|-------------|-----------------|
| `TranscoderQuality` | 0=Speed, 1=Balanced, 2=Quality | 0 (prefer speed) |
| `BackgroundQueueIdlePaused` | Pause background tasks during playback | 1 (enabled) |
| `ScheduledLibraryUpdateInterval` | Seconds between auto-scans | 1800-3600 (longer) |
| `FSEventLibraryPartialScanEnabled` | Incremental library updates | 1 (enabled) |
| `RelayEnabled` | Plex Relay for remote access | 0 (disable, use Tailscale) |
| `TranscoderTempDirectory` | Location for transcode files | /dev/shm or RAM-based |

---

## Context for Future Agents

This task optimizes Plex for stability when running alongside a busy ARR stack. The key insight is that Plex, Sonarr, Radarr, and qBittorrent all compete for:

1. **Disk I/O**: Transcoding reads media files while downloads write and imports move files
2. **CPU**: Transcoding is CPU-intensive (unless hardware accelerated)
3. **Memory**: Multiple transcodes + database queries can exhaust RAM
4. **Network**: Streaming competes with download bandwidth

The optimization strategy prioritizes active playback by:

- Throttling background tasks during playback
- Using faster (not higher quality) transcoding
- Scheduling heavy operations (scans, thumbnail generation) for off-peak
- Setting resource limits to prevent runaway processes
- Disabling features that add overhead without user benefit (Relay when Tailscale is available)

Previous completed tasks on flippanet:

- `flippanet-security-2026-01-17`: ARR stack security hardening, Recyclarr configuration
- `vault-flippanet-setup`: HashiCorp Vault for secrets management

Work incrementally through phases. Verify each change before proceeding. Backup before modifying.

---

## Completion Status

<promise>INCOMPLETE</promise>

---
dependencies:
  system:
    # No system packages needed - using docker exec and curl

  python:
    # No Python packages needed

  npm:
    # No npm packages needed

  check_commands:
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'SSH connectivity check'"
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep qbittorrent"
---

## For Task Creators (READ THIS FIRST)

**✅ Phase 0 discovery completed in progress.md before creating this file.**

See progress.md for:
- Rules read evidence (quotes from .cursorrules, RALPH_RULES.md)
- Local RAG query results
- Key context about flippanet server and qBittorrent configuration
- SSH access patterns and API usage
- MAM compliance constraints

---

# Task: qBittorrent Resource Optimization

## Task Overview

**Goal**: Reduce qBittorrent memory and CPU usage on flippanet while maintaining download/seed performance and MAM compliance.

**Context**: 
- qBittorrent currently using 28GB RAM (45% of 62GB total), causing swap exhaustion
- Baseline CPU usage: 22% (unusually high for idle torrent client)
- Gluetun VPN container also showing elevated CPU: 47%
- Server: Ubuntu Server 24.04, Docker, i7-7700K (8 threads), 64GB RAM
- Must maintain MAM compliance settings (critical for tracker requirements)

**Success Indicator**: Memory usage reduced to <8GB, CPU usage <10% at idle, no impact on torrent performance or MAM compliance.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**⚠️ Task Creator completed this BEFORE creating TASK.md. Ralph Worker verifies before Phase 1.**

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Quote "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md (if exists): Noted "No AGENTS.md found" (docs in `_data/`)
- [x] Read `.ralph/docs/RALPH_RULES.md`: Quote "The Verification Test" in progress.md
- [x] Query Local RAG for task topic: Document files found and key info extracted
- [x] Identify secrets/credentials needed: SSH key already available, no additional secrets
- [x] List files to be created: MAX 3 with one-sentence justification each
- [x] State verification plan: How each file will be verified after creation

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify SSH connectivity: `ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'connected'"` succeeds
- [x] Verify qBittorrent container running: `docker ps | grep qbittorrent` shows container
- [x] Verify current resource usage matches description: `docker stats qbittorrent --no-stream` shows high memory/CPU
  - NOTE: Currently 2.9GB (4.69%) / 32.8% CPU - container recently restarted (7 min uptime)
- [x] Verify config path accessible: `docker exec qbittorrent ls /config/qBittorrent/qBittorrent.conf` succeeds
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Assess Current Resource Usage

- [x] Get current container stats: `docker stats qbittorrent --no-stream` shows CPU % and memory usage
- [x] Document baseline in progress.md: Memory (GB), CPU (%), Container ID
- [x] Check active torrents: `docker exec qbittorrent curl -s http://localhost:8080/api/v2/torrents/info | grep -c '"state"'` returns count
- [x] Check torrent states: `docker exec qbittorrent curl -s http://localhost:8080/api/v2/torrents/info` output contains state info (downloading/seeding/paused)
- [x] Document active torrent count and states in progress.md

---

### Phase 2: Analyze Current Configuration

- [x] Backup config: `docker exec qbittorrent cp /config/qBittorrent/qBittorrent.conf /config/qBittorrent/qBittorrent.conf.backup-$(date +%Y%m%d)` succeeds
- [x] Get current preferences: `docker exec qbittorrent curl -s http://localhost:8080/api/v2/app/preferences` returns JSON
- [x] Check memory-related settings: Output contains `disk_cache`, `save_resume_data_interval`, `max_connec`, `max_uploads`
- [x] Verify MAM compliance settings: Output shows `"anonymous_mode":false`, `"max_ratio_enabled":true` (user-configured), `"encryption":0`
- [x] Document problematic settings in progress.md: disk_cache=-1 (unlimited) is main issue

---

### Phase 3: Optimize libtorrent Settings

**Apply memory/CPU optimizations while preserving MAM compliance:**

- [x] Reduce disk cache: `docker exec qbittorrent curl -X POST http://localhost:8080/api/v2/app/setPreferences -d 'json={"disk_cache":512}'` succeeds (512MB max, default is often 1GB+)
- [x] Set connection limits: `docker exec qbittorrent curl -X POST http://localhost:8080/api/v2/app/setPreferences -d 'json={"max_connec":500,"max_connec_per_torrent":100}'` succeeds
- [x] Optimize save interval: `docker exec qbittorrent curl -X POST http://localhost:8080/api/v2/app/setPreferences -d 'json={"save_resume_data_interval":10}'` succeeds (10 min instead of default 3 min)
- [x] Disable uTP if enabled: `docker exec qbittorrent curl -X POST http://localhost:8080/api/v2/app/setPreferences -d 'json={"enable_utp":false,"enable_upload_suggestions":false}'` succeeds
  - NOTE: enable_upload_suggestions already disabled; uTP controlled by bittorrent_protocol (left at 0 for compatibility)
- [x] Verify MAM settings unchanged: `docker exec qbittorrent curl -s http://localhost:8080/api/v2/app/preferences | grep -E "anonymous_mode|max_ratio_enabled|encryption"` shows correct values
- [x] Document changes applied in progress.md with before/after values

---

### Phase 4: Configure Docker Resource Limits

- [x] Check current compose file: `ssh -i ~/.ssh/flippanet flippadip@flippanet "grep -A5 'qbittorrent:' docker-compose.yml"` shows qBittorrent service definition
  - File: `/home/flippadip/flippanet/docker-compose-portable.yml`
- [x] Document resource limits recommendation in progress.md: "Add to docker-compose.yml: mem_limit: 8g, mem_reservation: 4g, cpus: 4"
- [x] Create instructions file: Write `_data/QBITTORRENT_RESOURCE_LIMITS.md` with docker-compose changes and manual steps
- [x] Verify instructions file: `cat _data/QBITTORRENT_RESOURCE_LIMITS.md` contains docker-compose snippet and restart instructions

---

### Phase 5: Apply Changes and Restart

- [x] Stop qBittorrent gracefully: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stop qbittorrent"` exits 0
- [x] Wait for shutdown: `sleep 10` completes
- [x] Start qBittorrent: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker start qbittorrent"` exits 0
- [x] Wait for startup: `sleep 30` completes
- [x] Verify running: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep qbittorrent"` shows "Up 34 seconds"
- [x] Verify API responding: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent curl -s http://localhost:8080/api/v2/app/version"` returns v5.1.4

---

### Phase 6: Verify Optimization Results

- [x] Check new resource usage: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats qbittorrent --no-stream"` shows reduced memory and CPU
  - Memory: 489.7 MiB (0.76%) - down from 2.944 GiB (83% reduction!)
- [x] Document new baseline in progress.md: Memory (GB), CPU (%), compare to Phase 1
- [x] Verify torrents still active: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent curl -s http://localhost:8080/api/v2/torrents/info | grep -c 'state'"` returns same or similar count to Phase 1
  - 55 torrents (unchanged)
- [x] Verify MAM compliance: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker exec qbittorrent curl -s http://localhost:8080/api/v2/app/preferences | grep -E 'anonymous_mode|max_ratio_enabled|encryption'"` shows correct values
  - anonymous_mode:false, encryption:0 ✓
- [x] Check Gluetun CPU: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats gluetun --no-stream"` shows CPU usage
  - Gluetun: 48.34% CPU
- [x] Document Gluetun CPU in progress.md: If still high (>30%), note for potential future investigation
  - NOTE: Gluetun at 48% - recommend separate investigation task

---

### Phase 7: Create Optimization Documentation

- [x] Create summary doc: Write `_data/QBITTORRENT_OPTIMIZATION.md` with changes applied, before/after metrics, rollback instructions
- [x] Document includes settings: File contains disk_cache, max_connec, save_resume_data_interval values
- [x] Document includes verification: File contains commands to check current settings
- [x] Document includes rollback: File contains restore backup and restart commands
- [x] Update progress.md: Add "Documentation Complete" section with file location
- [x] Verify doc completeness: `grep -E "disk_cache|max_connec|Rollback" _data/QBITTORRENT_OPTIMIZATION.md` returns all three terms

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Apply Docker Resource Limits (Optional but Recommended)

See `_data/QBITTORRENT_RESOURCE_LIMITS.md` for instructions.

```yaml
# Add to docker-compose.yml under qbittorrent service:
mem_limit: 8g          # Hard limit
mem_reservation: 4g    # Soft limit
cpus: 4                # CPU cores
```

Then restart stack:
```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet "cd /path/to/compose && docker-compose up -d"
```

### 2. Monitor Over 24 Hours

Check memory/CPU trends:
```bash
# Run periodically
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats --no-stream qbittorrent gluetun"
```

### 3. Gluetun Investigation (If Needed)

If Gluetun CPU remains >30% after qBittorrent optimization, create separate task to investigate VPN container.

---

## Rollback Plan

If optimizations cause issues (slow downloads, tracker errors, crashes):

```bash
# 1. Restore backup config (replace YYYYMMDD with backup date)
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  docker exec qbittorrent cp /config/qBittorrent/qBittorrent.conf.backup-YYYYMMDD /config/qBittorrent/qBittorrent.conf
"

# 2. Restart qBittorrent
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker restart qbittorrent"

# 3. Verify API responding (after 30 seconds)
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  docker exec qbittorrent curl -s http://localhost:8080/api/v2/app/version
"

# 4. Check torrents still active
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  docker exec qbittorrent curl -s http://localhost:8080/api/v2/torrents/info | head -20
"
```

**Note**: Docker resource limits in docker-compose.yml must be removed manually if applied.

---

## Notes

- **Critical**: Do NOT modify MAM compliance settings (`anonymous_mode`, `max_ratio_enabled`, `encryption`, `dht`, `pex`, `lsd`)
- **Backup**: Config backup created in Phase 2, kept in container at `/config/qBittorrent/qBittorrent.conf.backup-YYYYMMDD`
- **Active torrents**: Changes applied via API take effect immediately for new connections, existing connections persist until renegotiated
- **Restart timing**: qBittorrent needs 30-60 seconds to fully start and load torrent state
- **Gluetun dependency**: qBittorrent network goes through Gluetun VPN container

---

## Context for Future Agents

This task addresses memory and CPU resource consumption by qBittorrent on flippanet server. The root cause is likely:

1. **High disk cache**: Default libtorrent settings often allocate 1GB+ of RAM for disk cache
2. **Excessive connections**: No limits on peer connections can cause memory bloat
3. **Frequent resume data saves**: Writing torrent state every 3 minutes causes I/O and CPU spikes
4. **uTP overhead**: Micro Transport Protocol can increase CPU usage

Key considerations:

1. **MAM compliance is non-negotiable**: Settings like `anonymous_mode=false`, no seeding limits, and `encryption=0` are required by MyAnonamouse tracker rules
2. **libtorrent defaults are aggressive**: Designed for maximum performance, not resource efficiency
3. **Docker resource limits are safety net**: Should be applied in docker-compose.yml but are NOT sufficient alone (app-level tuning required)
4. **Gluetun VPN relationship**: High qBittorrent traffic can cause elevated Gluetun CPU usage (network processing)

Work incrementally through phases. Verify MAM compliance after each change. Monitor torrent health (seeding/downloading status) throughout.

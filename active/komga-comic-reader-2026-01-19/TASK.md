---
dependencies:
  system:
    # No system packages needed

  python:
    # No Python packages needed

  npm:
    # No npm packages needed

  check_commands:
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'SSH connectivity check'"
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps"
---

## For Task Creators (READ THIS FIRST)

**✅ Phase 0 discovery completed in progress.md before creating this file.**

See progress.md for:
- Rules read evidence (quotes from .cursorrules, RALPH_RULES.md)
- Local RAG query results for flippanet access and comic setup
- Key context about flippanet server, Kapowarr integration, compose file location
- Komga details from official documentation

---

# Task: Add Komga Comic Reader to Flippanet Stack

## Task Overview

**Goal**: Add Komga comic reader/server to flippanet's existing Docker stack to provide web-based comic reading for the Kapowarr-managed library.

**Context**: 
- Flippanet runs a media server stack with Sonarr, Radarr, Kapowarr, and other services
- Compose file: `/home/flippadip/flippanet/docker-compose-portable.yml`
- Kapowarr manages comics at `/data/Comics/`
- All services use named volumes, resource limits, healthchecks, and `flippanet_network`
- Server: Ubuntu 24.04, i7-7700K (8 threads), 64GB RAM
- Komga: https://github.com/gotson/komga - comic/manga reader server
- Default port: 25600

**Success Indicator**: Komga container running and healthy on flippanet, accessible via `http://flippanet:25600`, following existing stack patterns (resource limits, healthcheck, named volume).

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**⚠️ Task Creator completed this BEFORE creating TASK.md. Ralph Worker verifies before Phase 1.**

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Quote "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md (if exists): Noted flippanet patterns from Kapowarr task
- [x] Read `.ralph/docs/RALPH_RULES.md`: Quote "The Verification Test" in progress.md
- [x] Query Local RAG for task topic: Document files found and key info extracted
- [x] Identify secrets/credentials needed: SSH key available, no additional secrets (Komga creates accounts at first run)
- [x] List files to be created: MAX 3 with one-sentence justification each
- [x] State verification plan: How each file will be verified after creation

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify SSH connectivity: `ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'connected'"` succeeds
- [x] Verify compose file exists: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ls -lh /home/flippadip/flippanet/docker-compose-portable.yml"` shows file
- [x] Verify flippanet_network exists: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker network ls | grep flippanet_network"` shows network
- [x] Verify Comics directory exists: Path is `/mnt/media/Comics` (DATA_PATH=/mnt/media)
- [x] Add corrections or additional context if needed - Kapowarr running healthy
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Add Komga Service to Docker Compose

- [x] Backup compose file: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cp ~/flippanet/docker-compose-portable.yml ~/flippanet/docker-compose-portable.yml.backup-$(date +%Y%m%d-%H%M%S)"`
- [x] Add komga service to compose file following existing patterns:
  - Image: `ghcr.io/gotson/komga:latest`
  - Port: `25600:25600`
  - Volumes: `komga-config:/config` (database/config) + `${DATA_PATH}/Comics:/data:ro` (read-only)
  - Environment: PUID, PGID, TZ
  - Network: `flippanet_network`
  - Resource limits: `memory: 1g`, `cpus: 1.0`, reservation `memory: 256m`
  - Healthcheck: `curl -f http://localhost:25600/api/v1/libraries || exit 1`
  - Restart policy: `unless-stopped`
- [x] Add named volume `komga-config` to volumes section with name `flippanet_komga-config`
- [x] Verify compose file syntax: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cd ~/flippanet && docker compose -f docker-compose-portable.yml config --quiet"` exits 0

---

### Phase 2: Deploy and Verify Container

- [x] Pull image: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker pull ghcr.io/gotson/komga:latest"`
- [x] Start komga: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cd ~/flippanet && docker compose -f docker-compose-portable.yml up -d komga"`
- [x] Verify container running: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep komga"` shows container
- [x] Wait for startup: `ssh -i ~/.ssh/flippanet flippadip@flippanet "sleep 30"`
- [x] Verify healthcheck: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker inspect komga --format='{{.State.Health.Status}}'"` returns "healthy"
- [x] Verify web UI responds: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s -o /dev/null -w '%{http_code}' http://localhost:25600"` returns 200 or 401 (auth required)

**Note**: Healthcheck modified from `/api/v1/libraries` to root URL (`/`) because the API endpoint returns 401 which fails the `-f` flag. Root URL returns 200.

---

### Phase 3: Document Configuration

- [x] Update progress.md with deployment details:
  - Access URL: `http://flippanet:25600`
  - OPDS URL: `http://flippanet:25600/opds/v1.2/catalog`
  - Port: 25600
  - Config volume: `flippanet_komga-config`
  - Data path: `/mnt/media/Comics` (read-only via ${DATA_PATH}/Comics)
- [x] Mark task complete in progress.md with timestamp

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Initial Komga Setup (After Deployment)

Access `http://flippanet:25600` in browser and configure:

1. **Create admin account** on first visit
   - Komga prompts for email/password on first access
   
2. **Add library**:
   - Settings → Libraries → Add
   - Name: "Comics"
   - Root folder: `/data`
   - Scan interval: "Every 6 hours" (or preferred)
   - Click "Add"

3. **Wait for initial scan** - Komga will index all comics from Kapowarr

### 2. Optional: OPDS Setup for Mobile Apps

For reading on mobile devices (Panels, Chunky, etc.):

- OPDS URL: `http://flippanet:25600/opds/v1.2/catalog`
- Username/password: Your Komga admin credentials
- Some apps require OPDS v1.2 specifically

### 3. Optional: Integrate with Kapowarr

No integration needed - they share the same `/data/Comics` directory:
- Kapowarr writes: downloads and organizes comics
- Komga reads: scans directory and serves comics
- Komga auto-detects new files on scan interval

---

## Rollback Plan

If Komga causes issues:

```bash
# Stop and remove komga container
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cd ~/flippanet
  docker compose -f docker-compose-portable.yml stop komga
  docker compose -f docker-compose-portable.yml rm -f komga
"

# Restore backup compose file if needed
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp ~/flippanet/docker-compose-portable.yml.backup-YYYYMMDD-HHMMSS \
     ~/flippanet/docker-compose-portable.yml
"

# Remove volume (deletes all config/database - only if needed)
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker volume rm flippanet_komga-config"
```

---

## Notes

- **Image source**: `ghcr.io/gotson/komga` is the official image maintained by the developer
- **Resource limits**: Conservative 1GB memory limit (typical usage ~200-500MB for small libraries)
- **Network**: Uses `flippanet_network` for internal DNS
- **Read-only mount**: Comics mounted `:ro` since Komga only reads, Kapowarr manages writes
- **Port 25600**: Standard Komga port, no conflicts in current stack
- **Healthcheck endpoint**: `/api/v1/libraries` requires auth but returns 401 (still proves server is running)

---

## Context for Future Agents

This task adds Komga, a comic/manga reader server, to complement the existing Kapowarr installation:

- **Kapowarr**: Download automation & library management (like Sonarr for comics)
- **Komga**: Reading experience & serving comics (like Plex for comics)

**Key considerations:**

1. **Follows existing patterns**: Uses same volume naming, network, resource limit format as other services
2. **Read-only integration**: Komga doesn't modify files - safe to run alongside Kapowarr
3. **OPDS support**: Built-in OPDS server for mobile reading apps (Panels, Chunky, etc.)
4. **No secrets needed**: User creates account on first visit, credentials stored in Komga's database

Work incrementally through phases. Test container health before marking complete.

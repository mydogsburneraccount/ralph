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
- Local RAG query results for flippanet access and setup
- Key context about flippanet server, existing ARR stack, compose file location
- Docker compose file contents retrieved from flippanet
- Kapowarr details from GitHub repository

---

# Task: Integrate Kapowarr into Flippanet ARR Stack

## Task Overview

**Goal**: Add Kapowarr (comic book library manager) to flippanet's existing *arr Docker stack following established patterns.

**Context**: 
- Flippanet runs a media server stack with Sonarr, Radarr, Prowlarr, and other *arr services
- Compose file: `/home/flippadip/flippanet/docker-compose-portable.yml`
- All services use named volumes, resource limits, healthchecks, and `flippanet_network`
- Server: Ubuntu 24.04, i7-7700K (8 threads), 64GB RAM
- Kapowarr: https://github.com/Casvt/Kapowarr - comic book library manager
- Default port: 5656

**Success Indicator**: Kapowarr container running and healthy on flippanet, accessible via `http://flippanet:5656`, following existing stack patterns (resource limits, healthcheck, named volume).

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**⚠️ Task Creator completed this BEFORE creating TASK.md. Ralph Worker verifies before Phase 1.**

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Quote "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md (if exists): Flippanet project at `projects/flippanet/`
- [x] Read `.ralph/docs/RALPH_RULES.md`: Quote "The Verification Test" in progress.md
- [x] Query Local RAG for task topic: Document files found and key info extracted
- [x] Identify secrets/credentials needed: SSH key available, ComicVine API optional (user can add later)
- [x] List files to be created: MAX 3 with one-sentence justification each
- [x] State verification plan: How each file will be verified after creation

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify SSH connectivity: `ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'connected'"` succeeds
- [x] Verify compose file exists: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ls -lh /home/flippadip/flippanet/docker-compose-portable.yml"` shows file
- [x] Verify flippanet_network exists: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker network ls | grep flippanet_network"` shows network
- [x] Add corrections or additional context if needed
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Add Kapowarr Service to Docker Compose

- [x] Backup compose file: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cp ~/flippanet/docker-compose-portable.yml ~/flippanet/docker-compose-portable.yml.backup-$(date +%Y%m%d-%H%M%S)"`
- [x] Add kapowarr service to compose file following existing patterns:
  - Image: `mrcas/kapowarr:latest`
  - Port: `5656:5656`
  - Volume: `kapowarr-config:/app/db` (config) + `${DATA_PATH}:/data` (comics)
  - Environment: PUID, PGID, TZ
  - Network: `flippanet_network`
  - Resource limits: `memory: 1g`, `cpus: 1.0`, reservation `memory: 256m`
  - Healthcheck: `curl -f http://localhost:5656`
  - Restart policy: `unless-stopped`
- [x] Add named volume `kapowarr-config` to volumes section
- [x] Verify compose file syntax: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cd ~/flippanet && docker compose -f docker-compose-portable.yml config --quiet"` exits 0

---

### Phase 2: Deploy and Verify Container

- [x] Pull image: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker pull mrcas/kapowarr:latest"`
- [x] Start kapowarr: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cd ~/flippanet && docker compose -f docker-compose-portable.yml up -d kapowarr"`
- [x] Verify container running: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep kapowarr"` shows container
- [x] Wait for healthcheck: `ssh -i ~/.ssh/flippanet flippadip@flippanet "sleep 30 && docker inspect kapowarr --format='{{.State.Health.Status}}'"` returns "healthy"
- [x] Verify web UI accessible: `ssh -i ~/.ssh/flippanet flippadip@flippanet "curl -s -o /dev/null -w '%{http_code}' http://localhost:5656"` returns 200

---

### Phase 3: Document Configuration

- [x] Add Kapowarr to existing flippanet documentation in progress.md:
  - Access URL: `http://flippanet:5656`
  - Port: 5656
  - Config volume: `flippanet_kapowarr-config`
  - Data path: `${DATA_PATH}/Comics` (recommended subfolder)
- [x] Update progress.md with deployment details and timestamp
- [x] Mark task complete in progress.md

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Initial Kapowarr Setup (After Deployment)

Access `http://flippanet:5656` in browser and configure:

1. **Set download client**: Add qBittorrent
   - Host: `gluetun` (uses gluetun network)
   - Port: `8080`
   - Username/Password: from existing qbittorrent config
   
2. **Set root folder**: Add comics folder
   - Path: `/data/Comics` (or your preferred location)
   
3. **ComicVine API** (optional): 
   - Get key from https://comicvine.gamespot.com/api/
   - Add in Settings → General

### 2. Add to Prowlarr (Optional)

If you want Prowlarr to push indexers to Kapowarr:
- In Prowlarr: Settings → Apps → Add → Kapowarr
- Kapowarr URL: `http://kapowarr:5656`
- API Key: Get from Kapowarr Settings → General

---

## Rollback Plan

If Kapowarr causes issues:

```bash
# Stop and remove kapowarr container
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cd ~/flippanet
  docker compose -f docker-compose-portable.yml stop kapowarr
  docker compose -f docker-compose-portable.yml rm -f kapowarr
"

# Restore backup compose file if needed
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp ~/flippanet/docker-compose-portable.yml.backup-YYYYMMDD-HHMMSS \
     ~/flippanet/docker-compose-portable.yml
"

# Remove volume (deletes all config - only if needed)
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker volume rm flippanet_kapowarr-config"
```

---

## Notes

- **Image source**: `mrcas/kapowarr:latest` is the official image from the maintainer
- **Resource limits**: Conservative 1GB memory limit (typical usage ~200-400MB)
- **Network**: Uses `flippanet_network` for internal DNS (can reach other services by name)
- **Comics path**: Recommend creating `/data/Comics` subfolder on DATA_PATH
- **ComicVine API**: Free, but requires account - provides metadata for comics

---

## Context for Future Agents

This task adds Kapowarr, a comic book library manager, to the flippanet media server stack. Kapowarr fits the *arr pattern:
- Monitors for new comics
- Searches configured indexers
- Downloads via qBittorrent
- Organizes and renames files

**Key considerations:**

1. **Follows existing patterns**: Uses same volume naming, network, resource limit format as other *arr services
2. **Minimal footprint**: Comics are less demanding than video - conservative resource limits appropriate
3. **Optional Prowlarr integration**: Can receive indexers from Prowlarr, but works standalone too
4. **ComicVine dependency**: For metadata lookup - free API key required for full functionality

Work incrementally through phases. Test container health before marking complete.

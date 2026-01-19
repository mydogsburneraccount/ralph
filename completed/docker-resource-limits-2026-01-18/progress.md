# Ralph Progress Log

> **Auto-updated by the agent after each iteration**

---

## Current Status

**Last Updated**: 2026-01-18
**Iteration**: 5
**Task**: Docker Resource Limits for All Flippanet Containers
**Status**: COMPLETE - All phases finished, ready to archive

---

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**

- `.cursorrules` Anti-Gaming Rules: *"Creating 5 files when 1 would suffice = FAILURE, not thoroughness"* and *"Minimal Documentation: Create ONLY what's needed and verified"*
- Project AGENTS.md: No `projects/flippanet/AGENTS.md` found (docs moved to `_data/` directory)
- `.ralph/core/docs/RALPH_RULES.md` Golden Rule: *"Can an agent sitting in a bash terminal with no GUI, no human input, and no interactive prompts complete this criterion by running commands and checking output?"*

**Local RAG Query:**

- Query: "flippanet docker containers services stack resource management compose"
- Results Found:
  - `_scripts/PROJECT_STATE_2026-01-15.md` - docker-compose-portable.yml location, compose commands
  - `_data/FLIPPANET_QUICK_START.md` - Docker service management patterns
  - `projects/flippanet/ARR_TROUBLESHOOTING.md` - Container status checking
  - `_scripts/FLIPPANET_COMPLETE_DOCUMENTATION.md` - Compose file path, restart patterns
  - `projects/flippanet/FLIPPANET.md` - Stack overview, container management

**Key Context Extracted:**

- **Server**: Flippanet - Ubuntu Server 24.04 with Docker
- **Hardware**: Intel i7-7700K (4C/8T = 8 threads), 64GB DDR4 RAM, RTX 3080 Ti, 16TB storage
- **Compose File**: `/home/flippadip/flippanet/docker-compose-portable.yml`
- **Container Count**: ~17 containers running (user reported)
- **SSH Access**: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- **Network**: All services on `flippanet_network` Docker bridge network
- **Known Issues**: qBittorrent was using 28GB RAM (now fixed), swap exhaustion (8GB/8GB)

**Recent Optimization Work:**

From previous Ralph tasks:
- `plex-stability-2026-01-18`: Optimized Plex transcoding settings, identified qBittorrent and Gluetun issues
- `qbittorrent-optimization-2026-01-18`: Reduced qBittorrent from 28GB → 489MB (83%), created `_data/QBITTORRENT_RESOURCE_LIMITS.md` as manual step
- `gluetun-cpu-optimization-2026-01-18`: Active task to reduce Gluetun CPU from 48% → <15%

**Container Tiers (Expected):**

Critical Services:
- Plex (media streaming - needs CPU/GPU for transcoding)
- Gluetun (VPN backbone - qBittorrent depends on it)
- Tailscale (remote access)

Download/Media Management:
- qBittorrent (torrents - now optimized but needs hard limit)
- Sonarr, Radarr, Lidarr, Readarr (ARR stack)
- Prowlarr (indexer manager)

Support Services:
- Tautulli (Plex monitoring)
- Recyclarr (ARR custom formats)
- Overseerr/Jellyseerr (request management)
- Audiobookshelf (audiobook server)
- Other containers (TBD during audit)

**Secrets/Credentials:**

- SSH key `~/.ssh/flippanet` - already available
- No additional credentials needed
- Vault access available if needed: `./.ralph/core/scripts/ralph-secrets.sh get <path>`

**Files Created (3):**

1. `TASK.md` - Task definition with 6 phases: audit, tier classification, limit calculation, compose changes, documentation
2. `progress.md` - This file with Phase 0 discovery evidence and execution log
3. `.iteration` - Iteration counter starting at 0

**Verification Plan:**

- `TASK.md`: `Select-String -Path .ralph/active/docker-resource-limits-2026-01-18/TASK.md -Pattern "^## Task Overview|^## Success Criteria|^## Rollback Plan"` returns all three sections
- `progress.md`: `Select-String -Path .ralph/active/docker-resource-limits-2026-01-18/progress.md -Pattern "Task Creator Discovery"` returns this section
- `.iteration`: `Get-Content .ralph/active/docker-resource-limits-2026-01-18/.iteration` returns `0`

---

### Ralph Worker Verification (filled during execution)

- [x] Verified SSH connectivity to flippanet: `echo connected` succeeded
- [x] Confirmed compose file exists: `-rw-rw-r-- 4.7K Jan 19 03:29 docker-compose-portable.yml`
- [x] Verified container count: **25 containers** (more than expected ~17)
- [x] Confirmed system resources: 62GB RAM, 8 threads (i7-7700K), 3.7GB swap used
- [x] Additional context: **No containers have resource limits** (all show mem=0 cpu=0)

**CRITICAL FINDING**: qBittorrent using **37.38GB RAM (59.59%)** - requires immediate attention!

---

## Task Summary

Audit all Docker containers on flippanet and define appropriate resource limits for each based on:

- Container role (critical vs background)
- Historical usage patterns
- Service priority and dependencies
- System capacity (8 threads, 64GB RAM)

**Goal**: Prevent resource exhaustion, ensure fair resource allocation, protect critical services, and establish predictable performance.

**Output**: Comprehensive `_data/DOCKER_RESOURCE_LIMITS.md` with per-container recommendations and docker-compose snippets.

**Key Constraints:**

- This is a **planning/documentation task** - actual compose changes are MANUAL
- Cannot restart all containers simultaneously (would cause service outage)
- Must prioritize based on service criticality
- Limits must be conservative (allow growth but prevent runaway usage)
- Cannot break existing dependencies (e.g., qBittorrent → Gluetun)

---

## Completed Work

- [x] Phase 0: Verification Gate - Rules read, context gathered, files created, Ralph Worker verification complete
- [x] Phase 1: Audit All Running Containers - 25 containers documented with resource usage
- [x] Phase 2: Classify Containers by Tier - 4-tier system with dependency chains
- [x] Phase 3: Calculate Resource Limits - 4.55GB reservation, 20.66GB limits
- [x] Phase 4: Create Docker Compose Recommendations - `_data/DOCKER_RESOURCE_LIMITS.md`
- [x] Phase 5: Document Implementation Plan - 4-phase staggered rollout
- [x] Phase 6: Create Rollback Documentation - Per-container and full rollback procedures

---

## Phase 1 Audit Data (Iteration 1)

### Container List (25 containers)

| Container | Image | Status |
|-----------|-------|--------|
| plex | lscr.io/linuxserver/plex:latest | Up (healthy) |
| port-updater | curlimages/curl:latest | Up |
| qbittorrent | lscr.io/linuxserver/qbittorrent:latest | Up |
| audiobookshelf | ghcr.io/advplyr/audiobookshelf:latest | Up (unhealthy) |
| gluetun | qmcgaw/gluetun:latest | Up (healthy) |
| jellyseerr | fallenbagel/jellyseerr:latest | Up (healthy) |
| bazarr | lscr.io/linuxserver/bazarr:latest | Up (unhealthy) |
| vault | hashicorp/vault:latest | Up (unhealthy) |
| listenarr | listenarr:fixed-category | Up (healthy) |
| tailscale | tailscale/tailscale:latest | Up (healthy) |
| recyclarr | ghcr.io/recyclarr/recyclarr:latest | Up |
| open-webui | ghcr.io/open-webui/open-webui:main | Up (healthy) |
| prowlarr | lscr.io/linuxserver/prowlarr:latest | Up (healthy) |
| sonarr | lscr.io/linuxserver/sonarr:latest | Up (healthy) |
| searxng | searxng/searxng:latest | Up (healthy) |
| whisparr | ghcr.io/hotio/whisparr:nightly | Up (healthy) |
| flaresolverr | ghcr.io/flaresolverr/flaresolverr:latest | Up (healthy) |
| ollama-bridge | alpine/socat:latest | Up |
| mcpo | ghcr.io/open-webui/mcpo:main | Up (unhealthy) |
| tautulli | lscr.io/linuxserver/tautulli:latest | Up (healthy) |
| radarr | lscr.io/linuxserver/radarr:latest | Up (healthy) |
| edge-tts | travisvn/openai-edge-tts:latest | Up (unhealthy) |
| supabase-db | supabase/postgres:15.8.1.049 | Up (healthy) |
| supabase-auth | supabase/gotrue:v2.170.0 | Up (healthy) |
| supabase-kong | kong:2.8.1 | Up (healthy) |

### Current Resource Usage

| Container | CPU % | Memory Usage | Memory % |
|-----------|-------|--------------|----------|
| **qbittorrent** | **15.51%** | **37.38GB** | **59.59%** |
| gluetun | 28.92% | 19.8MB | 0.03% |
| supabase-kong | 7.11% | 14.27MB | 0.02% |
| tailscale | 5.64% | 39.32MB | 0.06% |
| supabase-auth | 1.83% | 6.36MB | 0.01% |
| vault | 0.34% | 43.86MB | 0.07% |
| plex | 0.24% | 45.76MB | 0.07% |
| open-webui | 0.12% | 21.4MB | 0.03% |
| mcpo | 0.12% | 31.68MB | 0.05% |
| bazarr | 0.11% | 58.45MB | 0.09% |
| radarr | 0.11% | 127MB | 0.20% |
| prowlarr | 0.07% | 140.4MB | 0.22% |
| sonarr | 0.07% | 165MB | 0.26% |
| listenarr | 0.06% | 193.6MB | 0.30% |
| whisparr | 0.03% | 80.18MB | 0.12% |
| tautulli | 0.02% | 13.21MB | 0.02% |
| supabase-db | 0.04% | 11.08MB | 0.02% |
| audiobookshelf | 0.01% | 8.72MB | 0.01% |
| jellyseerr | 0.00% | 93.58MB | 0.15% |
| flaresolverr | 0.00% | 40.8MB | 0.06% |
| searxng | 0.00% | 14.34MB | 0.02% |
| recyclarr | 0.00% | 936KB | 0.00% |
| edge-tts | 0.00% | 760KB | 0.00% |
| port-updater | 0.00% | 616KB | 0.00% |
| ollama-bridge | 0.00% | 444KB | 0.00% |

### Existing Resource Limits

**None.** All 25 containers have `mem=0 cpu=0` (unlimited).

### Key Issues Identified

1. **qBittorrent memory bloat**: 37.38GB (59.59%) - CRITICAL, needs hard limit
2. **Gluetun CPU usage**: 28.92% - high but noted in separate optimization task
3. **No resource governance**: Every container can consume unlimited resources
4. **Swap usage**: 3.7GB of 8GB used (46%) - partially due to qBittorrent

---

## Phase 2: Tier Classification

### Tier 1 - Critical (Must Stay Up)

| Container | Role | Dependencies | Priority |
|-----------|------|--------------|----------|
| plex | Media streaming to users | None (uses local storage) | 1 |
| gluetun | VPN backbone | None (provides network to others) | 1 |
| tailscale | Remote access | None | 1 |

### Tier 2 - Core Media (Download/Management)

| Container | Role | Dependencies | Priority |
|-----------|------|--------------|----------|
| qbittorrent | Torrent downloads | gluetun (network) | 2 |
| sonarr | TV show management | prowlarr, qbittorrent | 3 |
| radarr | Movie management | prowlarr, qbittorrent | 3 |
| prowlarr | Indexer management | flaresolverr (captcha) | 2 |
| listenarr | Audiobook management | qbittorrent | 3 |
| bazarr | Subtitle management | sonarr, radarr | 4 |
| whisparr | Adult content management | prowlarr, qbittorrent | 4 |
| jellyseerr | Request management | sonarr, radarr | 4 |
| audiobookshelf | Audiobook server | None | 3 |

### Tier 3 - Support (Monitoring/Optional)

| Container | Role | Dependencies | Priority |
|-----------|------|--------------|----------|
| tautulli | Plex monitoring | plex | 5 |
| recyclarr | ARR custom formats | sonarr, radarr | 5 |
| flaresolverr | Captcha solving | None | 4 |
| searxng | Search engine | None | 5 |
| open-webui | AI chat interface | ollama-bridge, mcpo | 5 |
| ollama-bridge | Ollama connection | None | 5 |
| mcpo | MCP orchestration | None | 5 |
| edge-tts | Text to speech | None | 6 |
| port-updater | Port management | gluetun | 5 |

### Tier 4 - Infrastructure (Supabase Stack)

| Container | Role | Dependencies | Priority |
|-----------|------|--------------|----------|
| supabase-db | PostgreSQL database | None | 3 |
| supabase-auth | Authentication | supabase-db | 4 |
| supabase-kong | API gateway | supabase-auth | 4 |
| vault | Secrets management | None | 4 |

### Dependency Chain Summary

```
gluetun ← qbittorrent ← sonarr, radarr, listenarr, whisparr
                     ← bazarr (via sonarr/radarr)
                     ← jellyseerr (via sonarr/radarr)

prowlarr ← flaresolverr (for captcha)
        ← sonarr, radarr (for indexers)

plex ← tautulli (monitoring)

supabase-db ← supabase-auth ← supabase-kong
```

### Priority Ranking (1 = highest)

1. **gluetun, plex, tailscale** - Network/streaming backbone
2. **qbittorrent, prowlarr** - Core download functionality
3. **sonarr, radarr, audiobookshelf, listenarr, supabase-db** - Media management
4. **bazarr, whisparr, jellyseerr, flaresolverr, vault, supabase-auth, supabase-kong** - Secondary services
5. **tautulli, recyclarr, searxng, open-webui, ollama-bridge, mcpo, port-updater** - Optional/monitoring
6. **edge-tts** - Rarely used

---

## Phase 3: Resource Limit Calculations

### System Capacity

- **Total RAM**: 62GB
- **Reserved for system**: 8GB
- **Allocatable RAM**: 54GB
- **Total CPU threads**: 8
- **Reserved for system**: 1
- **Allocatable CPU**: 7 threads

### Resource Limit Strategy

- **mem_reservation**: Soft guarantee - Docker tries to ensure this much is available
- **mem_limit**: Hard ceiling - container OOM-killed if exceeded
- **cpus**: CPU quota (decimal, e.g., 2.0 = 2 threads)

**Philosophy**: Conservative reservations (sum < 10GB) with generous limits (allow burst). Only qBittorrent needs a tight limit due to memory leak history.

### Tier 1 - Critical Services

| Container | Current | mem_reservation | mem_limit | cpus | Rationale |
|-----------|---------|-----------------|-----------|------|-----------|
| plex | 46MB | 1g | 8g | 4.0 | Transcoding needs burst capacity, GPU handles video |
| gluetun | 20MB | 256m | 512m | 1.0 | VPN critical, high CPU noted separately |
| tailscale | 39MB | 128m | 256m | 0.5 | Lightweight, must stay up |

**Tier 1 Totals**: reservation=1.38GB, limit=8.75GB, cpus=5.5

### Tier 2 - Core Media Services

| Container | Current | mem_reservation | mem_limit | cpus | Rationale |
|-----------|---------|-----------------|-----------|------|-----------|
| qbittorrent | **37.4GB** | 512m | **2g** | 2.0 | CRITICAL: Memory leak history, HARD limit required |
| sonarr | 165MB | 256m | 1g | 1.0 | Media scanning can spike |
| radarr | 127MB | 256m | 1g | 1.0 | Media scanning can spike |
| prowlarr | 140MB | 128m | 512m | 0.5 | Indexer queries |
| listenarr | 194MB | 256m | 512m | 0.5 | Audiobook processing |
| bazarr | 58MB | 128m | 256m | 0.5 | Subtitle downloads |
| whisparr | 80MB | 128m | 512m | 0.5 | Similar to sonarr/radarr |
| jellyseerr | 94MB | 128m | 512m | 0.5 | Request handling |
| audiobookshelf | 9MB | 128m | 512m | 0.5 | Audio streaming |

**Tier 2 Totals**: reservation=1.92GB, limit=7.25GB, cpus=7.0

### Tier 3 - Support Services

| Container | Current | mem_reservation | mem_limit | cpus | Rationale |
|-----------|---------|-----------------|-----------|------|-----------|
| tautulli | 13MB | 64m | 256m | 0.25 | Monitoring only |
| recyclarr | 1MB | 32m | 128m | 0.25 | Periodic sync |
| flaresolverr | 41MB | 128m | 512m | 0.5 | Headless browser for captcha |
| searxng | 14MB | 64m | 256m | 0.25 | Search queries |
| open-webui | 21MB | 256m | 1g | 0.5 | AI interface, may need memory |
| ollama-bridge | 0.4MB | 16m | 64m | 0.1 | Simple proxy |
| mcpo | 32MB | 64m | 256m | 0.25 | MCP orchestration |
| edge-tts | 0.8MB | 32m | 128m | 0.25 | TTS processing |
| port-updater | 0.6MB | 16m | 64m | 0.1 | Minimal |

**Tier 3 Totals**: reservation=672MB, limit=2.66GB, cpus=2.45

### Tier 4 - Infrastructure (Supabase)

| Container | Current | mem_reservation | mem_limit | cpus | Rationale |
|-----------|---------|-----------------|-----------|------|-----------|
| supabase-db | 11MB | 256m | 1g | 0.5 | Database needs headroom |
| supabase-auth | 6MB | 64m | 256m | 0.25 | Authentication |
| supabase-kong | 14MB | 128m | 512m | 0.5 | API gateway |
| vault | 44MB | 128m | 256m | 0.25 | Secrets |

**Tier 4 Totals**: reservation=576MB, limit=2.0GB, cpus=1.5

### Grand Totals

| Metric | Value | System Limit | Headroom |
|--------|-------|--------------|----------|
| **Total mem_reservation** | 4.55GB | 54GB | 49.45GB (92%) |
| **Total mem_limit** | 20.66GB | 54GB | 33.34GB (62%) |
| **Total cpus** | 16.45 | 7 available | Oversubscribed (OK - soft limits) |

**Notes:**
- CPU oversubscription is intentional - all containers won't max CPU simultaneously
- mem_reservation is conservative - leaves 92% headroom for burst
- mem_limit prevents runaway usage - qBittorrent hard-capped at 2GB
- Total limits (20GB) well under system capacity - allows concurrent burst

---

## Implementation Summary (Phase 5-6)

### Staggered Rollout Strategy

| Phase | Tier | Services | Risk | Wait Time |
|-------|------|----------|------|-----------|
| A | Tier 3 | tautulli, recyclarr, searxng, open-webui, ollama-bridge, mcpo, edge-tts, port-updater | Lowest | 24-48h |
| B | Tier 4 + Tier 2 non-critical | supabase-*, vault, bazarr, whisparr, audiobookshelf | Low | 24-48h |
| C | Tier 2 Core | qbittorrent, sonarr, radarr, prowlarr, listenarr, jellyseerr, flaresolverr | Medium | 24-48h |
| D | Tier 1 | plex, gluetun, tailscale | Highest | Monitor ongoing |

### Output File

**Location**: `_data/DOCKER_RESOURCE_LIMITS.md`

**Contents**:
- Current baseline usage table
- 4-tier classification system
- Per-container compose snippets (25 containers)
- Total allocation summary
- Step-by-step implementation plan
- Rollback procedures (single container and full)
- Troubleshooting guide

---

## Next Steps

**Task Complete.** User should:

1. Review `_data/DOCKER_RESOURCE_LIMITS.md` recommendations
2. Backup compose file before changes
3. Implement limits using staggered rollout (Tier 3 → Tier 4 → Tier 2 → Tier 1)
4. Monitor after each phase for OOM kills or performance issues
5. Adjust limits if needed based on actual usage

**CRITICAL**: qBittorrent is currently using 37.4GB RAM. Apply the 2GB hard limit ASAP.

---

## Notes

- **SSH access**: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- **Compose file**: `/home/flippadip/flippanet/docker-compose-portable.yml`
- **Current state**: No resource limits on any containers (except maybe a few)
- **Recent issues**: Swap exhaustion (8GB/8GB), qBittorrent memory bloat (now fixed)
- **System capacity**: 8 CPU threads, 64GB RAM, 16TB disk
- **Documentation only**: This task creates recommendations, user applies them manually

---

## Rollback Instructions

This is a documentation-only task. If you implement the recommendations and need to rollback:

```bash
# 1. Restore backup compose file
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp /home/flippadip/flippanet/docker-compose-portable.yml.backup-YYYYMMDD /home/flippadip/flippanet/docker-compose-portable.yml
"

# 2. Recreate affected containers
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cd /home/flippadip/flippanet && docker compose -f docker-compose-portable.yml up -d [container_name]
"

# 3. Verify container status
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps"
```

---

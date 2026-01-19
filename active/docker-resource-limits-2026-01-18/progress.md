# Ralph Progress Log

> **Auto-updated by the agent after each iteration**

---

## Current Status

**Last Updated**: 2026-01-18
**Iteration**: 0
**Task**: Docker Resource Limits for All Flippanet Containers
**Status**: PENDING - Ready for Ralph worker execution

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

## Next Steps

1. Phase 1: Audit All Running Containers
2. Phase 2: Classify Containers by Tier
3. Phase 3: Calculate Resource Limits
4. Phase 4: Create Docker Compose Recommendations
5. Phase 5: Document Implementation Plan
6. Phase 6: Create Rollback Documentation

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

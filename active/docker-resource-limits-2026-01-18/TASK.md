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
- Local RAG query results
- Key context about flippanet server, hardware specs, compose file location
- Recent optimization work (Plex, qBittorrent, Gluetun tasks)
- Expected container tiers and service priorities

---

# Task: Docker Resource Limits for All Flippanet Containers

## Task Overview

**Goal**: Audit all ~17 Docker containers on flippanet and create comprehensive resource limit recommendations to prevent resource exhaustion and ensure fair allocation.

**Context**: 
- Recent issues: qBittorrent used 28GB RAM (now fixed), swap exhaustion (8GB/8GB)
- Server: Ubuntu 24.04, i7-7700K (8 threads), 64GB RAM, 16TB storage
- No resource limits currently defined (free-for-all)
- ~17 containers: Plex, qBittorrent, Gluetun, ARR stack, Tautulli, Tailscale, etc.
- Compose file: `/home/flippadip/flippanet/docker-compose-portable.yml`

**Success Indicator**: Comprehensive documentation created with per-container resource limits (mem_limit, mem_reservation, cpus) based on role, priority, and usage patterns. User can implement recommendations incrementally.

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
- [x] Verify compose file exists: `ssh -i ~/.ssh/flippanet flippadip@flippanet "ls -lh /home/flippadip/flippanet/docker-compose-portable.yml"` shows file
- [x] Verify container count: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps --format '{{.Names}}' | wc -l"` returns 25 (more than expected)
- [x] Verify system resources: `ssh -i ~/.ssh/flippanet flippadip@flippanet "free -h && nproc"` shows 62GB RAM, 8 threads
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Audit All Running Containers

- [x] Get container list: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"` lists all containers
- [x] Document container names in progress.md: Complete list with images (25 containers)
- [x] Get resource usage snapshot: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats --no-stream --format 'table {{.Name}}\t{{CPUPerc}}\t{{MemUsage}}\t{{MemPerc}}'"` shows current usage
- [x] Document current usage in progress.md: Table with CPU %, Memory usage, Memory % for each container
- [x] Check for existing limits: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker inspect --format='{{.Name}}: mem={{.HostConfig.Memory}} cpu={{.HostConfig.NanoCpus}}' \$(docker ps -q)"` shows which containers have limits
- [x] Document existing limits in progress.md: **None** - all containers have mem=0 cpu=0

---

### Phase 2: Classify Containers by Tier

**Create tier classification in progress.md:**

- [x] Identify Tier 1 (Critical): plex, gluetun, tailscale
- [x] Identify Tier 2 (Core Media): qbittorrent, sonarr, radarr, prowlarr, listenarr, bazarr, whisparr, jellyseerr, audiobookshelf
- [x] Identify Tier 3 (Support): tautulli, recyclarr, flaresolverr, searxng, open-webui, ollama-bridge, mcpo, edge-tts, port-updater
- [x] Document dependencies: gluetun←qbittorrent←ARR stack, prowlarr←flaresolverr, supabase-db←auth←kong
- [x] Document priority: 6-tier priority ranking (1=critical, 6=rarely used)
- [x] Create tier table in progress.md: 4 tier tables with container, role, dependencies, priority

---

### Phase 3: Calculate Resource Limits

**For each container, define limits based on:**

- [x] Calculate total allocatable resources: 54GB RAM, 7 CPU threads (after 8GB/1 thread reserved)
- [x] Define Tier 1 limits in progress.md: plex 8g, gluetun 512m, tailscale 256m
- [x] Define Tier 2 limits in progress.md: qbittorrent 2g (HARD CAP), ARR stack 256m-1g
- [x] Define Tier 3 limits in progress.md: 64m-1g based on current usage + headroom
- [x] Calculate totals: mem_reservation=4.55GB (92% headroom), mem_limit=20.66GB
- [x] Verify CPU allocation: 16.45 cpus total (oversubscribed OK - soft limits, won't all max simultaneously)
- [x] Document calculation rationale in progress.md: Each container has rationale column

---

### Phase 4: Create Docker Compose Recommendations

- [x] Create recommendations file: Write `_data/DOCKER_RESOURCE_LIMITS.md` with per-container resource limits
- [x] File includes current usage: Document Phase 1 baseline for comparison
- [x] File includes tier classification: Explain priority system (4 tiers)
- [x] File includes compose snippets: Ready-to-use YAML for each container with mem_limit, mem_reservation, cpus
- [x] File includes total allocation: Summary of reserved vs limit totals (4.55GB/20.66GB)
- [x] Verify file structure: `grep -E "mem_limit|mem_reservation|cpus" _data/DOCKER_RESOURCE_LIMITS.md | wc -l` returns 33 (>30 ✓)

---

### Phase 5: Document Implementation Plan

- [x] Add implementation section to recommendations file: Step-by-step process (4 phases)
- [x] Include staggered rollout: Phase A (Tier 3) → Phase B (Tier 4) → Phase C (Tier 2) → Phase D (Tier 1)
- [x] Include testing procedure: OOM check, docker stats, swap monitoring, health check
- [x] Include backup instructions: cp command with date-based naming
- [x] Include monitoring commands: dmesg, docker stats, free -h, docker ps
- [x] Document implementation in progress.md: Summary included below

---

### Phase 6: Create Rollback Documentation

- [x] Add rollback section to recommendations file: "Rollback Plan" section
- [x] Include per-container rollback: "Quick Rollback: Remove Limits from Single Container"
- [x] Include full rollback: "Full Rollback: Restore Backup"
- [x] Include verification: "Verify Limits Removed" with docker inspect command
- [x] Update progress.md: Marked complete with file location `_data/DOCKER_RESOURCE_LIMITS.md`
- [x] Verify documentation completeness: `grep -E "Rollback|backup|restore"` returns 6 matches (>0 ✓)

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Backup Compose File

Before applying any changes:

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp /home/flippadip/flippanet/docker-compose-portable.yml \
     /home/flippadip/flippanet/docker-compose-portable.yml.backup-\$(date +%Y%m%d)
"
```

### 2. Apply Resource Limits (Staggered Rollout Recommended)

**Phase A - Start with Tier 3 (lowest risk):**
```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet
cd /home/flippadip/flippanet
nano docker-compose-portable.yml
# Add limits to support services first
docker compose -f docker-compose-portable.yml up -d [tier3_services]
```

**Phase B - Then Tier 2:**
```bash
# Add limits to ARR stack, qBittorrent
docker compose -f docker-compose-portable.yml up -d [tier2_services]
```

**Phase C - Finally Tier 1 (most critical):**
```bash
# Add limits to Plex, Gluetun, Tailscale
docker compose -f docker-compose-portable.yml up -d [tier1_services]
```

### 3. Monitor After Each Phase

Wait 24-48 hours between phases and monitor:
```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats --no-stream"
```

Check for:
- Containers being OOM-killed (memory limit too low)
- Performance degradation (CPU limit too restrictive)
- Swap usage (should go down with proper limits)

### 4. Adjust If Needed

If a container hits limits frequently, increase them in compose file and recreate.

---

## Rollback Plan

If resource limits cause issues:

```bash
# Option 1: Remove limits from specific container
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cd /home/flippadip/flippanet
  # Edit docker-compose-portable.yml and remove mem_limit, mem_reservation, cpus lines for problem container
  nano docker-compose-portable.yml
  docker compose -f docker-compose-portable.yml up -d [container_name]
"

# Option 2: Full rollback to backup
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp /home/flippadip/flippanet/docker-compose-portable.yml.backup-YYYYMMDD \
     /home/flippadip/flippanet/docker-compose-portable.yml
  cd /home/flippadip/flippanet
  docker compose -f docker-compose-portable.yml up -d
"

# Option 3: Check specific container limits
docker inspect [container_name] | grep -E "Memory|NanoCpus"
```

---

## Notes

- **This is a planning/documentation task** - Ralph creates recommendations, user applies them manually
- **Staggered rollout is critical** - Don't apply all limits at once (risk of mass OOM-kills)
- **Conservative limits recommended** - Start with generous limits, tighten over time if needed
- **mem_reservation vs mem_limit**:
  - `mem_reservation`: Soft limit (Docker tries to guarantee this much)
  - `mem_limit`: Hard limit (container killed if exceeded)
- **cpus limit**: Decimal values (e.g., `cpus: 2.5` = 2.5 CPU threads)
- **Total allocation strategy**: 
  - Reserve ~56GB total (leaving 8GB for system)
  - Hard limits can exceed 64GB (unlikely all containers hit limit simultaneously)

---

## Context for Future Agents

This task establishes resource governance for a multi-service Docker host. The server had recent resource exhaustion issues (qBittorrent memory bloat, swap exhaustion) due to lack of limits.

**Key considerations:**

1. **Tier classification matters**: Critical services (Plex, VPN) need generous limits. Background services can be constrained.

2. **Dependencies must be respected**: qBittorrent depends on Gluetun network. If Gluetun is OOM-killed, qBittorrent loses connectivity.

3. **Staggered rollout reduces risk**: Apply limits to low-priority services first, monitor, then move to critical services.

4. **Limits are guidelines, not prisons**: Start conservative, adjust based on actual usage patterns.

5. **mem_reservation is key**: Docker uses this for memory allocation decisions. Sum of all reservations should be < available RAM.

6. **CPU limits are soft**: Multiple containers can have `cpus: 4` - they share CPU time when contending.

**Expected outcome:**

- Each container has appropriate resource constraints
- System won't swap under normal load
- Runaway containers (like old qBittorrent) can't exhaust system resources
- Critical services (Plex, VPN) have guaranteed resources
- User has clear implementation path with rollback safety

Work incrementally through phases. Focus on creating clear, actionable documentation. User will implement recommendations over days/weeks, not all at once.

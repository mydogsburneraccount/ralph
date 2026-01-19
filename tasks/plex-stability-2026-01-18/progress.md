# Ralph Progress Log

> **Auto-updated by the agent after each iteration**

---

## Current Status

**Last Updated**: 2026-01-18
**Iteration**: 0
**Task**: Plex Stability Optimization for Multi-User Load
**Status**: Phase 0 Complete - Ready for Execution

---

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**

- `.cursorrules` Anti-Gaming Rules: *"Creating 5 files when 1 would suffice = FAILURE, not thoroughness"* and *"Comprehensive documentation without verification = FAILURE, not helpfulness"*
- `projects/flippanet/AGENTS.md`: *"All secrets require human authorization via GPG passphrase"* and *"For Agents: Always request human authorization for secret access. Never attempt to bypass GPG authentication."*
- `.ralph/docs/RALPH_RULES.md` Golden Rule (TL;DR): *"Can an agent sitting in a bash terminal with no GUI, no human input, and no interactive prompts complete this criterion by running commands and checking output?"*
- `.ralph/docs/ANTIPATTERNS.md`: Read completely - no GUI clicks, no manual service restarts, no TUI interactions in criteria

**Local RAG Query:**

- Query: "plex stability optimization transcoding concurrent users reliability"
- Results Found:
  - `projects/flippanet/FLIPPANET.md` - Hardware specs (RTX 3080 Ti, 64GB RAM, i7-7700K), Plex port 32400, Tautulli port 8181
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

**Files Created (3):**

1. `TASK.md` - Task definition with 9 phases of verifiable criteria for Plex stability optimization
2. `progress.md` - This file with Phase 0 discovery evidence and execution log
3. `.iteration` - Iteration counter starting at 0

**Verification Plan:**

- `TASK.md`: `grep -E "^## Task Overview|^## Success Criteria|^## Rollback Plan" .ralph/tasks/plex-stability-2026-01-18/TASK.md` returns all three sections
- `progress.md`: `grep "Task Creator Discovery" .ralph/tasks/plex-stability-2026-01-18/progress.md` returns this section
- `.iteration`: `cat .ralph/tasks/plex-stability-2026-01-18/.iteration` returns `0`

---

### Ralph Worker Verification (to be filled during execution)

- [ ] Verified SSH connectivity to flippanet
- [ ] Confirmed Plex container is running
- [ ] Confirmed Preferences.xml path exists
- [ ] Additional context: (to be added during execution)

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
- **Secrets require GPG passphrase** - agent cannot access directly, must ask user

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

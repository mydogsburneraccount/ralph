# Progress: Kapowarr Integration into Flippanet ARR Stack

**Task**: Add Kapowarr (comic book manager) to flippanet's existing *arr stack
**Created**: 2026-01-19
**Status**: COMPLETE - All phases verified

---

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**
- `.cursorrules` Anti-Gaming Rules: "Creating 5 files when 1 would suffice = FAILURE, not thoroughness"
- `RALPH_RULES.md` Verification Test: "Can Ralph verify completion by running a command and checking output? YES = Valid ✅, NO = Invalid ❌"
- Project `AGENTS.md`: Flippanet project exists at `projects/flippanet/` - standard ARR stack patterns

**Local RAG Query:**
- Query: "flippanet arr stack docker setup access SSH"
- Results Found:
  - `projects/flippanet/README.md` - SSH access command
  - `projects/flippanet/FLIPPANET.md` - Stack config location, restart commands
  - `_data/FLIPPANET_ARR_SETUP_GUIDE.md` - ARR application setup patterns
  - `projects/flippanet/ARR_TROUBLESHOOTING.md` - Network inspection, port checking

**Key Context Extracted:**
- SSH access: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- Compose file: `~/flippanet/docker-compose-portable.yml`
- Network: `flippanet_network` (bridge, subnet 172.20.0.0/16)
- Server specs: i7-7700K (8 threads), 64GB RAM, Ubuntu 24.04
- Existing ARR services: Sonarr, Radarr, Prowlarr, Listenarr, Whisparr, Bazarr
- Volume naming pattern: `flippanet_<service>-config`
- Standard env vars: PUID=1000, PGID=1000, TZ=${TZ:-America/Chicago}
- All services use linuxserver.io images where available

**Docker Compose Retrieved:**
- Full compose file fetched from `~/flippanet/docker-compose-portable.yml`
- Contains 20+ services with resource limits, healthchecks, and named volumes
- Uses `deploy.resources.limits` for memory/CPU constraints

**Kapowarr Details (from GitHub):**
- GitHub: https://github.com/Casvt/Kapowarr
- Image: `mrcas/kapowarr:latest` (or from GHCR)
- Default port: 5656
- Documentation: https://casvt.github.io/Kapowarr/
- Features: Comic library management, download automation, integrates with *arr ecosystem
- Supports ComicVine API for metadata

**Secrets/Credentials:**
- SSH key `~/.ssh/flippanet` - already available, verified working
- ComicVine API key will be needed for metadata - user must provide or skip
- No other secrets required for basic setup

**Files to Create (3):**
1. `TASK.md` - Task definition with verifiable phases for Ralph worker
2. `progress.md` - This file with discovery evidence and execution log
3. `.iteration` - Iteration counter starting at 0

**Verification Plan:**
- TASK.md: `grep -E "^## Task Overview|^## Success Criteria|^## Rollback Plan" TASK.md`
- progress.md: `grep "Task Creator Discovery" progress.md`
- Container running: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep kapowarr"`
- Healthcheck passing: `ssh -i ~/.ssh/flippanet flippadip@flippanet "docker inspect kapowarr --format='{{.State.Health.Status}}'"`

---

### Ralph Worker Verification (filled during execution)

- [x] Verified SSH connectivity to flippanet - `echo 'connected'` succeeded
- [x] Verified compose file exists at `~/flippanet/docker-compose-portable.yml` - 27K file found
- [x] Verified flippanet_network exists - bridge network `0dae4b3578b2` confirmed
- [x] Additional context: None needed, all prerequisites confirmed
- [x] Proceed to Phase 1 only after verification complete - READY

---

## Execution Log

### Phase 1: Add Kapowarr to Docker Compose
**Completed**: 2026-01-19 07:55 UTC

- Created backup: `docker-compose-portable.yml.backup-20260119-015415`
- Added kapowarr service after bazarr service (line 502)
- Added `kapowarr-config` volume with name `flippanet_kapowarr-config`
- Fixed healthcheck to use Python (curl not available in image):
  ```yaml
  test: ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen(\\\"http://127.0.0.1:5656\\\")\""]
  ```
- Compose syntax validated

### Phase 2: Deploy and Verify Container
**Completed**: 2026-01-19 07:59 UTC

- Image pulled: `mrcas/kapowarr:latest` (sha256:484f7decc7cc...)
- Container created and started
- Volume created: `flippanet_kapowarr-config`
- Health status: `healthy`
- Web UI: HTTP 200 on port 5656
- API key generated: `752bd287c31e20facc7a35d1de315e65`

### Phase 3: Document Access
**Completed**: 2026-01-19 08:00 UTC

**Kapowarr Access:**
- URL: `http://flippanet:5656`
- Port: 5656
- Config volume: `flippanet_kapowarr-config`
- Data path: `${DATA_PATH}` (mount `/data` in container)
- Recommended comics folder: `/data/Comics`

---

## Task Status: COMPLETE

All automated criteria verified. Manual setup steps (download client, root folder, ComicVine API) documented in TASK.md for user to complete in browser.

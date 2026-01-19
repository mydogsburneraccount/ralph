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
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps | grep gluetun"
---

## For Task Creators (READ THIS FIRST)

**✅ Phase 0 discovery completed in progress.md before creating this file.**

See progress.md for:
- Rules read evidence (quotes from .cursorrules, RALPH_RULES.md)
- Local RAG query results
- Key context about Gluetun VPN container and network architecture
- SSH access patterns and container inspection methods
- qBittorrent dependency (network_mode: service:gluetun)

---

# Task: Gluetun VPN Container CPU Optimization

## Task Overview

**Goal**: Reduce Gluetun VPN container CPU usage from 48% to <15% at idle while maintaining VPN connectivity and throughput.

**Context**: 
- Gluetun consistently at 47-48% CPU across multiple measurements
- Low memory usage (27.68 MiB) - CPU is the only issue
- Provides VPN network for qBittorrent via `network_mode: service:gluetun`
- Server: Ubuntu Server 24.04, Docker, i7-7700K (8 threads)
- VPN Provider: ProtonVPN with OpenVPN protocol
- qBittorrent was recently optimized (83% memory reduction), but Gluetun CPU remained elevated

**Success Indicator**: CPU usage <15% at idle, VPN connectivity maintained, qBittorrent traffic still routed through VPN, no impact on download/upload speeds.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**⚠️ Task Creator completed this BEFORE creating TASK.md. Ralph Worker verifies before Phase 1.**

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Quote "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md (if exists): Noted "No AGENTS.md found" (docs in `_data/`)
- [x] Read `.ralph/docs/RALPH_RULES.md`: Quote "The Verification Test" in progress.md
- [x] Query Local RAG for task topic: Document files found and key info extracted
- [x] Identify secrets/credentials needed: SSH key already available, VPN creds already in Gluetun
- [x] List files to be created: MAX 3 with one-sentence justification each
- [x] State verification plan: How each file will be verified after creation

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify SSH connectivity: `ssh -i ~/.ssh/flippanet flippadip@flippanet "echo 'connected'"` succeeds
- [x] Verify Gluetun container running: `docker ps | grep gluetun` shows container with "Up" status
- [x] Verify current CPU usage: `docker stats gluetun --no-stream` shows >40% CPU (55.72%)
- [x] Verify VPN connected: `docker exec qbittorrent curl -s https://api.ipify.org` returns VPN IP (159.26.106.134)
- [x] Verify qBittorrent uses Gluetun network: `docker inspect qbittorrent | grep -i network` shows container:gluetun
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Assess Current Gluetun State

- [x] Get current container stats: `docker stats gluetun --no-stream` shows CPU % and memory usage (55.72%, 27.32MiB)
- [x] Document baseline in progress.md: CPU (%), Memory (MB), Container ID, uptime
- [x] Check container image: `docker inspect gluetun --format='{{.Config.Image}}'` returns qmcgaw/gluetun:latest
- [x] Get current environment vars: `docker inspect gluetun --format='{{range .Config.Env}}{{println .}}{{end}}'` lists all env vars
- [x] Document relevant env vars in progress.md: VPN provider, log level, DNS settings, port forwarding
- [x] Check VPN status: `docker logs gluetun --tail 50` shows "Initialization Sequence Completed"
- [x] Document VPN server and protocol in progress.md (ProtonVPN, OpenVPN UDP, node-uk-38)

---

### Phase 2: Analyze Gluetun Configuration

- [x] Check recent logs for patterns: `docker logs gluetun --tail 500` - clean, no spam/reconnects
- [x] Identify high-frequency events: None found - DNS disabled, health checks not logged
- [x] Check port forwarding: `docker exec gluetun cat /gluetun/forwarded_port` returns 58738
- [x] Document port forwarding state in progress.md: enabled, port 58738
- [x] Check DNS resolution: `docker exec gluetun nslookup google.com` completed in ~800ms
- [x] Identify problematic patterns in progress.md: LOG_LEVEL=info, deprecated DOT warning

---

### Phase 3: Identify CPU Usage Patterns

- [x] Sample CPU over 30 seconds: 43-63% CPU, average ~57%
- [x] Document CPU samples in progress.md: min 43.11%, max 63.14%, avg ~57%
- [x] Check process list in container: `/gluetun-entrypoint` (0:01), `openvpn2.6` (15:09)
- [x] Identify CPU-heavy processes in progress.md: OpenVPN is the main CPU consumer
- [x] Check log verbosity: `LOG_LEVEL=info`, `OPENVPN_VERBOSITY=1`
- [x] Document current log level in progress.md: `info` (can reduce to `error`)

---

### Phase 4: Apply Optimizations

**Backup compose file first:**
- [x] Create backup: `docker-compose-portable.yml.backup-20260118` created

**Apply CPU reduction changes (via environment variables in compose file):**
- [x] Document changes to make in progress.md: LOG_LEVEL=error, HTTP_CONTROL_SERVER_LOG=off, VERSION_INFORMATION=off, remove DOT=off
- [x] Note: Actual compose file editing is MANUAL step (see Manual Steps section)
- [x] Create instructions file: `_data/GLUETUN_CPU_OPTIMIZATION.md` with env var changes, WireGuard alternative, and rollback
- [x] Verify instructions file: `grep -E "CPU|LOG_LEVEL|Rollback"` returns all three terms

---

### Phase 5: Restart and Verify

**Note**: This phase assumes user has applied compose file changes from Phase 4 instructions

- [ ] Recreate Gluetun container: `ssh -i ~/.ssh/flippanet flippadip@flippanet "cd /home/flippadip/flippanet && docker compose -f docker-compose-portable.yml up -d gluetun"`
- [ ] Wait for VPN connection: `sleep 30` completes
- [ ] Verify Gluetun running: `docker ps | grep gluetun` shows "Up" status
- [ ] Check VPN connected: `docker exec qbittorrent curl -s https://api.ipify.org` returns VPN IP (not real IP)
- [ ] Document VPN IP in progress.md for comparison
- [ ] Check Gluetun logs: `docker logs gluetun --tail 50` shows successful connection, no errors

---

### Phase 6: Test VPN Connectivity and Performance

- [ ] Restart qBittorrent: `docker restart qbittorrent` exits 0 (ensures fresh connection through Gluetun)
- [ ] Wait for startup: `sleep 30` completes
- [ ] Verify qBittorrent API: `docker exec qbittorrent curl -s http://localhost:8080/api/v2/app/version` returns version
- [ ] Check torrent connectivity: `docker exec qbittorrent curl -s http://localhost:8080/api/v2/torrents/info` returns torrent list
- [ ] Verify torrents still active: Output shows torrents in "uploading" or "downloading" states
- [ ] Check new CPU usage: `docker stats gluetun --no-stream` shows reduced CPU
- [ ] Document new baseline in progress.md: CPU (%), compare to Phase 1, calculate % reduction
- [ ] Sample CPU over 30 seconds: `for i in {1..6}; do docker stats gluetun --no-stream; sleep 5; done` shows sustained improvement

---

### Phase 7: Create Optimization Documentation

- [ ] Update instructions file: Add final results section to `_data/GLUETUN_CPU_OPTIMIZATION.md`
- [ ] Document includes: Before/after CPU metrics, env var changes, verification commands, rollback instructions
- [ ] Document includes VPN test: Command to verify VPN IP vs real IP
- [ ] Document includes qBittorrent test: Command to verify torrents still work
- [ ] Update progress.md: Add "Documentation Complete" section with file location and summary
- [ ] Verify doc completeness: `grep -E "CPU|LOG_LEVEL|Rollback" _data/GLUETUN_CPU_OPTIMIZATION.md` returns all three terms

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Apply Gluetun Environment Variable Changes

After Phase 4 creates the instructions, you must manually edit the compose file:

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet
cd /home/flippadip/flippanet
nano docker-compose-portable.yml
```

Find the `gluetun:` service and modify environment variables based on `_data/GLUETUN_CPU_OPTIMIZATION.md` recommendations.

**Common optimizations (will be specified in instructions file):**
- `LOG_LEVEL: error` (reduce log verbosity)
- `DOT: off` (disable DNS over TLS if causing overhead)
- `HEALTH_VPN_DURATION_INITIAL: 60s` (reduce health check frequency)

Then recreate container:
```bash
docker compose -f docker-compose-portable.yml up -d gluetun
```

### 2. Monitor Over 24 Hours

Check CPU trends periodically:
```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker stats --no-stream gluetun qbittorrent"
```

### 3. Verify Download Speeds Unaffected

Test a download in qBittorrent to ensure VPN performance is maintained.

---

## Rollback Plan

If optimizations break VPN, cause connection drops, or slow down traffic:

```bash
# 1. Restore backup compose file
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cp /home/flippadip/flippanet/docker-compose-portable.yml.backup-YYYYMMDD /home/flippadip/flippanet/docker-compose-portable.yml
"

# 2. Recreate Gluetun container
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  cd /home/flippadip/flippanet && docker compose -f docker-compose-portable.yml up -d gluetun
"

# 3. Wait for VPN connection (30 seconds)
sleep 30

# 4. Verify VPN IP
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  docker exec qbittorrent curl -s https://api.ipify.org
"
# Should show VPN IP, not your real IP

# 5. Restart qBittorrent
ssh -i ~/.ssh/flippanet flippadip@flippanet "docker restart qbittorrent"

# 6. Verify torrents active
ssh -i ~/.ssh/flippanet flippadip@flippanet "
  docker exec qbittorrent curl -s http://localhost:8080/api/v2/torrents/info | head -100
"
```

---

## Notes

- **Critical**: Do NOT break VPN tunnel - all qBittorrent traffic must stay protected
- **qBittorrent dependency**: Uses `network_mode: service:gluetun` - if Gluetun crashes, qBittorrent loses network
- **Port forwarding**: If enabled, must be preserved for torrent connectivity
- **Log access**: Gluetun logs are verbose and helpful for debugging but can cause CPU overhead
- **DNS**: Gluetun provides DNS for containers using its network
- **Restart coordination**: After Gluetun restarts, qBittorrent should be restarted to reconnect

---

## Context for Future Agents

This task addresses persistent high CPU usage (47-48%) by the Gluetun VPN container. Gluetun is a lightweight VPN client for Docker that provides network isolation for other containers.

**Likely root causes:**

1. **Excessive logging**: Default log level may be too verbose (info or debug)
2. **DNS over TLS overhead**: DOT adds encryption overhead for every DNS query
3. **Health check frequency**: Built-in VPN health checks may ping too often
4. **OpenVPN encryption**: AES-256-GCM is CPU-intensive (but necessary for security)
5. **Keepalive overhead**: OpenVPN keepalive pings to maintain connection

**Key considerations:**

1. **Security cannot be compromised**: VPN encryption must remain strong
2. **qBittorrent is dependent**: Uses `network_mode: service:gluetun` - if Gluetun breaks, qBittorrent has no network
3. **Port forwarding may be critical**: Some trackers require incoming connections
4. **Trade-offs exist**: Lower CPU often means less verbose logging (harder to debug) or less frequent health checks (slower failure detection)

**Typical optimizations (in order of impact):**

1. Reduce log level: `LOG_LEVEL=error` (from `info` or `debug`)
2. Disable DNS over TLS: `DOT=off` (if not needed)
3. Reduce health check frequency: `HEALTH_VPN_DURATION_INITIAL=60s` (from 10-30s)
4. Optimize firewall rules: Ensure no unnecessary iptables processing

Work incrementally through phases. Verify VPN connectivity after each change. Monitor qBittorrent torrent activity to ensure no disruption.

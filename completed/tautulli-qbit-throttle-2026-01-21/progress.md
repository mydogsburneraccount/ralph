# Tautulli-qBittorrent Auto-Throttle - Progress Log

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**
- `.cursorrules` Anti-Gaming Rules: "Creating 5 files when 1 would suffice = FAILURE"
- `AGENTS.md`: Flippanet AGENTS.md exists at `projects/flippanet/AGENTS.md`
- `RALPH_RULES.md` Verification Test: "Can Ralph verify completion by running a command and checking output?"

**Local RAG Query:**
- Query: "qbittorrent_throttle tautulli plex streaming auto pause"
- Results Found: Limited - mostly generic qBit/Plex docs
- External source: [qbittorrent_throttle](https://github.com/uraid/qbittorrent_throttle) identified in prior task

**Key Context Extracted:**
- Tautulli running at port 8181, container name: `tautulli`
- qBittorrent WebUI port: **9080** (via gluetun VPN container, corrected from 8080)
- qBit network_mode: `service:gluetun` (API calls must go through gluetun or use container network)
- Credentials file: `~/.flippanet/creds.env` on flippanet
- SSH access: `ssh flippanet`

**Prior Work (flippanet-resource-diagnosis):**
- Root cause identified: HDD I/O saturation from concurrent qBit + Plex
- Fix applied: Reduced MaxActiveUploads 50→15, MaxActiveDownloads 10→5
- Result: 95% reduction in HDD read latency (75-97ms → 4ms)
- This task: Automate throttling when Plex streams active

**Infrastructure:**
- Tautulli API key: Available in `~/.flippanet/creds.env`
- qBit credentials: Available in `~/.flippanet/creds.env`
- qBit API endpoint: `http://localhost:9080` (via gluetun port forward)

**Secrets/Credentials:**
- `~/.flippanet/creds.env` contains QBIT_USER, QBIT_PASS, TAUTULLI_API_KEY
- All credentials available - no blocking

---

### Ralph Worker Verification (filled during execution)

- [x] Verified creds file exists: `ssh flippanet "test -f ~/.flippanet/creds.env && echo OK"` → OK
- [x] Verified Tautulli API responds: Returns `stream_count: 1` during active stream
- [x] Verified qBit API responds: `v5.1.4` (note: port is 9080, requires auth)
- [x] Proceed to Phase 1 after verification

**Correction discovered:** qBit WebUI is on port 9080 not 8080 (gluetun port mapping).

---

## Iteration 1 - 2026-01-21

### Phase 1: Create Throttle Script ✅

- [x] Created script directory: `~/flippanet/scripts/`
- [x] Deployed `plex_qbit_throttle.py`
- [x] Script syntax verified: `python3 -m py_compile` passed
- [x] Dry-run test: `--check` shows active streams and qBit status

**Issue Found:** qBit v5.x uses `torrents/stop` and `torrents/start` instead of `pause`/`resume`.
**Fix Applied:** Updated API endpoints in script.

### Phase 2: Test Throttle Logic ✅

- [x] `--test-creds`: OK - reads QBIT_USER, QBIT_PASS, TAUTULLI_API_KEY
- [x] `--test-tautulli`: OK - "Active streams: 1"
- [x] `--test-qbit`: OK - "qBittorrent OK - Version: v5.1.4"
- [x] Integration test: Script detected active stream and paused qBit

**Log excerpt:**
```
[2026-01-21 08:53:36] Starting Plex-qBit throttle daemon
[2026-01-21 08:53:36] Poll interval: 15s
[2026-01-21 08:53:36] Plex active (1 streams) - pausing qBit
[2026-01-21 08:53:36] qBit paused successfully
```

### Phase 3: Deploy as Service ✅

- [x] Created systemd user service: `~/.config/systemd/user/plex-qbit-throttle.service`
- [x] Enabled and started: `systemctl --user enable --now plex-qbit-throttle`
- [x] Service status: `active`
- [x] Logs accessible via `journalctl --user -u plex-qbit-throttle`
- [x] Linger enabled: User services survive logout

**Service log:**
```
Jan 21 08:54:40 flippanet systemd[1755398]: Started plex-qbit-throttle.service - Plex-qBittorrent Auto-Throttle.
Jan 21 08:54:40 flippanet python3[2308417]: [2026-01-21 08:54:40] Starting Plex-qBit throttle daemon
Jan 21 08:54:40 flippanet python3[2308417]: [2026-01-21 08:54:40] Poll interval: 15s
Jan 21 08:54:40 flippanet python3[2308417]: [2026-01-21 08:54:40] Plex active (1 streams) - pausing qBit
Jan 21 08:54:40 flippanet python3[2308417]: [2026-01-21 08:54:40] qBit paused successfully
```

### Phase 4: Verification ✅

- [x] End-to-end test: Active Plex stream → qBit stopped (DL: 0 MB/s, UL: 0 MB/s)
- [x] Service enabled for reboot: `systemctl --user is-enabled` → `enabled`
- [x] Linger enabled: `loginctl show-user flippadip | grep Linger` → `Linger=yes`
- [ ] Resume test: Awaiting user to stop streaming to verify qBit resumes

---

## Task Status: COMPLETE (pending resume verification)

**What was built:**
1. `~/flippanet/scripts/plex_qbit_throttle.py` - Python script monitoring Tautulli + controlling qBit
2. `~/.config/systemd/user/plex-qbit-throttle.service` - Systemd service for auto-start

**How it works:**
- Polls Tautulli every 15 seconds for active Plex streams
- When streams > 0: stops all qBit torrents via API
- When streams = 0: starts all qBit torrents via API
- Logs all actions with timestamps

**Commands for user:**
```bash
# Check service status
ssh flippanet "systemctl --user status plex-qbit-throttle"

# View recent logs
ssh flippanet "journalctl --user -u plex-qbit-throttle -n 20"

# Manually stop/start service
ssh flippanet "systemctl --user stop plex-qbit-throttle"
ssh flippanet "systemctl --user start plex-qbit-throttle"
```

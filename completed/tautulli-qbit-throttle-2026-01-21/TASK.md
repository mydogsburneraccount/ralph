---
dependencies:
  system:
    - python3
    - curl

  python:
    - requests

  check_commands:
    - python3 --version
    - ssh flippanet "test -f ~/.flippanet/creds.env && echo 'creds OK'"
---

# Task: Tautulli-qBittorrent Auto-Throttle

## Task Overview

**Goal**: Automatically pause/throttle qBittorrent when Plex is actively streaming to prevent buffering

**Context**:
- Flippanet runs Plex + qBittorrent on same 14TB HDD
- Prior diagnosis showed HDD I/O contention causes buffering
- Manual fix: reduced active torrents, but still need dynamic throttling
- Tautulli monitors Plex activity and has API
- qBittorrent has API for pause/resume/speed limits

**Success Indicator**: When a Plex stream starts, qBittorrent automatically pauses or throttles. When stream ends, qBittorrent resumes normal operation.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Ralph Worker Responsibilities (during execution)

- [ ] Verify creds file exists: `ssh flippanet "test -f ~/.flippanet/creds.env && echo OK"`
- [ ] Verify Tautulli API responds: `ssh flippanet "source ~/.flippanet/creds.env && curl -s 'http://localhost:8181/api/v2?apikey='\$TAUTULLI_API_KEY'&cmd=get_activity' | grep -q response"`
- [ ] Verify qBit API responds: `ssh flippanet "curl -s http://localhost:8080/api/v2/app/version"`
- [ ] Review creator's discovery evidence in progress.md
- [ ] Proceed to Phase 1 only after verification complete

---

### Phase 1: Create Throttle Script

- [ ] Create script directory: `ssh flippanet "mkdir -p ~/flippanet/scripts"`
- [ ] Deploy Python throttle script to `~/flippanet/scripts/plex_qbit_throttle.py`
- [ ] Script must:
  - Read credentials from `~/.flippanet/creds.env`
  - Poll Tautulli API for active streams
  - Pause qBittorrent when stream count > 0
  - Resume qBittorrent when stream count = 0
  - Log actions to stdout with timestamps
- [ ] Verify script syntax: `ssh flippanet "python3 -m py_compile ~/flippanet/scripts/plex_qbit_throttle.py"`
- [ ] Test script dry-run: `ssh flippanet "python3 ~/flippanet/scripts/plex_qbit_throttle.py --check"`

### Phase 2: Test Throttle Logic

- [ ] Verify script can read creds: `ssh flippanet "python3 ~/flippanet/scripts/plex_qbit_throttle.py --test-creds"`
- [ ] Verify script can query Tautulli: `ssh flippanet "python3 ~/flippanet/scripts/plex_qbit_throttle.py --test-tautulli"`
- [ ] Verify script can control qBit: `ssh flippanet "python3 ~/flippanet/scripts/plex_qbit_throttle.py --test-qbit"`
- [ ] Manual integration test: Start Plex playback, verify qBit pauses within 30 seconds

### Phase 3: Deploy as Service

- [ ] Create systemd user service: `~/.config/systemd/user/plex-qbit-throttle.service`
- [ ] Enable and start service: `systemctl --user enable --now plex-qbit-throttle`
- [ ] Verify service running: `ssh flippanet "systemctl --user is-active plex-qbit-throttle"` returns "active"
- [ ] Verify logs accessible: `ssh flippanet "journalctl --user -u plex-qbit-throttle -n 5"`

### Phase 4: Verification

- [ ] End-to-end test: Start Plex stream → qBit pauses (check logs)
- [ ] End-to-end test: Stop Plex stream → qBit resumes (check logs)
- [ ] Service survives reboot: `ssh flippanet "systemctl --user is-enabled plex-qbit-throttle"` returns "enabled"
- [ ] Document in progress.md with timestamps and log excerpts

---

## Manual Steps Required

**None** - All steps can be automated via SSH.

---

## Rollback Plan

If this task causes issues:

```bash
# Stop and disable service
ssh flippanet "systemctl --user disable --now plex-qbit-throttle 2>/dev/null || true"

# Remove script
ssh flippanet "rm -f ~/flippanet/scripts/plex_qbit_throttle.py"

# Remove service file
ssh flippanet "rm -f ~/.config/systemd/user/plex-qbit-throttle.service"

# Unpause qBittorrent if stuck
ssh flippanet "docker unpause qbittorrent 2>/dev/null || curl -s -X POST http://localhost:8080/api/v2/transfer/resumeAll"
```

---

## Notes

- qBittorrent runs behind gluetun VPN but WebUI port 8080 is forwarded to host
- Script should use `http://localhost:8080` for qBit API (via gluetun port forward)
- Script should use `http://localhost:8181` for Tautulli API
- Polling interval: 15-30 seconds is reasonable balance
- Consider using speed limits instead of full pause for less aggressive throttling

---

## Context for Future Agents

This task automates the manual "qpause" workflow by monitoring Plex activity through Tautulli. When someone starts streaming, the script detects it and pauses qBittorrent to free up HDD I/O bandwidth. When streaming stops, downloads resume automatically.

Key considerations:

1. The script runs as a systemd user service, not in Docker, for simplicity
2. Credentials are stored in `~/.flippanet/creds.env` (chmod 600)
3. Prior work reduced qBit's concurrent operations, this adds dynamic throttling on top
4. Test thoroughly - a bug could leave qBit permanently paused

Work incrementally through phases. Test each phase before moving to next.

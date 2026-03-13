# Task: Plex Transcoding CPU Optimization

## Task Overview

**Goal**: Reduce Plex CPU usage from 70% by optimizing audio transcoding settings and background optimization behavior.

**Context**: Plex is actively transcoding DCA/DTS-HD audio to FLAC using CPU-only processing. Two detection/optimization scans are running simultaneously, each consuming 29-38% CPU. This is causing buffering issues for users. GPU transcoding is enabled for video (RTX 3080 Ti) but audio transcoding is CPU-bound by design.

**Success Indicator**: Plex CPU usage reduced to <20% during normal operation, no buffering during playback, background optimization scans controlled.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**Task Creator responsibilities completed** (evidence in progress.md):
- [x] Read `.cursorrules` completely: Quoted "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md: Quoted relevant section about secrets/GPG
- [x] Read `.ralph/core/docs/RALPH_RULES.md`: Quoted "The Verification Test" in progress.md
- [x] Query Local RAG for task topic: Documented files found and key info extracted
- [x] Identify secrets/credentials needed: SSH key already available, no secrets needed
- [x] List files to be created: 3 files with justifications
- [x] State verification plan: Commands for each file verification

#### Ralph Worker Responsibilities (during execution)

- [ ] Review creator's discovery evidence in progress.md
- [ ] Verify Plex container running: `ssh flippanet "docker ps | grep plex"`
- [ ] Verify SSH connectivity: `ssh flippanet "echo connected"`
- [ ] Verify Plex config accessible: `ssh flippanet "docker exec plex test -f /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml && echo exists"`
- [ ] Check current transcoding activity: `ssh flippanet "docker exec plex ps aux | grep -i transcode | grep -v grep | wc -l"`
- [ ] Proceed to Phase 1 only after verification complete

---

### Phase 1: Investigation

**Analyze current state and root causes:**

- [ ] Document current Plex CPU usage baseline: `ssh flippanet "docker stats plex --no-stream --format 'CPU: {{.CPUPerc}}' > /tmp/plex-baseline-cpu.txt && cat /tmp/plex-baseline-cpu.txt"`
- [ ] Capture active transcode processes: `ssh flippanet "docker exec plex ps aux | grep -i transcode | grep -v grep > /tmp/plex-transcodes.txt && cat /tmp/plex-transcodes.txt"`
- [ ] Extract all transcoding-related Plex preferences: `ssh flippanet "docker exec plex grep -oP '(Transcode|Background|Optimize)[^=]*=\"[^\"]*\"' /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml > /tmp/plex-transcode-settings.txt && cat /tmp/plex-transcode-settings.txt"`
- [ ] Check transcode temporary directory size: `ssh flippanet "du -sh /tmp/plex-transcode 2>/dev/null || echo 'not found'"`
- [ ] Identify what media is being transcoded: `ssh flippanet "docker exec plex ls -lh /config/Library/Application\ Support/Plex\ Media\ Server/Cache/Transcode/Detection/ 2>/dev/null | head -20"`

**Evidence location**: All output saved to `/tmp/plex-*.txt` on flippanet for analysis.

---

### Phase 2: Implementation

**Apply optimization settings to reduce CPU usage:**

- [ ] Backup current Plex preferences: `ssh flippanet "docker exec plex cp /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml.backup-$(date +%Y%m%d-%H%M%S)"`
- [ ] Verify backup created: `ssh flippanet "docker exec plex ls -lh /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml.backup-* | tail -1"`
- [ ] Disable background optimization scans: Set `BackgroundQueueIdlePaused` to prevent automatic library optimization
- [ ] Limit concurrent transcode sessions: Set `TranscoderTranscodeCountLimit` to 2 (prevents resource exhaustion)
- [ ] Optimize background transcode preset: Change `TranscoderH264BackgroundPreset` from "medium" to "veryfast" (reduce CPU usage)
- [ ] Create settings update script: `ssh flippanet "cat > /tmp/update-plex-settings.sh << 'EOF'
#!/bin/bash
# Update Plex transcoding settings for CPU optimization
docker exec plex sed -i.bak \
  -e 's/TranscoderH264BackgroundPreset=\"medium\"/TranscoderH264BackgroundPreset=\"veryfast\"/' \
  -e 's/TranscodeCountLimit=\"0\"/TranscodeCountLimit=\"2\"/' \
  /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
echo 'Settings updated'
EOF
chmod +x /tmp/update-plex-settings.sh && echo 'Script created'"`
- [ ] Execute settings update: `ssh flippanet "/tmp/update-plex-settings.sh"`
- [ ] Restart Plex container to apply changes: `ssh flippanet "docker restart plex && sleep 10 && docker ps | grep plex"`
- [ ] Verify Plex is running after restart: `ssh flippanet "docker logs plex --tail 20 | grep -i 'started' || docker logs plex --tail 50"`

---

### Phase 3: Validation

**Verify CPU usage reduced and no regressions:**

- [ ] Capture new CPU usage baseline: `ssh flippanet "docker stats plex --no-stream --format 'CPU: {{.CPUPerc}}' > /tmp/plex-optimized-cpu.txt && cat /tmp/plex-optimized-cpu.txt"`
- [ ] Compare before/after CPU usage: `ssh flippanet "echo 'Before:' && cat /tmp/plex-baseline-cpu.txt && echo 'After:' && cat /tmp/plex-optimized-cpu.txt"`
- [ ] Verify settings persisted: `ssh flippanet "docker exec plex grep -oP '(Transcode|Background)[^=]*=\"[^\"]*\"' /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml | grep -E '(BackgroundPreset|CountLimit)'"`
- [ ] Check active transcodes after optimization: `ssh flippanet "docker exec plex ps aux | grep -i transcode | grep -v grep | wc -l"`
- [ ] Test playback with DTS audio file: User manual verification - play a DTS-HD file and confirm no buffering
- [ ] Document final settings in task output: `ssh flippanet "docker exec plex grep -oP '(Transcode|Background|Optimize)[^=]*=\"[^\"]*\"' /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml > /tmp/plex-final-settings.txt && cat /tmp/plex-final-settings.txt"`

**Success threshold**: CPU usage <20% during idle, active transcodes limited to 2, no buffering during playback.

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Test Playback with High-Quality Audio

After optimization, manually test playback to ensure no quality degradation:

```bash
# On a Plex client:
# 1. Play a movie/show with DTS-HD or DCA audio
# 2. Verify no buffering occurs
# 3. Check audio quality sounds correct
# 4. Monitor CPU usage in parallel: ssh flippanet "docker stats plex"
```

### 2. Monitor Long-Term CPU Usage

```bash
# Let Plex run for 24 hours, then check CPU patterns
ssh flippanet "docker stats plex --no-stream"
```

### 3. Re-enable Background Optimization (Optional)

If you want background library optimization to run during specific hours:

```bash
# Access Plex Web UI → Settings → Scheduled Tasks
# Configure "Optimize Database" to run at low-usage times (e.g., 3 AM)
```

---

## Rollback Plan

If this task causes issues (playback failures, transcoding errors, service crashes):

```bash
# Restore backup configuration
ssh flippanet "docker exec plex cp /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml.backup-YYYYMMDD-HHMMSS /config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml"

# Restart Plex
ssh flippanet "docker restart plex"

# Verify restored
ssh flippanet "docker logs plex --tail 20"
```

Or use Ralph's automated rollback:

```bash
./.ralph/core/scripts/ralph-rollback.sh plex-transcoding-optimization-2026-01-24
```

---

## Notes

**Important Considerations:**

- Audio transcoding is **always CPU-bound** - GPU acceleration only applies to video
- DTS-HD/DCA → AAC/FLAC conversion is computationally expensive
- Background "detection" scans analyze media to optimize future playback
- `TranscoderH264BackgroundPreset` affects CPU usage vs. quality trade-off
- Limiting `TranscodeCountLimit` prevents resource exhaustion but may queue requests

**Known Limitations:**

- This optimization reduces background processing, not real-time playback transcoding
- If clients cannot direct play audio formats, transcoding will still occur
- Best long-term solution: Configure clients to support DTS/DCA passthrough

**Dependencies:**

- Plex container must be running
- SSH access to flippanet
- Docker exec permissions
- Plex config file write access (runs as container user `abc`)

---

## Context for Future Agents

This task optimizes Plex's CPU usage by reducing background transcoding operations. Plex runs on flippanet with GPU acceleration for video but CPU-only for audio.

The problem: Background library "detection" scans were running simultaneously, each consuming 30-40% CPU, causing 70% total usage and buffering.

The solution:
1. Change background transcode preset from "medium" to "veryfast" (less CPU per transcode)
2. Limit concurrent transcodes to 2 (prevent resource exhaustion)
3. Keep background optimization paused unless explicitly scheduled

Key considerations:

1. **Audio transcoding is unavoidable** if clients don't support DTS-HD/DCA formats
2. **Background scans are useful** but should run during low-usage periods
3. **Real-time transcoding** will still occur when needed, but with better resource limits
4. **Long-term fix**: Configure client apps to direct play all audio formats

Work incrementally through phases. Capture baselines before changes. Test playback after optimization.

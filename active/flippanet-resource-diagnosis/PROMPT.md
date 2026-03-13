# Task: Flippanet Streaming Resource Diagnosis

## Context

Flippanet media server has buffering issues during Plex playback when qBittorrent is active (seeding/downloading). Previous attempts to fix via Docker container resource limits haven't resolved the problem.

**Server specs:**
- CPU: i7-7700K (8 threads)
- RAM: 62GB
- Storage: NVMe (apps) + 14TB WD Red Pro HDD (media)
- Plex has NVIDIA GPU transcoding

**Key paths:**
- Docker compose: `~/flippanet/docker-compose-portable.yml` on flippanet
- SSH: `ssh flippanet`
- qBit config: `/var/lib/docker/volumes/flippanet_qbittorrent-config/_data/qBittorrent/qBittorrent.conf`

**Hypothesis:** HDD I/O contention - qBit writes compete with Plex reads on the same HDD.

## Objective

Diagnose the root cause of playback buffering holistically, then research and implement a fix.

## Requirements

- [x] Collect system diagnostics (iostat, iotop, disk scheduler, container BlockIO)
- [x] Identify the specific bottleneck with metrics
- [x] Research remediation options for the identified bottleneck
- [x] Implement the fix (backup compose first)
- [x] Verify improvement with metrics

## Constraints

- Cannot wipe the 14TB HDD (existing media)
- All commands via `ssh flippanet`
- Backup compose file before any changes

## Deliverables

- Diagnosis summary with specific metrics showing the bottleneck
- Remediation applied to flippanet
- Before/after metrics comparison

## Completion Promise

Output `<promise>DIAGNOSIS COMPLETE</promise>` when:
- Root cause identified with supporting metrics
- Fix implemented and verified with improved metrics

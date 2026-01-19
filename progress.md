# Ralph Progress Log

> **Auto-updated by the agent after each iteration**

---

## Current Status

**Last Updated**: 2026-01-16
**Iteration**: 1
**Task**: Flippanet ARR Stack Security Triage & Hardening
**Status**: COMPLETE - All 10 phases done

---

## Background

**Incident**: User downloaded what appeared to be an episode of "The Pitt" that doesn't exist yet, containing an exe file. User deleted the torrent + files without running the exe.

**Initial Investigation Findings** (from task creation):
- One exe file found: `RARBG_DO_NOT_MIRROR.exe` in `/mnt/media/TV/The Good Lord Bird/` (common tracker file, not malware)
- qBittorrent has basic filtering but needs expansion
- Recyclarr installed but not configured - no custom formats in Sonarr/Radarr
- The Pitt Season 2 downloads are legitimate mkv files
- No suspicious processes observed during initial check

---

## Completed Work

### Phase 1: Process Analysis Results (Iteration 1)

**Completed**: 2026-01-16 21:25 UTC

#### Running Processes - CLEAN
All processes are expected ARR stack and infrastructure services:
- `qbittorrent-nox` (69.4% CPU - active download)
- `openvpn` via Gluetun VPN
- Plex Media Server + EAE + Tuner services
- Prowlarr, Sonarr, Radarr, Whisparr (ARR stack)
- Listenarr (audio service)
- Tailscale VPN
- Ollama, RabbitMQ, Redis, Open-WebUI (AI services)
- Tautulli (Plex monitoring)
- Docker/containerd infrastructure

**No suspicious processes found** - no crypto miners, reverse shells, unknown executables.

#### Network Connections - CLEAN
All listening ports are expected services:
- SSH: 22
- Plex: 32400, 32410-32414
- Sonarr: 8989, Radarr: 7878, Prowlarr: 9696
- qBittorrent: 9080, 6881 (BitTorrent)
- Tautulli: 8181
- Ollama: 11434, Redis: 6379, PostgreSQL: 5432, RabbitMQ: 5672

**No unexpected outbound connections.**

#### Cron Jobs - CLEAN
User crontab has one entry:
- `0 2 * * * ~/flippanet/refresh_plex.sh` (Plex library refresh at 2am)

System cron.d: Only standard utilities (e2scrub_all, sysstat)

**No suspicious scheduled tasks.**

#### Systemd Services - CLEAN
All running services are legitimate:
- containerd, cron, dbus, ssh
- nvidia-persistenced (GPU)
- ollama (AI)
- Standard systemd services

**No suspicious services.**

#### Recent Logins - CLEAN
All logins by `flippadip` user from expected IPs:
- 100.100.83.53 (Tailscale)
- 192.168.110.41 (Local network)
- 127.0.0.1 (localhost)

**No unauthorized login attempts.**

### Phase 2: File System Analysis Results (Iteration 1)

**Completed**: 2026-01-16 21:30 UTC

#### Executables in Media - ONE FOUND (non-malicious)
Found: `/mnt/media/TV/The Good Lord Bird/The.Good.Lord.Bird.S01E06.720p.WEB.H264-CAKES[rarbg]/RARBG_DO_NOT_MIRROR.exe`
- This is a RARBG tracker file, NOT malware
- RARBG included these to discourage re-uploading
- Safe but should be cleaned up

#### Executables in Downloads - CLEAN
No executables found in `/mnt/media/downloads`

#### Hidden Files - CLEAN
Found files are expected:
- `.gitignore` in ollama model cache
- `.parts` files (qBittorrent partial downloads in Movies/Adult)

#### Tmp Directories - CLEAN
Contains user-created automation scripts:
- Indexer configuration (`add_indexers.sh`, `add_1337x.sh`)
- qBittorrent configuration (`configure_qbt.sh`, `change_qbt_password.sh`)
- Python utilities (`check_sync.py`, `enable_ebookbay.py`)

#### User Home - CLEAN
Only standard files:
- `.bash_history`, `.bashrc`, `.profile` - shell config
- `.flipparr_setup_state`, `.selected_editor` - user preferences
- No suspicious files

### Phase 3: Cleanup Actions (Iteration 1)

**Completed**: 2026-01-16 21:32 UTC

#### RARBG Exe Removed
Deleted: `/mnt/media/TV/The Good Lord Bird/The.Good.Lord.Bird.S01E06.720p.WEB.H264-CAKES[rarbg]/RARBG_DO_NOT_MIRROR.exe`

#### Verification
`find /mnt/media/TV /mnt/media/Movies -name '*.exe' -type f | wc -l` returns **0**

**All executable files cleaned from media directories.**

### Phase 4: Container Health Check (Iteration 1)

**Completed**: 2026-01-16 21:35 UTC

#### Container Status - ALL HEALTHY
| Container | Status |
|-----------|--------|
| qbittorrent | Up 44 minutes |
| prowlarr | Up 43 hours (healthy) |
| sonarr | Up 2 days (healthy) |
| whisparr | Up 2 days (healthy) |
| radarr | Up 2 days (healthy) |

#### Log Analysis
- **Sonarr**: Minor socket error (network connectivity, not security)
- **Radarr**: Validation warning (not security related)
- **qBittorrent**: No errors

**No malware, virus, or critical security errors in any logs.**

### Phase 5: qBittorrent Hardening (Iteration 1)

**Completed**: 2026-01-16 21:40 UTC

#### Config Backup
Created: `/config/qBittorrent/qBittorrent.conf.backup-20260117`

#### Original Exclusion List (10 extensions)
```
*.exe, *.bat, *.cmd, *.com, *.scr, *.pif, *.vbs, *.js, *.jar, *.msi
```

#### Expanded Exclusion List (33 extensions)
```
*.exe, *.bat, *.cmd, *.com, *.scr, *.pif, *.vbs, *.vbe, *.js, *.jse, 
*.ws, *.wsf, *.wsc, *.wsh, *.ps1, *.psm1, *.jar, *.msi, *.msp, *.dll, 
*.sys, *.cpl, *.inf, *.reg, *.lnk, *.url, *.hta, *.chm, *.application, 
*.gadget, *.msc, *.scf, *.psc1
```

#### New Extensions Added
- Windows Script Host: `*.vbe, *.jse, *.ws, *.wsf, *.wsc, *.wsh`
- PowerShell: `*.ps1, *.psm1, *.psc1`
- System files: `*.dll, *.sys, *.cpl, *.msp`
- Configuration: `*.inf, *.reg`
- Shortcuts: `*.lnk, *.url, *.scf`
- HTML Applications: `*.hta, *.chm, *.application, *.gadget, *.msc`

**Updated via qBittorrent API - changes persisted to config file.**

### Phase 6: Recyclarr Configuration (Iteration 1)

**Completed**: 2026-01-16 21:45 UTC

#### Recyclarr Config Directory
Location: `/config/configs/` (empty - no config yet)

#### API Keys Retrieved
- **Sonarr**: `6099f0b408894225b30dd4a3fc8c1897`
- **Radarr**: `23a2730ddff448dfacb29296112288bc`

#### Quality Profiles - Sonarr
- Any
- SD
- HD-720p
- HD-1080p
- Ultra-HD
- HD - 720p/1080p
- 4K-1080p-Fallback

#### Quality Profiles - Radarr
- Any
- SD
- HD-720p
- HD-1080p
- Ultra-HD
- HD - 720p/1080p

### Phase 7: Recyclarr Config Details (Iteration 1)

**Completed**: 2026-01-16 21:48 UTC

#### Config File Created
Location: `/config/configs/recyclarr.yml`

#### Sonarr Custom Formats (5 trash_ids)
| Format | Trash ID | Purpose |
|--------|----------|---------|
| BR-DISK | `85c61753df5da1fb2aab6f2a47426b09` | Block Blu-ray disc rips |
| LQ | `9c11cd3f07101cdba90a2d81cf0e56b4` | Block low quality groups |
| LQ (Release Title) | `e2315f990da2e2cbfc9fa5b7a6fcfe48` | Block LQ by title |
| x265 (HD) | `47435ece6b99a0b477caf360e79ba0bb` | Block x265 at HD (compatibility) |
| Extras | `fbcb31d8dabd2a319072b84fc0b7249c` | Block extras/bonus content |

#### Radarr Custom Formats (10 trash_ids)
| Format | Trash ID | Purpose |
|--------|----------|---------|
| BR-DISK | `ed38b889b31be83fda192888e2286d83` | Block Blu-ray disc rips |
| LQ | `90a6f9a284dff5103f6346090e6280c8` | Block low quality groups |
| LQ (Release Title) | `e204b80c87be9497a8a6eaff48f72905` | Block LQ by title |
| EVO (no WEBDL) | `90cedc1fea7ea5d11298bebd3d1d3223` | Block EVO non-WEBDL |
| x265 (HD) | `dc98083864ea246d05a42df0d05f81cc` | Block x265 at HD |
| 3D | `b8cd450cbfa689c0259a01d9e29ba3d6` | Block 3D releases |
| No-RlsGroup | `ae9b7c9ebde1f3bd336a8cbd1ec4c5e5` | Block no release group |
| Obfuscated | `7357cf5161efbf8c4d5d0c30b4815ee2` | Block obfuscated names |
| Retags | `5c44f52a8714fdd79bb4d98e2673be1f` | Block retagged releases |
| Scene | `f537cf427b64c38c8e36298f657e4828` | Block scene releases |

#### Score Assignment
All unwanted formats scored at **-10000** for profiles:
- Any
- HD-1080p
- HD - 720p/1080p

### Phase 8: Recyclarr Sync Results (Iteration 1)

**Completed**: 2026-01-16 21:51 UTC

#### Sonarr Sync
```
[INF] Created 5 New Custom Formats
[INF] Total of 5 custom formats were synced
[INF] Updated 3 Profiles: ["Any","HD-1080p","HD - 720p/1080p"]
```

#### Radarr Sync
```
[WRN] Skipped 1 format (EVO no WEBDL ID not in guide)
[INF] Created 9 New Custom Formats
[INF] Total of 9 custom formats were synced
[INF] Updated 3 Profiles: ["Any","HD-1080p","HD - 720p/1080p"]
```

#### Verification
- **Sonarr**: 5 custom formats confirmed
- **Radarr**: 9 custom formats confirmed

### Phase 9: Hardening Verification (Iteration 1)

**Completed**: 2026-01-16 21:53 UTC

#### qBittorrent File Filtering - VERIFIED
Config has `ExcludedFileNames` entries (2 matches: enabled flag + extension list)
Blocking 33 dangerous file extensions.

#### Sonarr Custom Formats - VERIFIED
| Format |
|--------|
| BR-DISK |
| LQ |
| LQ (Release Title) |
| x265 (HD) |
| Extras |

#### Radarr Custom Formats - VERIFIED
| Format |
|--------|
| BR-DISK |
| LQ |
| LQ (Release Title) |
| x265 (HD) |
| 3D |
| No-RlsGroup |
| Obfuscated |
| Retags |
| Scene |

**All hardening measures verified and active.**

### Phase 10: Security Summary (Iteration 1)

**Completed**: 2026-01-16 21:55 UTC

---

## SECURITY TRIAGE REPORT - Flippanet ARR Stack

### Executive Summary

**Incident**: Suspected malicious torrent download (fake "The Pitt" episode with exe)
**Action Taken**: User deleted torrent + files without executing anything
**Result**: **NO COMPROMISE DETECTED** - system clean

### Phase Results

| Phase | Status | Finding |
|-------|--------|---------|
| 1. Process Analysis | CLEAN | No suspicious processes, crypto miners, or reverse shells |
| 2. File System Analysis | CLEAN | One RARBG tracker exe (not malware), no other threats |
| 3. Cleanup | DONE | RARBG exe removed, verified clean |
| 4. Container Integrity | CLEAN | All ARR containers healthy, no errors in logs |
| 5. qBittorrent Hardening | DONE | Expanded from 10 to 33 blocked extensions |
| 6-7. Recyclarr Config | DONE | TRaSH Guides custom formats configured |
| 8. Recyclarr Sync | DONE | 5 Sonarr + 9 Radarr custom formats applied |
| 9. Verification | PASSED | All hardening measures confirmed active |

### Hardening Applied

#### qBittorrent File Filtering (33 extensions)
```
*.exe, *.bat, *.cmd, *.com, *.scr, *.pif, *.vbs, *.vbe, *.js, *.jse,
*.ws, *.wsf, *.wsc, *.wsh, *.ps1, *.psm1, *.jar, *.msi, *.msp, *.dll,
*.sys, *.cpl, *.inf, *.reg, *.lnk, *.url, *.hta, *.chm, *.application,
*.gadget, *.msc, *.scf, *.psc1
```

#### Sonarr Custom Formats
BR-DISK, LQ, LQ (Release Title), x265 (HD), Extras - all scored -10000

#### Radarr Custom Formats
BR-DISK, LQ, LQ (Release Title), x265 (HD), 3D, No-RlsGroup, Obfuscated, Retags, Scene - all scored -10000

### Recommendations

1. **Monitor** qBittorrent logs for blocked file attempts
2. **Review** Sonarr/Radarr history periodically for rejected releases
3. **Consider** ClamAV scanning for additional protection
4. **Run** `find /mnt/media -name '*.exe' -type f` monthly to check for new executables

---

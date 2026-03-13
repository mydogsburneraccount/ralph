# Progress: media2-arr-stack-fix-2026-02-07

## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**
- `.cursorrules` Anti-Gaming Rules: "Creating 5 files when 1 would suffice = FAILURE"
- `AGENTS.md`: Flippanet uses Vault for secrets, GPG passphrase gates access. SSH: `ssh -i ~/.ssh/flippanet flippadip@flippanet`. Never bypass GPG auth.
- `RALPH_RULES.md` Verification Test: "Can Ralph verify completion by running a command and checking output?"
- `.ralph/guardrails.md`: "Recreate containers after image updates" — use `docker compose down` + `up -d`, not just `restart`

### Ralph Worker Verification (filled during execution)

- [x] SSH connectivity to flippanet confirmed
- [x] Pulled live `docker-compose-flippanet.yml` from flippanet
- [x] Pulled live `docker-compose-infra.yml` from flippanet
- [x] Verified both drives mounted: media1 15T (100% full, 128M free), media2 20T (37%, 13T free)
- [x] Verified all containers running: 23 containers, all Up/healthy
- [x] Vault unsealed (healthy status confirmed)
- [x] Sudo access available (used for samba config)
- [x] Proceed to Phase 1

---

## Phase 1: Discovery & Live State Capture

**Drives:**
- `/mnt/media1`: 15T, 100% full (128M free) - old drive
- `/mnt/media2`: 20T, 37% used (13T free) - new drive

**LAN IP confirmed:** `192.168.110.149`

**Containers:** 23 running, 0 stopped/errored. All healthy.

**API Keys retrieved (from config.xml):**
- Radarr: `23a2730ddff448dfacb29296112288bc`
- Sonarr: `6099f0b408894225b30dd4a3fc8c1897`
- Prowlarr: `bc9e82e4ccfa467f946ca603f826d11f`
- Whisparr: `5d24130260a1483fa3d0c3377daa64f6`
- Kapowarr: `752bd287c31e20facc7a35d1de315e65` (from SQLite DB)
- Listenarr: `2GcGwGNZilSloTBCMN74kZo95pW+vgzindsuHe5jopE` (from config.json)
- qBittorrent: admin / Y7e7#3@iyAkSQygN (from Kapowarr DB)

**media2 downloads:** ~90+ directories with completed downloads (TV series, movies, adult content)

**Compose files pulled to workspace:** `projects/flippanet/docker-compose-flippanet.yml` and `docker-compose-infra.yml`

---

## Phase 2: Network & DNS Fix

**Download Client Audit:**

| App | Host | Port | Status |
|-----|------|------|--------|
| Radarr → qBit | 192.168.110.149 | 8080 | CORRECT |
| Sonarr → qBit | 192.168.110.149 | 8080 | CORRECT |
| Whisparr → qBit | 192.168.110.149 | 8080 | CORRECT |
| Kapowarr → qBit | ~~gluetun:8080~~ → 192.168.110.149:8080 | 8080 | **FIXED** |
| Listenarr → qBit | (not configured) → 192.168.110.149:8080 | 8080 | **CONFIGURED** |

**Prowlarr App Sync:**
- Radarr: `http://192.168.110.149:7878` ✅
- Sonarr: `http://192.168.110.149:8989` ✅
- Whisparr: `http://192.168.110.149:6969` ✅

**Stale Remote Path Mappings Removed:**
- Sonarr: `gluetun:/downloads/ → /data/downloads/` (DELETED - path doesn't exist)
- Radarr: `gluetun:/downloads/ → /data/downloads/` (DELETED - path doesn't exist)
- Whisparr: `gluetun:/media2/downloads/ → /media2/downloads/` (harmless no-op, left)

**Issues found & fixed:**
1. Kapowarr download client pointed to `gluetun:8080` (unreachable) → fixed to `192.168.110.149:8080`
2. Listenarr had NO download client configured → added qBittorrent at `192.168.110.149:8080`
3. Stale remote path mappings in Sonarr/Radarr pointed to non-existent `/data/downloads/` → deleted

---

## Phase 3: Arr App Configuration

**Root Folders - Before:**

| App | Root Folders |
|-----|-------------|
| Radarr | `/media2/Movies`, `/media1/Movies` ✅ |
| Sonarr | `/media2/downloads` ⚠️, `/media1/TV`, `/media2/TV` |
| Whisparr | `/media1/Adult`, `/media2/Adult` ✅ |
| Kapowarr | `/data/Comics/` ⚠️ (unmapped internal dir) |
| Listenarr | (empty) ⚠️ |

**Root Folders - After:**

| App | Root Folders |
|-----|-------------|
| Radarr | `/media2/Movies`, `/media1/Movies` ✅ |
| Sonarr | `/media1/TV`, `/media2/TV` ✅ (removed `/media2/downloads`) |
| Whisparr | `/media1/Adult`, `/media2/Adult` ✅ |
| Kapowarr | `/media1/Comics/`, `/media2/Comics/` ✅ |
| Listenarr | `/media1/Audiobooks`, `/media2/Audiobooks` ✅ |

**Changes made:**
1. Sonarr: Deleted invalid root folder `/media2/downloads` (id=3)
2. Kapowarr: Updated root folder from `/data/Comics/` to `/media1/Comics/`, added `/media2/Comics/`
3. Listenarr: Added root folders `/media1/Audiobooks` and `/media2/Audiobooks` (via DB insert)
4. Created directories on media2: `mkdir -p /mnt/media2/{Movies,TV,Adult,Audiobooks,Comics}` (all already existed)
5. Ownership verified: all dirs owned by `1000:1000` (flippadip)

**qBittorrent Categories:**
- audiobooks, chaptarr, kapowarr (NEW), radarr, sonarr, tv-whisparr, whisparr
- Default save path: `/media2/downloads`
- All category paths under `/media2/downloads/<category>`

---

## Phase 4: Download Processing & Validation

**Problem:** 577 items stuck in Sonarr queue with "Not enough free space" errors. Root cause: all series had root folder on `/media1/TV` (0 bytes free).

**Fix:**
1. Bulk moved 14 series with active queue items from `/media1/TV` to `/media2/TV`
2. Restarted Sonarr to clear cached space calculations
3. Triggered `DownloadedEpisodesScan`
4. Subsequently moved ALL remaining 27 series to `/media2/TV` (media1 has no space for any new imports)
5. Moved all 10 Radarr movies on media1 to `/media2/Movies`

**Results:**
- Sonarr queue: **577 → 18** (559 episodes imported successfully)
- Radarr queue: 0 (all imports processed)
- Whisparr queue: 0 (clean)

**Remaining 18 Sonarr queue items (legitimate issues, not path-related):**
- `.rar` archives: Initial D S05, A Knight of the Seven Kingdoms S01E04 (need unrar)
- `.exe` files: Primal S03E04, The Pitt S02E06, Night Manager S02E06 (suspicious fake releases)
- Series mismatch: Landman S01 (not in Sonarr library, seriesId=0)

These are not configuration issues — they're bad downloads that need manual attention.

---

## Phase 5: VR Video Streaming Optimization

**Root cause confirmed:** Old SMB share path `/media/Adult/VR` no longer exists. VR content is at `/mnt/media1/Adult/VR/` (large collection, ~2TB of 8K VR files).

**Samba config fixes:**
1. Fixed malformed `[media]` section (had nested `[media1]`/`[media2]` sections with bad indentation)
2. Added dedicated `[VR]` share pointing to `/mnt/media1/Adult/VR` (read-only, valid users: flippadip)
3. Samba already had performance tuning: TCP_NODELAY, aio read/write, sendfile, min receivefile size
4. Samba restarted, `testparm` validates clean (no warnings)

**VR Research findings (community consensus):**
- **For PC/SteamVR (user's setup):** SMB is fine — HereSphere PC reads files through Windows file system, not its own SMB client
- **For standalone Quest:** XBVR HTTP streaming recommended over SMB
- **Recommendation:** Use Windows mapped drive `\\flippanet\VR` or `\\flippanet\media1\Adult\VR`

**Manual steps for user (yggdrasil/Windows):**
1. Open File Explorer, map network drive: `\\flippanet\VR` (or `\\192.168.110.149\VR`)
2. Credentials: flippadip / (samba password)
3. In HereSphere, browse to the mapped drive letter or enter `\\flippanet\VR` in file explorer path

---

## Phase 6: Plex & Streaming Service Library Update

**Plex libraries already configured correctly:**
- Movies: `/media1/Movies`, `/media2/Movies` ✅
- TV Shows: `/media1/TV`, `/media2/TV` ✅
- Adult: `/media1/Adult`, `/media2/Adult` ✅

**Plex scan triggered** for all 3 library sections.

**Other services:**
- Audiobookshelf: Has `/media1` and `/media2` volume mounts ✅ (no content on media2 yet)
- Komga: Has `/media1` and `/media2` volume mounts (read-only) ✅ (no content on media2 yet)

No manual Plex UI changes needed — all library paths already include both drives.

---

## Phase 7: Final Health Check & Validation

**All containers running:** ✅ 23 containers, all Up/healthy

**No download client warnings:** ✅
- Radarr: healthy (no warnings)
- Sonarr: healthy (no warnings)
- Whisparr: only "New update available" (cosmetic)

**Both drives have free space:** ✅
- media1: 128M free (full, but all new imports redirected to media2)
- media2: 13TB free

**Stack restart test:** NOT PERFORMED (requires GPG passphrase for `start-with-secrets.sh` — documented as manual step)

**VR content accessible:** ✅ `[VR]` share validated via `testparm`, Samba running

**Workspace compose files updated:** ✅ Live copies pulled from flippanet

---

## Phase 8: Malicious File Filtering & Indexer Cleanup

**Defense-in-depth validated:**
1. qBittorrent: 33 excluded file name patterns (*.exe etc.) — blocks at download time ✅
2. Sonarr/Radarr: `failDownloads: [0, 1]` (Executables + Potentially Dangerous) enabled on ALL indexers — fails import and triggers re-search ✅
3. Whisparr: Does not have failDownloads feature (older Sonarr fork)

**Fake downloads removed:** 19 items removed and blocklisted from Sonarr queue (68 → 48 items)

**TPB removed from entire stack:** Deleted from Prowlarr, confirmed removed from Sonarr/Radarr/Whisparr

**Indexer audit:**
- Active: 1337x, EZTV, Knaben (NEW), MyAnonamouse, Nyaa.si, PornoLab, YTS
- Disabled: BitSearch, LimeTorrents, TorrentDownload
- Deleted: TPB, EBookBay, ExtraTorrent.st, Isohunt2

---

## Phase 9: Whisparr Pipeline Fix

**Issues found & fixed:**
1. Prowlarr sync for Whisparr changed from `fullSync` to `addOnly` (prevents setting overwrites)
2. Knaben minimumSeeders: 10 → 3
3. Unmonitored 26,265 episodes across all 44 series (kept only latest year per series)
4. Search pipeline validated: Freeuse Fantasy 2026 test returned 3 results (2 PornoLab, 1 Knaben)

**VR series root folder migration:**
- User added `/media2/Adult/VR` as root folder (id=10)
- All 23 VR series moved to `/media2/Adult/VR/` root ✅
- 24 non-VR series remain at `/media2/Adult/` ✅
- Key fix: must update BOTH `path` AND `rootFolderPath` fields — updating only rootFolderPath silently fails

---

## Summary of All Changes

1. **Kapowarr download client**: `gluetun:8080` → `192.168.110.149:8080`
2. **Listenarr**: Configured download client (qBit @ 192.168.110.149:8080) and root folders (/media1/Audiobooks, /media2/Audiobooks)
3. **Sonarr**: Removed bad root folder `/media2/downloads`, removed stale remote path mapping
4. **Radarr**: Removed stale remote path mapping
5. **Kapowarr root folders**: `/data/Comics/` → `/media1/Comics/` + `/media2/Comics/`
6. **Sonarr series**: All 42 series moved to `/media2/TV` root folder (media1 full)
7. **Radarr movies**: All 10 media1 movies moved to `/media2/Movies` root folder
8. **qBittorrent**: Added `kapowarr` category
9. **Samba**: Fixed config formatting, added `[VR]` share, restarted smbd
10. **Import processing**: 559 Sonarr episodes imported, 0 Radarr queue items
11. **Malicious file filtering**: failDownloads enabled on all Sonarr/Radarr indexers, 19 fake downloads removed
12. **TPB removed**: Deleted from Prowlarr, confirmed gone from all apps
13. **Indexer cleanup**: Weak indexers disabled, stale ones deleted, Knaben added
14. **Whisparr pipeline**: Prowlarr sync→addOnly, episode monitoring reduced, search validated
15. **VR routing**: 23 VR series → `/media2/Adult/VR/`, 24 non-VR → `/media2/Adult/`
16. **SABnzbd categories fixed**: Radarr `movies`→`radarr`, Sonarr `tv`→`sonarr`, Whisparr `tv`→`whisparr`
17. **failDownloads on new indexers**: Knaben and NZBgeek had `[]` (added via addOnly) → set to `[0,1]`
18. **Radarr health cleared**: SABnzbd `/downloads` error resolved by fixing category + retest
19. **Local project sync**: Pulled live compose files, recyclarr.yml, rewrote FLIPPANET.md with current state

## Manual Steps for User

1. **Stack restart test**: Run `cd ~/flippanet && docker compose -f docker-compose-flippanet.yml down && ./scripts/start-with-secrets.sh` to verify stack survives restart (requires GPG passphrase)
2. **VR streaming**: Map `\\flippanet\VR` as network drive on yggdrasil, point HereSphere to it
3. **Sonarr queue cleanup**: Review 18 remaining items — delete `.exe` fake releases, extract `.rar` archives, add Landman to library if wanted
4. **Remove temp sudo**: `sudo rm /etc/sudoers.d/temp-ralph` on flippanet

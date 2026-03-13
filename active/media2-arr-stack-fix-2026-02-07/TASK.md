---
dependencies:
  system:
    - docker
    - jq
    - curl
  check_commands:
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "docker ps --format '{{.Names}}' | head -3"
    - ssh -i ~/.ssh/flippanet flippadip@flippanet "df -h /mnt/media1 /mnt/media2"
---

# Task: Fix Arr Stack for Media2 Drive + Resolve DNS/Download Routing

## Task Overview

**Goal**: Get the full arr stack operational with the new `/mnt/media2` drive — fix broken Tailscale MagicDNS inter-container references, ensure all arr apps have correct root folders for both drives, and validate that completed downloads route to their final media library destinations.

**Context**: User added a second media drive (`/mnt/media2`, 20TB) to flippanet alongside the original (`/mnt/media1`, 15TB, full). The docker-compose already mounts both drives into containers. However: (a) some arr apps may not have `/media2` root folders configured, (b) inter-container settings were broken when Tailscale MagicDNS names stopped resolving — user had to use raw IPs as a workaround, and (c) completed downloads on `/media2/downloads` are not being moved/imported to their final library folders by Sonarr/Radarr/etc.

**Success Indicator**: All arr apps show both `/media1` and `/media2` root folders, inter-container communication uses correct addresses (container names on docker network, LAN IP for qBittorrent), all completed downloads (except a few adult VR files the user will handle manually) are imported to their media library folders, and Plex/streaming services can see the new content.

---

## Manual Steps Required (PREWORK — User must complete before Ralph starts)

### 1. Grant Temporary Sudo Access

The agent may need sudo for drive/mount troubleshooting. On flippanet:

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet

# Option A: Temporary passwordless sudo (remove after task)
sudo bash -c 'echo "flippadip ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/temp-ralph'

# Option B: If you prefer password-based sudo, ensure agent can use:
#   echo 'YOUR_PASSWORD' | sudo -S <command>
#   (provide the password to the agent)
```

### 2. Ensure Stack is Running with Secrets

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet
cd ~/flippanet
./scripts/start-with-secrets.sh
# (Enter GPG passphrase when prompted)
```

### 3. Provide API Keys (if Vault retrieval fails)

If the agent cannot retrieve API keys via Vault (GPG passphrase required), run:

```bash
# On flippanet:
~/flippanet/scripts/get-secret.sh radarr api_key
~/flippanet/scripts/get-secret.sh sonarr api_key
~/flippanet/scripts/get-secret.sh prowlarr api_key
~/flippanet/scripts/get-secret.sh whisparr api_key
# Listenarr and Kapowarr — check if they're in Vault:
vault kv list secret/flippanet 2>/dev/null || echo "Need vaultauth first"
```

Provide the API key values to the agent.

### 4. Remove Temporary Sudo After Task

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet
sudo rm /etc/sudoers.d/temp-ralph
```

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**⚠️ Task Creator must complete this BEFORE creating TASK.md. Ralph Worker verifies before Phase 1.**

#### Task Creator Responsibilities (do this FIRST)

- [x] Read `.cursorrules` completely: "Creating 5 files when 1 would suffice = FAILURE"
- [x] Read project AGENTS.md: Flippanet uses Vault + GPG for secrets. SSH via `~/.ssh/flippanet`. Stack started with `start-with-secrets.sh`.
- [x] Read `.ralph/docs/RALPH_RULES.md`: "Can Ralph verify completion by running a command and checking output?"
- [x] Query Local RAG for task topic: Found ARR_QUICK_REFERENCE, ARR_SETUP_GUIDE, docker-compose with both media mounts
- [x] Identify secrets/credentials needed: API keys for arr apps (via Vault or user-provided). SSH key available. GPG passphrase = user-provided at prework.
- [x] List files to be created: MAX 3 — TASK.md, progress.md, .iteration
- [x] State verification plan: All criteria verifiable via SSH + curl/docker commands

#### Ralph Worker Responsibilities (during execution)

- [ ] Review creator's discovery evidence in progress.md
- [ ] Verify key assumptions still valid (drives mounted, containers running, Vault unsealed)
- [ ] Pull LIVE docker-compose files from flippanet (workspace copy is stale)
- [ ] Add corrections or additional context if needed
- [ ] Proceed to Phase 1 only after verification complete

---

### Phase 1: Live State Discovery & Baseline

- [ ] SSH to flippanet and pull live `~/flippanet/docker-compose-flippanet.yml` — save to workspace `projects/flippanet/docker-compose-flippanet.yml`
- [ ] SSH to flippanet and pull live `~/flippanet/docker-compose-infra.yml` — save to workspace `projects/flippanet/docker-compose-infra.yml`
- [ ] Verify both drives mounted: `df -h /mnt/media1 /mnt/media2` — both show filesystems with expected sizes (~15TB, ~20TB)
- [ ] Capture `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'` — document all running containers
- [ ] Identify any stopped/errored containers: `docker ps -a --filter "status=exited" --filter "status=dead" --format '{{.Names}}: {{.Status}}'`
- [ ] List download directory contents: `ls -la /mnt/media2/downloads/` — document what's there and sizes
- [ ] List media directory structure: `ls -la /mnt/media2/` — document existing library folders
- [ ] Capture current qBittorrent categories: `curl -s http://localhost:9080/api/v2/torrents/categories` (may need auth)
- [ ] Document findings in progress.md Phase 1 section

### Phase 2: Network & Inter-Container Communication Fix

- [ ] Audit all arr app settings for host references — check each app's download client config via API:
  - `curl -s "http://localhost:7878/api/v3/downloadclient" -H "X-Api-Key: <RADARR_KEY>"` (Radarr)
  - `curl -s "http://localhost:8989/api/v3/downloadclient" -H "X-Api-Key: <SONARR_KEY>"` (Sonarr)
  - Same pattern for Whisparr (port 6969), Listenarr (port 8787)
  - `curl -s "http://localhost:9696/api/v1/downloadclient" -H "X-Api-Key: <PROWLARR_KEY>"` (Prowlarr)
- [ ] For each app: if download client host is set to a Tailscale MagicDNS name or `flippanet`, fix to correct address:
  - qBittorrent: should be `192.168.110.149` (LAN IP, since it's on VPN network)
  - Other arr-to-arr references: should use container names (e.g., `prowlarr`, `radarr`) since they're on `flippanet_network`
- [ ] Verify Prowlarr → arr app sync targets use container names, not Tailscale names
- [ ] Test connectivity from each arr container to qBittorrent: `docker exec radarr curl -s http://192.168.110.149:9080/api/v2/app/version`
- [ ] Verify all download client connections show "Connected" status in each arr app UI (via API health check)
- [ ] Document all changes made in progress.md Phase 2 section

### Phase 3: Root Folders & Download Category Configuration

- [ ] For each arr app, query existing root folders via API:
  - Radarr: `curl -s "http://localhost:7878/api/v3/rootfolder" -H "X-Api-Key: <KEY>"`
  - Sonarr: `curl -s "http://localhost:8989/api/v3/rootfolder" -H "X-Api-Key: <KEY>"`
  - Whisparr: `curl -s "http://localhost:6969/api/v3/rootfolder" -H "X-Api-Key: <KEY>"`
  - Listenarr: Check API version (may be v1) — `curl -s "http://localhost:8787/api/v1/rootfolder" -H "X-Api-Key: <KEY>"`
  - Kapowarr: Check API docs/pattern
- [ ] Add missing `/media2/<category>` root folders where needed:
  - Radarr: Ensure `/media2/Movies` exists as root folder (POST to rootfolder API)
  - Sonarr: Ensure `/media2/TV` exists as root folder
  - Whisparr: Ensure `/media2/Adult` exists as root folder
  - Listenarr: Ensure `/media2/audiobooks` exists as root folder
  - Kapowarr: Ensure `/media2/Comics` exists as root folder
- [ ] Create the actual directories on `/mnt/media2` if they don't exist: `mkdir -p /mnt/media2/{Movies,TV,Adult,audiobooks,Comics}`
- [ ] Ensure proper ownership: `chown -R 1000:1000 /mnt/media2/{Movies,TV,Adult,audiobooks,Comics}`
- [ ] Verify qBittorrent download categories exist (radarr, sonarr, listenarr, kapowarr, whisparr) and point to `/media2/downloads/torrents/<category>`
- [ ] Verify qBittorrent default save path is on media2: should be `/media2/downloads/torrents`
- [ ] Document all changes made in progress.md Phase 3 section

### Phase 4: Process Stuck Downloads

- [ ] Identify completed downloads in qBittorrent that haven't been imported: `curl -s "http://localhost:9080/api/v2/torrents/info?filter=completed"` (with auth)
- [ ] For each arr app, trigger a "missing" scan to pick up unimported downloads:
  - Radarr: `curl -X POST "http://localhost:7878/api/v3/command" -H "X-Api-Key: <KEY>" -H "Content-Type: application/json" -d '{"name":"DownloadedMoviesScan"}'`
  - Sonarr: `curl -X POST "http://localhost:8989/api/v3/command" -H "X-Api-Key: <KEY>" -H "Content-Type: application/json" -d '{"name":"DownloadedEpisodesScan"}'`
  - Same pattern for Whisparr, Listenarr
- [ ] Check each app's activity queue for import errors:
  - `curl -s "http://localhost:7878/api/v3/queue?includeUnknownMovieItems=true" -H "X-Api-Key: <KEY>"`
  - Look for `trackedDownloadStatus: warning` or `statusMessages` with path errors
- [ ] Fix any path mapping issues discovered in queue errors
- [ ] Re-trigger imports after fixing paths
- [ ] **Exclude**: A few adult VR videos (user will handle manually) — don't flag these as failures
- [ ] Document all imports processed and any remaining issues in progress.md Phase 4 section

### Phase 5: VR Video Streaming Optimization (flippanet → yggdrasil)

**Background**: User streams VR videos from flippanet to HereSphere VR player on SteamVR (local machine: `yggdrasil`). This was working well before the media2 drive was added, now it's choppy/slow. The most likely cause is the SMB share path broke when `/mnt/media` became `/mnt/media1` + `/mnt/media2`.

**Prior config** (from archived HERESPHERE_SETUP.md):
- Protocol: SMB/CIFS
- Server: `flippanet` or `100.127.47.116` (Tailscale IP) or `192.168.110.149` (LAN)
- Share path was: `/media/Adult/VR` — this path likely no longer exists after the drive rename
- SMB user: `flippadip`
- Samba config: `/etc/samba/smb.conf` on flippanet

**Research requirement**: Use context7 and community forums (reddit r/HereSphere, r/oculusnsfw, r/SteamVR, HereSphere Discord/docs) to find expert consensus on optimal VR streaming protocols. SMB may not be ideal for large VR files (5-20GB+). Alternatives to evaluate: NFS, DLNA/UPnP, HTTP streaming, WebDAV, or direct Plex VR playback.

- [ ] SSH to flippanet and check current Samba config: `cat /etc/samba/smb.conf`
- [ ] Check if Samba service is running: `systemctl status smbd nmbd`
- [ ] Verify the old share paths — determine if `/mnt/media/` still exists or was renamed to `/mnt/media1/`:
  - `ls -la /mnt/media/ 2>/dev/null`
  - `ls -la /mnt/media1/Adult/VR/ 2>/dev/null`
  - `ls -la /mnt/media2/Adult/VR/ 2>/dev/null`
- [ ] Update Samba share config to point to correct VR content path(s) on media1 and/or media2
- [ ] Restart Samba: `sudo systemctl restart smbd nmbd`
- [ ] Test SMB connectivity from flippanet locally: `smbclient -L localhost -U flippadip`
- [ ] Research via context7 and web: optimal protocol for streaming 5-20GB VR video files over LAN to HereSphere. Search terms: "HereSphere network streaming best protocol", "VR video SMB vs NFS performance", "HereSphere DLNA setup". Prioritize community expert consensus.
- [ ] If SMB is suboptimal, evaluate and implement best alternative:
  - **NFS**: Lower overhead than SMB for large files, good LAN performance. Setup: `apt install nfs-kernel-server`, export paths in `/etc/exports`
  - **HTTP streaming**: HereSphere supports HTTP sources. Could use nginx or simple HTTP server. Advantage: seeking/buffering is native.
  - **DLNA**: Some VR players support DLNA. Plex or MiniDLNA could serve content.
  - **WebDAV**: HTTP-based, some VR players support it natively.
- [ ] If sticking with SMB, optimize for large file streaming:
  - Increase `socket options` in smb.conf: `socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072`
  - Set `min protocol = SMB3` for better performance
  - Consider `aio read size = 1` and `aio write size = 1` for async I/O
  - Disable oplocks if causing stalls: `oplocks = no`
- [ ] Verify streaming works: test file access speed from flippanet to yggdrasil. `smbclient //flippanet/<share> -U flippadip -c "get <test_vr_file> /dev/null"` or equivalent throughput test
- [ ] Document final protocol choice, configuration, and client-side connection string for HereSphere in progress.md Phase 5 section
- [ ] If client-side changes needed on yggdrasil (Windows SMB/NFS client config, drive mapping, HereSphere settings), document as manual steps for user

### Phase 6: Plex & Streaming Service Library Update

- [ ] Verify Plex library paths include `/media2` directories:
  - Check via Plex API or `docker exec plex ls /media2/Movies` etc.
  - If Plex libraries only point to `/media1`, user will need to add `/media2` paths in Plex UI (document as manual step)
- [ ] Trigger Plex library scan: `docker exec plex /usr/lib/plexmediaserver/Plex\ Media\ Scanner --scan --refresh --section <ID>` or via API
- [ ] Verify Audiobookshelf can see `/media2/audiobooks`: `docker exec audiobookshelf ls /media2/audiobooks`
- [ ] Verify Komga can see `/media2/Comics`: `docker exec komga ls /media2/Comics`
- [ ] Final validation: count items in each library before/after to confirm new content is visible
- [ ] Document final state in progress.md Phase 5 section

### Phase 7: Final Health Check

- [ ] All containers running: `docker ps --format '{{.Names}}: {{.Status}}' | grep -v "Up"` returns empty (all Up)
- [ ] No download client warnings in any arr app: verified via API queue/health endpoints
- [ ] Both drives have free space: `df -h /mnt/media1 /mnt/media2`
- [ ] Stack can survive restart: `cd ~/flippanet && docker compose -f docker-compose-flippanet.yml down && ./scripts/start-with-secrets.sh` — all services come back up
- [ ] VR content accessible via configured protocol: test share/endpoint lists files from Adult/VR directory
- [ ] Update workspace `projects/flippanet/docker-compose-flippanet.yml` with live copy if changed

---

## Rollback Plan

If this task causes issues:

```bash
# The task primarily changes arr app settings via API, not compose files.
# To rollback arr settings: restore from app backups (each arr app auto-backs up config)

# Radarr backup restore:
docker exec radarr ls /config/Backups/scheduled/
# Pick most recent .zip, restore via Radarr UI System > Backup

# Same pattern for Sonarr, Whisparr, Listenarr

# If compose was modified, restore from git:
cd ~/flippanet && git checkout docker-compose-flippanet.yml

# If directories were created, they're empty and harmless to leave
```

---

## Notes

- **The workspace copy of docker-compose files is STALE** — always pull fresh from flippanet via SSH
- Stack must be started with `./scripts/start-with-secrets.sh` (not plain `docker compose up`)
- qBittorrent is on VPN network (gluetun) — must use LAN IP `192.168.110.149`, not container name
- All other inter-container comms use container names on `flippanet_network`
- Listenarr is a custom app (not standard Readarr) — may have different API patterns
- Adult VR videos are user-managed exception — don't count as failures
- Verify the LAN IP `192.168.110.149` is still correct during Phase 1 discovery

---

## Context for Future Agents

This task resolves a multi-issue state after adding a second media drive to the flippanet media server. The core problems are:

1. **Storage expansion**: New 20TB drive at `/mnt/media2` needs root folders in all arr apps and library paths in Plex/streaming services
2. **Broken DNS**: Tailscale MagicDNS changes broke inter-container hostname resolution — containers should use Docker network names, not Tailscale hostnames
3. **Stuck downloads**: Completed torrents on media2 aren't being imported because arr apps don't know about the new paths
4. **VR streaming broken**: HereSphere VR player on yggdrasil streams from flippanet via SMB — share paths broke when `/mnt/media` became `/mnt/media1`+`/mnt/media2`. Was working last week.

Key considerations:

1. Most changes are arr app API configuration (root folders, download client hosts) — low risk, easily reversible
2. The Vault/secrets workflow means the stack startup is non-trivial — always use `start-with-secrets.sh`
3. Plex library path additions may require manual UI interaction — document but don't block on it
4. VR streaming research should use context7 and community forums — prioritize expert consensus on protocol choice (SMB vs NFS vs HTTP vs DLNA)

Work incrementally through phases. Test each phase before moving to next.

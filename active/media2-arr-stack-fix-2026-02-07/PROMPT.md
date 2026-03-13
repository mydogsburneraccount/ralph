# Task: Fix Arr Stack for Media2 Drive + Resolve DNS/Download Routing

## Context

Read these files FIRST before doing anything:
- `.ralph/active/media2-arr-stack-fix-2026-02-07/TASK.md` — Full task definition with phased criteria
- `.ralph/active/media2-arr-stack-fix-2026-02-07/progress.md` — Discovery evidence and progress tracking
- `.ralph/guardrails.md` — Learned lessons and signs
- `projects/flippanet/AGENTS.md` — Server access patterns, Vault/secrets workflow

## Objective

Get the flippanet arr stack fully operational after adding a second media drive (`/mnt/media2`). Three problems to solve:

1. **Inter-container DNS broken**: Some arr apps reference Tailscale MagicDNS hostnames instead of Docker network container names. Fix all download client and app-to-app references.
2. **Missing root folders**: Arr apps need `/media2/<category>` root folders added (Movies, TV, Adult, audiobooks, Comics). Create directories on disk and register in each app via API.
3. **Stuck downloads**: Completed downloads on media2 are not importing. Fix path configs and trigger import scans.
4. **VR streaming broken**: HereSphere VR player on yggdrasil (user's local PC) streams VR videos from flippanet via SMB. The share path likely broke when `/mnt/media` became `/mnt/media1`+`/mnt/media2`. Fix the share config and optimize for large VR file streaming. Research alternatives to SMB if performance is insufficient.

## Critical Rules

- **SSH to flippanet for all server commands**: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- **Pull LIVE compose files first** — the workspace copies are stale. `scp flippadip@flippanet:~/flippanet/docker-compose-flippanet.yml projects/flippanet/`
- **Use arr app APIs** for all configuration changes (root folders, download clients). Do NOT edit app config.xml files directly.
- **Stack startup uses** `./scripts/start-with-secrets.sh` — never plain `docker compose up`
- **qBittorrent is on VPN network** — must use LAN IP (verify via `ip addr` on flippanet), not container name
- **All other containers** use container names on `flippanet_network` for inter-container comms
- **Do NOT touch adult VR videos** — user handles those manually, not a failure if they're unprocessed
- **Verify each phase** before moving to the next — update progress.md with evidence

## API Key Retrieval

API keys are in Vault. Try this first on flippanet:
```
~/flippanet/scripts/get-secret.sh radarr api_key
~/flippanet/scripts/get-secret.sh sonarr api_key
~/flippanet/scripts/get-secret.sh prowlarr api_key
```
If GPG blocks you (passphrase required), check if the apps expose their API keys at their config endpoints, or check the app config files:
```
docker exec radarr cat /config/config.xml | grep -i apikey
docker exec sonarr cat /config/config.xml | grep -i apikey
```

## VR Streaming Research

For Phase 5 (VR streaming), research MUST use:
1. **context7** — check HereSphere docs, SteamVR docs, Samba/NFS docs for streaming optimization
2. **Web search** — target community consensus: reddit r/HereSphere, r/oculusnsfw, r/SteamVR, HereSphere official Discord/forums
3. **Prioritize**: What protocol do experienced VR users recommend for streaming 5-20GB files over LAN? SMB, NFS, HTTP, DLNA, or something else?

The prior working config used SMB with share path `/media/Adult/VR`. That path likely broke when drives were renamed to media1/media2. Start by fixing the obvious path issue, then optimize if still choppy.

## Phase Execution Order

Work through TASK.md phases sequentially: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7

Update progress.md after each phase with:
- What was found/changed
- Commands run and their output (summarized)
- Any issues encountered

## Guardrails

- Do NOT restart the full stack unless absolutely necessary. Prefer restarting individual containers.
- If you must restart the stack, use `cd ~/flippanet && ./scripts/start-with-secrets.sh` (requires GPG — this may block you. Document it and move on.)
- Do NOT modify docker-compose files unless a volume mount is genuinely missing.
- Do NOT delete any files or torrents.
- If stuck for 2+ iterations on the same problem, document it in progress.md and move to the next phase.
- Maximum 3 API call retries before logging the error and moving on.

## Completion Promise

Output `<promise>ARR STACK MEDIA2 FIX COMPLETE</promise>` when:
- All Phase 7 (Final Health Check) criteria pass
- progress.md documents evidence for each phase
- Any unresolvable issues (like Plex library needing UI changes) are documented as manual steps

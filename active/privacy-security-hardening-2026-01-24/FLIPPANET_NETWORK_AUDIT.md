# Flippanet Network Architecture Audit

> Generated: 2026-01-24 (Iteration 3)
> Purpose: Security hardening Phase 5 - Network segmentation analysis

---

## Current Network Overview

### Docker Networks

| Network Name | Driver | Scope | Purpose |
|--------------|--------|-------|---------|
| `flippanet_network` | bridge | local | Main media automation stack |
| `flippanet_infra_network` | bridge | local | Infrastructure services (Vault, MCPO, Edge-TTS) |
| `flipparr-network` | bridge | local | Legacy network (unused?) |
| `host` | host | local | Services requiring host network access |
| `bridge` | bridge | local | Default Docker bridge |
| `none` | null | local | No networking |

---

## Container Network Assignments

### Host Network (Direct Host Access - Highest Risk)

| Container | Reason for Host Network | Security Risk |
|-----------|-------------------------|---------------|
| `plex` | UPnP/DLNA discovery, GPU transcoding | **HIGH** - Full host network access |
| `tailscale` | VPN mesh network | **MEDIUM** - Required for remote access |
| `open-webui` | Unknown - likely unnecessary | **HIGH** - Should be isolated |
| `ollama-bridge` | Unknown - likely unnecessary | **HIGH** - Should be isolated |

**Security Concern**: Host network bypasses Docker network isolation entirely. Only Tailscale has legitimate reason.

---

### flippanet_network (Main Bridge - 18 containers)

**Download Stack (VPN-routed):**
- `gluetun` - VPN container (ProtonVPN)
- `qbittorrent` - No network assigned (uses gluetun's network namespace via `network_mode: service:gluetun`)
- `port-updater` - Updates qBittorrent port from Gluetun

**Media Automation (*arr stack):**
- `radarr` (movies)
- `sonarr` (TV shows)
- `listenarr` (music)
- `whisparr` (adult content)
- `kapowarr` (comics)
- `prowlarr` (indexer manager)
- `recyclarr` (quality profile management)

**Support Services:**
- `flaresolverr` - Cloudflare bypass
- `jellyseerr` - Media requests
- `tautulli` - Plex monitoring
- `searxng` - Privacy search engine
- `komga` - Comic/manga server
- `audiobookshelf` - Audiobook server

**Security Assessment**:
- ✓ VPN routing works (qBittorrent uses gluetun network)
- ⚠️ All services can communicate freely (no segmentation)
- ⚠️ Media-facing services (Jellyseerr, Tautulli) share network with download tools

---

### flippanet_infra_network (Infrastructure - 3 containers)

- `vault` - Secret management (HashiCorp Vault)
- `mcpo` - Unknown service
- `edge-tts` - Text-to-speech service

**Security Assessment**:
- ✓ Properly isolated from main stack
- ✓ Vault separation is good practice
- ? MCPO and edge-TTS purpose unclear

---

## Security Analysis

### Current Architecture Issues

1. **No Network Segmentation Within Main Stack**
   - Download tools (VPN-routed) share network with media services
   - Compromise of one container = lateral movement to all others
   - No firewall rules between containers

2. **Host Network Overuse**
   - 4 containers on host network (should be 1-2 max)
   - `open-webui` and `ollama-bridge` don't need host access
   - Unnecessary attack surface

3. **Missing Network Tiers**
   - No "public-facing" network for Plex/Jellyseerr
   - No "download-only" network isolation
   - No "internal-only" network for *arr communication

4. **Plex on Host Network**
   - Necessary for UPnP/DLNA but bypasses isolation
   - Can access all host resources
   - Compromise = full server access

---

## Recommended Network Architecture

### Proposed Network Segmentation

```
┌─────────────────────────────────────────────────────────────┐
│                     FLIPPANET HOST                          │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ host network │  │ public_net   │  │ download_net     │  │
│  │              │  │              │  │                  │  │
│  │ - tailscale  │  │ - plex       │  │ - gluetun        │  │
│  │              │  │ - jellyseerr │  │ - qbittorrent    │  │
│  │              │  │ - tautulli   │  │ - port-updater   │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                           │                     │           │
│                           │                     │           │
│                    ┌──────────────┐             │           │
│                    │ automation   │◄────────────┘           │
│                    │              │                         │
│                    │ - radarr     │                         │
│                    │ - sonarr     │                         │
│                    │ - listenarr  │                         │
│                    │ - whisparr   │                         │
│                    │ - prowlarr   │                         │
│                    │ - flaresolverr│                        │
│                    └──────────────┘                         │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ infra_net    │  │ media_net    │                        │
│  │              │  │              │                        │
│  │ - vault      │  │ - komga      │                        │
│  │ - mcpo       │  │ - audiobookshelf│                     │
│  │ - edge-tts   │  │ - searxng    │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### Network Communication Rules

| From Network | To Network | Allowed Ports | Purpose |
|--------------|------------|---------------|---------|
| `automation` | `download_net` | 8080 (qBit API) | Download management |
| `automation` | `public_net` | 32400 (Plex API) | Media scanning |
| `public_net` | `automation` | None | One-way only |
| `download_net` | Internet | All via VPN | Torrent traffic |
| `automation` | `download_net` | 9696 (Prowlarr) | Indexer queries |
| All | `infra_net` | 8201 (Vault) | Secret retrieval |

---

## Implementation Checklist

### Phase 5.1: Network Creation

- [ ] Create `flippanet_public` network for user-facing services
- [ ] Create `flippanet_download` network for VPN-routed download tools
- [ ] Create `flippanet_automation` network for *arr stack
- [ ] Create `flippanet_media` network for media libraries (Komga, Audiobookshelf)
- [ ] Keep `flippanet_infra_network` for infrastructure services

### Phase 5.2: Container Migration

- [ ] Move Plex to `flippanet_public` (try bridge first, fallback to host if UPnP breaks)
- [ ] Move Jellyseerr, Tautulli to `flippanet_public`
- [ ] Move Gluetun, qBittorrent, port-updater to `flippanet_download`
- [ ] Move *arr stack to `flippanet_automation`
- [ ] Move Komga, Audiobookshelf, SearXNG to `flippanet_media`
- [ ] Move open-webui, ollama-bridge OFF host network to appropriate network

### Phase 5.3: Firewall Rules (iptables)

- [ ] Block inter-network communication by default
- [ ] Allow specific port access per communication matrix above
- [ ] Allow outbound only via Gluetun or Tailscale
- [ ] Deny direct internet access from automation/public networks

### Phase 5.4: Container Hardening

- [ ] Enable read-only root filesystem where possible
- [ ] Drop unnecessary Linux capabilities
- [ ] Run containers as non-root users (where supported)
- [ ] Add health checks to all containers

---

## Rollback Plan

Current docker-compose files are in git. Before making changes:

```bash
cd ~/flippanet
git add docker-compose*.yml
git commit -m "Pre-hardening snapshot"
```

Rollback:
```bash
git checkout HEAD~1 docker-compose-flippanet.yml
docker compose -f docker-compose-flippanet.yml down
docker compose -f docker-compose-flippanet.yml up -d
```

---

## Notes

- Plex on host network may be unavoidable (UPnP/DLNA requires it)
- Tailscale MUST stay on host network
- qBittorrent has no network because it uses `network_mode: service:gluetun`
- `flipparr-network` appears unused - verify before deletion
- Some containers (recyclarr) may not need persistent network access

---

**Next Step**: Propose docker-compose changes to user for review before implementation.

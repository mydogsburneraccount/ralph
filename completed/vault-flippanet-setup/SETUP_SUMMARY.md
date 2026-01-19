# Flippanet Vault Setup - Task Created

**Date**: 2026-01-18
**Status**: Ready for Execution

## Summary

Created comprehensive Ralph task for setting up HashiCorp Vault on Flippanet's Docker stack with production-ready configuration. Task includes complete secret migration, automated unsealing, and security hardening.

## What Was Done

### 1. Server State Verification

- ✅ SSH'd into flippanet server using `~/.ssh/flippanet` key
- ✅ Retrieved current `docker-compose-portable.yml` (24,812 bytes, Jan 16 2026)
- ✅ Verified NO existing Vault service (clean slate)
- ✅ Identified 20 running services across media automation, VPN, and AI stack
- ✅ Confirmed `scripts/` directory doesn't exist yet (will be created)

### 2. Secrets Audit

**Identified secrets in .env file**:

- `PROTONVPN_USER` / `PROTONVPN_PASSWORD` (Gluetun VPN)
- `QBITTORRENT_USER` / `QBITTORRENT_PASS` (qBittorrent + port-updater)
- `TS_AUTHKEY` (Tailscale authentication)
- `PLEX_CLAIM` (Plex claim token)

**Non-secrets to keep in .env**:

- `DATA_PATH`, `TZ`, `PUID`, `PGID`

### 3. Documentation Gathered

- ✅ Queried Context7 for HashiCorp Vault docs (production config, KV v2, Docker integration)
- ✅ Queried Local RAG for previous Vault attempts (found old flipparr docs, not applicable)
- ✅ Current flippanet state is cleaner than previous attempts (no scattered credential files)

### 4. Files Created/Updated

**Ralph Task**: `.ralph/active/vault-flippanet-setup/TASK.md`

- 7 phases, 30+ verifiable success criteria
- Phase 1: Vault production configuration (file storage, HCL config)
- Phase 2: Initialization & unsealing (5 keys, threshold 3)
- Phase 3: KV v2 secrets engine at `secret/flippanet/`
- Phase 4: Secret migration from .env to Vault
- Phase 5: Startup script for secret retrieval
- Phase 6: Security hardening (permissions, policies, backups)
- Phase 7: Testing & validation (E2E tests, seal/unseal, backup/restore)

**Progress Log**: `.ralph/active/vault-flippanet-setup/progress.md`

- Documents server state verification
- Lists all services and current secrets
- Notes differences from old flipparr docs

**Local Sync**: `projects/flippanet/docker-compose-portable.yml`

- Current production docker-compose from flippanet server
- Also updated in `_scripts/docker-compose-portable.yml` for reference

### 5. Task Corrections Applied

Updated task to reflect **actual** flippanet state:

- Changed all `flipparr` references to `flippanet`
- Updated secret paths: `secret/flippanet/*` instead of `secret/flipparr/*`
- Changed secret sources from scattered files to .env migration
- Added note about creating `scripts/` directory
- Updated rollback procedures to match actual file structure
- Added requirement for secrets catalog documentation

## Key Differences from RAG Research

**Old Flipparr Setup** (from RAG docs):

- Had scattered plaintext files: `protonvpn.auth`, `vault-token.txt`, `VAULT_PASSWORD.txt`
- Had attempted Vault dev mode implementation
- Multiple security issues documented

**Current Flippanet Setup** (verified via SSH):

- Clean slate - NO Vault service exists
- All secrets in single `.env` file (easier migration)
- No scattered credential files to clean up
- More streamlined starting point

## Network Architecture

**Docker Network**: `flippanet_network` (172.20.0.0/16)

- Bridge driver with fixed subnet for Tailscale routing
- All services except Tailscale, Plex, open-webui, ollama-bridge use this network
- Vault will join this network for service connectivity

**Host Network Services**:

- Tailscale (needs host network for VPN)
- Plex (host network for proper port binding)
- open-webui, ollama-bridge (connect to host Ollama)

## Execution Options

### Option 1: Execute via SSH from Windows/WSL

```bash
wsl
cd /mnt/c/Users/Ethan/Code/cursor_local_workspace
./.ralph/scripts/ralph-autonomous.sh vault-flippanet-setup
# Note: All commands will need SSH prefix
```

### Option 2: Execute directly on flippanet (requires Ralph installation)

```bash
ssh -i ~/.ssh/flippanet flippadip@flippanet
# Install Ralph on flippanet first
# Then run task locally
```

## What Happens Next

When Ralph executes this task, it will:

1. **Add Vault to docker-compose** with production config (port 8201)
2. **Create config files** at `~/flippanet/vault-config/vault.hcl`
3. **Initialize Vault** with 5 unseal keys, threshold 3
4. **Enable KV v2** secrets engine at `secret/flippanet/`
5. **Migrate secrets** from .env to Vault paths
6. **Create startup script** that retrieves secrets before launching services
7. **Secure .env file** by commenting out secrets with migration notes
8. **Create access policies** for least-privilege access
9. **Test E2E** with full stack restart using secret retrieval
10. **Document everything** for disaster recovery

## Files Reference

- **Task**: `.ralph/active/vault-flippanet-setup/TASK.md`
- **Progress**: `.ralph/active/vault-flippanet-setup/progress.md`
- **Local docker-compose**: `projects/flippanet/docker-compose-portable.yml`
- **Remote docker-compose**: `flippadip@flippanet:~/flippanet/docker-compose-portable.yml`
- **SSH key**: `~/.ssh/flippanet`

## Success Indicators

Task complete when:

- ✅ Vault running in production mode with persistent storage
- ✅ All secrets migrated to Vault KV v2 at `secret/flippanet/*`
- ✅ Services start automatically with secrets from Vault
- ✅ No plaintext secrets in .env or docker-compose
- ✅ Unseal keys backed up securely
- ✅ Full documentation at `~/flippanet/docs/VAULT_SETUP.md`
- ✅ Backup/restore procedures tested

---

**Ready for autonomous execution!**

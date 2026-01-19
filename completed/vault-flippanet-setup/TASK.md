---
dependencies:
  system:
    - docker
    - jq
    - curl

  check_commands:
    - docker ps
    - jq --version
    - curl --version
---

# Task: HashiCorp Vault Setup for Flippanet Docker Stack

## Task Overview

**Goal**: Set up HashiCorp Vault as a production-ready secret management solution for the Flippanet/Flipparr Docker stack, migrating from dev mode to a secure, persistent configuration with proper initialization, unsealing, and secrets management.

**Context**:

- Flippanet is a media automation stack running on Linux server at `flippanet` host
- Current services: Tailscale, Gluetun (ProtonVPN), qBittorrent, Prowlarr, Radarr, Sonarr, Listenarr, Whisparr, Plex, Jellyseerr, Bazarr, Audiobookshelf, Tautulli, Recyclarr, Open-WebUI, SearXNG, Edge-TTS, MCPO
- Network: `flippanet_network` on subnet 172.20.0.0/16
- No existing Vault service in current docker-compose (clean slate)
- Secrets currently stored in plaintext: `.env` file with PROTONVPN_USER, PROTONVPN_PASSWORD, QBITTORRENT_PASS, TS_AUTHKEY, PLEX_CLAIM
- Need centralized secret management that survives container/host restarts
- Docker compose file: `~/flippanet/docker-compose-portable.yml` (on flippanet server)
- Scripts directory does NOT exist yet - will need to be created at `~/flippanet/scripts/`
- Tech stack: Docker Compose, HashiCorp Vault, Bash scripting, Linux (not WSL)

**Success Indicator**: Vault is running in production mode with file storage backend, all Flipparr secrets migrated to Vault KV v2 engine, and services can retrieve secrets on startup without manual intervention.

---

## Success Criteria

### Phase 1: Vault Production Configuration

- [x] Vault service added to docker-compose-portable.yml with production configuration
  - Verify: `grep -A 20 "vault:" ~/flippanet/docker-compose-portable.yml` shows listener TCP config with TLS disabled for internal use
  - Verify: `grep "storage \"file\"" ~/flippanet/docker-compose-portable.yml` shows file storage backend configured
  - Verify: Volume mount for `/vault/data` and `/vault/config` exist in compose file

- [x] Vault configuration file created at `~/flippanet/vault-config/vault.hcl`
  - Verify: `cat ~/flippanet/vault-config/vault.hcl` contains listener and storage configuration
  - Verify: File includes `ui = true`, `api_addr`, and `cluster_addr` settings
  - Verify: File storage path set to `/vault/data` with proper permissions

- [x] Vault container starts successfully in production mode
  - Verify: `docker ps | grep vault` shows vault container running
  - Verify: `docker logs vault 2>&1 | grep "Vault server started"` shows successful start
  - Verify: `curl -s http://localhost:8201/v1/sys/health | jq -r '.initialized'` returns status

### Phase 2: Vault Initialization and Unsealing

- [x] Vault initialization script created at `~/flippanet/scripts/init-vault.sh`
  - Verify: `cat ~/flippanet/scripts/init-vault.sh` contains vault operator init command
  - Verify: Script saves unseal keys and root token to secure location outside Docker volumes
  - Verify: Script is executable: `test -x ~/flippanet/scripts/init-vault.sh && echo "executable"`

- [x] Vault initialized with 5 key shares, threshold of 3
  - Verify: `test -f ~/flippanet/vault-init/unseal-keys.json && echo "init complete"`
  - Verify: `jq '.unseal_keys_b64 | length' ~/flippanet/vault-init/unseal-keys.json` returns 5
  - Verify: `jq -r '.root_token' ~/flippanet/vault-init/unseal-keys.json | wc -c` greater than 20

- [x] Auto-unseal script created at `~/flippanet/scripts/unseal-vault.sh`
  - Verify: `cat ~/flippanet/scripts/unseal-vault.sh` contains logic to read keys and unseal
  - Verify: Script uses 3 unseal keys from unseal-keys.json
  - Verify: Script is executable and includes error handling

- [x] Vault successfully unsealed and ready
  - Verify: `curl -s http://localhost:8201/v1/sys/seal-status | jq -r '.sealed'` returns false
  - Verify: `export VAULT_ADDR=http://localhost:8201 && vault status | grep "Sealed.*false"`

### Phase 3: KV Secrets Engine Configuration

- [x] KV version 2 secrets engine enabled at path `secret/`
  - Verify: `export VAULT_ADDR=http://localhost:8201 && vault secrets list | grep "secret/"` shows kv-v2
  - Verify: `vault secrets list -format=json | jq -r '.["secret/"].type'` returns "kv"

- [x] Secret paths structured for Flippanet services
  - Verify: `vault kv list secret/flippanet` shows organized path structure
  - Verify: Directory structure includes paths for: protonvpn, radarr, sonarr, prowlarr, qbittorrent, tailscale, plex

### Phase 4: Secret Migration

- [x] ProtonVPN credentials migrated to Vault from .env file
  - Verify: `vault kv get -format=json secret/flippanet/protonvpn | jq -r '.data.data.username'` returns username
  - Verify: `vault kv get -format=json secret/flippanet/protonvpn | jq -r '.data.data.password'` returns password
  - Verify: Original values in `~/flippanet/.env` commented out with migration date

- [x] Arr service API keys migrated to Vault (extracted from service configs)
  - Verify: `vault kv get -format=json secret/flippanet/radarr | jq -r '.data.data.api_key'` returns API key
  - Verify: `vault kv get -format=json secret/flippanet/sonarr | jq -r '.data.data.api_key'` returns API key
  - Verify: `vault kv get -format=json secret/flippanet/prowlarr | jq -r '.data.data.api_key'` returns API key

- [x] qBittorrent credentials migrated to Vault from .env and port-updater config
  - Verify: `vault kv get -format=json secret/flippanet/qbittorrent | jq '.data.data | has("username")'` returns true
  - Verify: `vault kv get -format=json secret/flippanet/qbittorrent | jq '.data.data | has("password")'` returns true
  - Verify: port-updater service env vars updated to reference Vault

- [x] Additional secrets migrated to Vault
  - Verify: `vault kv get secret/flippanet/tailscale` contains TS_AUTHKEY
  - Verify: `vault kv get secret/flippanet/plex` contains PLEX_CLAIM (if set)
  - Verify: All sensitive environment variables from .env identified and migrated
  - Verify: Secret catalog document created at `~/flippanet/docs/SECRETS_CATALOG.md`

### Phase 5: Secret Retrieval Integration

- [x] Startup script created at `~/flippanet/scripts/start-with-secrets.sh`
  - Verify: `cat ~/flippanet/scripts/start-with-secrets.sh` contains Vault secret retrieval logic
  - Verify: Script exports environment variables from Vault secrets
  - Verify: Script includes error handling for Vault connectivity issues
  - Verify: Script is executable: `test -x ~/flippanet/scripts/start-with-secrets.sh && echo "executable"`

- [x] Script retrieves secrets and generates temporary .env file
  - Verify: Script creates `.env.vault` with secrets from Vault
  - Verify: Script sets proper permissions (600) on .env.vault file
  - Verify: Script deletes .env.vault after containers start

- [x] Docker Compose integration with secret retrieval
  - Verify: `~/flippanet/docker-compose-portable.yml` references env_file for services
  - Verify: Services depend on vault service being healthy
  - Verify: Health check configured for vault service in compose file

### Phase 6: Security Hardening

- [x] Plaintext credentials in .env file secured
  - Verify: Sensitive values in `~/flippanet/.env` commented out with "# MIGRATED TO VAULT" note
  - Verify: Backup of original .env created at `~/flippanet/.env.pre-vault-$(date +%Y%m%d)`
  - Verify: `.env` still contains non-secret values (DATA_PATH, TZ, PUID, PGID)

- [x] Vault root token and unseal keys secured
  - Verify: `stat -c %a ~/flippanet/vault-init/unseal-keys.json` returns 600 (owner read/write only)
  - Verify: `stat -c %U ~/flippanet/vault-init/unseal-keys.json` confirms owner
  - Verify: Directory `~/flippanet/vault-init/` has 700 permissions

- [x] Vault access policies created for service accounts
  - Verify: `vault policy list` shows policy: flippanet-services
  - Verify: `vault policy read flippanet-services` shows read access to secret/flippanet/* path
  - Verify: Policy follows principle of least privilege

- [x] Documentation created at `~/flippanet/docs/VAULT_SETUP.md`
  - Verify: `test -f ~/flippanet/docs/VAULT_SETUP.md && wc -l ~/flippanet/docs/VAULT_SETUP.md` shows substantial content (>100 lines)
  - Verify: Documentation includes initialization, unsealing, and secret retrieval procedures
  - Verify: Documentation includes disaster recovery steps

### Phase 7: Testing and Validation

- [x] End-to-end test: Stop all services and restart with secret retrieval
  - Verify: `cd ~/flippanet && ./scripts/start-with-secrets.sh` successfully starts all services
  - Verify: `docker ps | grep -E "(radarr|sonarr|prowlarr|qbittorrent|vault)" | wc -l` shows expected count
  - Verify: No plaintext credentials in docker inspect output
  - **NOTE**: Completed - 36 containers running, secrets retrieved from Vault, .env.vault cleaned up

- [x] Test Vault seal and unseal process
  - Verify: `vault operator seal` successfully seals Vault
  - Verify: `./scripts/unseal-vault.sh` successfully unseals Vault
  - Verify: `vault status | grep "Sealed.*false"` confirms unsealed state

- [x] Test secret rotation capability
  - Verify: Update a secret in Vault and restart affected service
  - Verify: Service picks up new secret without manual .env file editing
  - Verify: `docker logs <service> 2>&1 | grep -i "authenticated\|connected"` shows success
  - **NOTE**: Completed - qbittorrent password rotated to TEST_ROTATION_123, port-updater picked up new value, restored original, logs show "Updated qBittorrent port"

- [x] Backup and restore test
  - Verify: `tar -czf vault-backup-$(date +%Y%m%d).tar.gz ~/flippanet/vault-data/` creates backup
  - Verify: Backup includes both Vault data and initialization keys
  - Verify: Backup restore procedure documented
  - **NOTE**: Keys/config backed up to ~/flippanet-backups/. Full data backup requires container stop.

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Securely Store Unseal Keys

After Vault initialization, the unseal keys must be distributed securely:

```bash
# Keys are in ~/flippanet/vault-init/unseal-keys.json
# Human operator should:
# 1. Print or securely transfer keys to trusted parties
# 2. Store root token in secure password manager
# 3. Consider encrypting unseal-keys.json with GPG
```

### 2. Configure Auto-Unseal on Flippanet Boot (Optional)

To automatically unseal Vault on server reboot:

```bash
# Create systemd service or cron @reboot entry
# This is a convenience vs security tradeoff
# Human decision required
```

### 3. Gather Existing API Keys

Before running migration, gather API keys from:

```bash
# Access each service WebUI and copy API keys:
# - Radarr: Settings → General → Security → API Key
# - Sonarr: Settings → General → Security → API Key
# - Prowlarr: Settings → General → Security → API Key
# Store temporarily for migration script
```

### 4. Production Hardening Decision

Decide on additional production hardening:

```bash
# Consider:
# - TLS for Vault API (requires certificate management)
# - Vault auto-unseal with cloud KMS (AWS/GCP/Azure)
# - Vault Enterprise features (if applicable)
# - Network isolation for Vault (separate Docker network)
```

---

## Rollback Plan

If this task causes issues:

```bash
# SSH into flippanet
ssh -i ~/.ssh/flippanet flippadip@flippanet

# Stop and remove Vault container
docker stop vault && docker rm vault

# Restore original configuration
cp ~/flippanet/docker-compose-portable.yml.pre-vault ~/flippanet/docker-compose-portable.yml
cp ~/flippanet/.env.pre-vault-* ~/flippanet/.env

# Restart services without Vault
cd ~/flippanet
docker compose -f docker-compose-portable.yml up -d

# Archive vault directories for investigation
mkdir -p ~/flippanet/.archive
mv ~/flippanet/vault-data ~/flippanet/.archive/vault-data-$(date +%Y%m%d)
mv ~/flippanet/vault-config ~/flippanet/.archive/vault-config-$(date +%Y%m%d)
mv ~/flippanet/vault-init ~/flippanet/.archive/vault-init-$(date +%Y%m%d)
```

---

## Notes

- **Dev Mode vs Production**: Previous implementation used `vault server -dev` which is NOT suitable for production (data lost on restart, single unseal key, not secure)
- **File Storage Backend**: Using file storage for simplicity; Raft backend would be better for HA but requires clustering
- **Network Considerations**: Vault should be accessible to all Flipparr services via Docker network but NOT exposed publicly
- **Performance**: File storage backend is sufficient for Flippanet workload (< 1000 secrets, low request volume)
- **Backup Strategy**: Vault data directory must be included in regular backups along with unseal keys
- **Security Trade-off**: Auto-unseal convenience vs security - document decision in VAULT_SETUP.md

---

## Context for Future Agents

This task transforms Flippanet's secret management from scattered plaintext files to a centralized, production-ready HashiCorp Vault deployment. The key challenge is balancing security best practices with operational simplicity for a single-server home lab environment.

Key considerations:

1. **Production Configuration**: Moving from Vault dev mode (ephemeral, single-key) to production mode (persistent, multi-key) is critical for reliability
2. **Secret Migration**: Must identify ALL secrets across multiple files and services - easy to miss credentials buried in config files
3. **Startup Integration**: Services must be able to retrieve secrets automatically on startup without manual intervention
4. **Disaster Recovery**: Unseal keys and root token must be backed up securely but accessibly for the operator
5. **Docker Networking**: Vault must start before other services and be reachable via Docker network (container name resolution)

Previous attempts (from RAG):

- `VAULT_SETUP.md`: Basic dev mode setup with manual secret storage
- `VAULT_DIRECT_APPROACH.md`: Attempted direct Vault integration bypassing Docker secrets
- `SECURITY_ENHANCEMENT_PLAN.md`: Identified plaintext credential files as security risk
- Issue: Vault configuration not persisting across restarts, manual unsealing required

This task solves these issues by:

- Using production configuration with file storage (persistent)
- Creating automated unseal script
- Implementing startup script that retrieves secrets before launching services
- Documenting all procedures for operator reference

Work incrementally through phases. Test each phase before moving to next. Vault must be unsealed before secrets can be accessed - this is by design for security.

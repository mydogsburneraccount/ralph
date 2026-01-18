# Ralph Secret Management with Flippanet Vault

## Overview

Ralph uses HashiCorp Vault running on Flippanet server for secure secret storage. This keeps secrets:
- ✅ Off the dev machine (Yggdrasil)
- ✅ Encrypted at rest
- ✅ Access-controlled
- ✅ Backed up with server data
- ✅ Accessible via Tailscale from anywhere

## Architecture

```
Yggdrasil (WSL)                    Flippanet (Server)
┌──────────────┐   Tailscale      ┌──────────────┐
│ Ralph Scripts│ ────────────────→ │ Vault :8201  │
│              │   Encrypted       │              │
│ curl/jq only │                   │ Secrets DB   │
└──────────────┘                   └──────────────┘
```

## Setup

### 1. Verify Vault Access

```bash
# From Yggdrasil/WSL
curl http://flippanet:8201/v1/sys/health

# Should return JSON with "sealed": false
```

### 2. Store Secrets (One-Time)

```bash
# SSH into Flippanet
ssh -i ~/.ssh/flippanet flippadip@flippanet

# Store GitHub token
docker exec -it vault vault kv put secret/ralph/github-token \
  value="ghp_xxxxxxxxxxxxxxxxxxxxx"

# Store Anthropic API key (if needed)
docker exec -it vault vault kv put secret/ralph/anthropic-key \
  value="sk-ant-api03-xxxxxxxxxxxxx"

# Store any other secrets
docker exec -it vault vault kv put secret/ralph/corporate-api-key \
  value="your-key-here"
```

### 3. Test Retrieval from Yggdrasil

```bash
# From Yggdrasil/WSL
./.ralph/scripts/ralph-secrets.sh get ralph/github-token

# Should output your token
```

## Usage in Ralph Scripts

### Get a Secret

```bash
# In any Ralph script
GH_TOKEN=$(./.ralph/scripts/ralph-secrets.sh get ralph/github-token)
export GITHUB_TOKEN="$GH_TOKEN"

# Or inline
gh auth login --with-token <<< "$(./.ralph/scripts/ralph-secrets.sh get ralph/github-token)"
```

### List All Secrets

```bash
./.ralph/scripts/ralph-secrets.sh list
```

### Set New Secret

```bash
# From Flippanet
ssh flippanet
docker exec -it vault vault kv put secret/ralph/new-secret value="secret-value"
```

## Security Benefits

### What This Protects Against

✅ **Secrets in code** - Never commit tokens to git  
✅ **Secrets in shell history** - Not stored in .bashrc or entered interactively  
✅ **Secrets in environment** - Not visible in `ps` or Docker inspect  
✅ **Loss of dev machine** - Secrets not on Yggdrasil if stolen/lost  
✅ **Accidental exposure** - Can't accidentally share via screenshots/logs  

### How It Works

1. **Encrypted Storage**: Vault encrypts secrets at rest on Flippanet
2. **Network Security**: Tailscale encrypts traffic between machines
3. **Access Control**: Only authorized tokens can read secrets
4. **Audit Logging**: Vault can log all secret access (if configured)

## Common Secrets to Store

```bash
# GitHub
secret/ralph/github-token        # Personal access token
secret/ralph/github-copilot-key  # If separate from token

# AI APIs
secret/ralph/anthropic-key       # Claude API key
secret/ralph/openai-key          # OpenAI API key (if used)

# Corporate
secret/ralph/corp-github-token   # Corporate GitHub PAT
secret/ralph/corp-api-key        # Other corporate APIs

# Services
secret/ralph/discord-webhook     # Discord notifications
secret/ralph/slack-webhook       # Slack notifications
```

## Integration with Ralph

### ralph-autonomous.sh

Add to beginning of script:

```bash
# Load secrets from Vault
if command -v ./.ralph/scripts/ralph-secrets.sh &> /dev/null; then
    export GITHUB_TOKEN=$(./.ralph/scripts/ralph-secrets.sh get ralph/github-token 2>/dev/null || true)
    export ANTHROPIC_API_KEY=$(./.ralph/scripts/ralph-secrets.sh get ralph/anthropic-key 2>/dev/null || true)
fi
```

### ralph-copilot.sh

```bash
# Ensure GitHub token is loaded
if [ -z "$GITHUB_TOKEN" ]; then
    GITHUB_TOKEN=$(./.ralph/scripts/ralph-secrets.sh get ralph/github-token)
fi

gh auth login --with-token <<< "$GITHUB_TOKEN"
```

## Troubleshooting

### Can't connect to Vault

```bash
# Check Tailscale
ping flippanet

# Check Vault is running
ssh flippanet "docker ps | grep vault"

# Check Vault port
curl -v http://flippanet:8201/v1/sys/health
```

### Vault is sealed

```bash
# Check status
curl http://flippanet:8201/v1/sys/health | jq .sealed

# If true, unseal (on Flippanet)
ssh flippanet
docker exec -it vault vault operator unseal
# Enter unseal keys (you should have these stored securely)
```

### Wrong token

```bash
# The default dev token is: flipparr-root-token
# Set in ralph-secrets.sh or:
export VAULT_TOKEN="your-actual-token"
```

## Alternative: Local Vault (Not Recommended)

If you want secrets on Yggdrasil instead:

```bash
# Install Vault locally
ralph-install-dependency system vault

# Run in dev mode
vault server -dev &

# Store secrets
export VAULT_ADDR='http://127.0.0.1:8200'
vault kv put secret/ralph/github-token value="token"
```

**Why not recommended:**
- ❌ Secrets on dev machine (risk if stolen)
- ❌ No backup if machine fails
- ❌ Needs to run vault server constantly
- ❌ Lost if you reinstall WSL

**Use Flippanet instead** - it's more secure and already set up!

## Next Steps

1. [ ] Verify Vault access from Yggdrasil
2. [ ] Store GitHub token in Vault
3. [ ] Test retrieval with ralph-secrets.sh
4. [ ] Update ralph scripts to use Vault
5. [ ] Remove hardcoded secrets from .bashrc/.env files

---

**Security Note**: The Vault root token (`flipparr-root-token`) should be changed to something more secure. For production use, create app-specific tokens with limited permissions.

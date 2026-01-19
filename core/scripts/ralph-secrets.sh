#!/bin/bash
# Ralph Secret Manage
# Securely manages secrets for Ralph automation
#
# Two modes:
# 1. Vault mode (if Flippanet Vault is available)
# 2. Local mode (uses ~/.ralph/secrets.env)

set -euo pipefail

SECRETS_FILE="${HOME}/.ralph/secrets.env"
# Default to flippanet (not localhost) since Vault runs on flippanet server
VAULT_ADDR="${VAULT_ADDR:-http://flippanet:8201}"

# SECURITY: Token must be provided via environment variable or ~/.ralph/vault-token
# Never hardcode tokens. Get token from file if not in env.
if [ -z "${VAULT_TOKEN:-}" ]; then
    if [ -f "${HOME}/.ralph/vault-token" ]; then
        # Strip CRLF to handle Windows line endings in token file
        VAULT_TOKEN=$(tr -d '\r\n' < "${HOME}/.ralph/vault-token")
    else
        VAULT_TOKEN=""
    fi
fi

# Check if Vault is available
vault_available() {
    curl -sf "$VAULT_ADDR/v1/sys/health" &>/dev/null
}

# Get secret from local file
get_secret_local() {
    local key="$1"

    if [ ! -f "$SECRETS_FILE" ]; then
        echo "Error: Secrets file not found: $SECRETS_FILE" >&2
        echo "Run: $0 init" >&2
        return 1
    fi

    # Extract value from ENV_VAR="value" format
    local value=$(grep "^export ${key}=" "$SECRETS_FILE" 2>/dev/null | cut -d'"' -f2)

    if [ -n "$value" ]; then
        echo "$value"
        return 0
    else
        echo "Error: Secret not found: $key" >&2
        return 1
    fi
}

# Get secret from Vault
get_secret_vault() {
    local secret_path="$1"
    local field="${2:-}"  # Optional: specific field to extract

    if [ -z "$VAULT_TOKEN" ]; then
        echo "Error: No Vault token configured." >&2
        echo "Set VAULT_TOKEN env var or create ~/.ralph/vault-token" >&2
        return 1
    fi

    local response=$(curl -sf -H "X-Vault-Token: $VAULT_TOKEN" \
        "$VAULT_ADDR/v1/secret/data/$secret_path" 2>/dev/null)

    if [ -z "$response" ]; then
        echo "Error: Could not retrieve secret: $secret_path" >&2
        echo "Check: token valid, path correct, Vault unsealed" >&2
        return 1
    fi

    # If field specified, get that field; otherwise get 'value' or show all data
    if [ -n "$field" ]; then
        local value=$(echo "$response" | jq -r ".data.data.${field}" 2>/dev/null)
    else
        # Try 'value' field first (for simple secrets)
        local value=$(echo "$response" | jq -r '.data.data.value' 2>/dev/null)
        # If no 'value' field, show all fields as JSON
        if [ "$value" = "null" ]; then
            value=$(echo "$response" | jq -r '.data.data' 2>/dev/null)
        fi
    fi

    if [ "$value" != "null" ] && [ -n "$value" ]; then
        echo "$value"
        return 0
    else
        echo "Error: Could not retrieve secret: $secret_path" >&2
        echo "Check: token valid, path correct, Vault unsealed" >&2
        return 1
    fi
}

# Set secret in local file
set_secret_local() {
    local key="$1"
    local value="$2"

    # Create file if it doesn't exist
    if [ ! -f "$SECRETS_FILE" ]; then
        mkdir -p "$(dirname "$SECRETS_FILE")"
        cat > "$SECRETS_FILE" << 'EOF'
# Ralph Secrets - DO NOT COMMIT
# This file stores sensitive tokens for Ralph automation
# File permissions: 600 (readable only by you)
EOF
        chmod 600 "$SECRETS_FILE"
    fi

    # Update or add the secret
    if grep -q "^export ${key}=" "$SECRETS_FILE"; then
        # Update existing
        sed -i "s|^export ${key}=.*|export ${key}=\"${value}\"|" "$SECRETS_FILE"
    else
        # Add new
        echo "export ${key}=\"${value}\"" >> "$SECRETS_FILE"
    fi

    echo "✓ Secret ${key} saved to $SECRETS_FILE"
}

# Initialize secrets file
init_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        echo "Secrets file already exists: $SECRETS_FILE"
        read -p "Overwrite? (y/N): " -n 1 -
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    mkdir -p "$(dirname "$SECRETS_FILE")"

    cat > "$SECRETS_FILE" << 'EOF'
# Ralph Secrets - DO NOT COMMIT
# This file stores sensitive tokens for Ralph automation
# File permissions: 600 (readable only by you)

# GitHub Personal Access Token
# Create at: https://github.com/settings/tokens
# Scopes needed: repo, read:org, use
export GITHUB_TOKEN=""

# Anthropic API Key (for Aider, if using)
# Get from: https://console.anthropic.com/
export ANTHROPIC_API_KEY=""

# Corporate GitHub Token (if different from personal)
export CORP_GITHUB_TOKEN=""

# Discord Webhook (optional - for notifications)
export DISCORD_WEBHOOK=""

# Slack Webhook (optional - for notifications)
export SLACK_WEBHOOK=""
EOF

    chmod 600 "$SECRETS_FILE"

    echo "✓ Created secrets file: $SECRETS_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Edit file: nano $SECRETS_FILE"
    echo "  2. Add your tokens"
    echo "  3. Source in shell: source $SECRETS_FILE"
    echo "  4. Or auto-load: echo 'source $SECRETS_FILE' >> ~/.bashrc"
}

# List secrets
list_secrets() {
    if vault_available; then
        echo "Vault mode (listing from Vault):"
        curl -sf -H "X-Vault-Token: $VAULT_TOKEN" \
            "$VAULT_ADDR/v1/secret/metadata/?list=true" \
            | jq -r '.data.keys[]' 2>/dev/null || echo "No secrets found"
    elif [ -f "$SECRETS_FILE" ]; then
        echo "Local mode (listing from $SECRETS_FILE):"
        grep "^export " "$SECRETS_FILE" | cut -d'=' -f1 | sed 's/export //'
    else
        echo "No secrets configured. Run: $0 init"
    fi
}

# Main CLI
case "${1:-}" in
    get)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 get <key> [field]"
            echo "  key: secret path (e.g., flippanet/protonvpn)"
            echo "  field: optional specific field (e.g., username)"
            exit 1
        fi

        if vault_available; then
            get_secret_vault "$2" "${3:-}"
        else
            get_secret_local "$2"
        fi
        ;;

    set)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            echo "Usage: $0 set <key> <value>"
            exit 1
        fi

        if vault_available; then
            echo "Vault mode - use SSH to set:"
            echo "ssh flippanet 'docker exec vault vault kv put secret/$2 value=\"$3\"'"
        else
            set_secret_local "$2" "$3"
        fi
        ;;

    init)
        init_secrets
        ;;

    list)
        list_secrets
        ;;

    edit)
        if [ ! -f "$SECRETS_FILE" ]; then
            echo "Secrets file doesn't exist. Creating..."
            init_secrets
        fi
        ${EDITOR:-nano} "$SECRETS_FILE"
        ;;

    mode)
        if vault_available; then
            echo "Mode: Vault (Flippanet)"
            echo "Vault: $VAULT_ADDR"
            if [ -n "$VAULT_TOKEN" ]; then
                echo "Token: ✓ Configured (${#VAULT_TOKEN} chars)"
            else
                echo "Token: ✗ Not configured"
                echo "  Set VAULT_TOKEN env var or create ~/.ralph/vault-token"
            fi
        else
            echo "Mode: Local file"
            echo "File: $SECRETS_FILE"
            if [ -f "$SECRETS_FILE" ]; then
                echo "Status: ✓ File exists"
            else
                echo "Status: ✗ Not initialized (run: $0 init)"
            fi
        fi
        ;;

    *)
        echo "Ralph Secret Manager"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init              Create secrets file"
        echo "  get <key>         Get a secret value"
        echo "  set <key> <value> Set a secret value"
        echo "  list              List all secret keys"
        echo "  edit              Edit secrets file"
        echo "  mode              Show current mode (Vault or Local)"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 set GITHUB_TOKEN 'ghp_xxxxx'"
        echo "  $0 get GITHUB_TOKEN"
        echo "  $0 edit"
        exit 1
        ;;
esac

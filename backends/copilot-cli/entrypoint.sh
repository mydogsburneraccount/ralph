#!/bin/bash
# Entrypoint script for Ralph Copilot Sandbox
#
# Aligns user permissions between host and container to ensure
# files created in /work have correct ownership.

set -e

# If running as root and PUID/PGID set, switch to that user
if [[ "$(id -u)" = "0" ]] && [[ -n "${PUID:-}" ]] && [[ -n "${PGID:-}" ]]; then
    # Create group if it doesn't exist
    if ! getent group "$PGID" >/dev/null; then
        groupadd --gid "$PGID" hostgroup
    fi

    # Create user if it doesn't exist
    if ! id "$PUID" >/dev/null 2>&1; then
        useradd --uid "$PUID" --gid "$PGID" -m hostuser
    fi

    # Execute command as the specified user
    exec gosu "$PUID:$PGID" "$@"
fi

# Otherwise run as current user
exec "$@"

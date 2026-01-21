# Ralph Copilot Sandbox Dockerfile
#
# This container provides a safe environment for running Copilot CLI
# with --allow-all-tools flag. The container is isolated so any
# destructive commands only affect the mounted /work directory.
#
# Based on community pattern from Gordon Beeming's Docker sandbox guide.
#
# Usage:
#   docker build -t ralph-copilot-sandbox .
#   docker run -it -v $(pwd):/work ralph-copilot-sandbox copilot -p "your prompt"

FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub Copilot CLI globally
RUN npm install -g @github/copilot

# Create working directory
WORKDIR /work

# Create non-root user for better permission alignment
# The entrypoint will handle user switching based on host UID/GID
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd --gid $GROUP_ID developer 2>/dev/null || true && \
    useradd --uid $USER_ID --gid $GROUP_ID -m developer 2>/dev/null || true

# Set up entrypoint for permission alignment
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Default command - interactive Copilot shell
CMD ["copilot"]

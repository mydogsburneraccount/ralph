#!/bin/bash
# Aider + Anthropic Backend Setup

set -euo pipefail

echo "═══════════════════════════════════════════════════"
echo "  Aider + Anthropic Backend Setup for Ralph"
echo "═══════════════════════════════════════════════════"
echo ""

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    echo ""
    echo "Install Python 3.8+ and try again."
    exit 1
fi

echo "✓ Python found: $(python3 --version)"

# Check for pipx (recommended)
if ! command -v pipx &> /dev/null; then
    echo ""
    echo "pipx not found (recommended for aider installation)"
    read -p "Install pipx? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# Install aider
echo ""
echo "Installing aider-chat..."
if command -v aider &> /dev/null; then
    echo "✓ aider already installed: $(aider --version 2>&1 | head -1)"
else
    if command -v pipx &> /dev/null; then
        pipx install aider-chat
    else
        python3 -m pip install --user aider-chat
    fi
    echo "✓ aider installed"
fi

# Check for API key
echo ""
echo "Checking for Anthropic API key..."
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "✓ ANTHROPIC_API_KEY is set"
else
    echo "⚠️  ANTHROPIC_API_KEY not set"
    echo ""
    echo "Get your API key from: https://console.anthropic.com/"
    echo ""
    read -p "Set API key now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter API key: " api_key
        echo ""
        echo "export ANTHROPIC_API_KEY=\"$api_key\"" >> ~/.bashrc
        export ANTHROPIC_API_KEY="$api_key"
        echo "✓ API key saved to ~/.bashrc"
    else
        echo ""
        echo "You can set it later:"
        echo "  export ANTHROPIC_API_KEY=\"sk-ant-...\""
        echo "  echo 'export ANTHROPIC_API_KEY=\"sk-ant-...\"' >> ~/.bashrc"
    fi
fi

# Install base toolset
echo ""
echo "Ralph base toolset (Python, Node.js, etc.)..."
if [ -f "../../core/scripts/ralph-base-toolset.sh" ]; then
    read -p "Run base toolset installer? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ../../core/scripts/ralph-base-toolset.sh
    fi
fi

# Create .ralph directory
echo ""
echo "Setting up ~/.ralph directory..."
mkdir -p ~/.ralph/{active,completed}
echo "✓ Created ~/.ralph structure"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "    Only use this backend for PERSONAL projects."
echo "    Do NOT use for corporate/proprietary code."
echo ""
echo "Next steps:"
echo "  1. Create a task:"
echo "     ../../core/scripts/ralph-task-manager.sh create my-task"
echo "  2. Run Ralph:"
echo "     ./ralph-aider.sh my-task"
echo ""
echo "Estimated costs:"
echo "  - Haiku: ~$0.10 per 10 iterations"
echo "  - Sonnet: ~$0.50 per 10 iterations (default)"
echo "  - Opus: ~$2.00 per 10 iterations"
echo ""

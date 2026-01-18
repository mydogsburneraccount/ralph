#!/bin/bash
# Cursor Agent Backend Setup

set -euo pipefail

echo "═══════════════════════════════════════════════════"
echo "  Cursor Agent Backend Setup for Ralph"
echo "═══════════════════════════════════════════════════"
echo ""

# Detect OS
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "✓ Detected WSL environment"
    IS_WSL=true
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "✓ Detected macOS"
    IS_WSL=false
else
    echo "✓ Detected Linux"
    IS_WSL=false
fi

# Check for Cursor
if ! command -v cursor-agent &> /dev/null; then
    echo ""
    echo "❌ cursor-agent not found"
    echo ""
    echo "Install Cursor from: https://cursor.sh/"
    echo "Then run this setup again."
    exit 1
fi

echo "✓ cursor-agent found: $(cursor-agent --version 2>&1 | head -1)"

# Check authentication
echo ""
echo "Checking cursor-agent authentication..."
if cursor-agent status &> /dev/null; then
    echo "✓ Authenticated"
else
    echo "⚠️  Not authenticated"
    echo ""
    echo "Run: cursor-agent login"
    exit 1
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
else
    echo "⚠️  Base toolset script not found at ../../core/scripts/ralph-base-toolset.sh"
fi

# Create .ralph directory in home
echo ""
echo "Setting up ~/.ralph directory..."
mkdir -p ~/.ralph/{active,completed}
echo "✓ Created ~/.ralph structure"

# Create symlink to scripts
echo ""
echo "Creating script symlinks..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ln -sf "$SCRIPT_DIR/ralph-autonomous.sh" ~/.local/bin/ralph-autonomous 2>/dev/null || true
ln -sf "../../core/scripts/ralph-task-manager.sh" ~/.local/bin/ralph-task 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Create a task:"
echo "     ralph-task create my-first-task"
echo ""
echo "  2. Edit the task:"
echo "     nano ~/.ralph/active/my-first-task/TASK.md"
echo ""
echo "  3. Run Ralph:"
echo "     $SCRIPT_DIR/ralph-autonomous.sh my-first-task"
echo ""
echo "See README.md for more information."
echo ""

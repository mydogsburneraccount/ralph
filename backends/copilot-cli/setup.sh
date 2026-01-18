#!/bin/bash
# GitHub Copilot CLI Backend Setup

set -euo pipefail

echo "═══════════════════════════════════════════════════"
echo "  GitHub Copilot CLI Backend Setup for Ralph"
echo "═══════════════════════════════════════════════════"
echo ""
echo "⚠️  This backend requires an active GitHub Copilot license"
echo ""

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found"
    echo ""
    echo "Install:"
    echo "  Ubuntu/Debian: sudo apt-get install gh"
    echo "  Mac: brew install gh"
    echo "  Windows: winget install GitHub.cli"
    exit 1
fi

echo "✓ GitHub CLI found: $(gh --version | head -1)"

# Check authentication
echo ""
echo "Checking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "✓ Authenticated to GitHub"
else
    echo "⚠️  Not authenticated"
    echo ""
    echo "Run: gh auth login"
    exit 1
fi

# Check for Copilot CLI
echo ""
echo "Checking for Copilot CLI..."
HAS_COPILOT=false

if command -v copilot &> /dev/null; then
    echo "✓ Found new copilot CLI: $(copilot --version 2>&1 | head -1)"
    HAS_COPILOT=true
elif gh copilot --help &> /dev/null 2>&1; then
    echo "✓ Found gh copilot extension"
    HAS_COPILOT=true
else
    echo "❌ Copilot CLI not found"
    echo ""
    echo "Install:"
    echo "  npm: npm install -g @github/copilot"
    echo "  brew: brew install github/copilot/copilot"
    echo "  winget: winget install GitHub.Copilot"
    echo ""
    read -p "Install via npm now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npm install -g @github/copilot
        HAS_COPILOT=true
    else
        exit 1
    fi
fi

# Verify Copilot license
if [ "$HAS_COPILOT" = true ]; then
    echo ""
    echo "⚠️  IMPORTANT: Testing Copilot license..."
    echo ""
    echo "This backend REQUIRES an active GitHub Copilot license."
    echo "If you don't have one, this setup will work but ralph-copilot.sh will fail."
    echo ""
    read -p "Do you have an active Copilot license? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "⚠️  Setup cannot proceed without Copilot license."
        echo ""
        echo "Get Copilot at: https://github.com/features/copilot"
        echo "Or use a different backend:"
        echo "  - cursor-agent (if you have Cursor IDE)"
        echo "  - aider (if you have Anthropic API key)"
        exit 1
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
echo "⚠️  IMPORTANT: This backend is UNTESTED"
echo "    It was designed based on documentation research."
echo "    See COPILOT_TESTING.md for validation procedures."
echo ""
echo "Next steps:"
echo "  1. Read: COPILOT_TESTING.md"
echo "  2. Create test task:"
echo "     ../../core/scripts/ralph-task-manager.sh create test-copilot"
echo "  3. Run (carefully):"
echo "     ./ralph-copilot.sh test-copilot"
echo ""

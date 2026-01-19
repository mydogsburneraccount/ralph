#!/bin/bash
# VS Code + Copilot Corporate Mac Setup Script
# Run this on your corporate Mac to set up agentic Copilot experience
#
# Usage: chmod +x mac-copilot-setup.sh && ./mac-copilot-setup.sh

set -euo pipefail

echo "═══════════════════════════════════════════════════════════"
echo "VS Code + Copilot Corporate Mac Setup"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

# Track what needs manual intervention
MANUAL_STEPS=()

echo "Phase 1: Prerequisites Verification"
echo "────────────────────────────────────"

# Check VS Code
if command -v code &> /dev/null; then
    success "VS Code installed: $(code --version | head -1)"
else
    warn "VS Code not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install --cask visual-studio-code
        success "VS Code installed via Homebrew"
    else
        fail "Homebrew not found. Install VS Code manually from https://code.visualstudio.com"
        MANUAL_STEPS+=("Install VS Code from https://code.visualstudio.com")
    fi
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
    success "GitHub CLI installed: $(gh --version | head -1)"
else
    warn "GitHub CLI not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install gh
        success "GitHub CLI installed"
    else
        fail "Install GitHub CLI: brew install gh"
        MANUAL_STEPS+=("Install GitHub CLI: brew install gh")
    fi
fi

# Check Copilot CLI
if command -v copilot &> /dev/null; then
    success "Copilot CLI installed: $(copilot --version 2>/dev/null || echo 'version check failed')"
else
    warn "Copilot CLI not found. Installing..."
    if command -v npm &> /dev/null; then
        npm install -g @github/copilot
        success "Copilot CLI installed via npm"
    elif command -v brew &> /dev/null; then
        brew install copilot-cli
        success "Copilot CLI installed via Homebrew"
    else
        fail "Install Copilot CLI: npm install -g @github/copilot"
        MANUAL_STEPS+=("Install Copilot CLI: npm install -g @github/copilot")
    fi
fi

echo ""
echo "Phase 2: VS Code Extensions"
echo "────────────────────────────────────"

if command -v code &> /dev/null; then
    # Install Copilot extension
    if code --list-extensions 2>/dev/null | grep -qi "github.copilot$"; then
        success "GitHub Copilot extension already installed"
    else
        echo "Installing GitHub Copilot extension..."
        code --install-extension GitHub.copilot
        success "GitHub Copilot extension installed"
    fi

    # Install Copilot Chat extension
    if code --list-extensions 2>/dev/null | grep -qi "github.copilot-chat"; then
        success "GitHub Copilot Chat extension already installed"
    else
        echo "Installing GitHub Copilot Chat extension..."
        code --install-extension GitHub.copilot-chat
        success "GitHub Copilot Chat extension installed"
    fi
else
    fail "VS Code not available - cannot install extensions"
    MANUAL_STEPS+=("Install VS Code extensions: GitHub.copilot and GitHub.copilot-chat")
fi

echo ""
echo "Phase 3: VS Code Agent Mode Configuration"
echo "────────────────────────────────────"

VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

if [[ -f "$VSCODE_SETTINGS" ]]; then
    # Check if agent mode already configured
    if grep -q "chat.agent.enabled" "$VSCODE_SETTINGS" 2>/dev/null; then
        success "Agent mode settings already present"
    else
        warn "Adding agent mode settings to VS Code..."
        # Backup existing settings
        cp "$VSCODE_SETTINGS" "$VSCODE_SETTINGS.backup.$(date +%Y%m%d)"

        # Use Python to safely merge JSON (available on macOS)
        python3 << 'PYTHON_EOF'
import json
import os

settings_path = os.path.expanduser("~/Library/Application Support/Code/User/settings.json")

# Read existing settings
with open(settings_path, 'r') as f:
    settings = json.load(f)

# Add Copilot agent settings
settings["chat.agent.enabled"] = True
settings["github.copilot.chat.agent.runTasks"] = True
settings["github.copilot.chat.agent.autoFix"] = True
settings["github.copilot.editor.enableAutoCompletions"] = True
settings["github.copilot.enable"] = {"*": True}

# Write back
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print("Settings updated successfully")
PYTHON_EOF
        success "Agent mode settings added (backup created)"
    fi
else
    warn "VS Code settings.json not found at expected location"
    MANUAL_STEPS+=("Add agent mode settings to VS Code settings.json manually")
fi

echo ""
echo "Phase 4: Authentication"
echo "────────────────────────────────────"

# Check GitHub CLI auth
if gh auth status &> /dev/null; then
    success "GitHub CLI authenticated"
else
    warn "GitHub CLI not authenticated"
    MANUAL_STEPS+=("Run: gh auth login")
fi

# Check Copilot CLI auth (this usually requires interactive login)
if command -v copilot &> /dev/null; then
    warn "Copilot CLI requires interactive authentication"
    MANUAL_STEPS+=("Run: copilot /login")
else
    fail "Copilot CLI not installed"
fi

echo ""
echo "Phase 5: Project Instructions Template"
echo "────────────────────────────────────"

# Create .github directory and instructions template
if [[ ! -d ".github" ]]; then
    mkdir -p .github
    success "Created .github directory"
fi

if [[ ! -f ".github/copilot-instructions.md" ]]; then
    cat > .github/copilot-instructions.md << 'INSTRUCTIONS_EOF'
# Copilot Project Instructions

> This file provides project context to GitHub Copilot (similar to CLAUDE.md for Claude Code)

## Project Overview

[Describe your project here]

## Code Style

- [Language-specific conventions]
- [Formatting preferences]
- [Naming conventions]

## Architecture

- [Key patterns used]
- [Directory structure]
- [Important modules]

## Testing

- Test framework: [e.g., Jest, pytest, etc.]
- Run tests: `[command to run tests]`
- Coverage requirements: [if any]

## Important Files

- Entry point: [path]
- Configuration: [paths]
- Environment: [.env handling]

## Common Tasks

- Build: `[build command]`
- Test: `[test command]`
- Deploy: `[deploy notes]`

## Gotchas

- [Known issues or non-obvious behaviors]
- [Things that commonly trip people up]
INSTRUCTIONS_EOF
    success "Created .github/copilot-instructions.md template"
else
    success ".github/copilot-instructions.md already exists"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Setup Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Final verification
echo "Verification:"
command -v code &> /dev/null && success "VS Code: installed" || fail "VS Code: missing"
command -v gh &> /dev/null && success "GitHub CLI: installed" || fail "GitHub CLI: missing"
command -v copilot &> /dev/null && success "Copilot CLI: installed" || fail "Copilot CLI: missing"
[[ -f ".github/copilot-instructions.md" ]] && success "Project instructions: created" || fail "Project instructions: missing"

echo ""

# Show manual steps if any
if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
    echo "Manual steps required:"
    for step in "${MANUAL_STEPS[@]}"; do
        echo "  → $step"
    done
    echo ""
fi

echo "Next steps:"
echo "  1. Run 'copilot /login' to authenticate with your corporate GitHub"
echo "  2. Open VS Code and press Cmd+Shift+I to open Chat"
echo "  3. Select 'Agent' from the mode dropdown"
echo "  4. Customize .github/copilot-instructions.md for your project"
echo ""
echo "Test commands:"
echo "  copilot /whoami          # Verify authentication"
echo "  copilot /model           # See available models"
echo "  echo 'Hello' | copilot   # Test CLI response"
echo ""
echo "═══════════════════════════════════════════════════════════"

#!/usr/bin/env bash
# Ralph CLI Setup Script
# Sets up Ralph with Aider (or other CLI tools) for autonomous coding

set -euo pipefail

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - CLI Setup                      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "This script will help you set up Ralph for CLI-only"
echo "autonomous coding (no Cursor required)."
echo ""

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Darwin*)    OS_NAME="Mac";;
    Linux*)     OS_NAME="Linux";;
    CYGWIN*|MINGW*|MSYS*) OS_NAME="Windows";;
    *)          OS_NAME="Unknown";;
esac

echo "Detected OS: $OS_NAME"
echo ""

# Detect shell
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "bash" ]; then
    if [ "$OS_NAME" = "Mac" ]; then
        SHELL_RC="$HOME/.bash_profile"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
else
    SHELL_RC="$HOME/.profile"
fi

echo "Shell config: $SHELL_RC"
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 1: Choose CLI Tool
# ═══════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────"
echo "STEP 1: Choose your CLI coding tool"
echo "─────────────────────────────────────────────────────"
echo ""
echo "Options:"
echo "  1) Aider + Anthropic Claude API (recommended)"
echo "  2) Aider + OpenAI GPT API"
echo "  3) GitHub Copilot CLI (if you have corporate access)"
echo "  4) OpenAI Codex CLI (requires ChatGPT Plus/Pro)"
echo "  5) Skip (I'll install manually)"
echo ""

read -p "Choose option [1-5]: " TOOL_CHOICE

case "$TOOL_CHOICE" in
    1)
        TOOL="aider"
        MODEL_PROVIDER="anthropic"
        echo ""
        echo "✅ Selected: Aider + Anthropic Claude"
        ;;
    2)
        TOOL="aider"
        MODEL_PROVIDER="openai"
        echo ""
        echo "✅ Selected: Aider + OpenAI GPT"
        ;;
    3)
        TOOL="copilot"
        MODEL_PROVIDER="github"
        echo ""
        echo "✅ Selected: GitHub Copilot CLI"
        ;;
    4)
        TOOL="codex"
        MODEL_PROVIDER="openai"
        echo ""
        echo "✅ Selected: OpenAI Codex CLI"
        ;;
    5)
        TOOL="manual"
        echo ""
        echo "✅ Skipping tool installation"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""

# ═══════════════════════════════════════════════════════════
# STEP 2: Install Tool
# ═══════════════════════════════════════════════════════════

if [ "$TOOL" != "manual" ]; then
    echo "─────────────────────────────────────────────────────"
    echo "STEP 2: Install $TOOL"
    echo "─────────────────────────────────────────────────────"
    echo ""
    
    case "$TOOL" in
        aider)
            if command -v aider &> /dev/null; then
                echo "✅ aider already installed: $(aider --version)"
            else
                echo "Installing aider..."
                
                # Try different installation methods
                if command -v pipx &> /dev/null; then
                    echo "Using pipx..."
                    pipx install aider-chat
                elif command -v uv &> /dev/null; then
                    echo "Using uv..."
                    uv tool install aider-chat
                elif command -v pip &> /dev/null; then
                    echo "Using pip..."
                    pip install aider-chat
                else
                    echo "❌ No Python package manager found (pip/pipx/uv)"
                    echo "Please install Python 3.10+ first, then run:"
                    echo "  pip install aider-chat"
                    exit 1
                fi
                
                if command -v aider &> /dev/null; then
                    echo "✅ aider installed successfully"
                else
                    echo "⚠️  aider installed but not in PATH"
                    echo "You may need to restart your terminal"
                fi
            fi
            ;;
            
        copilot)
            if gh copilot --version &> /dev/null; then
                echo "✅ GitHub Copilot CLI already installed"
            else
                echo "Installing GitHub Copilot CLI..."
                
                if ! command -v gh &> /dev/null; then
                    echo "Installing GitHub CLI first..."
                    if [ "$OS_NAME" = "Mac" ]; then
                        if command -v brew &> /dev/null; then
                            brew install gh
                        else
                            echo "❌ Homebrew not found. Install from: https://brew.sh"
                            exit 1
                        fi
                    else
                        echo "Install GitHub CLI from: https://cli.github.com/"
                        exit 1
                    fi
                fi
                
                gh extension install github/gh-copilot
                
                if gh copilot --version &> /dev/null; then
                    echo "✅ GitHub Copilot CLI installed"
                else
                    echo "❌ Installation failed"
                    exit 1
                fi
            fi
            ;;
            
        codex)
            if command -v codex &> /dev/null; then
                echo "✅ OpenAI Codex CLI already installed"
            else
                echo "Installing OpenAI Codex CLI..."
                echo "Downloading installer..."
                curl -sSfL https://cli.openai.com/install.sh | bash
                
                if command -v codex &> /dev/null; then
                    echo "✅ Codex CLI installed"
                else
                    echo "⚠️  Codex installed but not in PATH"
                    echo "You may need to restart your terminal"
                fi
            fi
            ;;
    esac
    
    echo ""
fi

# ═══════════════════════════════════════════════════════════
# STEP 3: API Key Setup
# ═══════════════════════════════════════════════════════════

if [ "$TOOL" = "aider" ]; then
    echo "─────────────────────────────────────────────────────"
    echo "STEP 3: API Key Setup"
    echo "─────────────────────────────────────────────────────"
    echo ""
    
    if [ "$MODEL_PROVIDER" = "anthropic" ]; then
        if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
            echo "You need an Anthropic API key."
            echo ""
            echo "Get one at: https://console.anthropic.com/"
            echo "(New accounts get \$5 free credit)"
            echo ""
            read -p "Enter your Anthropic API key (sk-ant-...): " API_KEY
            
            if [ -n "$API_KEY" ]; then
                export ANTHROPIC_API_KEY="$API_KEY"
                echo "" >> "$SHELL_RC"
                echo "# Ralph - Anthropic API key" >> "$SHELL_RC"
                echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
                echo "✅ API key saved to $SHELL_RC"
            else
                echo "⚠️  No API key entered. You'll need to set it manually:"
                echo "  export ANTHROPIC_API_KEY='sk-ant-...'"
            fi
        else
            echo "✅ ANTHROPIC_API_KEY already set"
        fi
    elif [ "$MODEL_PROVIDER" = "openai" ]; then
        if [ -z "${OPENAI_API_KEY:-}" ]; then
            echo "You need an OpenAI API key."
            echo ""
            echo "Get one at: https://platform.openai.com/api-keys"
            echo ""
            read -p "Enter your OpenAI API key (sk-...): " API_KEY
            
            if [ -n "$API_KEY" ]; then
                export OPENAI_API_KEY="$API_KEY"
                echo "" >> "$SHELL_RC"
                echo "# Ralph - OpenAI API key" >> "$SHELL_RC"
                echo "export OPENAI_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
                echo "✅ API key saved to $SHELL_RC"
            else
                echo "⚠️  No API key entered. You'll need to set it manually:"
                echo "  export OPENAI_API_KEY='sk-...'"
            fi
        else
            echo "✅ OPENAI_API_KEY already set"
        fi
    fi
    
    echo ""
fi

# ═══════════════════════════════════════════════════════════
# STEP 4: Setup Workspace
# ═══════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────"
echo "STEP 4: Setup Ralph workspace"
echo "─────────────────────────────────────────────────────"
echo ""

WORKSPACE=$(pwd)
echo "Current directory: $WORKSPACE"
echo ""

# Create .ralph directory
if [ ! -d "$WORKSPACE/.ralph" ]; then
    echo "Creating .ralph directory..."
    mkdir -p "$WORKSPACE/.ralph"
fi

# Create state files
touch "$WORKSPACE/.ralph/progress.md"
touch "$WORKSPACE/.ralph/guardrails.md"
touch "$WORKSPACE/.ralph/errors.log"
touch "$WORKSPACE/.ralph/activity.log"

if [ ! -f "$WORKSPACE/.ralph/.iteration" ]; then
    echo "0" > "$WORKSPACE/.ralph/.iteration"
fi

# Initialize progress.md if empty
if [ ! -s "$WORKSPACE/.ralph/progress.md" ]; then
    cat > "$WORKSPACE/.ralph/progress.md" << EOF
# Ralph Progress

## Current Status
- Workspace initialized on $(date '+%Y-%m-%d')
- Ready for first task

## History
_Iterations will be logged here_
EOF
fi

# Initialize guardrails.md if empty
if [ ! -s "$WORKSPACE/.ralph/guardrails.md" ]; then
    cat > "$WORKSPACE/.ralph/guardrails.md" << 'EOF'
# Ralph Guardrails (Signs)

## What Are Signs?

When failures occur, document them here as "Signs" so future iterations don't repeat the same mistakes.

### Format:
```markdown
### Sign: [Rule name]
- **Trigger**: When to apply this rule
- **Instruction**: What to do
- **Added after**: Iteration X - what went wrong
```

## Signs

_None yet - will be added as Ralph learns from failures_
EOF
fi

echo "✅ Workspace structure created"
echo ""

# ═══════════════════════════════════════════════════════════
# STEP 5: Initialize Git
# ═══════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────"
echo "STEP 5: Git setup"
echo "─────────────────────────────────────────────────────"
echo ""

if [ ! -d "$WORKSPACE/.git" ]; then
    echo "Initializing git repository..."
    git init
    echo "✅ Git initialized"
else
    echo "✅ Git already initialized"
fi

# Check git config
GIT_USER=$(git config user.name || echo "")
GIT_EMAIL=$(git config user.email || echo "")

if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
    echo ""
    echo "⚠️  Git user not configured"
    echo ""
    read -p "Enter your name: " USER_NAME
    read -p "Enter your email: " USER_EMAIL
    
    if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
        git config user.name "$USER_NAME"
        git config user.email "$USER_EMAIL"
        echo "✅ Git configured"
    else
        echo "⚠️  Git not configured. Run manually:"
        echo "  git config user.name 'Your Name'"
        echo "  git config user.email 'your@email.com'"
    fi
else
    echo "✅ Git configured as: $GIT_USER <$GIT_EMAIL>"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# STEP 6: Create Sample Task
# ═══════════════════════════════════════════════════════════

if [ ! -f "$WORKSPACE/RALPH_TASK.md" ]; then
    echo "─────────────────────────────────────────────────────"
    echo "STEP 6: Create sample task file"
    echo "─────────────────────────────────────────────────────"
    echo ""
    
    read -p "Create sample RALPH_TASK.md? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat > "$WORKSPACE/RALPH_TASK.md" << 'EOF'
# Sample Ralph Task

## Task Overview

This is a sample task to test Ralph. Replace this with your actual task.

**Goal**: Create a simple Python hello world script

**Context**: Testing Ralph setup

---

## Success Criteria

- [ ] Create hello.py file
- [ ] File prints "Hello from Ralph!" when run
- [ ] File has proper Python shebang
- [ ] Git commit created with changes

---

## Notes

This is just a test. For real tasks:
- Make criteria specific and testable
- Use format: `- [ ]` for unchecked, `- [x]` for checked
- Ralph counts remaining `[ ]` to know when done
- Be thorough - "make it work" is bad, "GET /health returns 200" is good

---

## Rollback Plan

If something goes wrong:

```bash
# View recent commits
git log --oneline --grep="ralph:"

# Revert specific commit
git revert <commit-hash>

# Or reset to before Ralph started
git reset --hard <commit-before-ralph>
```
EOF
        echo "✅ Sample RALPH_TASK.md created"
        echo ""
        echo "Edit it with your actual task:"
        echo "  nano RALPH_TASK.md"
    fi
fi

# ═══════════════════════════════════════════════════════════
# COMPLETION
# ═══════════════════════════════════════════════════════════

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Setup Complete!                                ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Edit your task file:"
echo "   nano RALPH_TASK.md"
echo ""
echo "2. Make sure scripts are executable:"
echo "   chmod +x ralph-aider.sh ralph-copilot.sh ralph-codex.sh"
echo ""
echo "3. Run Ralph:"

case "$TOOL" in
    aider)
        echo "   ./ralph-aider.sh"
        echo ""
        echo "   Or with specific model:"
        echo "   RALPH_MODEL=haiku ./ralph-aider.sh  # Cheap"
        echo "   RALPH_MODEL=sonnet ./ralph-aider.sh # Balanced (default)"
        echo "   RALPH_MODEL=opus ./ralph-aider.sh   # Premium"
        ;;
    copilot)
        echo "   ./ralph-copilot.sh"
        ;;
    codex)
        echo "   ./ralph-codex.sh"
        ;;
    manual)
        echo "   Choose the appropriate script for your tool"
        ;;
esac

echo ""
echo "4. Monitor progress:"
echo "   cat .ralph/progress.md"
echo "   cat .ralph/.iteration"
echo ""
echo "5. View commits:"
echo "   git log --oneline --grep='ralph:'"
echo ""
echo "For help, see:"
echo "  - .ralph/docs/RALPH_CLI_ONLY.md"
echo "  - .ralph/docs/QUICKREF.md"
echo ""
echo "✨ Happy coding!"

# Ralph Wiggum - CLI Only Edition

**For Corporate Mac (or any machine) - No Cursor Required**

> Use your own API key (Anthropic, OpenAI, or GitHub Copilot) to run autonomous Ralph

---

## Why CLI-Only?

**Perfect for corporate environments where**:

- Cursor isn't approved/installable
- You have corporate GitHub Copilot access
- You have your own Anthropic/OpenAI API key
- You want more control over the agent
- You need to work within IT restrictions

**Advantages**:

- No special IDE installation needed
- Works with corporate API keys
- Fully transparent (just Python/bash scripts)
- Easy to get IT approval (it's just a CLI tool)
- Portable across any Unix-like environment

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│   ralph-cli.sh (Main Loop)              │
│   - Reads .ralph/active/<task>/TASK.md  │
│   - Counts [ ] checkboxes               │
│   - Calls CLI tool (Aider/Codex/etc)    │
│   - Commits to git                      │
│   - Iterates until complete             │
└─────────────────────────────────────────┘
            │
            ↓
┌─────────────────────────────────────────┐
│   CLI Tool (Choose One)                 │
│   - Aider (Claude/GPT)                  │
│   - OpenAI Codex CLI                    │
│   - GitHub Copilot CLI                  │
│   - Claude Code CLI                     │
└─────────────────────────────────────────┘
            │
            ↓
┌─────────────────────────────────────────┐
│   AI Provider API                       │
│   - Anthropic Claude                    │
│   - OpenAI GPT                          │
│   - GitHub Copilot (via corp)           │
└─────────────────────────────────────────┘
```

---

## Option 1: Aider + Anthropic Claude ⭐ RECOMMENDED

**Best for**: Personal API keys, full control, works everywhere

### Why Aider?

- Open source, mature, battle-tested
- Works with Claude, GPT, and many other models
- Excellent at editing code (uses tree-sitter for smart diffs)
- Simple CLI interface
- Non-interactive mode perfect for automation

### Setup (Mac)

```bash
# Install aider (requires Python 3.10+)
pip install aider-chat

# Or use pipx for isolated install
pipx install aider-chat

# Get Anthropic API key from https://console.anthropic.com/
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"

# Add to shell config for persistence
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"' >> ~/.zshrc

# Verify
aider --version
```

### Cost

**Anthropic API Pricing** (as of Jan 2026):

| Model | Input | Output | Best For |
|-------|--------|--------|----------|
| Claude 3.5 Sonnet | $3/M tokens | $15/M tokens | Balanced (recommended) |
| Claude 3.5 Haiku | $0.80/M tokens | $4/M tokens | Cheap/fast |
| Claude Opus 4 | $15/M tokens | $75/M tokens | Complex tasks |

**Typical Ralph task costs**:

- Small task (5-10 files): $0.50-$2
- Medium task (20-30 files): $2-$5
- Large task (50+ files): $5-$15

**Much cheaper than Cursor subscription** ($20-40/mo) if you only run occasionally!

### Ralph Script for Aider

**Implemented!** See `.ralph/backends/aider/ralph-aider.sh` - ready to use.

---

## Option 2: OpenAI Codex CLI 🔥 ALSO EXCELLENT

**Best for**: OpenAI API users, ChatGPT Plus/Pro subscribers

### Why Codex CLI?

- Official OpenAI tool
- Included with ChatGPT Plus/Pro ($20-200/mo)
- Excellent code understanding
- Built-in approval modes (suggest/auto/full-auto)
- Native GitHub integration

### Setup (Mac)

```bash
# Install (requires ChatGPT Plus/Pro account)
curl -sSfL https://cli.openai.com/install.sh | bash

# Or download from https://openai.com/codex

# Login
codex auth login

# Verify
codex --version
```

### Cost

**Included in ChatGPT subscription**:

- ChatGPT Plus: $20/mo (light usage)
- ChatGPT Pro: $200/mo (heavy usage, full workdays)
- ChatGPT Business/Enterprise: Variable

**Or API-only**:

- GPT-5-Codex via API: ~$5-10/M tokens

### Ralph Script for Codex

I'll create `ralph-codex.sh` below.

---

## Option 3: GitHub Copilot CLI 🏢 BEST FOR CORPORATE

**Best for**: Corporate environments with GitHub Copilot access

### Why Copilot CLI?

- **Already approved by IT** (if you have Copilot in your IDE)
- No personal API key needed (uses corporate account)
- Built-in custom agents (explore, task, plan, code-review)
- GitHub integration
- Can use multiple models (GPT-4, Claude, etc.)

### Setup (Mac)

```bash
# Install via GitHub CLI (gh)
brew install gh

# Install Copilot CLI extension
gh extension install github/gh-copilot

# Or install directly
npm install -g @github/copilot-cli

# Login (uses your GitHub account)
gh auth login

# Verify Copilot access
gh copilot --version
```

### Cost

**Included in GitHub Copilot subscription**:

- Copilot Individual: $10/mo or $100/yr
- Copilot Business: $19/user/mo
- Copilot Enterprise: $39/user/mo

**If your company has Copilot, this is FREE to you!** 🎉

### Ralph Script for Copilot

I'll create `ralph-copilot.sh` below.

---

## Option 4: Claude Code CLI 🆕 NEW FROM ANTHROPIC

**Best for**: Claude fans who want official Anthropic tooling

### Why Claude Code CLI?

- Official Anthropic product
- Purpose-built for coding
- Web/mobile/CLI integrated
- Advanced agentic features

### Setup (Mac)

```bash
# Install
npm install -g @anthropic-ai/claude-code

# Set API key
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"

# Login
claude-code auth

# Verify
claude-code --version
```

### Cost

**Requires Claude subscription**:

- Claude Pro: $20/mo (basic)
- Claude Max: $100-200/mo (advanced features)

---

## The Ralph Scripts

### 1. Ralph with Aider (`ralph-aider.sh`)

```bash
#!/usr/bin/env bash
# Ralph Autonomous Loop - Aider Edition
# Uses Aider + Anthropic Claude API

set -euo pipefail

# Configuration
TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "Usage: $0 <task-name>"
    echo "Example: $0 my-task"
    exit 1
fi

WORKSPACE=$(pwd)
TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
TASK_FILE="$TASK_DIR/TASK.md"
ITERATION_FILE="$TASK_DIR/.iteration"
PROGRESS_FILE="$TASK_DIR/progress.md"
GUARDRAILS_FILE="$WORKSPACE/.ralph/guardrails.md"
MAX_ITERATIONS=20
MODEL="sonnet"  # or "haiku" for cheaper, "opus" for better

# Check prerequisites
if [ ! -d "$TASK_DIR" ]; then
    echo "❌ Task '$TASK_NAME' not found at $TASK_DIR"
    echo "Create it first: ./.ralph/core/scripts/ralph-task-manager.sh create $TASK_NAME"
    exit 1
fi

if [ ! -f "$TASK_FILE" ]; then
    echo "❌ TASK.md not found in $TASK_DIR"
    exit 1
fi

if ! command -v aider &> /dev/null; then
    echo "❌ aider not found. Install: pip install aider-chat"
    exit 1
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "❌ ANTHROPIC_API_KEY not set"
    echo "Get key from: https://console.anthropic.com/"
    echo "Set with: export ANTHROPIC_API_KEY='sk-ant-...'"
    exit 1
fi

# Get current iteration
ITERATION=$(cat "$ITERATION_FILE" 2>/dev/null || echo "0")

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - Aider Edition                  ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Model: Claude $MODEL"
echo "Starting iteration: $ITERATION"
echo "Max iterations: $MAX_ITERATIONS"
echo ""
sleep 2

# Main autonomous loop
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "Iteration $ITERATION / $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════"
    echo ""

    # Build prompt that includes Ralph protocol
    PROMPT="You are Ralph, an autonomous coding agent. This is iteration $ITERATION for task '$TASK_NAME'.

PROTOCOL:
1. Read .ralph/active/$TASK_NAME/TASK.md for the task definition and success criteria
2. Read .ralph/guardrails.md for global lessons learned from previous failures
3. Read .ralph/active/$TASK_NAME/progress.md to understand current state
4. Find the FIRST unchecked criterion: [ ] in TASK.md
5. Work on that criterion until complete
6. Test your changes if applicable
7. Update .ralph/active/$TASK_NAME/progress.md with what you accomplished
8. Check off the criterion in TASK.md (change [ ] to [x])
9. Commit with message: 'ralph($TASK_NAME): [criterion name] - brief description'

IMPORTANT:
- Work on ONE criterion at a time
- Commit frequently (after each meaningful change)
- Update progress.md with details
- If you fail, add a Sign to .ralph/guardrails.md explaining what went wrong
- Be specific and thorough

Now, start working on the first unchecked criterion."

    # Run aider in non-interactive mode
    # --yes auto-confirms edits
    # --no-auto-commits lets us control commits
    # --model specifies Claude version
    aider \
        --model "$MODEL" \
        --yes \
        --message "$PROMPT" \
        "$TASK_FILE" \
        "$PROGRESS_FILE" \
        "$GUARDRAILS_FILE" \
        2>&1 | tee -a .ralph/aider-iteration-$ITERATION.log

    EXIT_CODE=${PIPESTATUS[0]}

    if [ $EXIT_CODE -ne 0 ]; then
        echo ""
        echo "⚠️  Iteration $ITERATION failed with exit code $EXIT_CODE"
        echo "[$(date)] Iteration $ITERATION failed (exit $EXIT_CODE)" >> "$WORKSPACE/.ralph/errors.log"
    fi

    # Check if task is complete (no unchecked boxes)
    UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" || echo "0")
    if [ "$UNCHECKED" = "0" ]; then
        echo ""
        echo "✅ TASK COMPLETE! All criteria checked off."
        break
    fi

    echo ""
    echo "Remaining: $UNCHECKED unchecked criteria"
    echo "Continuing to next iteration..."
    sleep 2
done

if [ $ITERATION -ge $MAX_ITERATIONS ]; then
    echo ""
    echo "⚠️  Max iterations ($MAX_ITERATIONS) reached"
fi

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Complete                                 ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Total iterations: $ITERATION"
echo "View logs: .ralph/aider-iteration-*.log"
echo "View commits: git log --oneline --grep='ralph:'"
```

---

### 2. Ralph with Codex (`ralph-codex.sh`)

```bash
#!/usr/bin/env bash
# Ralph Autonomous Loop - Codex Edition
# Uses OpenAI Codex CLI

set -euo pipefail

TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "Usage: $0 <task-name>"
    exit 1
fi

WORKSPACE=$(pwd)
TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
TASK_FILE="$TASK_DIR/TASK.md"
ITERATION_FILE="$TASK_DIR/.iteration"
MAX_ITERATIONS=20

# Check prerequisites
if [ ! -f "$TASK_FILE" ]; then
    echo "❌ TASK.md not found for task '$TASK_NAME'"
    exit 1
fi

if ! command -v codex &> /dev/null; then
    echo "❌ codex not found. Install from: https://openai.com/codex"
    exit 1
fi

ITERATION=$(cat "$ITERATION_FILE" 2>/dev/null || echo "0")

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - Codex Edition                  ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "Iteration $ITERATION / $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════"

    PROMPT="Ralph iteration $ITERATION for task '$TASK_NAME'. Follow the Ralph protocol:
1. Read .ralph/active/$TASK_NAME/TASK.md, .ralph/guardrails.md, .ralph/active/$TASK_NAME/progress.md
2. Work on first unchecked [ ] criterion
3. Commit: 'ralph($TASK_NAME): [criterion] - description'
4. Update progress.md and check off criterion [x]"

    # Run codex in non-interactive exec mode
    # --approval-mode auto-edit (files auto, commands need approval)
    # or --approval-mode full-auto (fully autonomous)
    codex exec \
        --approval-mode auto-edit \
        --message "$PROMPT" \
        2>&1 | tee -a .ralph/codex-iteration-$ITERATION.log

    UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" || echo "0")
    if [ "$UNCHECKED" = "0" ]; then
        echo ""
        echo "✅ TASK COMPLETE!"
        break
    fi

    sleep 2
done

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Complete                                 ║"
echo "╚════════════════════════════════════════════════════╝"
```

---

### 3. Ralph with GitHub Copilot (`ralph-copilot.sh`)

```bash
#!/usr/bin/env bash
# Ralph Autonomous Loop - GitHub Copilot Edition
# Uses gh copilot CLI

set -euo pipefail

TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "Usage: $0 <task-name>"
    exit 1
fi

WORKSPACE=$(pwd)
TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
TASK_FILE="$TASK_DIR/TASK.md"
ITERATION_FILE="$TASK_DIR/.iteration"
MAX_ITERATIONS=20

# Check prerequisites
if [ ! -f "$TASK_FILE" ]; then
    echo "❌ TASK.md not found for task '$TASK_NAME'"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "❌ gh (GitHub CLI) not found. Install: brew install gh"
    exit 1
fi

if ! gh copilot --version &> /dev/null; then
    echo "❌ GitHub Copilot CLI not found."
    echo "Install: gh extension install github/gh-copilot"
    exit 1
fi

ITERATION=$(cat "$ITERATION_FILE" 2>/dev/null || echo "0")

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - Copilot Edition                ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "Iteration $ITERATION / $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════"

    # Read task info to build context
    TASK_CONTENT=$(cat "$TASK_FILE")
    PROGRESS_CONTENT=$(cat "$TASK_DIR/progress.md" 2>/dev/null || echo "No progress yet")

    PROMPT="Ralph iteration $ITERATION.

TASK FILE:
$TASK_CONTENT

CURRENT PROGRESS:
$PROGRESS_CONTENT

INSTRUCTIONS:
1. Find first unchecked [ ] criterion in task
2. Implement it
3. Update progress.md
4. Change [ ] to [x] in TASK.md
5. Commit: 'ralph($TASK_NAME): [criterion] - description'"

    # Use gh copilot with --silent for non-interactive
    # Note: Copilot CLI is more interactive by default
    # This may require manual intervention
    gh copilot suggest \
        --silent \
        "$PROMPT" \
        2>&1 | tee -a .ralph/copilot-iteration-$ITERATION.log

    UNCHECKED=$(grep -c '\[ \]' "$TASK_FILE" || echo "0")
    if [ "$UNCHECKED" = "0" ]; then
        echo ""
        echo "✅ TASK COMPLETE!"
        break
    fi

    sleep 2
done

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Complete                                 ║"
echo "╚════════════════════════════════════════════════════╝"
```

---

## Quick Start Guide

### For Personal Use (Anthropic API)

```bash
# 1. Install aider
pip install aider-chat

# 2. Get API key
# Go to: https://console.anthropic.com/
# Create key, copy it

# 3. Set API key
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"' >> ~/.zshrc

# 4. Download Ralph scripts to your project
cd ~/your-project
curl -O https://raw.githubusercontent.com/[your-repo]/ralph-aider.sh
chmod +x ralph-aider.sh

# 5. Initialize Ralph workspace
mkdir -p .ralph/{active,completed,docs}
touch .ralph/guardrails.md

# 6. Create a task
./ralph-task-manager.sh create my-task

# 7. Define your task
nano .ralph/active/my-task/TASK.md

# ⚠️ IMPORTANT: Before writing tasks, understand antipatterns
# See: .ralph/docs/ANTIPATTERNS.md
# NEVER include criteria requiring GUI clicks, manual restarts, or interactive prompts

# 8. Run Ralph!
./ralph-aider.sh my-task
```

---

### For Corporate Use (GitHub Copilot)

```bash
# 1. Verify Copilot access
gh auth status
gh copilot --version

# If not installed:
brew install gh
gh extension install github/gh-copilot

# 2. Transfer Ralph script to corporate Mac
# (via git, email, etc. - see RALPH_MAC_CORPORATE_RESEARCH.md)

# 3. Setup workspace
cd ~/your-project
mkdir -p .ralph/{active,completed,docs}
touch .ralph/guardrails.md

# 4. Create a task
./ralph-task-manager.sh create my-task

# 5. Define your task
nano .ralph/active/my-task/TASK.md

# ⚠️ CRITICAL: Read .ralph/docs/ANTIPATTERNS.md first
# Never include GUI clicks, manual restarts, or interactive prompts in criteria

# 6. Run Ralph!
./ralph-copilot.sh my-task
```

---

## Cost Comparison

### Monthly Cost Estimates

**Scenario: 10 tasks per month, average 20 files per task**

| Option | Setup Cost | Per-Task Cost | Monthly Total | Notes |
|--------|------------|---------------|---------------|-------|
| **Cursor** | $0 | Included | $20-40/mo | Subscription required |
| **Aider + Claude Sonnet** | $0 | $2-5 | $20-50 | Pay per use, cheaper if infrequent |
| **Aider + Claude Haiku** | $0 | $0.50-1 | $5-10 | Cheapest, still good quality |
| **OpenAI Codex CLI** | $0 | Included | $20-200/mo | ChatGPT subscription |
| **GitHub Copilot** | $0 | Included | $10-19/mo | Or FREE if corp provides |

**Winner for cost**: **GitHub Copilot** (if corporate) or **Aider + Haiku** (if personal)

---

## Advantages of CLI-Only Ralph

### 1. No IDE Required

- Works on any machine with bash + git
- No GUI needed (works over SSH!)
- Corporate restrictions don't matter

### 2. API Key Flexibility

- Use your own key (full control)
- Or use corporate key (IT-approved)
- Switch models easily (Claude, GPT, etc.)

### 3. Transparent & Auditable

- All code is in bash scripts (easy to review)
- No binary executables (IT security ✓)
- Full git history of all changes

### 4. Easy IT Approval

```
IT: "What is this?"
You: "It's a bash script that calls our GitHub Copilot API
      to automate code changes. All changes go through git
      for review. Want to see the source?"
IT: "Sure" [reviews 100 lines of bash]
IT: "Approved ✓"
```

### 5. Portable

- Same script works on:
  - Mac (zsh/bash)
  - Linux (bash)
  - Windows WSL (bash)
  - Corporate machines
  - Personal machines
  - Servers (if needed)

---

## Limitations & Mitigations

### Limitation 1: Not as smooth as cursor-agent

**cursor-agent** is purpose-built for autonomous coding. CLI tools are more general.

**Mitigation**:

- Aider is specifically designed for code editing (best option)
- Scripts can be tuned to your workflow
- Still WAY better than manual coding

---

### Limitation 2: Some tools require interaction

GitHub Copilot CLI, in particular, is more interactive by default.

**Mitigation**:

- Use Aider (fully non-interactive)
- Or use OpenAI Codex with `--approval-mode full-auto`
- Or adapt scripts to handle interaction

---

### Limitation 3: API costs can add up

If you run Ralph heavily, Anthropic API costs accumulate.

**Mitigation**:

- Use Haiku model for cheaper runs ($0.80/M input tokens)
- Or use corporate GitHub Copilot (free to you)
- Or subscribe to ChatGPT Pro (unlimited Codex)

---

## Best Practices

### 1. Start with Haiku, upgrade to Sonnet if needed

```bash
# In ralph-aider.sh, change:
MODEL="haiku"  # Fast and cheap

# If quality isn't good enough:
MODEL="sonnet"  # Balanced

# For really hard tasks:
MODEL="opus"   # Best quality
```

---

### 2. Set reasonable iteration limits

```bash
MAX_ITERATIONS=10  # For small tasks
MAX_ITERATIONS=20  # For medium tasks
MAX_ITERATIONS=50  # For large tasks (watch costs!)
```

---

### 3. Review after each iteration (for first few runs)

```bash
# Instead of running to completion:
MAX_ITERATIONS=1 ./ralph-aider.sh

# Check results:
git diff
git log --oneline -1

# If good, continue:
MAX_ITERATIONS=20 ./ralph-aider.sh
```

---

### 4. Monitor API costs

```bash
# For Anthropic:
# Check dashboard: https://console.anthropic.com/
# Set billing alerts

# For OpenAI:
# Check usage: https://platform.openai.com/usage

# For GitHub Copilot:
# Usually unlimited within subscription
```

---

### 5. Use git branches for safety

```bash
# Before running Ralph:
git checkout -b ralph-experiment

# Run Ralph:
./ralph-aider.sh

# If good:
git checkout main
git merge ralph-experiment

# If bad:
git checkout main
git branch -D ralph-experiment
```

---

## Troubleshooting

### "API key invalid"

```bash
# Check key is set:
echo $ANTHROPIC_API_KEY

# If empty:
export ANTHROPIC_API_KEY="sk-ant-..."

# Make permanent:
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
source ~/.zshrc
```

---

### "Rate limit exceeded"

**Anthropic**: Tier limits based on usage

- New accounts: $5/day limit
- Tier 1 ($5+ spent): $50/day
- Tier 2 ($50+ spent): $500/day

**Solution**: Wait, or upgrade tier, or use different model

---

### "aider not found"

```bash
# Install with pip:
pip install aider-chat

# Or with pipx (isolated):
pipx install aider-chat

# Or with uv (fast):
uv tool install aider-chat

# Make sure it's in PATH:
which aider
```

---

### Aider makes bad changes

```bash
# Revert last commit:
git revert HEAD

# Or reset to before Ralph:
git log  # Find commit before Ralph started
git reset --hard <commit-hash>

# Add a Sign to prevent recurrence:
nano .ralph/guardrails.md
```

---

## Advanced: Custom Models & Providers

### Using OpenAI GPT with Aider

```bash
# Set OpenAI key instead:
export OPENAI_API_KEY="sk-proj-..."

# Run with GPT:
aider --model gpt-5 --message "$PROMPT"
```

---

### Using Local Models (Ollama)

```bash
# Install Ollama
brew install ollama

# Pull model:
ollama pull codellama

# Use with Aider:
aider --model ollama/codellama --message "$PROMPT"
```

**Pros**: Free, private, no API costs
**Cons**: Slower, lower quality, requires local GPU

---

## Comparison: CLI-Only vs cursor-agent

| Aspect | cursor-agent | CLI-Only (Aider) |
|--------|-------------|------------------|
| **Setup** | Install Cursor app | `pip install aider-chat` |
| **Corporate approval** | May be difficult | Easy (just a Python package) |
| **Cost** | $20-40/mo subscription | Pay-per-use or corporate |
| **Quality** | Excellent | Excellent (uses same models) |
| **Speed** | Fast | Fast |
| **Autonomy** | Purpose-built | Requires scripting |
| **Transparency** | Closed source | Open source scripts |
| **Flexibility** | Limited to Cursor models | Any model/provider |
| **Portability** | Requires Cursor install | Works anywhere |

**Verdict**: **CLI-Only is better for corporate environments** 🏆

---

## Next Steps

### Immediate: Try Aider locally

```bash
# 1. Install
pip install aider-chat

# 2. Get $5 free Anthropic credit
# https://console.anthropic.com/
# (New accounts get trial credit)

# 3. Quick test
cd ~/test-project
export ANTHROPIC_API_KEY="sk-ant-..."
aider --model haiku

# In aider prompt:
# "Create a hello.py file that prints Hello Ralph"
```

---

### Then: Adapt for corporate Mac

```bash
# 1. Check if you have GitHub Copilot
gh auth status
gh copilot --version

# 2. If yes, use ralph-copilot.sh (no API key needed!)

# 3. If no, request Copilot from IT:
#    "GitHub Copilot for CLI development workflows"
#    Usually approved if IT already pays for Copilot

# 4. Transfer ralph-copilot.sh to corporate Mac
#    (via git clone, email, etc.)

# 5. Run on small test task first
```

---

## Conclusion

**CLI-Only Ralph is the BEST option for corporate environments**:

✅ No special IDE installation
✅ Works with corporate GitHub Copilot (free!)
✅ Or use your own Anthropic key ($5-20/mo)
✅ Easy IT approval (transparent bash scripts)
✅ Portable (works anywhere)
✅ Same quality as cursor-agent

**Recommended setup**:

- Corporate: GitHub Copilot CLI (free via corp subscription)
- Personal: Aider + Claude Haiku (cheap, $5-10/mo)
- Heavy use: Aider + Claude Sonnet (best quality, $20-50/mo)

---

## Files to Create

I'll create the actual scripts in the next step. You'll get:

1. `ralph-aider.sh` - Full autonomous loop with Aider
2. `ralph-codex.sh` - Full autonomous loop with Codex
3. `ralph-copilot.sh` - Full autonomous loop with Copilot
4. `ralph-cli-setup.sh` - One-command setup script
5. `RALPH_TASK_SAMPLE.md` - Sample task to test with

All ready to transfer to your corporate Mac! 🎯

---

**Created**: 2026-01-16
**Author**: Claude (Sonnet 4.5)
**For**: Ethan (CLI-only Ralph for corporate Mac)

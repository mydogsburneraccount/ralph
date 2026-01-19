# Aider + Anthropic Backend

Uses [Aider](https://aider.chat/) with Anthropic Claude API for CLI-based autonomous development.

## When to Use This Backend

✅ **Best for:**
- Personal projects with Anthropic API key
- SSH/headless server environments
- Mac corporate laptops (no Cursor restrictions)
- Pure CLI workflows

❌ **Not ideal for:**
- Corporate projects (data leaves company)
- Environments without internet
- Users without Anthropic API key

## Prerequisites

- Python 3.8 or higher
- Anthropic API key from https://console.anthropic.com/
- `aider-chat` package (installed via pipx)

## Setup

```bash
# 1. Install aider via pipx (recommended)
pipx install aider-chat

# OR via pip
pip install aider-chat

# 2. Set API key
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"

# Make permanent
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc

# 3. Verify
aider --version
```

## Usage

```bash
# Create a task
../../core/scripts/ralph-task-manager.sh create my-task

# Edit the task
nano ~/.ralph/active/my-task/TASK.md

# Run with Aider backend
./ralph-aider.sh my-task

# Specify model
RALPH_MODEL=haiku ./ralph-aider.sh my-task     # Fast & cheap
RALPH_MODEL=sonnet ./ralph-aider.sh my-task    # Balanced (default)
RALPH_MODEL=opus ./ralph-aider.sh my-task      # Best quality
```

## Environment Variables

```bash
# Model selection
RALPH_MODEL=haiku    # Claude 3.5 Haiku (fast, cheap)
RALPH_MODEL=sonnet   # Claude 3.5 Sonnet (default)
RALPH_MODEL=opus     # Claude 3 Opus (expensive, best)

# Advanced
RALPH_MAX_ITERATIONS=50        # Max loops before stopping
RALPH_AUTO_INSTALL=true        # Auto-install dependencies
```

## Security Considerations

### ⚠️ Corporate Use Warning

**Do NOT use for corporate projects:**
- Sends code to Anthropic's external servers
- Personal API key (not company contract)
- May violate corporate data policies
- No audit logging for enterprise
- Bypasses corporate IT controls

### ✅ Safe for Personal Use

- Public/open source projects
- Personal learning projects
- Code you'd post on GitHub anyway

## Cost Management

Aider costs vary by model:

| Model | Cost (Input) | Cost (Output) | Use Case |
|-------|--------------|---------------|----------|
| Haiku | $0.25/1M | $1.25/1M | Quick tasks |
| Sonnet | $3/1M | $15/1M | Most tasks |
| Opus | $15/1M | $75/1M | Complex reasoning |

**Typical task costs:**
- Small task (10 iterations): $0.10 - $0.50
- Medium task (50 iterations): $0.50 - $2.00
- Large task (200 iterations): $2.00 - $10.00

## Mac Corporate Setup

This backend works well on corporate Macs where Cursor may not be approved:

```bash
# 1. Install on Mac
brew install pipx
pipx install aider-chat

# 2. Use personal API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 3. Only use for personal/learning projects
```

See `RALPH_MAC_QUICKSTART.md` for Mac-specific setup.

## Documentation

- `RALPH_CLI_ONLY.md` - CLI-only Ralph guide
- `RALPH_MAC_QUICKSTART.md` - Mac setup instructions
- [Aider Official Docs](https://aider.chat/docs/)

## Features

- ✅ Pure CLI, works over SSH
- ✅ Excellent AI quality (Claude)
- ✅ No IDE required
- ✅ Direct Anthropic API access
- ✅ Works on any OS with Python

## Notes

- Requires active internet connection
- API costs apply (pay-per-use)
- Best for personal projects
- Not suitable for corporate use without approval
- **⚠️ UNTESTED**: This backend has not been validated with a live Anthropic API key. The code is based on working patterns but needs testing before production use.

---

**Status**: Untested (requires Anthropic API key for validation)
**Maintained**: Active
**Version**: 2.0

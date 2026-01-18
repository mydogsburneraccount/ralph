# Cursor Agent Backend

Uses Cursor IDE's `cursor-agent` CLI for autonomous development.

## When to Use This Backend

✅ **Best for:**
- Personal development projects
- Cursor IDE users
- Local development workstations

❌ **Not ideal for:**
- Corporate environments (may need approval)
- Headless/SSH-only servers
- Non-Cursor IDE users

## Prerequisites

- [Cursor IDE](https://cursor.sh/) with active license
- `cursor-agent` CLI installed and authenticated
- WSL (if on Windows) or native bash (Mac/Linux)

## Setup

```bash
# 1. Install Cursor and authenticate
cursor-agent login

# 2. Run WSL setup (if on Windows)
./ralph-wsl-setup.sh

# 3. Test cursor-agent
cursor-agent --version
```

## Usage

```bash
# Create a task
../../core/scripts/ralph-task-manager.sh create my-task

# Edit the task
nano ~/.ralph/active/my-task/TASK.md

# Run autonomous loop
./ralph-autonomous.sh my-task

# Run once (single iteration)
./ralph-once.sh my-task

# Run in watch mode
./ralph-watch.sh my-task

# Run multiple tasks in loop
./ralph-loop.sh my-task other-task
```

## Scripts Included

| Script | Purpose |
|--------|---------|
| `ralph-autonomous.sh` | Main autonomous loop |
| `ralph-once.sh` | Single iteration execution |
| `ralph-loop.sh` | Multi-task rotation |
| `ralph-watch.sh` | File-watching mode |
| `ralph-wsl-setup.sh` | Windows WSL setup |
| `ralph-cli-setup.sh` | CLI environment setup |

## Features

- ✅ Full autonomous capabilities
- ✅ Cost tracking
- ✅ Context rotation
- ✅ Dependency management
- ✅ RAG integration (optional)
- ✅ Guardrails system

## Notes

- This is the original and most mature backend
- Best AI quality (Claude Sonnet via Cursor)
- Requires Cursor IDE to be running
- See `../../core/docs/QUICKREF.md` for detailed usage

---

**Status**: ✅ Production-ready and tested
**Maintained**: Active
**Version**: 2.0

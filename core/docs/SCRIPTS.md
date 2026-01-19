# Ralph Scripts Reference

> **Scripts are organized by function:**
> - Core scripts: `.ralph/core/scripts/`
> - Backend-specific scripts: `.ralph/backends/<backend>/`

## Script Locations

### Core Scripts (`.ralph/core/scripts/`)

| Script | Purpose |
|--------|---------|
| `ralph-task-manager.sh` | Create/list/archive tasks |
| `ralph-switch-task.sh` | Switch between active tasks |
| `ralph-rollback.sh` | Rollback task changes |
| `ralph-common.sh` | Shared functions |
| `ralph-base-toolset.sh` | Install base development tools |
| `ralph-setup.sh` | Initial setup |
| `init-ralph.sh` | Initialize new task |

### Cursor-Agent Backend (`.ralph/backends/cursor-agent/`)

| Script | Purpose |
|--------|---------|
| `ralph-autonomous.sh` | Main autonomous iteration loop |
| `ralph-once.sh` | Single iteration execution |
| `ralph-loop.sh` | Multi-iteration loop |
| `ralph-watch.sh` | File watcher |
| `ralph-wsl-setup.sh` | WSL-specific setup |
| `ralph-cli-setup.sh` | CLI-only setup |

### Aider Backend (`.ralph/backends/aider/`)

| Script | Purpose |
|--------|---------|
| `ralph-aider.sh` | Aider-based iteration loop |
| `ralph-mac-setup.sh` | macOS setup for Aider |

### Copilot Backend (`.ralph/backends/copilot-cli/`)

| Script | Purpose |
|--------|---------|
| `ralph-copilot.sh` | Copilot CLI iteration loop |

## Quick Reference

```bash
# List active tasks
./.ralph/core/scripts/ralph-task-manager.sh list

# Create new task
./.ralph/core/scripts/ralph-task-manager.sh create <task-name>

# Run autonomous loop (Cursor backend)
./.ralph/backends/cursor-agent/ralph-autonomous.sh <task-name>

# Run with Aider backend
./.ralph/backends/aider/ralph-aider.sh <task-name>
```

See `.ralph/core/docs/INDEX.md` for full documentation.

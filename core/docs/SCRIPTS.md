# Ralph Scripts Reference

> **Scripts location**: `.ralph/scripts/`

Ralph scripts are intentionally kept in `.ralph/scripts/` for Cursor IDE integration.

## Script Categories

### Core Workflow
- `ralph-autonomous.sh` - Main autonomous iteration loop
- `ralph-once.sh` - Single iteration execution
- `ralph-loop.sh` - Multi-iteration loop

### Task Management
- `ralph-task-manager.sh` - Create/list/archive tasks
- `ralph-switch-task.sh` - Switch between active tasks

### Setup
- `ralph-setup.sh` - Initial setup
- `ralph-wsl-setup.sh` - WSL-specific setup
- `ralph-mac-setup.sh` - macOS setup
- `ralph-cli-setup.sh` - CLI-only setup
- `init-ralph.sh` - Initialize new task

### Utilities
- `ralph-common.sh` - Shared functions
- `ralph-watch.sh` - File watcher
- `ralph-aider.sh` - Aider integration

## Quick Reference

```bash
# List active tasks
./.ralph/scripts/ralph-task-manager.sh list

# Create new task
./.ralph/scripts/ralph-task-manager.sh create <task-name>

# Run single iteration
./.ralph/scripts/ralph-once.sh <task-name>

# Run autonomous loop
./.ralph/scripts/ralph-autonomous.sh <task-name>
```

See `.ralph/scripts/README.md` for full documentation.

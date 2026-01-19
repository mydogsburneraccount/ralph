# ralph-copilot.sh Design Document

**Version**: 1.0  
**Date**: 2026-01-17  
**Status**: Design Phase - UNTESTED (requires Copilot license)

---

## Executive Summary

This document outlines the design for `ralph-copilot.sh`, a corporate-friendly alternative backend for Ralph autonomous loops using GitHub Copilot CLI instead of Aider + Anthropic API.

**Key Decision**: Use **ACP Mode (Approach B)** as the primary integration method, with **MCP Server Bridge (Approach C)** as a future enhancement option.

---

## Integration Approach Decision

### Selected: Approach B - ACP Mode Integration

```bash
copilot --acp
```

**Why ACP Mode?**

| Factor | ACP Mode | CLI Wrapping | MCP Bridge |
|--------|----------|--------------|------------|
| Programmatic Control | ✅ Full | ❌ Limited | ✅ Full |
| Structured Responses | ✅ JSON | ❌ Text | ✅ Native |
| Permission Handling | ✅ Built-in | ❌ None | ⚠️ Custom |
| Implementation Complexity | Medium | Low | High |
| Documentation | ⚠️ Evolving | ✅ Stable | ⚠️ Custom |
| Production Ready | ⚠️ Issues #989 | ✅ Yes | ❌ Needs dev |

**Fallback Strategy**: If ACP mode proves unreliable during testing, fall back to simple CLI wrapping with `echo "$PROMPT" | copilot`.

### Alternative: Approach C - MCP Server (Future)

The `@trishchuk/copilot-mcp-server` package provides non-interactive automation. Consider for v2 if ACP proves problematic.

---

## Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       ralph-copilot.sh                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐    │
│  │ Task Parser  │──▶│ ACP Client   │──▶│ Copilot CLI      │    │
│  │ (TASK.md)    │   │ (subprocess) │   │ (--acp mode)     │    │
│  └──────────────┘   └──────────────┘   └──────────────────┘    │
│         │                  │                    │               │
│         ▼                  ▼                    ▼               │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐    │
│  │ Progress     │   │ Permission   │   │ GitHub Copilot   │    │
│  │ Tracker      │   │ Handler      │   │ API              │    │
│  └──────────────┘   └──────────────┘   └──────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

1. **Task Parser**: Reads TASK.md, extracts unchecked criteria
2. **ACP Client**: Manages subprocess communication with `copilot --acp`
3. **Permission Handler**: Auto-approves safe operations, prompts for risky ones
4. **Progress Tracker**: Updates progress.md, iteration counts, activity logs

---

## Prompt Strategy

### Context Injection

Since Copilot CLI doesn't yet support `.prompt.md` files (#1004), we'll use:

1. **Project Instructions**: `.github/copilot-instructions.md` for static context
2. **Dynamic Prompt**: Pass TASK.md content via ACP message

### Project Instructions File

Create `.github/copilot-instructions.md`:

```markdown
# Project Instructions for Copilot

## Ralph Protocol

This project uses the Ralph task management system. When executing Ralph tasks:

1. Read TASK.md in the task directory for criteria
2. Read guardrails.md for lessons learned (Signs)
3. Read progress.md for current state
4. Complete ONE criterion per iteration
5. Commit with message: ralph(<task>): [criterion] - change
6. Update progress.md and check off criterion
7. Commit state files

## Coding Standards

- Python 3.10+ with type hints
- Use pathlib, not os.path
- Ruff formatter (88 char lines)
- Google-style docstrings

## File Safety

- NEVER delete files - archive to _archive/
- Create backups before modifying config files
- Verify changes before claiming completion
```

### Dynamic Prompt Template

```python
PROMPT_TEMPLATE = """
Execute Ralph iteration {iteration} for task: {task_name}

## Current Task
{task_content}

## Guardrails (Signs)
{guardrails_content}

## Progress
{progress_content}

## Instructions

1. Find the FIRST unchecked [ ] criterion in the task
2. Complete ONLY that criterion
3. Run verification commands to confirm success
4. Commit changes: git commit -m 'ralph({task_name}): [criterion] - change'
5. Update progress.md with what was done
6. Check off the criterion with [x]
7. Commit state files: git commit -m 'ralph({task_name}): state update'

Focus on: {next_criterion}
"""
```

### File Editing Strategy

Copilot CLI supports file editing natively via its agentic capabilities. The script will:

1. Grant file edit permissions for task directory
2. Allow git operations
3. Require confirmation for operations outside task directory

### Verification Strategy

After each criterion:

```bash
# Check criterion is marked complete
grep -q '\[x\].*{criterion}' TASK.md

# Check progress was updated
grep -q "$(date +%Y-%m-%d)" progress.md

# Check commit was made
git log -1 --grep="ralph($TASK_NAME):" --oneline
```

### Loop Detection

To prevent infinite loops on stuck criteria:

```python
STUCK_THRESHOLD = 3  # Max attempts on same criterion

def detect_stuck():
    # If same criterion attempted 3 times, escalate
    if criterion_attempts[current_criterion] >= STUCK_THRESHOLD:
        log_warning(f"Stuck on criterion: {current_criterion}")
        add_to_guardrails(f"Criterion '{current_criterion}' caused loop")
        return True
    return False
```

---

## Error Handling

### Rate Limit Handling

```python
class RateLimitError(Exception):
    pass

def handle_rate_limit(response):
    if "rate limit" in response.lower():
        # Log the event
        log_error("Rate limit hit")
        
        # Wait with exponential backoff
        wait_time = min(300, 30 * (2 ** retry_count))
        log_info(f"Waiting {wait_time}s before retry")
        time.sleep(wait_time)
        
        return True
    return False
```

### Network Failure Handling

```python
MAX_RETRIES = 3
RETRY_DELAYS = [5, 15, 30]  # seconds

def with_retry(func):
    for attempt, delay in enumerate(RETRY_DELAYS):
        try:
            return func()
        except ConnectionError:
            log_warning(f"Network error, retry {attempt + 1}/{MAX_RETRIES}")
            time.sleep(delay)
    raise NetworkError("Failed after max retries")
```

### Model Unavailability

```python
FALLBACK_MODELS = ["claude-sonnet-4.5", "gpt-5", "claude-4"]

def select_model():
    preferred = os.getenv("RALPH_COPILOT_MODEL", "claude-sonnet-4.5")
    
    # During testing, if model unavailable, try fallbacks
    # In production, fail fast to alert user
    if preferred not in available_models:
        if os.getenv("RALPH_COPILOT_FALLBACK", "false") == "true":
            for model in FALLBACK_MODELS:
                if model in available_models:
                    log_warning(f"Using fallback model: {model}")
                    return model
        raise ModelUnavailableError(f"Model {preferred} not available")
    
    return preferred
```

### Fallback Behavior Summary

| Error Type | Behavior |
|------------|----------|
| Rate Limit | Exponential backoff, max 5 min |
| Network | 3 retries with 5/15/30s delays |
| Model Unavailable | Fail (or fallback if enabled) |
| Auth Expired | Exit with instructions to re-auth |
| Permission Denied | Log and skip (don't auto-approve risky ops) |
| Copilot CLI Not Found | Exit with install instructions |

---

## Security Considerations

### Permission Model

```python
# Safe operations - auto-approve
SAFE_OPERATIONS = [
    "read_file",
    "write_file",  # Within task directory only
    "git_commit",
    "git_status",
    "git_diff",
]

# Risky operations - require confirmation or skip
RISKY_OPERATIONS = [
    "execute_shell",  # Except whitelisted commands
    "delete_file",
    "write_file",  # Outside task directory
    "git_push",
]

def should_auto_approve(operation, args):
    if operation in SAFE_OPERATIONS:
        if operation == "write_file":
            return args["path"].startswith(TASK_DIR)
        return True
    return False
```

### Audit Logging

All operations logged to `activity.log`:

```python
def log_operation(operation, args, approved, result):
    entry = {
        "timestamp": datetime.now().isoformat(),
        "iteration": current_iteration,
        "operation": operation,
        "args": sanitize(args),  # Remove sensitive data
        "approved": approved,
        "result": "success" if result else "failed"
    }
    activity_log.append(json.dumps(entry))
```

### Corporate Approval Checklist

```markdown
## Pre-Deployment Checklist

### IT Security
- [ ] Confirm Copilot CLI uses same data path as IDE Copilot
- [ ] Review operation permission model
- [ ] Approve audit logging format

### Compliance
- [ ] Verify data stays in GitHub/Microsoft infrastructure
- [ ] Confirm enterprise audit log access
- [ ] Review automated operation scope

### Manager
- [ ] Approve use case (autonomous development assistance)
- [ ] Acknowledge iteration limits and safety mechanisms
```

---

## Cost Tracking

Copilot uses subscription-based pricing, but we still track usage:

### Premium Request Tracking

```python
# Track premium requests for quota awareness
PREMIUM_MODELS = ["claude-sonnet-4.5", "claude-4", "gpt-5"]
FREE_MODELS = ["gpt-4.1", "gpt-5-mini", "gpt-4o"]  # 0x multiplier

def log_request(model, iteration):
    is_premium = model in PREMIUM_MODELS
    
    with open(COST_LOG, "a") as f:
        f.write(f"[{datetime.now()}] Iteration {iteration}: "
                f"model={model}, premium={is_premium}\n")
    
    if is_premium:
        increment_premium_counter()
```

### Quota Awareness

```bash
# Check remaining quota (if copilot-usage.sh available)
check_quota() {
    if command -v copilot-usage.sh &> /dev/null; then
        remaining=$(copilot-usage.sh --remaining)
        if [ "$remaining" -lt 10 ]; then
            echo "⚠️ Low premium request quota: $remaining remaining"
        fi
    fi
}
```

---

## Known Limitations

### From Research (Requires Live Testing)

| Limitation | Issue | Workaround |
|------------|-------|------------|
| ACP tool ID bugs | #989 | May need CLI fallback |
| Non-interactive context | #979 | Pass context in prompt |
| No plan mode | #934 | Manual criterion parsing |
| No prompt files | #1004 | Use project instructions |
| Auto-compact | #947 | Keep iterations focused |

### Compared to ralph-aider.sh

| Feature | ralph-aider.sh | ralph-copilot.sh |
|---------|----------------|------------------|
| Model selection | Full control | Limited to Copilot models |
| Cost model | Per-token | Subscription + quota |
| API stability | Mature | Evolving (daily releases) |
| Offline support | No | No |
| Corporate approved | No (personal API) | Yes (existing contract) |

---

## Implementation Plan

### File Structure

```
.ralph/core/scripts/
├── ralph-copilot.sh        # Main script (bash wrapper)
├── ralph-copilot/
│   ├── __init__.py
│   ├── acp_client.py       # ACP mode subprocess management
│   ├── prompt_builder.py   # Dynamic prompt construction
│   ├── permission_handler.py
│   └── progress_tracker.py
```

### Script Interface (Match ralph-aider.sh)

```bash
# Usage (same as ralph-aider.sh)
./ralph-copilot.sh <task-name>

# Environment variables
RALPH_COPILOT_MODEL=claude-sonnet-4.5|claude-4|gpt-5  # default: claude-sonnet-4.5
RALPH_COPILOT_FALLBACK=true|false                      # default: false
RALPH_COPILOT_AUTO_APPROVE=true|false                  # default: true (safe ops only)
```

### Implementation Phases

1. **Phase 5a**: Basic shell wrapper with CLI invocation
2. **Phase 5b**: Add ACP mode if stable (test on corp MacBook first)
3. **Phase 5c**: Full Python implementation with permission handling
4. **Future**: MCP server integration

---

## Testing Guide (For Corp MacBook)

### Prerequisites

```bash
# Verify copilot-cli installed
copilot --version

# Verify authentication
copilot /login

# Check available models
copilot /model
```

### Basic Testing

```bash
# Test 1: Simple prompt
echo "What files are in the current directory?" | copilot

# Test 2: File reading
copilot "Read package.json and summarize dependencies"

# Test 3: File editing (in test directory)
copilot "Create a file test.txt with 'hello world'"

# Test 4: ACP mode (if implementing Approach B)
copilot --acp  # Then send structured messages
```

### Ralph Integration Testing

```bash
# Test with simple Ralph task
./ralph-copilot.sh test-task

# Verify:
# - Task criterion completed
# - Progress updated
# - Commits made correctly
# - No errors in activity.log
```

### Comparison Testing

Run same Ralph task with both backends:

```bash
# Aider backend
RALPH_MODEL=sonnet ./ralph-aider.sh test-task

# Copilot backend
./ralph-copilot.sh test-task

# Compare:
# - Quality of completions
# - Speed
# - Reliability
# - Cost (API vs subscription)
```

---

## Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| ACP mode primary | Programmatic control, structured responses | 2026-01-17 |
| Bash wrapper first | Match existing ralph-aider.sh interface | 2026-01-17 |
| Auto-approve safe ops | Balance autonomy with safety | 2026-01-17 |
| No model fallback default | Explicit is better than implicit | 2026-01-17 |
| Track premium requests | Quota awareness for subscription plans | 2026-01-17 |

---

## References

- [RESEARCH_FINDINGS.md](./RESEARCH_FINDINGS.md) - Full research documentation
- [ralph-aider.sh](../../scripts/ralph-aider.sh) - Reference implementation
- [Copilot CLI Docs](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [ACP Issues](https://github.com/github/copilot-cli/issues?q=acp)

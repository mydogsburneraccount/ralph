# Ralph Task Writing Rules

> **Read this when writing Ralph tasks**
>
> This guide contains the core rules for writing autonomous Ralph tasks.
> For complete antipattern guide, see [ANTIPATTERNS.md](./ANTIPATTERNS.md).

---

## Critical: Task Writing Antipatterns

**BEFORE writing ANY Ralph task, read**: [ANTIPATTERNS.md](./ANTIPATTERNS.md)

NEVER include criteria requiring:

- ❌ GUI interactions (clicks, buttons, menus, tray icons)
- ❌ Manual service restarts (Docker Desktop, nginx, etc.)
- ❌ Interactive TUI/prompts (dive, interactive CLIs)
- ❌ Human approvals or decisions

---

## The Verification Test

Can Ralph verify completion by running a command and checking output?

| Answer | Result |
|--------|--------|
| **YES** | Valid criterion ✅ |
| **NO** | Invalid criterion ❌ (document it instead, or script it) |

---

## Examples

### Good Criteria

These can be verified autonomously:

```bash
# Container running
docker ps | grep myapp

# Tests pass
npm test  # exits with code 0

# File contains setting
grep "setting=value" config.json
```

### Bad Criteria

These require human interaction:

- Right-click Docker tray icon → Restart
- Open settings GUI and configure X
- Test with interactive dive tool
- Get approval from team

---

## Fix Approach for Invalid Criteria

When you identify an invalid criterion, fix it:

1. **Document it** → "Add to progress.md: Manual step required"
2. **Script it** → Create automation script, verify script exists
3. **Move it** → Separate "Manual Steps" section outside criteria
4. **Remove it** → If not essential

---

## Related Documentation

- **[ANTIPATTERNS.md](./ANTIPATTERNS.md)** - Complete antipattern guide with examples
- **[QUICKREF.md](./QUICKREF.md)** - Quick reference for Ralph operations
- **[INDEX.md](./INDEX.md)** - Index of all Ralph documentation

---

## Dependency Declaration

Ralph tasks can declare required dependencies in the TASK.md frontmatter. Ralph will automatically check and optionally install missing dependencies before starting work.

### Dependency Format

Add a `dependencies` section to your TASK.md frontmatter:

```yaml
---
dependencies:
  system:
    - docker        # System package (apt/yum/brew)
    - jq            # JSON processor
    - curl          # HTTP client
  python:
    - aider-chat    # pip install aider-chat
    - pytest>=7.0   # Version constraints supported
  npm:
    - typescript    # npm install -g typescript
    - "@types/node" # Scoped packages supported
  check_commands:
    - docker ps     # Verify docker daemon is running
    - aider --version  # Verify aider works
    - jq --version  # Verify jq installed
---
```

### Dependency Types

| Type | Package Manager | Install Command |
|------|----------------|-----------------|
| `system` | apt/yum/brew (auto-detected) | `sudo apt install <pkg>` |
| `python` | pip | `pip install <pkg>` |
| `npm` | npm | `npm install -g <pkg>` |
| `check_commands` | N/A (verification only) | Runs command to verify setup |

### Installation Behavior

Ralph's dependency management has three modes (controlled by `RALPH_AUTO_INSTALL` env var):

| Mode | Behavior |
|------|----------|
| `prompt` (default) | Ask before installing each dependency |
| `true` | Install all dependencies automatically |
| `false` | Check only, fail with instructions if missing |

### Examples

**Basic dependency declaration:**

```yaml
dependencies:
  python:
    - aider-chat
  check_commands:
    - aider --version
```

**Complex multi-language task:**

```yaml
dependencies:
  system:
    - docker
    - postgresql-client
  python:
    - pytest>=7.0
    - black
  npm:
    - typescript
    - prettier
  check_commands:
    - docker ps
    - psql --version
    - pytest --version
```

**Service verification:**

```yaml
dependencies:
  check_commands:
    - curl -f http://localhost:8080/health  # Verify local service running
    - docker ps | grep postgres  # Verify specific container
```

### Best Practices

1. **Declare all dependencies upfront** - Don't wait for failures
2. **Include verification commands** - Ensure dependencies actually work
3. **Use version constraints** - For python packages: `package>=1.0,<2.0`
4. **Test on clean environment** - Verify your dependency declarations work
5. **Document manual steps** - If something can't be automated (e.g., API keys)

### When Dependencies Fail

If Ralph can't install a dependency automatically, it will:

1. **Stop before starting iterations** - Fail fast, don't waste API calls
2. **Show clear error message** - Explain what's missing and why
3. **Provide install commands** - Copy-paste commands to fix the issue
4. **Log to activity.log** - Track dependency issues for debugging

Example failure output:

```
❌ Missing dependencies detected:

System packages (install with: sudo apt install <package>):
  - docker

Python packages (install with: pip install <package>):
  - aider-chat

Verification failed:
  - Command failed: docker ps
    Error: Cannot connect to Docker daemon

Fix these issues and re-run Ralph.
```

---

## Automated Sign Creation

When an iteration fails (exit code != 0), Ralph automatically:

1. **Detects the failure**: Tracks which iteration failed and why
2. **Prompts for Sign**: In the next iteration, adds guidance to create a Sign
3. **Verifies Sign creation**: Checks if `guardrails.md` was modified after prompting
4. **Logs the process**: Records Sign prompts and creation in `activity.log`

### How Automated Signs Work

```
Iteration N fails →
  Next iteration prompt includes:
    "Add a Sign to guardrails.md explaining this failure" →
      Agent creates Sign →
        Script verifies guardrails.md changed →
          Logs: "Sign added to guardrails"
```

### Sign Format

When prompted, create Signs with this format:

```markdown
### Sign: [Short description of the rule]
- **Trigger**: When this rule should be applied
- **Instruction**: What to do instead
- **Added after**: Iteration N - [brief cause description]
```

### Manual Sign Creation

You can also manually add Signs when you notice patterns or want to guide agent behavior:

1. Open `.ralph/guardrails.md`
2. Add a new Sign under "Active Signs" section
3. Commit the change

---

## Promise Marker (Alternative Completion Method)

Tasks can use a promise marker as an alternative to checkboxes for completion detection.

### How It Works

Instead of (or in addition to) using `- [ ]` checkboxes, you can add a promise marker to your TASK.md:

```markdown
## Completion Status
<promise>INCOMPLETE</promise>
```

When the agent determines the task is complete, it updates the marker:

```markdown
## Completion Status
<promise>COMPLETE</promise>
```

### When to Use Promise Markers

| Scenario | Best Method |
|----------|-------------|
| Discrete checkpoints | Checkboxes `- [ ]` |
| Exploratory/research tasks | Promise marker |
| Complex multi-phase tasks | Both together |
| Simple single-objective tasks | Promise marker |

### Completion Detection

Ralph checks for completion in this order:

1. **Promise marker**: If `<promise>COMPLETE</promise>` found → task complete
2. **Checkboxes**: If all `[ ]` are checked → task complete
3. **Both**: Works with either OR both

### Example Task with Promise Marker

```markdown
# Research Task: Evaluate Caching Strategies

## Goal
Research and recommend a caching strategy for our API.

## Deliverables
- Analysis document in progress.md
- Recommendation with rationale

## Completion Status
<promise>INCOMPLETE</promise>
```

The agent changes `INCOMPLETE` to `COMPLETE` when done.

---

## Summary

1. All criteria must be verifiable via command output
2. No GUI, no TUI, no human approval
3. When in doubt, document as manual step
4. Failures automatically prompt for Sign creation
5. Promise markers offer an alternative to checkboxes
6. See ANTIPATTERNS.md for the complete guide

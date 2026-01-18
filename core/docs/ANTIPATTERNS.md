# Ralph Task Antipatterns - CRITICAL REFERENCE

## ⚠️ CRITICAL: Read This Before Writing Ralph Tasks

**Date**: 2026-01-16  
**Status**: MANDATORY READING for all Ralph task authors

---

## The Fatal Antipattern

**NEVER include criteria that require human GUI interaction, manual actions, or interactive prompts.**

Ralph is **autonomous**. If a criterion cannot be verified by running a command and checking its output, **it is not a valid Ralph criterion**.

---

## 🚫 FORBIDDEN Criterion Patterns

### ❌ GUI Interactions
```markdown
BAD:
- [ ] Right-click Docker tray icon → Restart
- [ ] Open Docker Desktop settings
- [ ] Click "Apply & Restart" button
- [ ] Launch application GUI
- [ ] Navigate to Settings → Resources
- [ ] Select option from dropdown
```

**Why forbidden**: Ralph runs in a terminal. It cannot:
- Click buttons
- Open GUI windows
- Right-click tray icons
- Navigate menus
- Interact with visual interfaces

### ❌ Manual Service Operations
```markdown
BAD:
- [ ] Restart Docker Desktop
- [ ] Reboot the server
- [ ] Reload nginx configuration
- [ ] Restart the application
```

**Why forbidden**: These require either:
- GUI interaction (clicking restart button)
- Root/admin privileges Ralph may not have
- Service manager access Ralph cannot use

### ❌ Interactive TUI/Prompts
```markdown
BAD:
- [ ] Run `dive image:latest` and verify layers (requires interactive navigation)
- [ ] Test with interactive prompt `npm init`
- [ ] Confirm the dialog with 'y'
- [ ] Navigate through TUI menu
```

**Why forbidden**: Ralph cannot interact with:
- Interactive Text User Interfaces (TUI)
- Prompts requiring human input
- Tools that expect keyboard navigation
- Confirmation dialogs

### ❌ External Human Approvals
```markdown
BAD:
- [ ] Get PR approved by team
- [ ] Wait for code review
- [ ] Confirm deployment with ops team
- [ ] Ask user if they want X or Y
```

**Why forbidden**: Ralph works autonomously. It cannot:
- Wait for humans
- Communicate with teams
- Make decisions requiring human judgment
- Seek approvals

### ❌ Physical Hardware Operations
```markdown
BAD:
- [ ] Plug in USB device
- [ ] Insert SD card
- [ ] Connect to network cable
- [ ] Turn on hardware switch
```

**Why forbidden**: Ralph is software. Obvious, but worth stating.

---

## ✅ CORRECT Criterion Patterns

### ✅ Command Verification
```markdown
GOOD:
- [ ] Service is running: `docker ps | grep myapp` shows container
- [ ] Config applied: `grep "setting=value" /path/to/config` succeeds
- [ ] File exists: `ls /path/to/file` exits with code 0
- [ ] Build succeeds: `npm run build` exits with code 0
```

**Why correct**: Every criterion can be verified by:
1. Running a command
2. Checking its exit code or output
3. No human interaction required

### ✅ Documentation Tasks
```markdown
GOOD:
- [ ] Document restart requirement: Add to progress.md "Manual: Restart service X"
- [ ] Document GUI steps: Add section to README "Human Steps Required"
- [ ] Create maintenance guide: File docs/maintenance.md with manual procedures
```

**Why correct**: Agent writes documentation. Humans read it later and do the manual steps.

### ✅ Script Creation
```markdown
GOOD:
- [ ] Create restart script: File restart-service.sh that stops and starts service
- [ ] Script is executable: `ls -l restart-service.sh` shows -rwxr-xr-x
- [ ] Script works: `bash -n restart-service.sh` validates syntax
- [ ] Document script usage: Add to README "Run ./restart-service.sh to restart"
```

**Why correct**: Agent creates automation. Humans can run it manually if needed.

### ✅ Conditional File Operations
```markdown
GOOD:
- [ ] Update config if exists: If config.json exists, add "newSetting": true
- [ ] Backup before modify: If file.txt exists, copy to file.txt.backup
- [ ] Check and document: If README.md exists, add Docker section; else note in progress.md
```

**Why correct**: Agent makes decisions based on file system state. No human input needed.

---

## The Verification Test

**Every Ralph criterion MUST pass this test:**

> **Question**: Can Ralph verify this criterion is complete by running a command and checking its output?

- **YES** → Valid criterion ✅
- **NO** → Invalid criterion ❌

### Examples

| Criterion | Can Ralph Verify? | Valid? |
|-----------|-------------------|--------|
| `docker ps` shows container running | YES (run command, grep output) | ✅ |
| Tests pass: `npm test` exits 0 | YES (run command, check exit code) | ✅ |
| File contains "setting=true" | YES (grep file, check exit code) | ✅ |
| Click restart button | NO (requires GUI) | ❌ |
| User confirms deployment | NO (requires human) | ❌ |
| Navigate TUI with arrow keys | NO (requires interaction) | ❌ |

---

## Fixing Antipatterns

When you find a criterion that requires human action, you have **4 options**:

### Option 1: Document It
Convert the action into documentation:

```markdown
FROM: - [ ] Restart Docker Desktop
TO:   - [ ] Document restart: Add to progress.md "Manual: Restart Docker Desktop via tray icon"
```

### Option 2: Script It
Create automation that makes it verifiable:

```markdown
FROM: - [ ] Restart nginx service
TO:   - [ ] Create restart script: nginx-restart.sh that runs `systemctl restart nginx`
      - [ ] Script is valid: `bash -n nginx-restart.sh` exits 0
      - [ ] Document usage: Add to progress.md "Run: sudo ./nginx-restart.sh"
```

### Option 3: Move It
Put it in a separate "Manual Steps" section outside success criteria:

```markdown
## Success Criteria
- [ ] Configuration file updated
- [ ] Changes documented

## Manual Steps Required (Not for Ralph)
1. Restart Docker Desktop (right-click tray icon)
2. Verify running: docker ps
```

### Option 4: Remove It
If it's not essential to the automated goal, remove it entirely.

---

## Real-World Example: Docker Optimization Fix

### ❌ BEFORE (Antipatterns)

```markdown
### Phase 4: Configure Docker

- [ ] Update daemon.json with settings
- [ ] Restart Docker Desktop: Right-click tray icon → Restart
- [ ] Verify running: `docker ps` succeeds

### Phase 5: Allocate Resources

- [ ] Open Docker Desktop settings
- [ ] Go to Settings → Resources → Advanced
- [ ] Set CPU to 6+
- [ ] Set Memory to 8GB+
- [ ] Click "Apply & Restart"
- [ ] Verify: `docker info` shows new values
```

**Problems**:
- Can't click tray icon
- Can't open settings GUI
- Can't navigate menus
- Can't click buttons
- Ralph hangs indefinitely

### ✅ AFTER (Fixed)

```markdown
### Phase 4: Configure Docker

- [ ] Update daemon.json with settings
- [ ] Validate JSON: `python -m json.tool daemon.json` exits 0
- [ ] Document restart: Add to progress.md "Manual: Restart Docker Desktop"

### Phase 5: Document Resource Requirements

- [ ] Check current: `docker info | grep -E "CPUs|Memory"` outputs values
- [ ] Document current: Add to progress.md "Current: X CPUs, Y GB"
- [ ] Document recommended: Add to progress.md "Recommended: 6+ CPUs, 8+ GB"
- [ ] Add manual note: Add to progress.md "Manual: Adjust in Docker Desktop → Settings → Resources"

## Manual Steps Required (Outside Ralph Criteria)

1. **Restart Docker Desktop** (Required for daemon.json)
   - Right-click tray icon
   - Select "Restart"
   - Wait 30 seconds

2. **Adjust Resources** (Optional for performance)
   - Open Docker Desktop → Settings → Resources
   - Set CPU and Memory
   - Click Apply & Restart
```

**Fixed**:
- All criteria are command-verifiable
- Manual steps documented separately
- Ralph can complete autonomously
- Humans have clear instructions

---

## Task Writing Checklist

Before submitting a Ralph task, verify:

- [ ] Every criterion starts with a command or file operation
- [ ] No criteria mention "click", "GUI", "button", "tray icon"
- [ ] No criteria require service restarts without scripts
- [ ] No criteria use interactive TUI tools
- [ ] No criteria wait for human approvals
- [ ] All manual steps are in separate section or documented
- [ ] Each criterion has verifiable success condition
- [ ] Task can run overnight without human intervention

---

## Common Mistakes

### Mistake 1: "Optional" Actions
```markdown
❌ BAD:
- [ ] Optionally restart service X if needed

✅ GOOD:
- [ ] Document optional restart: Add to progress.md "Optional: Restart X for immediate effect"
```

### Mistake 2: "Verify Visually"
```markdown
❌ BAD:
- [ ] Verify UI loads correctly

✅ GOOD:
- [ ] Verify HTTP 200: `curl localhost:3000` returns 200 status
- [ ] Verify content: `curl localhost:3000` output contains "<title>App</title>"
```

### Mistake 3: "Test Manually"
```markdown
❌ BAD:
- [ ] Manually test the feature works

✅ GOOD:
- [ ] Automated test passes: `npm test feature.test.js` exits 0
- [ ] Integration test passes: `npm run integration` exits 0
```

### Mistake 4: "Configure in UI"
```markdown
❌ BAD:
- [ ] Configure setting X in UI

✅ GOOD:
- [ ] Set in config file: Add "setting_x": true to config.json
- [ ] Validate syntax: `python -m json.tool config.json` exits 0
```

---

## Emergency Stop Indicators

**If Ralph hangs and won't progress**, check for these antipatterns:

1. Last criterion mentions "GUI", "click", "button", "restart"
2. Last criterion requires interactive input
3. Last criterion waits for external event
4. Last criterion needs human decision

**Fix**: Ctrl+C to stop Ralph, remove antipattern criteria, resume.

---

## References

- **Task Fix Example**: `_archive/ralph-legacy-files-2026-01-17/RALPH_TASK_FIX_2026-01-16.md`
- **Good Examples**: `.ralph/docs/SETUP.md` → "Best Practices"
- **Bad Examples**: This document (what NOT to do)

---

## TL;DR - The Golden Rule

**Can an agent sitting in a bash terminal with no GUI, no human input, and no interactive prompts complete this criterion by running commands and checking output?**

- **YES** → Valid ✅
- **NO** → Fix it ❌

---

**Remember**: Ralph is **autonomous**. If it needs a human, it's not Ralph anymore.

**Status**: MANDATORY reading before writing Ralph tasks
**Updated**: 2026-01-16
**Version**: 1.0

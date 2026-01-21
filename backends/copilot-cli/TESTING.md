# Testing Guide for Ralph Copilot Backend v3

This document provides manual test procedures for validating the v3.0.0 features.

**Prerequisite**: Active GitHub Copilot license and authenticated `copilot` CLI.

---

## Test Matrix

| Test | Feature | Command | Expected Result |
|------|---------|---------|-----------------|
| T1 | Basic execution | `./ralph-copilot.sh test-task` | Loop starts, iterations run |
| T2 | Programmatic mode | `./ralph-copilot.sh test-task -p` | Uses `-p` flag in execution |
| T3 | Docker sandbox | `./ralph-copilot.sh test-task --docker` | Runs inside container |
| T4 | Custom agent | `./ralph-copilot.sh test-task --agent=ralph` | Uses ralph agent profile |
| T5 | ACP mode | `./ralph-copilot.sh test-task --acp` | Uses structured JSON communication |
| T6 | Tool restrictions | `RALPH_COPILOT_DENY_TOOLS='fetch' ./ralph-copilot.sh test-task -p` | Blocks fetch tool |
| T7 | Completion promise | `./ralph-copilot.sh test-task --completion-promise 'DONE'` | Exits when promise detected |
| T8 | Stuck detection | Run with no changes | Warns after threshold reached |

---

## Phase 1: Prerequisites

### T0.1 - Copilot CLI Installation
```bash
copilot --version
# Expected: version number (e.g., 0.0.384)
```

### T0.2 - Copilot Authentication
```bash
copilot /login
copilot /model
# Expected: Shows available models
```

### T0.3 - Docker Availability (for Docker tests)
```bash
docker --version
docker build -t ralph-copilot-sandbox .
# Expected: Image builds successfully
```

---

## Phase 2: Basic Functionality

### T1 - Basic Execution
```bash
# Create test task
mkdir -p .ralph/active/test-task
cat > .ralph/active/test-task/TASK.md << 'EOF'
# Test Task
- [ ] Create a file named test.txt with "Hello World"
EOF

# Run
./ralph-copilot.sh test-task --max-iterations 3

# Verify
# - Loop should start and attempt iterations
# - Progress file should be created/updated
```

### T2 - Programmatic Mode
```bash
./ralph-copilot.sh test-task -p --max-iterations 1

# Verify
# - Startup banner shows "Execution mode: Programmatic (-p)"
# - Copilot invoked with -p flag
```

---

## Phase 3: Docker Sandbox

### T3 - Docker Execution
```bash
# Build image first
docker build -t ralph-copilot-sandbox .

# Run with Docker
./ralph-copilot.sh test-task --docker --max-iterations 1

# Verify
# - Startup banner shows "Execution mode: Docker sandbox"
# - Copilot runs inside container
# - Files created in /work are visible on host
```

### T3.1 - Docker Compose Services
```bash
# Interactive mode
docker compose run --rm ralph-copilot

# YOLO mode
PROMPT="Create a test file" docker compose run --rm ralph-copilot-yolo
```

---

## Phase 4: Custom Agent

### T4 - Agent Profile
```bash
# Install agent
mkdir -p ~/.copilot/agents
cp ralph.agent.md ~/.copilot/agents/

# Run with agent
./ralph-copilot.sh test-task --agent=ralph --max-iterations 1

# Verify
# - Startup banner shows "Custom agent: ralph"
# - Copilot uses --agent=ralph flag
```

---

## Phase 5: ACP Mode

### T5 - ACP Execution
```bash
./ralph-copilot.sh test-task --acp --max-iterations 1

# Verify
# - Startup banner shows "Execution mode: ACP (experimental)"
# - JSON request sent to Copilot
# - Output may be JSON formatted
```

---

## Phase 6: Tool Restrictions

### T6 - Deny Tools
```bash
RALPH_COPILOT_DENY_TOOLS='shell(rm),fetch,websearch' \
  ./ralph-copilot.sh test-task -p --max-iterations 1

# Verify
# - Startup banner shows "Denied tools: shell(rm),fetch,websearch"
# - Copilot invoked with --deny-tool flags
```

---

## Phase 7: Completion Detection

### T7 - Promise Detection
```bash
./ralph-copilot.sh test-task \
  --completion-promise 'TASK COMPLETE' \
  --max-iterations 10

# Have Copilot output: <promise>TASK COMPLETE</promise>

# Verify
# - Loop exits when promise detected
# - Activity log shows "Promise fulfilled"
```

### T8 - Stuck Detection
```bash
./ralph-copilot.sh test-task \
  --stuck-threshold 2 \
  --max-iterations 10

# Don't make any file changes

# Verify
# - Warning appears after 2 iterations with no changes
# - Guardrails updated with stuck information
```

---

## Cleanup

```bash
# Remove test task
rm -rf .ralph/active/test-task

# Remove Docker image (optional)
docker rmi ralph-copilot-sandbox
```

---

## Known Issues

1. **ACP Mode Undocumented**: The `--acp` flag is experimental and may change
2. **Model Availability**: Some models may not be available in ACP mode
3. **Docker Networking**: Container may need host network for some operations
4. **Permission Alignment**: File ownership may vary based on Docker user

---

## Reporting Results

After testing, update the version from `3.0.0-untested` to `3.0.0` if all tests pass.

Report issues at: [project issue tracker]

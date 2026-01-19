# GitHub Copilot Backend Testing Guide

**Purpose**: Step-by-step guide for validating `ralph-copilot.sh` on a machine with an active GitHub Copilot license.

**Status**: AWAITING VALIDATION

---

## Prerequisites

Before starting, ensure you have:

- [ ] Active GitHub Copilot subscription (personal or corporate)
- [ ] Corporate GitHub account (if using corporate license)
- [ ] Terminal access with bash
- [ ] Git installed and configured
- [ ] Network access to GitHub

---

## Phase 1: Environment Setup

### 1.1 Install Copilot CLI

```bash
# Option 1: npm (recommended)
npm install -g @github/copilot

# Option 2: Homebrew
brew install copilot-cli

# Option 3: WinGet (Windows)
winget install GitHub.Copilot

# Verify installation
copilot --version
```

**Expected**: Version number displayed (e.g., `0.0.384`)

### 1.2 Authenticate

```bash
copilot /login
```

**Expected**: Browser opens, you authenticate, CLI confirms success.

### 1.3 Verify Access

```bash
# Check available models
copilot /model

# Test basic prompt
echo "What is 2+2?" | copilot
```

**Expected**: 
- Model list shows claude-sonnet-4.5, claude-4, gpt-5, etc.
- Basic prompt returns "4" or similar response

---

## Phase 2: Basic Functionality Tests

### 2.1 Test Standard CLI Mode

```bash
# Create test directory
mkdir -p /tmp/ralph-copilot-test
cd /tmp/ralph-copilot-test

# Test file reading
echo "Hello World" > test.txt
echo "Read test.txt and tell me what it contains" | copilot
```

**Expected**: Copilot reads and reports "Hello World"

### 2.2 Test File Creation

```bash
echo "Create a file called greeting.py that prints 'Hello from Copilot'" | copilot
ls -la greeting.py
cat greeting.py
```

**Expected**: File created with appropriate Python code

### 2.3 Test File Editing

```bash
echo "Add a second print statement to greeting.py that says 'Goodbye'" | copilot
cat greeting.py
```

**Expected**: File modified with additional print statement

### 2.4 Test Git Operations

```bash
git init
git add .
echo "Commit these files with a descriptive message" | copilot
git log --oneline
```

**Expected**: Commit created with sensible message

---

## Phase 3: Model Selection Tests

### 3.1 Test Default Model (Claude Sonnet 4.5)

```bash
echo "Which model are you?" | copilot
```

**Expected**: Identifies as Claude Sonnet 4.5 or similar

### 3.2 Test Model Switching

```bash
# In interactive mode
copilot
/model gpt-5
# Type: Which model are you?
# Then /exit
```

**Expected**: Model switches and identifies correctly

### 3.3 Test Free Tier Model

```bash
# Test 0x multiplier model
copilot
/model gpt-4.1
# Type: Which model are you?
# Then /exit
```

**Expected**: Model works without counting against premium quota

---

## Phase 4: ACP Mode Tests (Experimental)

### 4.1 Test ACP Mode Launch

```bash
copilot --acp
```

**Expected**: Copilot starts in ACP mode (may show different prompt or wait for structured input)

### 4.2 Test ACP Message Sending

```bash
# This test is experimental - actual protocol may differ
echo '{"type":"message","content":"Hello"}' | copilot --acp
```

**Document**: Record actual behavior for implementation updates

### 4.3 Test ACP Permission Handling

**Document**: How permissions are requested and granted in ACP mode

---

## Phase 5: ralph-copilot.sh Integration Tests

### 5.1 Setup Test Task

```bash
# Navigate to workspace
cd /path/to/cursor_local_workspace

# Create simple test task
mkdir -p .ralph/active/copilot-test
cat > .ralph/active/copilot-test/TASK.md << 'EOF'
# Test Task for Copilot Backend

## Success Criteria

- [ ] Create a file called `hello.txt` with content "Hello from Copilot"
- [ ] Create a file called `count.py` that prints numbers 1-5
- [ ] Commit both files
EOF

cat > .ralph/active/copilot-test/progress.md << 'EOF'
# Progress Log

## Current Status
**Iteration**: 0
**Task**: copilot-test
**Status**: Not started
EOF
```

### 5.2 Run Single Iteration

```bash
./ralph-copilot.sh copilot-test
# Press Ctrl+C after first iteration completes
```

**Expected**:
- [ ] Script starts without errors
- [ ] Model information displayed correctly
- [ ] Copilot CLI invoked successfully
- [ ] Some progress made on task

### 5.3 Verify Task Progress

```bash
# Check if criteria completed
grep '\[x\]' .ralph/active/copilot-test/TASK.md

# Check progress log
cat .ralph/active/copilot-test/progress.md

# Check activity log
cat .ralph/active/copilot-test/activity.log

# Check commits
git log --oneline --grep='ralph(copilot-test):'
```

**Expected**:
- [ ] At least one criterion checked off
- [ ] Progress file updated
- [ ] Activity logged
- [ ] Commits created

### 5.4 Run Full Loop (Small Task)

```bash
# Run until completion or max iterations
./ralph-copilot.sh copilot-test
```

**Expected**:
- [ ] Task completes (all criteria checked)
- [ ] "TASK COMPLETE" message shown
- [ ] All files created correctly
- [ ] Git history shows proper commits

---

## Phase 6: Error Handling Tests

### 6.1 Test Network Retry

```bash
# Disconnect network briefly during a run
# Reconnect within 30 seconds
```

**Expected**: Script retries and recovers

### 6.2 Test Stuck Detection

```bash
# Create task with impossible criterion
cat > .ralph/active/stuck-test/TASK.md << 'EOF'
# Stuck Test

## Success Criteria
- [ ] Do something that will fail repeatedly
EOF

# Run and observe stuck detection
./ralph-copilot.sh stuck-test
```

**Expected**:
- [ ] Stuck detection triggers after 3 attempts
- [ ] Guardrails file updated with lesson
- [ ] Loop stops gracefully

### 6.3 Test Premium Tracking

```bash
cat .ralph/active/copilot-test/premium_requests.log
```

**Expected**: Premium requests logged with timestamps and model names

---

## Phase 7: Quality Comparison

### 7.1 Same Task with Different Backends

Run the same simple task with both backends:

```bash
# Create identical test tasks
# ... (create ralph-copilot-compare and ralph-aider-compare)

# Run with Copilot
./ralph-copilot.sh copilot-compare

# Run with Aider (if available)
./ralph-aider.sh aider-compare
```

**Compare**:
- [ ] Time to completion
- [ ] Quality of code generated
- [ ] Number of iterations needed
- [ ] Error rate

### 7.2 Document Findings

Create a comparison report:

```markdown
## Comparison: Copilot vs Aider

| Metric | Copilot | Aider |
|--------|---------|-------|
| Iterations | X | Y |
| Time (min) | X | Y |
| Code Quality | 1-5 | 1-5 |
| Error Rate | X% | Y% |
```

---

## Troubleshooting

### "copilot: command not found"

```bash
# Check if installed
which copilot
npm list -g @github/copilot

# Reinstall if needed
npm install -g @github/copilot
```

### "Authentication failed"

```bash
# Clear and re-authenticate
gh auth logout
copilot /login
```

### "Rate limit exceeded"

```bash
# Check premium usage
cat premium_requests.log

# Switch to free tier
RALPH_COPILOT_MODEL=gpt-4.1 ./ralph-copilot.sh my-task
```

### "ACP mode not working"

ACP mode is experimental. Document the specific error and:

```bash
# Fall back to CLI mode
RALPH_COPILOT_USE_ACP=false ./ralph-copilot.sh my-task
```

### Script hangs

```bash
# Check if copilot is waiting for input
# Press Ctrl+C and check activity log
cat .ralph/active/<task>/activity.log
```

---

## Reporting Results

After completing testing, update the following files:

1. **COPILOT_BACKEND.md**: Update "Status" from UNTESTED to VALIDATED
2. **ralph-copilot.sh**: Remove UNTESTED warnings if validated
3. **progress.md**: Document test results in task progress

### Report Template

```markdown
## Validation Report

**Tested by**: [Your name]
**Date**: [Date]
**Environment**: [macOS/Windows/Linux] + [Copilot version]

### Results

| Test | Pass/Fail | Notes |
|------|-----------|-------|
| Installation | | |
| Authentication | | |
| Basic CLI | | |
| File Operations | | |
| Git Integration | | |
| ralph-copilot.sh | | |
| Error Handling | | |
| ACP Mode | | |

### Issues Found

1. [Issue description]
2. [Issue description]

### Recommendations

1. [Recommendation]
2. [Recommendation]
```

---

## Next Steps After Validation

1. Update documentation with findings
2. Fix any bugs discovered
3. Update TASK.md criteria to mark as complete
4. Consider creating automated tests
5. Share results with team

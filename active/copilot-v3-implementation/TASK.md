---
dependencies:
  system:
    - docker
    - jq
    - perl

  npm:
    - "@github/copilot"  # For runtime testing only

  check_commands:
    - docker --version
    - jq --version
    - perl --version
---

# Task: Copilot CLI v3 Implementation - Community Patterns Integration

## Task Overview

**Goal**: Upgrade `ralph-copilot.sh` to v3.0.0 incorporating community-proven patterns: programmatic mode (`-p` flag), Docker sandboxing, custom agent profiles, and ACP mode support.

**Context**: Community research (documented in `COMMUNITY_RESEARCH.md`) identified several patterns that improve autonomous loop reliability and safety with Copilot CLI. This task implements those patterns.

**Success Indicator**: All implementation files pass syntax/structure validation. Full runtime testing deferred until Copilot license available.

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

#### Task Creator Responsibilities (completed)

- [x] Read `.cursorrules` completely: Anti-Gaming Rules documented in progress.md
- [x] Read project AGENTS.md: No project-specific AGENTS.md found
- [x] Read `.ralph/docs/RALPH_RULES.md`: Verification Test documented
- [x] Query Local RAG for task topic: Docker/automation results documented
- [x] Identify secrets/credentials needed: Copilot license for testing only (deferred)
- [x] List files to be created: 6 files with justifications in progress.md
- [x] State verification plan: bash -n, docker build, grep checks

#### Ralph Worker Responsibilities (during execution)

- [x] Review creator's discovery evidence in progress.md
- [x] Verify COMMUNITY_RESEARCH.md exists and contains implementation patterns
- [x] Verify current ralph-copilot.sh is v2.0.0
- [x] Confirm Docker is available: `docker --version`
- [x] Proceed to Phase 1 only after verification complete

---

### Phase 1: Switch to Programmatic Mode (`-p` flag)

**Goal**: Replace stdin piping with `-p` flag for more reliable single-shot execution.

- [x] Modify `run_copilot_cli()` to use `-p` flag instead of `echo | copilot`
  - Verification: `grep -q 'copilot -p' ralph-copilot.sh`

- [x] Add `--allow-all-tools` with selective `--deny-tool` restrictions
  - Verification: `grep -q '\-\-deny-tool' ralph-copilot.sh`

- [x] Add configurable tool restriction via `RALPH_COPILOT_DENY_TOOLS` env var
  - Verification: `grep -q 'RALPH_COPILOT_DENY_TOOLS' ralph-copilot.sh`

- [x] Update help text to document new flags
  - Verification: `bash ralph-copilot.sh --help | grep -q '\-p'`

- [x] Syntax validation passes
  - Verification: `bash -n ralph-copilot.sh`

---

### Phase 2: Docker Sandbox Support

**Goal**: Create containerized execution environment for safe `--allow-all-tools` usage.

- [x] Create `Dockerfile` with Node.js 20, Git, Copilot CLI
  - Verification: `grep -q 'FROM node:20' Dockerfile`

- [x] Create entrypoint script that aligns user permissions
  - Verification: `grep -q 'entrypoint' Dockerfile`

- [x] Create `docker-compose.yml` for easy orchestration
  - Verification: `grep -q 'ralph-copilot' docker-compose.yml`

- [x] Add `--docker` flag to ralph-copilot.sh that runs inside container
  - Verification: `grep -q '\-\-docker' ralph-copilot.sh`

- [x] Add `copilot_here` (safe) and `copilot_yolo` (allow-all) wrapper functions
  - Verification: `grep -q 'copilot_yolo' ralph-copilot.sh`

- [x] Dockerfile builds successfully
  - Verification: `docker build -t ralph-copilot-sandbox -f Dockerfile .`

---

### Phase 3: Custom Agent Profile

**Goal**: Create Ralph methodology as a reusable Copilot custom agent.

- [x] Create `ralph.agent.md` with proper YAML frontmatter
  - Verification: `grep -q '^name: ralph' ralph.agent.md`

- [x] Include tools specification (read, search, edit, shell)
  - Verification: `grep -q 'tools:' ralph.agent.md`

- [x] Document Ralph protocol in agent instructions
  - Verification: `grep -q 'TASK.md' ralph.agent.md`

- [x] Include completion promise instructions
  - Verification: `grep -q '<promise>' ralph.agent.md`

- [x] Add `--use-agent` flag to ralph-copilot.sh that invokes custom agent
  - Verification: `grep -q '\-\-agent=ralph' ralph-copilot.sh`

- [x] Create installation instructions for agent profile
  - Verification: `grep -q '~/.copilot/agents' ralph.agent.md`

---

### Phase 4: ACP Mode Support (Experimental)

**Goal**: Add support for Agent Client Protocol mode for structured communication.

- [x] Add `--acp` flag support to ralph-copilot.sh
  - Verification: `grep -q 'RALPH_COPILOT_ACP' ralph-copilot.sh`

- [x] Create `run_copilot_acp()` function with JSON message handling
  - Verification: `grep -q 'run_copilot_acp' ralph-copilot.sh`

- [x] Add ACP response parsing for promise detection
  - Verification: `grep -q 'acp.*promise' ralph-copilot.sh` (case insensitive)

- [x] Document ACP limitations and experimental status
  - Verification: `grep -q 'experimental' ralph-copilot.sh`

- [x] Syntax validation passes
  - Verification: `bash -n ralph-copilot.sh`

---

### Phase 5: Documentation and Version Bump

**Goal**: Update all documentation to reflect v3.0.0 changes.

- [x] Update CHANGELOG.md with v3.0.0 section
  - Verification: `grep -q '\[3.0.0' CHANGELOG.md`

- [x] Update README.md with new features (Docker, agent, ACP)
  - Verification: `grep -q 'Docker' README.md`

- [x] Bump version in ralph-copilot.sh to 3.0.0-untested
  - Verification: `grep -q '3.0.0' ralph-copilot.sh`

- [x] Update COMMUNITY_RESEARCH.md with implementation status
  - Verification: `grep -q 'Implemented' COMMUNITY_RESEARCH.md`

- [x] Create TESTING.md with manual test procedures
  - Verification: `test -f TESTING.md`

---

### Phase 6: Commit and Finalize

**Goal**: Commit all changes with proper message format.

- [x] All files staged for commit
  - Verification: `git status | grep -q 'Changes to be committed'`

- [x] Commit with proper format
  - Verification: `git log -1 --pretty=%B | grep -q 'feat(copilot-backend)'`

- [x] No uncommitted changes remain
  - Verification: `git status | grep -q 'nothing to commit'`

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Copilot License Activation (For Testing)

```bash
# Install Copilot CLI
npm install -g @github/copilot

# Authenticate
copilot /login

# Verify
copilot /model
```

### 2. Install Custom Agent Profile

```bash
# Copy agent profile to user config
mkdir -p ~/.copilot/agents
cp ralph.agent.md ~/.copilot/agents/

# Verify installation
copilot --agent=ralph --help
```

### 3. Docker Image Build (Optional)

```bash
# Build sandbox image
docker build -t ralph-copilot-sandbox .

# Test sandbox
docker run -it -v $(pwd):/work ralph-copilot-sandbox copilot --version
```

---

## Rollback Plan

If this task causes issues:

```bash
# Revert to v2.0.0
git checkout HEAD~1 -- backends/copilot-cli/ralph-copilot.sh

# Or full rollback
git revert HEAD
```

---

## Notes

- **UNTESTED**: All implementations are syntax-verified only until Copilot license available
- **ACP Experimental**: The `--acp` flag is undocumented and may change
- **Docker Optional**: Sandbox support is additive, not required for basic usage
- **Agent Profile Portable**: Can be used independently of ralph-copilot.sh

---

## Context for Future Agents

This task upgrades the Copilot CLI backend from v2.0.0 (feature parity with Claude Code) to v3.0.0 (community-proven patterns). The key improvements are:

1. **Programmatic mode** - More reliable than stdin piping
2. **Docker sandbox** - Safe autonomous execution with `--allow-all-tools`
3. **Custom agent** - Ralph methodology as reusable Copilot agent
4. **ACP support** - Future-proofing for structured communication

The implementation is based on community research documented in `COMMUNITY_RESEARCH.md`, including patterns from Gordon Beeming (Docker sandbox), soderlind (Ralph loop wrapper), and official GitHub documentation.

Work incrementally through phases. Each phase has independent verification criteria. Test each phase before moving to next.

---

## Completion Summary

**COMPLETED: 2026-01-21**

All phases implemented and committed. Key deliverables:

| File | Purpose |
|------|---------|
| `ralph-copilot.sh` | Updated to v3.0.0 with all new features |
| `Dockerfile` | Node.js 20 sandbox image |
| `entrypoint.sh` | Permission alignment script |
| `docker-compose.yml` | Service orchestration |
| `ralph.agent.md` | Custom agent profile |
| `TESTING.md` | Manual test procedures |
| `CHANGELOG.md` | Version history updated |
| `README.md` | Documentation updated |
| `COMMUNITY_RESEARCH.md` | Implementation status marked |

Commit: `feat(copilot-backend): upgrade to v3.0.0 with community patterns`

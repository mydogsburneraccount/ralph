---
dependencies:
  system:
    # System packages (installed via apt/yum/brew)
    # - docker
    # - jq
    # - postgresql-client

  python:
    # Python packages (installed via pip)
    # - pytest>=7.0
    # - black
    # - aider-chat

  npm:
    # npm packages (installed globally)
    # - typescript
    # - "@types/node"

  check_commands:
    # Verification commands (must pass before starting)
    # - docker ps
    # - pytest --version
    # - jq --version
---

## For Task Creators (READ THIS FIRST)

**You (the agent creating this task) must complete Phase 0 discovery BEFORE creating files.**

### Required Steps

1. Read `.cursorrules`, `RALPH_RULES.md`, project `AGENTS.md` (if exists)
2. Query Local RAG for task-relevant context
3. Create `progress.md` WITH your discovery evidence pre-filled
4. Create `TASK.md` with Phase 0 requirements (for Ralph workers to verify)
5. Create `.iteration` set to `0`

### Why This Matters

Your discovery evidence helps Ralph workers understand:

- What context files are relevant (so they don't repeat searches)
- What RAG queries were already run (and what was found)
- What paths/commands were verified (provenance for assumptions)
- What was NOT found (prevents wasted effort)
- What secrets or auth access they will need (so they don't get stuck churning on manual steps)

**⚠️ CRITICAL: If secrets or credentials are required, you MUST prompt the user IMMEDIATELY - before creating the task. Ralph workers execute autonomously and CANNOT ask the user for anything. Do NOT write "ask user for X" in the task - resolve it NOW or the task will fail.**

**Do NOT leave progress.md as a blank template.** Fill in Phase 0 discovery evidence before creating TASK.md.

---

# Task: [Task Name Here]

## Task Overview

**Goal**: [Clear, concise goal statement]

**Context**: [Background information, tech stack, constraints]

**Success Indicator**: [How will we know this is complete?]

---

## Success Criteria

### Phase 0: VERIFICATION GATE (Task Creator fills, Ralph Worker verifies)

**⚠️ Task Creator must complete this BEFORE creating TASK.md. Ralph Worker verifies before Phase 1.**

#### Task Creator Responsibilities (do this FIRST)

- [x] Read `.cursorrules` completely: Quote "Anti-Gaming Rules" section in progress.md
- [x] Read project AGENTS.md (if exists): Quote relevant section or note "No AGENTS.md found"
- [x] Read `.ralph/docs/RALPH_RULES.md`: Quote "The Verification Test" in progress.md
- [x] Query Local RAG for task topic: Document files found and key info extracted
- [x] Identify secrets/credentials needed: If any required, **prompt user NOW** - do NOT defer to Ralph workers
- [x] List files to be created: MAX 3 with one-sentence justification each
- [x] State verification plan: How each file will be verified after creation

**Task creators mark these [x] because they complete them before creating the task.**

**⚠️ If you identify secrets needed (API keys, passwords, SSH keys, etc.), STOP and ask the user to provide them BEFORE creating the task. Ralph workers cannot ask for help.**

#### Ralph Worker Responsibilities (during execution)

- [ ] Review creator's discovery evidence in progress.md
- [ ] Verify key assumptions still valid (paths exist, services running, etc.)
- [ ] Add corrections or additional context if needed
- [ ] Proceed to Phase 1 only after verification complete

**Evidence of Phase 0 completion MUST appear in progress.md BEFORE Phase 1 work begins.**

**Example Phase 0 entry in progress.md:**

```markdown
## Phase 0: Verification Gate

### Task Creator Discovery (filled by task creator)

**Rules Read:**
- `.cursorrules` Anti-Gaming Rules: "Creating 5 files when 1 would suffice = FAILURE"
- `AGENTS.md`: No project-specific AGENTS.md found
- `RALPH_RULES.md` Verification Test: "Can Ralph verify completion by running a command and checking output?"

**Local RAG Query:**
- Query: "docker optimization flippanet"
- Results Found:
  - `FLIPPANET.md` - Server specs, RTX 3080 Ti for transcoding
  - `docker-build-optimization-extended.md` - Use agent-builder with cache
  - `FLIPPANET_ARR_QUICK_REFERENCE.md` - Volume paths and service ports

**Key Context Extracted:**
- Plex config path: `/var/lib/docker/volumes/flippanet_plex-config/_data/...`
- SSH access: `ssh -i ~/.ssh/flippanet flippadip@flippanet`
- Tautulli monitoring at port 8181

**Secrets/Credentials:**
- SSH key `~/.ssh/flippanet` - already available, no action needed
- No API keys or passwords required for this task
- (If secrets WERE needed: "BLOCKED - prompted user for X, awaiting response")

**Files to Create (3):**
1. `TASK.md` - Task definition with verifiable phases
2. `progress.md` - This file with discovery evidence
3. `.iteration` - Iteration counter starting at 0

**Verification Plan:**
- TASK.md: `grep -E "^## Task Overview|^## Success Criteria|^## Rollback Plan" TASK.md`
- progress.md: `grep "Task Creator Discovery" progress.md`

---

### Ralph Worker Verification (filled during execution)

- [ ] Verified Plex config path exists
- [ ] Confirmed SSH connectivity
- [ ] Additional context: (none needed)
```

---

### Phase 1: [Phase Name]

- [ ] Criterion 1: [Specific, measurable, verifiable]
- [ ] Criterion 2: [Can be checked with a command]
- [ ] Criterion 3: [No GUI interactions or manual steps]

### Phase 2: [Phase Name]

- [ ] Criterion 4: [Each criterion should be atomic]
- [ ] Criterion 5: [Tests can verify completion]
- [ ] Criterion 6: [Avoid human approvals]

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. [Manual Step Name]

```bash
# Commands or instructions
export API_KEY="your-key-here"
```

### 2. [Another Manual Step]

```bash
# Setup instructions that can't be automated
```

---

## Rollback Plan

If this task causes issues:

```bash
# Rollback all changes
./.ralph/core/scripts/ralph-rollback.sh <task-name>
```

---

## Notes

- [Important considerations]
- [Known limitations]
- [Dependencies or prerequisites]

---

## Context for Future Agents

[High-level explanation of what this task accomplishes and why it matters]

Key considerations:

1. [Important point 1]
2. [Important point 2]
3. [Important point 3]

Work incrementally through phases. Test each phase before moving to next.

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

# Task: [Task Name Here]

## Task Overview

**Goal**: [Clear, concise goal statement]

**Context**: [Background information, tech stack, constraints]

**Success Indicator**: [How will we know this is complete?]

---

## Success Criteria

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
./.ralph/scripts/ralph-rollback.sh <task-name>
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

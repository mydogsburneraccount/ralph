# Ralph Task: Fix Broken Path References

## Task Overview

**Goal**: Fix all broken path references within the .ralph module to achieve internal consistency.

**Context**: The .ralph module has evolved but documentation and scripts still reference paths that don't exist:
- `.cursor/ralph-scripts/` - DOESN'T EXIST (scripts are in `.ralph/core/scripts/` and `.ralph/backends/*/`)
- `_agent_knowledge/ralph/` - DOESN'T EXIST (was archived)
- `.ralph/scripts/` - DOESN'T EXIST (scripts are in `.ralph/core/scripts/`)

**Actual Structure**:
```
.ralph/
├── core/scripts/       ← Core scripts (ralph-task-manager.sh, ralph-common.sh, etc.)
├── backends/
│   ├── cursor-agent/   ← ralph-autonomous.sh, ralph-watch.sh, etc.
│   ├── aider/          ← ralph-aider.sh, ralph-mac-setup.sh
│   └── copilot-cli/    ← ralph-copilot.sh
├── core/docs/          ← Documentation
├── active/             ← Active tasks
├── completed/          ← Completed tasks
└── tasks/              ← Standalone task templates
```

**Success Indicator**: `grep -r "\.cursor/ralph-scripts\|_agent_knowledge/ralph\|\.ralph/scripts/" .ralph/ | wc -l` returns 0

---

## Phase 0: Pre-Work Checkpoint

- [ ] Read `.cursorrules` completely: Quote Anti-Gaming Rules in progress.md
- [ ] Read `.ralph/guardrails.md`: Quote verification test in progress.md
- [ ] Document discovery: List all broken references by file in progress.md

---

## Completion Criteria

### Phase 1: Audit Broken References

- [ ] Count .cursor/ralph-scripts refs: `grep -r "\.cursor/ralph-scripts" .ralph/ | wc -l` shows count (document in progress.md)
- [ ] Count _agent_knowledge/ralph refs: `grep -r "_agent_knowledge/ralph" .ralph/ | wc -l` shows count (document in progress.md)  
- [ ] Count .ralph/scripts refs: `grep -r "\.ralph/scripts/" .ralph/ | wc -l` shows count (document in progress.md)
- [ ] List affected files: Document each file with broken refs in progress.md

### Phase 2: Fix Core Script References

**Files in .ralph/core/scripts/:**

- [ ] Fix init-ralph.sh: Replace `.cursor/ralph-scripts` with `.ralph/core/scripts` or `.ralph/backends/cursor-agent`
- [ ] Fix ralph-rollback.sh: Replace broken paths
- [ ] Fix ralph-switch-task.sh: Replace broken paths
- [ ] Verify core scripts: `grep -r "\.cursor/ralph-scripts" .ralph/core/scripts/ | wc -l` returns 0

### Phase 3: Fix Backend Script References

**Files in .ralph/backends/:**

- [ ] Fix ralph-mac-setup.sh: Replace `.cursor/ralph-scripts` with correct paths
- [ ] Verify backend scripts: `grep -r "\.cursor/ralph-scripts" .ralph/backends/ | wc -l` returns 0

### Phase 4: Fix Documentation References

**Files in .ralph/core/docs/:**

- [ ] Fix INDEX.md: Update all script paths
- [ ] Fix QUICKREF.md: Update all script paths
- [ ] Fix SCRIPTS.md: Update all script paths
- [ ] Fix remaining docs: Update any other files with broken paths
- [ ] Verify docs: `grep -r "\.cursor/ralph-scripts\|_agent_knowledge/ralph\|\.ralph/scripts/" .ralph/core/docs/ | wc -l` returns 0

### Phase 5: Fix Completed Task References (Optional - Low Priority)

- [ ] Decision: Mark completed tasks as "historical" OR fix their references
- [ ] Document decision in progress.md

### Phase 6: Final Verification

- [ ] No .cursor/ralph-scripts refs: `grep -r "\.cursor/ralph-scripts" .ralph/ --include="*.sh" --include="*.md" | grep -v completed/ | wc -l` returns 0
- [ ] No _agent_knowledge/ralph refs: `grep -r "_agent_knowledge/ralph" .ralph/ --include="*.sh" --include="*.md" | grep -v completed/ | wc -l` returns 0
- [ ] No .ralph/scripts refs: `grep -r "\.ralph/scripts/" .ralph/ --include="*.sh" --include="*.md" | grep -v completed/ | wc -l` returns 0
- [ ] Scripts still work: `./.ralph/core/scripts/ralph-task-manager.sh list` succeeds
- [ ] Document completion in progress.md

---

## Path Mapping Reference

| Old Path | New Path | Notes |
|----------|----------|-------|
| `.cursor/ralph-scripts/ralph-autonomous.sh` | `.ralph/backends/cursor-agent/ralph-autonomous.sh` | Cursor agent backend |
| `.cursor/ralph-scripts/ralph-task-manager.sh` | `.ralph/core/scripts/ralph-task-manager.sh` | Core script |
| `.cursor/ralph-scripts/ralph-common.sh` | `.ralph/core/scripts/ralph-common.sh` | Core script |
| `.cursor/ralph-scripts/ralph-aider.sh` | `.ralph/backends/aider/ralph-aider.sh` | Aider backend |
| `.cursor/ralph-scripts/ralph-copilot.sh` | `.ralph/backends/copilot-cli/ralph-copilot.sh` | Copilot backend |
| `_agent_knowledge/ralph/` | `.ralph/core/docs/` | Documentation moved |
| `.ralph/scripts/` | `.ralph/core/scripts/` | Core scripts location |

---

## Out of Scope

- Fixing references in `.ralph/completed/` (historical accuracy)
- Fixing references in `_archive/` (archived for a reason)
- Changing the actual script locations (only updating references)

---

## Completion Status

<promise>INCOMPLETE</promise>

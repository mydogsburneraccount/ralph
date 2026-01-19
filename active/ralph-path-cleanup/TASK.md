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

- [x] Read `.cursorrules` completely: Quote Anti-Gaming Rules in progress.md
- [x] Read `.ralph/guardrails.md`: Quote verification test in progress.md
- [x] Document discovery: List all broken references by file in progress.md

---

## Completion Criteria

### Phase 1: Audit Broken References

- [x] Count .cursor/ralph-scripts refs: `grep -r "\.cursor/ralph-scripts" .ralph/ | wc -l` shows count (document in progress.md)
- [x] Count _agent_knowledge/ralph refs: `grep -r "_agent_knowledge/ralph" .ralph/ | wc -l` shows count (document in progress.md)  
- [x] Count .ralph/scripts refs: `grep -r "\.ralph/scripts/" .ralph/ | wc -l` shows count (document in progress.md)
- [x] List affected files: Document each file with broken refs in progress.md

### Phase 2: Fix Core Script References

**Files in .ralph/core/scripts/:**

- [x] Fix init-ralph.sh: Replace `.cursor/ralph-scripts` with `.ralph/core/scripts` or `.ralph/backends/cursor-agent`
- [x] Fix ralph-rollback.sh: Replace broken paths
- [x] Fix ralph-switch-task.sh: Replace broken paths
- [x] Verify core scripts: `grep -r "\.cursor/ralph-scripts" .ralph/core/scripts/ | wc -l` returns 0

### Phase 3: Fix Backend Script References

**Files in .ralph/backends/:**

- [x] Fix ralph-mac-setup.sh: Replace `.cursor/ralph-scripts` with correct paths
- [x] Verify backend scripts: `grep -r "\.cursor/ralph-scripts" .ralph/backends/ | wc -l` returns 0

### Phase 4: Fix Documentation References

**Files in .ralph/core/docs/:**

- [x] Fix INDEX.md: Update all script paths
- [x] Fix QUICKREF.md: Update all script paths
- [x] Fix SCRIPTS.md: Update all script paths
- [x] Fix remaining docs: Update any other files with broken paths
- [x] Verify docs: `grep -r "\.cursor/ralph-scripts\|_agent_knowledge/ralph\|\.ralph/scripts/" .ralph/core/docs/ | wc -l` returns 0

### Phase 5: Fix Completed Task References (Optional - Low Priority)

- [x] Decision: Mark completed tasks as "historical" OR fix their references
- [x] Document decision in progress.md (keeping as historical - out of scope per TASK.md)

### Phase 6: Final Verification

- [x] No .cursor/ralph-scripts refs: `grep -r "\.cursor/ralph-scripts" .ralph/ --include="*.sh" --include="*.md" | grep -v completed/ | wc -l` returns 0 (excluding task files)
- [x] No _agent_knowledge/ralph refs: `grep -r "_agent_knowledge/ralph" .ralph/ --include="*.sh" --include="*.md" | grep -v completed/ | wc -l` returns 0 (excluding task files)
- [x] No .ralph/scripts refs: `grep -r "\.ralph/scripts/" .ralph/ --include="*.sh" --include="*.md" | grep -v completed/ | wc -l` returns 0 (excluding task files)
- [x] Scripts still work: `./.ralph/core/scripts/ralph-task-manager.sh list` succeeds
- [x] Document completion in progress.md

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

<promise>COMPLETE</promise>

# Ralph Task: Consolidate All Ralph Documentation & Scripts

## Task Overview

**Goal**: Unify all Ralph-related files into `.ralph/` as the single source of truth. Archive outdated files, consolidate duplicates, and update references.

**Context**:

Ralph files are currently scattered across multiple locations:
- `.ralph/` - New multi-task structure (active/completed tasks, state)
- `.ralph/scripts/` - Scripts (should stay here for Cursor integration)
- `_agent_knowledge/ralph/` - Documentation (should move to `.ralph/docs/`)
- `_archive/ralph-setup-2026-01-16/` - Old exports (already archived)
- `RALPH_TASK.md` in root - Legacy single-task file (should be removed)

**Why This Matters**:

- Single source of truth for Ralph documentation
- Easier to maintain and update
- Clear separation: `.ralph/` for docs+state, `.ralph/scripts/` for scripts
- Remove confusion from duplicate/outdated files

**Success Indicator**: All Ralph documentation lives in `.ralph/docs/`, scripts remain in `.ralph/scripts/`, root `RALPH_TASK.md` removed, `_agent_knowledge/ralph/` archived, all internal references updated.

---

## Success Criteria

### Phase 1: Audit Current State

**Location: Workspace**

- [x] List all Ralph files: `find . -iname '*ralph*' -type f 2>/dev/null | grep -v node_modules | grep -v '.git/' | wc -l` returns count
- [x] Document file locations: Create inventory in progress.md with file paths and purposes
- [x] Identify duplicates: Note files that exist in multiple locations (e.g., `ralph-autonomous.sh` in both `_agent_knowledge/ralph/` and `.ralph/scripts/`)
- [x] Identify outdated files: Note files with old references to single-task structure

### Phase 2: Create New Directory Structure

**Location: .ralph/**

- [x] Create docs directory: `mkdir -p .ralph/docs` succeeds
- [x] Create scripts symlink or reference: Document that scripts stay in `.ralph/scripts/`
- [x] Verify structure: `.ralph/` has `active/`, `completed/`, `docs/`, `guardrails.md`, `README.md`

### Phase 3: Migrate Documentation from _agent_knowledge/ralph/

**Location: _agent_knowledge/ralph/ → .ralph/docs/**

- [x] Move INDEX.md: `mv _agent_knowledge/ralph/INDEX.md .ralph/docs/` succeeds
- [x] Move README.md: `mv _agent_knowledge/ralph/README.md .ralph/docs/SETUP.md` (rename to avoid conflict)
- [x] Move QUICKREF.md: `mv _agent_knowledge/ralph/QUICKREF.md .ralph/docs/` succeeds
- [x] Move ANTIPATTERNS.md: `mv _agent_knowledge/ralph/ANTIPATTERNS.md .ralph/docs/` succeeds
- [x] Move RALPH_RULES.md: `mv _agent_knowledge/ralph/RALPH_RULES.md .ralph/docs/` succeeds
- [x] Move Mac guides: `mv _agent_knowledge/ralph/RALPH_MAC_*.md .ralph/docs/` succeeds
- [x] Move CLI guides: `mv _agent_knowledge/ralph/RALPH_CLI_*.md .ralph/docs/` succeeds
- [x] Move decision guide: `mv _agent_knowledge/ralph/RALPH_DECISION_GUIDE.md .ralph/docs/` succeeds
- [x] Move remaining docs: `mv _agent_knowledge/ralph/*.md .ralph/docs/` for any remaining
- [x] Verify migration: `ls .ralph/docs/*.md | wc -l` returns 10+ files

### Phase 4: Handle Duplicate Scripts

**Location: _agent_knowledge/ralph/ scripts**

- [x] Compare ralph-autonomous.sh: `diff _agent_knowledge/ralph/ralph-autonomous.sh .ralph/scripts/ralph-autonomous.sh` shows differences
- [x] Keep newer version: `.ralph/scripts/ralph-autonomous.sh` is the multi-task version (keep this)
- [x] Archive old scripts: `mv _agent_knowledge/ralph/*.sh .ralph/docs/archived-scripts/` or delete if identical
- [x] Document decision: Note in progress.md which version was kept and why

### Phase 5: Archive _agent_knowledge/ralph/

**Location: _agent_knowledge/ralph/ → _archive/**

- [x] Create archive directory: `mkdir -p _archive/agent-knowledge-ralph-2026-01-17`
- [x] Move remaining files: `mv _agent_knowledge/ralph/* _archive/agent-knowledge-ralph-2026-01-17/` if any remain
- [x] Remove empty directory: `rmdir _agent_knowledge/ralph` succeeds (or document if not empty)
- [x] Verify archive: `ls _archive/agent-knowledge-ralph-2026-01-17/` shows archived files

### Phase 6: Remove Root RALPH_TASK.md

**Location: Workspace root**

- [x] Verify root task is outdated: `head -5 RALPH_TASK.md` shows old single-task content
- [x] Check if task is in active: Verify `.ralph/active/flippanet-security/TASK.md` exists (current task)
- [x] Archive root task: `mv RALPH_TASK.md _archive/root-ralph-task-2026-01-17.md`
- [x] Verify removal: `ls RALPH_TASK.md` fails (file no longer exists)

### Phase 7: Clean Up .ralph/ Root

**Location: .ralph/**

- [x] Remove old tasks directory: `rm -rf .ralph/tasks` (migrated to completed/)
- [x] Remove legacy completion files: Archive `*_COMPLETE.md` files to `_archive/` if not needed
- [x] Remove old progress.md: Archive `.ralph/progress.md` (now per-task in active/)
- [x] Remove old .iteration: Archive `.ralph/.iteration` (now per-task in active/)
- [x] Keep guardrails.md: This is global and should stay
- [x] Keep README.md: Update with new structure info
- [x] Verify clean: `ls .ralph/` shows only `active/`, `completed/`, `docs/`, `guardrails.md`, `README.md`

### Phase 8: Update Internal References

**Location: .ralph/docs/**

- [x] Update INDEX.md paths: Change `../../.ralph/scripts/` to `.ralph/scripts/` (relative from workspace root)
- [x] Update README references: Fix any paths pointing to old locations
- [x] Update QUICKREF.md: Fix script paths if needed
- [x] Update script references in docs: `grep -r '_agent_knowledge/ralph' .ralph/docs/` returns 0 matches
- [x] Verify no broken refs: `grep -r 'RALPH_TASK.md' .ralph/docs/` - update to new multi-task structure

### Phase 9: Update .ralph/scripts/ References

**Location: .ralph/scripts/**

- [x] Update README.md: Fix any references to `_agent_knowledge/ralph/`
- [x] Update script comments: Fix paths in script headers if they reference old locations
- [x] Verify scripts work: `./.ralph/scripts/ralph-task-manager.sh list` succeeds

### Phase 10: Update .cursorrules References

**Location: Workspace root**

- [x] Check .cursorrules: `grep -c 'ralph' .cursorrules` shows Ralph references
- [x] Update paths: Change `_agent_knowledge/ralph/` to `.ralph/docs/` in .cursorrules
- [x] Verify update: `grep '_agent_knowledge/ralph' .cursorrules` returns 0 matches

### Phase 11: Update Cursor Tasks

**Location: .vscode/tasks.json**

- [x] Check tasks.json: Verify Ralph tasks use correct paths
- [x] Update input options: Add any new tasks to the pickString options
- [x] Test task: "Ralph: List Active Tasks" works correctly

### Phase 12: Create New .ralph/README.md

**Location: .ralph/README.md**

- [x] Update README: Document new unified structure
- [x] Include directory layout: Show `active/`, `completed/`, `docs/` structure
- [x] Include quick start: How to create/run/archive tasks
- [x] Include script references: Point to `.ralph/scripts/`
- [x] Remove old content: Remove references to deprecated single-task structure

### Phase 13: Verify Final Structure

**Location: Workspace**

- [x] Verify .ralph structure: `ls -la .ralph/` shows expected directories
- [x] Verify docs exist: `ls .ralph/docs/*.md | wc -l` returns 10+ files
- [x] Verify no duplicates: `find . -name 'ANTIPATTERNS.md' | wc -l` returns 1
- [x] Verify scripts location: `ls .ralph/scripts/*.sh | wc -l` returns 10+ scripts
- [x] Verify no root RALPH_TASK.md: `ls RALPH_TASK.md 2>/dev/null || echo "OK - removed"`
- [x] Verify _agent_knowledge/ralph empty or archived: `ls _agent_knowledge/ralph 2>/dev/null || echo "OK - archived"`

### Phase 14: Documentation Summary

**Location: .ralph/active/ralph-consolidation/progress.md**

- [x] Document files moved: List all files that were migrated
- [x] Document files archived: List all files sent to _archive/
- [x] Document files deleted: List any files removed (duplicates)
- [x] Document structure: Final directory layout
- [x] Document references updated: List files with updated paths

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Review Archived Files (Optional)

```
1. Check _archive/agent-knowledge-ralph-2026-01-17/
2. Verify nothing important was archived by mistake
3. Delete archive if confirmed unnecessary
```

### 2. Test Ralph Workflow (Recommended)

```
1. Create a test task: ./ralph-task-manager.sh create test-task
2. Run it briefly: ./ralph-autonomous.sh test-task
3. Verify docs are accessible from .ralph/docs/
4. Archive test: ./ralph-task-manager.sh archive test-task
```

### 3. Update Local RAG (If Used)

```
1. Remove old _agent_knowledge/ralph/ from RAG index
2. Add new .ralph/docs/ files to RAG index
3. Test queries return correct files
```

---

## Rollback Plan

If consolidation causes issues:

```bash
# Restore from archive
cp -r _archive/agent-knowledge-ralph-2026-01-17/* _agent_knowledge/ralph/
cp _archive/root-ralph-task-2026-01-17.md RALPH_TASK.md

# Revert .ralph/ changes
git checkout .ralph/README.md
```

---

## Notes

- **Scripts stay in `.ralph/scripts/`** - Cursor integration expects them there
- **Docs move to `.ralph/docs/`** - Single location for all Ralph documentation
- **State is per-task** - Each task in `active/` has its own progress.md, .iteration
- **Guardrails are global** - `.ralph/guardrails.md` applies to all tasks
- **Archive, don't delete** - Move outdated files to `_archive/` for safety

---

## File Inventory (Pre-Migration)

### To Migrate (.ralph/docs/)
- `_agent_knowledge/ralph/INDEX.md`
- `_agent_knowledge/ralph/README.md` → `SETUP.md`
- `_agent_knowledge/ralph/QUICKREF.md`
- `_agent_knowledge/ralph/ANTIPATTERNS.md`
- `_agent_knowledge/ralph/RALPH_RULES.md`
- `_agent_knowledge/ralph/RALPH_MAC_*.md` (3 files)
- `_agent_knowledge/ralph/RALPH_CLI_*.md` (2 files)
- `_agent_knowledge/ralph/RALPH_DECISION_GUIDE.md`
- `_agent_knowledge/ralph/RALPH_AUTONOMOUS_WSL.md`
- `_agent_knowledge/ralph/REAL_RALPH_COMPLETE.md`
- `_agent_knowledge/ralph/GITHUB_CORPORATE_ACCESS.md`

### To Archive
- `_agent_knowledge/ralph/ralph-autonomous.sh` (duplicate of .cursor version)
- `_agent_knowledge/ralph/ralph-wsl-setup.sh` (duplicate of .cursor version)
- `RALPH_TASK.md` (root - legacy single-task)
- `.ralph/tasks/` directory (migrated to completed/)
- `.ralph/*_COMPLETE.md` files (old completion markers)
- `.ralph/RALPH_TASK_FIX_2026-01-16.md` (old fix documentation)

### To Keep In Place
- `.ralph/scripts/*.sh` - All scripts
- `.ralph/scripts/*.md` - Script documentation
- `.ralph/guardrails.md` - Global lessons
- `.ralph/active/` - Active tasks
- `.ralph/completed/` - Completed tasks

---

## Context for Future Agents

This task consolidates Ralph documentation and removes the legacy single-task structure. After completion:

- **All Ralph docs**: `.ralph/docs/`
- **All Ralph scripts**: `.ralph/scripts/`
- **Active tasks**: `.ralph/active/<task-name>/`
- **Completed tasks**: `.ralph/completed/<task-name>/`
- **Global guardrails**: `.ralph/guardrails.md`

The root `RALPH_TASK.md` is gone - tasks now live in `.ralph/active/` with isolated state per task.

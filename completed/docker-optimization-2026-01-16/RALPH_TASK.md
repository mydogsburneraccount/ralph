# Ralph Task: Refactor .cursorrules for Optimal Agent Performance

## Task Overview

**Goal**: Refactor the `.cursorrules` file from 695 lines to ~200 lines of core rules, extracting specialized content to knowledge base files, adding priority hierarchy, and creating a quick reference index.

**Context**:

- Current state: `.cursorrules` is 695 lines with dense, valuable information
- Problem: Information is difficult to prioritize when reasoning about tasks
- Model capability: Can read all 695 lines, but struggles to prioritize correctly when rules conflict
- Solution: Slim core rules + specialized knowledge base files + priority system

**Why This Matters**:

- Agents will follow rules more consistently with clear priorities
- Specialized content (Ralph, Docker, PowerShell) accessible via Local RAG
- Faster context loading for common scenarios
- Easier to maintain and extend
- Better separation of concerns

**Success Indicator**: Core `.cursorrules` file is 150-250 lines with priority system, all specialized content extracted to knowledge base, RAG queries return correct guidance for specialized topics.

---

## Success Criteria

### Phase 1: Backup and Analysis

**Location: Workspace root**

- [ ] Backup current file: Copy `.cursorrules` to `_archive/cursorrules-refactor-2026-01-16/.cursorrules.before-refactor` (695 lines)
- [ ] Verify backup exists: `wc -l _archive/cursorrules-refactor-2026-01-16/.cursorrules.before-refactor` returns 695
- [ ] Create work directory: `mkdir -p _archive/cursorrules-refactor-2026-01-16` succeeds
- [ ] Document current structure: Create `_archive/cursorrules-refactor-2026-01-16/analysis.md` with section breakdown (line ranges, topics, word counts)
- [ ] Identify extraction candidates: Document in analysis.md which sections to extract (Ralph, Docker, PowerShell, detailed examples)

### Phase 2: Extract Specialized Content - Ralph

**Location: _agent_knowledge/ralph/**

- [ ] Create Ralph rules file: `_agent_knowledge/ralph/RALPH_RULES.md` exists
- [ ] Extract Ralph section: Lines 576-610 from `.cursorrules` moved to RALPH_RULES.md (section "RALPH WIGGUM - AUTONOMOUS TASK EXECUTION")
- [ ] Add context: RALPH_RULES.md includes header explaining "Read this when writing Ralph tasks"
- [ ] Reference ANTIPATTERNS: RALPH_RULES.md links to existing ANTIPATTERNS.md file
- [ ] Verify extraction complete: `grep -i "ralph wiggum" .cursorrules` returns no matches
- [ ] Test file readable: `head -20 _agent_knowledge/ralph/RALPH_RULES.md` shows proper markdown headers

### Phase 3: Extract Specialized Content - Docker

**Location: _agent_knowledge/tools/**

- [ ] Create Docker extended guide: `_agent_knowledge/tools/docker-build-optimization-extended.md` exists
- [ ] Extract Docker section: Lines 615-663 from `.cursorrules` moved to docker-build-optimization-extended.md
- [ ] Merge if needed: If `_agent_knowledge/tools/docker-optimization.md` exists, combine content (new file contains sections from both: `grep -E "BuildKit|cache|agent-builder" docker-build-optimization-extended.md` returns at least 3 matches)
- [ ] Add examples: File includes cache command examples (`grep "cache-from.*cache-to" docker-build-optimization-extended.md` succeeds)
- [ ] Verify extraction complete: Docker section removed from `.cursorrules` (or reduced to < 10 lines): `grep -A20 "DOCKER BUILD" .cursorrules | wc -l` returns less than 30
- [ ] Test file readable: `grep "docker buildx" _agent_knowledge/tools/docker-build-optimization-extended.md` succeeds

### Phase 4: Extract Specialized Content - PowerShell/Shell

**Location: _agent_knowledge/workflows/**

- [ ] Create shell guide: `_agent_knowledge/workflows/windows-shell-escaping.md` exists
- [ ] Extract PowerShell section: Lines 338-401 from `.cursorrules` moved to windows-shell-escaping.md
- [ ] Add examples: Include all quoting examples, chaining examples, common mistakes table
- [ ] Add reference chart: Quick lookup table for "Need X → Use Y syntax"
- [ ] Verify extraction complete: Count lines in `.cursorrules` shell section reduced to < 15 lines (trigger + reference)
- [ ] Test file readable: `grep "single quotes" _agent_knowledge/workflows/windows-shell-escaping.md` succeeds

### Phase 5: Extract Detailed Examples and Workflows

**Location: _agent_knowledge/workflows/**

- [ ] Create verification guide: `_agent_knowledge/workflows/agent-verification-patterns.md` exists
- [ ] Extract verification examples: Lines 252-278 from `.cursorrules` moved to agent-verification-patterns.md ("Verify Before Claiming")
- [ ] Extract communication examples: Lines 88-135 from `.cursorrules` moved to `_agent_knowledge/workflows/communication-style.md` (detailed examples, anti-patterns table)
- [ ] Extract context efficiency: Lines 405-459 from `.cursorrules` moved to existing `_agent_knowledge/context-token-optimization-best-practices.md` (merge if needed)
- [ ] Verify files created: `ls _agent_knowledge/workflows/agent-verification-patterns.md _agent_knowledge/workflows/communication-style.md _agent_knowledge/workflows/windows-shell-escaping.md` all succeed (exit code 0 for all 3)
- [ ] Test files have headers: `grep -h "^# " _agent_knowledge/workflows/agent-verification-patterns.md _agent_knowledge/workflows/communication-style.md _agent_knowledge/workflows/windows-shell-escaping.md` returns 3 headers (one per file)

### Phase 6: Create New Core .cursorrules Structure

**Location: Workspace root**

- [ ] Create new core file: `.cursorrules.new` exists (will replace `.cursorrules` in Phase 8)
- [ ] Add priority section: Lines 1-50 contain "Rule Priority Hierarchy" with 4 levels (CRITICAL, HIGH, MEDIUM, LOW)
- [ ] Add quick reference: Lines 51-100 contain "Quick Reference Index" table (Situation → Section/File → Line reference)
- [ ] Add critical behaviors: Lines 101-200 contain essential patterns (Local RAG, Context7, verification, proactive behavior)
- [ ] Add tool preferences: Lines 201-250 contain core tool selection table (Local RAG, Context7, browser, filesystem)
- [ ] Add communication essentials: Lines 251-300 contain core voice/tone rules (terse, direct, anti-patterns)
- [ ] Verify line count: `wc -l .cursorrules.new` returns between 150-250 lines
- [ ] Verify no duplication: `grep -c "## Rule Priority Hierarchy" .cursorrules.new` returns exactly 1

### Phase 7: Add References to Extracted Content

**Location: .cursorrules.new**

- [ ] Ralph reference added: Section references `_agent_knowledge/ralph/RALPH_RULES.md` with trigger (TRIGGER: Writing Ralph task → ACTION: Check RALPH_RULES.md via Local RAG)
- [ ] Docker reference added: Section references `_agent_knowledge/tools/docker-build-optimization-extended.md` with trigger
- [ ] Shell reference added: Section references `_agent_knowledge/workflows/windows-shell-escaping.md` with trigger
- [ ] Verification reference added: Section references `_agent_knowledge/workflows/agent-verification-patterns.md` with trigger
- [ ] Communication reference added: Section references `_agent_knowledge/workflows/communication-style.md` with trigger
- [ ] Verify all references: `grep -c "_agent_knowledge" .cursorrules.new` returns at least 5 matches

### Phase 8: Priority System Implementation

**Location: .cursorrules.new**

- [ ] Priority levels defined: Section exists with 4 levels (CRITICAL, HIGH, MEDIUM, LOW)
- [ ] CRITICAL level documented: Security, data safety, file deletion policy, backup before modify
- [ ] HIGH level documented: Information sources (Local RAG → Context7 → docs), tool selection, verification
- [ ] MEDIUM level documented: Code quality, thoroughness, scope discipline, communication style
- [ ] LOW level documented: Formatting preferences, time estimates, optional optimizations
- [ ] Conflict resolution rule: Section explains "When rules conflict, follow highest priority level"
- [ ] Verify priority section: `grep -E "CRITICAL|HIGH|MEDIUM|LOW" .cursorrules.new` returns at least 10 matches

### Phase 9: Quick Reference Index

**Location: .cursorrules.new (top of file)**

- [ ] Index table created: Markdown table with columns "Situation | Go To | Line/File"
- [ ] Index covers common scenarios: Index has at least 10 rows (count table rows: `grep -c "|" .cursorrules.new` returns at least 30 for 10+ row table)
- [ ] Index references external files: `grep "_agent_knowledge" .cursorrules.new | head -100` shows at least 3 knowledge base file references in first 100 lines
- [ ] Verify index position: Index appears in first 100 lines of `.cursorrules.new` (`head -100 .cursorrules.new | grep "Quick Reference"` succeeds)

### Phase 10: Validation and Testing

**Location: Workspace root**

- [ ] Syntax validation: `.cursorrules.new` has no triple-backtick mismatches (`grep -c '```' .cursorrules.new` returns even number)
- [ ] Line count verification: `wc -l .cursorrules.new` returns 150-250 lines (target: ~200)
- [ ] Content preservation: `grep -E "Local RAG|Context7|verify before|be proactive|NEVER DELETE" .cursorrules.new` returns at least 5 matches
- [ ] References to extracted content: `grep -c "_agent_knowledge" .cursorrules.new` returns at least 5 (one per extracted file)
- [ ] Extracted files exist: `ls _agent_knowledge/ralph/RALPH_RULES.md _agent_knowledge/tools/docker-build-optimization-extended.md _agent_knowledge/workflows/windows-shell-escaping.md _agent_knowledge/workflows/agent-verification-patterns.md _agent_knowledge/workflows/communication-style.md` all succeed (exit code 0)
- [ ] Extracted files have headers: `head -5 _agent_knowledge/ralph/RALPH_RULES.md | grep -E "^#"` succeeds (has markdown header)

### Phase 11: Replace Old .cursorrules

**Location: Workspace root**

- [ ] Final backup: Copy current `.cursorrules` to `.cursorrules.2026-01-16-pre-refactor` (for easy rollback)
- [ ] Verify backup: `diff .cursorrules .cursorrules.2026-01-16-pre-refactor` returns no differences
- [ ] Replace file: `mv .cursorrules.new .cursorrules` succeeds (atomic operation)
- [ ] Verify new file active: `head -50 .cursorrules` shows priority section and quick reference
- [ ] Verify line count: `wc -l .cursorrules` returns 150-250 lines
- [ ] Delete new file artifact: `.cursorrules.new` no longer exists (was renamed)

### Phase 12: Ingest Extracted Content to Local RAG

**Location: Local RAG MCP tool**

- [ ] Ingest Ralph rules: Use `mcp_local-rag_add_documents` with `_agent_knowledge/ralph/RALPH_RULES.md` (returns success)
- [ ] Ingest Docker extended: Use `mcp_local-rag_add_documents` with `_agent_knowledge/tools/docker-build-optimization-extended.md` (returns success)
- [ ] Ingest shell guide: Use `mcp_local-rag_add_documents` with `_agent_knowledge/workflows/windows-shell-escaping.md` (returns success)
- [ ] Ingest verification guide: Use `mcp_local-rag_add_documents` with `_agent_knowledge/workflows/agent-verification-patterns.md` (returns success)
- [ ] Ingest communication guide: Use `mcp_local-rag_add_documents` with `_agent_knowledge/workflows/communication-style.md` (returns success)
- [ ] Verify ingestion: `mcp_local-rag_list_documents` returns at least 5 newly added files with today's timestamp

### Phase 13: Test RAG Retrieval

**Location: Local RAG queries**

- [ ] Test Ralph query: `mcp_local-rag_query_documents("writing ralph task antipatterns")` returns RALPH_RULES.md or ANTIPATTERNS.md in top 3 results
- [ ] Test Docker query: `mcp_local-rag_query_documents("docker build cache optimization")` returns docker-build-optimization-extended.md in top 3 results
- [ ] Test shell query: `mcp_local-rag_query_documents("powershell escaping json quotes")` returns windows-shell-escaping.md in top 3 results
- [ ] Test verification query: `mcp_local-rag_query_documents("verify before claiming completion")` returns agent-verification-patterns.md in top 3 results
- [ ] Test communication query: `mcp_local-rag_query_documents("agent communication style anti-patterns")` returns communication-style.md in top 3 results
- [ ] Document test results: Add to `.ralph/progress.md` section "RAG Test Results" with query → result mapping

### Phase 14: Create Migration Guide

**Location: _archive/cursorrules-refactor-2026-01-16/**

- [ ] Create migration doc: `_archive/cursorrules-refactor-2026-01-16/MIGRATION_GUIDE.md` exists
- [ ] Document changes: File explains what was extracted, where it moved, why change was made
- [ ] Before/after comparison: File includes line count comparison (695 → ~200 lines), structure comparison
- [ ] Rollback instructions: File includes commands to restore old `.cursorrules` from backup
- [ ] Future maintenance: File explains how to add new rules (core vs. knowledge base decision tree)
- [ ] File is complete: Has all sections, no TODO placeholders, proper markdown

### Phase 15: Update Meta-Documentation

**Location: _agent_knowledge/ralph/**

- [ ] Update INDEX.md: Add entry for RALPH_RULES.md with description "Detailed Ralph task writing guidance"
- [ ] Update QUICKREF.md: Update reference to point to RALPH_RULES.md for task writing
- [ ] Verify INDEX update: `grep "RALPH_RULES.md" _agent_knowledge/ralph/INDEX.md` succeeds
- [ ] Verify QUICKREF update: `grep "RALPH_RULES.md" _agent_knowledge/ralph/QUICKREF.md` succeeds

### Phase 16: Documentation Summary

**Location: .ralph/progress.md**

- [ ] Create summary section: File includes "# .cursorrules Refactoring Summary"
- [ ] Document metrics: Original size (695 lines), new size (~200 lines), reduction percentage
- [ ] Document extracted files: List of 5 new knowledge base files created with descriptions
- [ ] Document RAG ingestion: Confirmation that all 5 files successfully ingested
- [ ] Document validation: All tests passed (syntax, line count, RAG retrieval)
- [ ] Document benefits: Expected improvements (faster parsing, clearer priorities, better separation)

---

## Manual Steps Required

**These require human interaction and are NOT part of automated Ralph criteria:**

### 1. Review New .cursorrules File (Optional but Recommended)

```
1. Open .cursorrules in IDE
2. Scan through priority section (first 50 lines)
3. Review quick reference index
4. Verify essential rules preserved
5. Check references to extracted files are correct
```

### 2. Test Agent Behavior (Optional)

```
1. Start new chat with agent
2. Ask agent to write a Ralph task (should reference RALPH_RULES.md)
3. Ask agent about Docker caching (should query Local RAG)
4. Ask agent about PowerShell escaping (should query Local RAG)
5. Verify agent behavior aligns with priorities
```

### 3. Rollback if Needed (Emergency)

```
# If new .cursorrules causes issues:
cp .cursorrules.2026-01-16-pre-refactor .cursorrules

# Then test agent behavior again
# Can iterate on .cursorrules.new and re-run Phase 11
```

---

## Rollback Plan

If refactored `.cursorrules` causes issues:

```bash
# Restore original .cursorrules (atomic operation)
cp .cursorrules.2026-01-16-pre-refactor .cursorrules

# Verify restoration
wc -l .cursorrules  # Should return 695

# Check diff to confirm
diff .cursorrules .cursorrules.2026-01-16-pre-refactor  # Should be empty

# Original file remains in _archive/ for reference
ls _archive/cursorrules-refactor-2026-01-16/.cursorrules.before-refactor
```

To re-attempt refactoring:

1. Review `.cursorrules.new` if it still exists
2. Adjust extracted files in `_agent_knowledge/`
3. Re-run Phase 11 to replace `.cursorrules`

---

## Notes

- **Line count target**: 150-250 lines (flexible, prioritize clarity over exact count)
- **Priority system**: When rules conflict, higher priority wins (CRITICAL > HIGH > MEDIUM > LOW)
- **Extraction principle**: If content is > 50 lines or highly specialized, extract to knowledge base
- **Reference pattern**: Extracted content referenced via TRIGGER + ACTION + Local RAG query
- **RAG ingestion**: Essential for this refactoring to work - agents must be able to find extracted content
- **Atomicity**: Old `.cursorrules` only replaced after all extracted files are created and validated
- **Preservation**: Zero information loss - everything in original appears in new core or extracted files
- **Maintainability**: Future additions follow decision tree: Core (universal) vs. Knowledge Base (specialized)

---

## Quick Reference Commands

```bash
# Check current .cursorrules line count
wc -l .cursorrules

# Compare old vs new
diff .cursorrules.2026-01-16-pre-refactor .cursorrules | head -50

# View new structure
head -100 .cursorrules

# List extracted files
ls -lh _agent_knowledge/{ralph,tools,workflows}/*.md | grep 2026-01-16

# Test RAG retrieval
# (Use MCP tool in agent chat)
mcp_local-rag_query_documents("ralph task antipatterns")

# Check archive contents
ls _archive/cursorrules-refactor-2026-01-16/

# Rollback if needed
cp .cursorrules.2026-01-16-pre-refactor .cursorrules
```

---

## Success Metrics

**Quantitative**:

- Line count: 695 → 150-250 (65-78% reduction)
- Files created: 5 new knowledge base files
- RAG ingestion: 5 documents successfully added
- Validation: 100% of tests passed

**Qualitative**:

- Priority system enables conflict resolution
- Quick reference enables fast rule lookup
- Specialized content accessible via Local RAG
- Core rules fit on 2-3 screens (easy to scan)
- Future maintenance clearer (core vs. specialized decision)

---

## Context for Future Agents

This task refactors a 695-line `.cursorrules` file that was dense with valuable information but difficult to prioritize effectively during reasoning. The solution extracts specialized content (Ralph, Docker, PowerShell) to knowledge base files accessible via Local RAG, adds a priority hierarchy for conflict resolution, and creates a quick reference index for common scenarios.

The core insight: Model can read 695 lines easily, but struggles to prioritize correctly when rules conflict. The fix isn't reducing information, it's organizing for retrieval and reasoning. Core rules stay in `.cursorrules` (universal application), specialized rules move to knowledge base (queried when needed).

**Key principle**: "Descriptive, not judgmental" - The refactoring doesn't delete content (preservation), it organizes for better agent cognition.

# Ralph Task Archive

This directory stores completed and historical Ralph tasks for reference.

## Structure

Each task is stored as a markdown file with a descriptive name:

```
.ralph/tasks/
├── README.md                    # This file
├── listenarr-docker-fix.md     # Completed: Build/deploy fixed Listenarr image
└── [future-task-name].md        # Future archived tasks
```

## Workflow

1. **Active task**: `RALPH_TASK.md` in workspace root (what Ralph is currently working on)
2. **Completed task**: Move to `.ralph/tasks/[descriptive-name].md` when done
3. **New task**: Create new `RALPH_TASK.md` in workspace root

## Naming Convention

Use kebab-case with brief description:

- `project-feature-implementation.md`
- `bug-fix-description.md`
- `optimization-area.md`

## Purpose

- **Reference**: Look back at what was accomplished
- **Learning**: Review past task structure and criteria quality
- **Context**: Understand project history
- **Reuse**: Copy patterns from successful tasks

## Finding Tasks

```bash
# List all archived tasks
ls .ralph/tasks/*.md

# Search task contents
grep -r "keyword" .ralph/tasks/

# View specific task
cat .ralph/tasks/listenarr-docker-fix.md
```

## Current Active Task

See `RALPH_TASK.md` in workspace root for what Ralph is currently working on.

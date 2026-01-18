# Ralph Examples

Example tasks demonstrating Ralph's capabilities.

## Hello Ralph

A simple "Hello World" task to verify setup.

**File**: `hello-ralph-task.md`

**Purpose**: Tests basic Ralph functionality - file creation, script execution, git commits.

**Expected iterations**: 1-2

**Usage**:
```bash
# Copy to active tasks
cp hello-ralph-task.md ~/.ralph/active/hello-ralph/TASK.md

# Run with any backend
cd ../backends/cursor-agent && ./ralph-autonomous.sh hello-ralph
```

## More Examples

Add more example tasks here as they're developed:

- Multi-file refactoring
- API integration
- Documentation generation
- Test suite creation
- Docker setup automation

## Creating Your Own Tasks

1. Copy `hello-ralph-task.md` as a template
2. Modify success criteria for your needs
3. See `../core/docs/TASK_TEMPLATE.md` for full template
4. Read `../core/docs/RALPH_RULES.md` for best practices
5. Avoid antipatterns in `../core/docs/ANTIPATTERNS.md`

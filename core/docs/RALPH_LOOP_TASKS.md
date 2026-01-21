# Creating Ralph-Loop Tasks

## The Problem

Complex prompts with markdown formatting break when passed directly to `/ralph-loop` because bash interprets special characters:

- Backticks (`) → command substitution
- `<text>` → redirection
- `|` in tables → pipes
- `$variable` → variable expansion
- Quotes → string delimiters

**This will fail:**
```bash
/ralph-loop "Use `--flag` to do <thing>" --max-iterations 10
# Error: bash interprets backticks and angle brackets
```

## The Solution

Save complex prompts to a task file, then reference that file in a simple prompt.

### Step 1: Create Task Directory

```bash
mkdir -p .ralph/active/<task-name>
```

### Step 2: Create Task Prompt File

Save your detailed prompt to `.ralph/active/<task-name>/PROMPT.md`:

```bash
cat > .ralph/active/<task-name>/PROMPT.md << 'TASKEOF'
# Your Task Title

## Context
[Background information...]

## Objective
[What needs to be done...]

## Phases
1. Discovery
2. Implementation
3. Testing

## Deliverables
- File 1
- File 2

## Completion Promise
Output `<promise>YOUR PHRASE HERE</promise>` when done.
TASKEOF
```

**Important:** Use `<< 'TASKEOF'` (with quotes around TASKEOF) to prevent variable expansion inside the heredoc.

### Step 3: Run Ralph-Loop

```bash
/ralph-loop "Read .ralph/active/<task-name>/PROMPT.md and complete the task described there" \
  --max-iterations 25 \
  --completion-promise "YOUR PHRASE HERE" \
  --progress .ralph/active/<task-name>/progress.md \
  --stuck-threshold 5 \
  --guardrails .ralph/guardrails.md
```

## Complete Example

```bash
# 1. Create task directory
mkdir -p .ralph/active/add-auth-feature

# 2. Create prompt file
cat > .ralph/active/add-auth-feature/PROMPT.md << 'TASKEOF'
# Task: Add Authentication Feature

## Context
The app currently has no auth. We need JWT-based authentication.

## Objective
Implement login, logout, and protected routes.

## Requirements
- [ ] POST /login endpoint
- [ ] POST /logout endpoint
- [ ] JWT token generation
- [ ] Auth middleware for protected routes
- [ ] Tests for all endpoints

## Completion Promise
Output `<promise>AUTH FEATURE COMPLETE</promise>` when all requirements are checked off and tests pass.
TASKEOF

# 3. Run ralph-loop
/ralph-loop "Read .ralph/active/add-auth-feature/PROMPT.md and complete the task" \
  --max-iterations 20 \
  --completion-promise "AUTH FEATURE COMPLETE" \
  --progress .ralph/active/add-auth-feature/progress.md \
  --stuck-threshold 5
```

## Template

A minimal task prompt template:

```markdown
# Task: [Title]

## Context
[Why this task exists, background info]

## Objective
[Clear statement of what success looks like]

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

## Constraints
- [Any limitations or rules to follow]

## Deliverables
- [Files to create/modify]
- [Documentation to write]

## Completion Promise
Output `<promise>[PHRASE]</promise>` when:
- All requirements are checked off
- [Other success criteria]
```

## Tips

1. **Keep the reference prompt simple** - No special characters needed in the `/ralph-loop` command itself

2. **Use absolute or relative paths consistently** - `.ralph/active/` is relative to workspace root

3. **Match the completion promise exactly** - The phrase in `--completion-promise` must match what's documented in PROMPT.md

4. **Set reasonable iteration limits** - Start with 20-25 for complex tasks, 10-15 for simpler ones

5. **Always use --stuck-threshold** - Prevents infinite loops; 5 is a good default

6. **Include guardrails for complex tasks** - Point to `.ralph/guardrails.md` or task-specific guardrails

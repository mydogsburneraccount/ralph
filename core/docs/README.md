# Ralph Core Documentation

This directory contains backend-agnostic Ralph documentation.

## Essential Reading

### Getting Started
- [QUICKREF.md](./QUICKREF.md) - Quick reference for all commands
- [RALPH_RULES.md](./RALPH_RULES.md) - How to write tasks
- [ANTIPATTERNS.md](./ANTIPATTERNS.md) - What NOT to do

### Setup & Configuration
- [SECRET_MANAGEMENT.md](./SECRET_MANAGEMENT.md) - Secure credential storage
- [DEPENDENCY_MANAGEMENT.md](./DEPENDENCY_MANAGEMENT.md) - Automatic dependency installation
- [DEPENDENCY_QUICKREF.md](./DEPENDENCY_QUICKREF.md) - Quick dependency commands

### Advanced Topics
- [INDEX.md](./INDEX.md) - Complete documentation index
- [SCRIPTS.md](./SCRIPTS.md) - Script reference
- [TASK_TEMPLATE.md](./TASK_TEMPLATE.md) - Task template with examples

### Technical Details
- [PEP668_HANDLING.md](./PEP668_HANDLING.md) - Python PEP 668 compliance
- [PIPX_MIGRATION.md](./PIPX_MIGRATION.md) - Migration to pipx
- [NPM_PACKAGE_SELECTION.md](./NPM_PACKAGE_SELECTION.md) - Modern npm packages

## Documentation Structure

```
docs/
├── QUICKREF.md              # ⭐ Start here
├── RALPH_RULES.md           # ⭐ Task writing guide
├── ANTIPATTERNS.md          # ⭐ Common mistakes
│
├── SECRET_MANAGEMENT.md     # Credentials & API keys
├── DEPENDENCY_*.md          # Dependency system
│
├── INDEX.md                 # Full documentation index
├── SCRIPTS.md              # Script reference
└── TASK_TEMPLATE.md        # Task template
```

## Quick Links by Use Case

### "I want to write my first Ralph task"
1. Read [QUICKREF.md](./QUICKREF.md) (5 min)
2. Copy [TASK_TEMPLATE.md](./TASK_TEMPLATE.md)
3. Read [ANTIPATTERNS.md](./ANTIPATTERNS.md) to avoid common mistakes

### "How do I manage secrets/API keys?"
→ [SECRET_MANAGEMENT.md](./SECRET_MANAGEMENT.md)

### "How does dependency installation work?"
→ [DEPENDENCY_MANAGEMENT.md](./DEPENDENCY_MANAGEMENT.md)

### "My Python/npm install is failing"
→ [PEP668_HANDLING.md](./PEP668_HANDLING.md)
→ [DEPENDENCY_QUICKREF.md](./DEPENDENCY_QUICKREF.md)

### "What backend should I use?"
→ `../backends/README.md`

### "I need the complete docs list"
→ [INDEX.md](./INDEX.md)

## Contributing to Docs

When adding new documentation:

1. Add to this README's relevant section
2. Update [INDEX.md](./INDEX.md)
3. Cross-reference related docs
4. Keep examples practical and tested

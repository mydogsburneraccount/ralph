# Contributing to Ralph

Thanks for your interest in contributing! Here's how you can help.

## How to Contribute

### Reporting Bugs

Use the [Bug Report](../../issues/new?template=bug_report.yml) template and include:
- Which backend you're using
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs
- Your OS/environment

### Suggesting Features

Use the [Feature Request](../../issues/new?template=feature_request.yml) template and explain:
- The problem you're trying to solve
- Your proposed solution
- Why this would be useful to others

### Pull Requests

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (see Testing below)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Setup

### cursor-agent Backend
```bash
cd backends/cursor-agent
./setup.sh
```

### copilot-cli Backend
```bash
cd backends/copilot-cli
./setup.sh
```

### aider Backend
```bash
cd backends/aider
./setup.sh
```

## Testing

### Test Your Changes

1. Create a test task:
   ```bash
   ../core/scripts/ralph-task-manager.sh create test-my-feature
   ```

2. Run with your backend:
   ```bash
   ./ralph-autonomous.sh test-my-feature  # or ralph-copilot.sh, ralph-aider.sh
   ```

3. Verify the task completes successfully

### Test Base Toolset

If you modified dependency installation:
```bash
../core/scripts/test-base-toolset.sh
```

## Code Style

### Shell Scripts
- Use `#!/bin/bash` shebang
- Use `set -euo pipefail` for safety
- Quote variables: `"$VAR"` not `$VAR`
- Use meaningful function names
- Add comments for complex logic

### Documentation
- Update README files when changing functionality
- Keep examples up to date
- Use clear, concise language
- Include code examples where helpful

## Backend-Specific Guidelines

### cursor-agent
- Tested and production-ready
- Changes must maintain backward compatibility
- Test on both WSL and native Linux/Mac

### copilot-cli
- Currently untested (requires Copilot license)
- Document any changes thoroughly
- Mark breaking changes clearly
- Add to COPILOT_TESTING.md if testing procedure changes

### aider
- Currently untested (requires Anthropic API key)
- Keep cost-conscious (API charges apply)
- Document model selection changes
- Test with different models if possible

### Core
- Affects all backends - test carefully
- Document breaking changes prominently
- Update all backend READMEs if needed
- Maintain backward compatibility when possible

## Documentation Updates

When adding features:
1. Update relevant backend README
2. Update `core/docs/QUICKREF.md` if adding commands
3. Add to `core/docs/SCRIPTS.md` if adding scripts
4. Update main README.md if significant

## Questions?

- Check [Documentation](core/docs/)
- Read [Quick Reference](core/docs/QUICKREF.md)
- Open a [Discussion](../../discussions) (if enabled)
- Or just open an issue!

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

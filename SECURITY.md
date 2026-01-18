# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

**Do NOT open a public issue for security vulnerabilities.**

Instead:

1. Email security concerns to: (will be updated with contact)
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

You should receive a response within 48 hours.

## Security Considerations by Backend

### cursor-agent
- Uses Cursor IDE's authentication
- API keys managed by Cursor
- Code sent to Cursor's servers
- Review Cursor's security policies

### copilot-cli (Corporate Use)
- Uses GitHub authentication
- Enterprise audit logging available
- Data stays in GitHub/Microsoft infrastructure
- Review your organization's GitHub security policies

### aider (Personal Use Only)
- Uses Anthropic API key (user-provided)
- Code sent to Anthropic's servers
- **NOT suitable for proprietary/corporate code**
- Store API keys securely (use `ralph-secrets.sh`)

## Secret Management

Ralph includes `ralph-secrets.sh` for secure credential storage:

```bash
# Initialize secrets
./.ralph/scripts/ralph-secrets.sh init

# Set secrets
./.ralph/scripts/ralph-secrets.sh set GITHUB_TOKEN "your-token"

# Secrets stored in ~/.ralph/secrets.env (chmod 600)
```

**Never commit:**
- API keys
- Access tokens
- Secrets files (`.env`, `secrets.env`)
- Personal credentials

These are in `.gitignore` by default.

## Best Practices

1. **Use secret management**: Don't hardcode credentials
2. **Review task files**: Ensure tasks don't leak sensitive data
3. **Check logs**: Ralph logs may contain file contents
4. **Corporate use**: Use copilot-cli backend only (approved infrastructure)
5. **Personal use**: Keep sensitive projects separate from public repos
6. **API keys**: Rotate regularly, use minimal permissions

## Known Security Considerations

- Ralph reads/writes files in your workspace
- Tasks run shell commands (review TASK.md before running)
- AI backends see your code (check their privacy policies)
- Logs may contain sensitive information (stored in `~/.ralph/`)

## Questions?

For non-security questions, open an issue or discussion.
For security concerns, use the private reporting method above.

# npm Package Selection - Modern Alternatives

## Why We Don't Use Jest

Jest has deprecated dependencies with known issues:

```
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory.
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
```

**Problem:**
- Jest depends on old, unmaintained packages
- `inflight` has memory leaks (explicitly marked "do not use")
- `glob@7.x` is no longer supported
- 298 packages installed (bloated)

## Modern Alternative: Vitest

**Why Vitest?**
- ✅ No deprecated dependencies
- ✅ Much faster (uses Vite's transform pipeline)
- ✅ Better ESM/TypeScript support
- ✅ Jest-compatible API (easy migration)
- ✅ Actively maintained
- ✅ Smaller install size

**Migration:**
```javascript
// Works with both Jest and Vitest
import { describe, it, expect } from 'vitest'  // or 'jest'

describe('my test', () => {
  it('works', () => {
    expect(1 + 1).toBe(2)
  })
})
```

## npm Package Strategy

Ralph now uses a tiered approach:

### Core Packages (Auto-Install)
```
typescript  - TypeScript compiler (essential for TS projects)
prettier    - Code formatter (lightweight, no dependencies)
```

### Optional Packages (Ask First)
```
eslint      - JavaScript linter (large but useful)
vitest      - Modern test framework (replaces jest)
@types/node - TypeScript definitions for Node.js
```

## Other npm Alternatives

### Testing Frameworks

| Package | Status | Notes |
|---------|--------|-------|
| jest | ⚠️ Deprecated deps | Memory leaks, unmaintained dependencies |
| vitest | ✅ Modern | Fast, ESM-first, actively maintained |
| node:test | ✅ Native | Built into Node.js 18+, zero dependencies |
| uvu | ✅ Lightweight | Ultra-minimal, very fast |

### Linters

| Package | Status | Notes |
|---------|--------|-------|
| eslint | ✅ Good | Standard linter, large but widely used |
| rome | ⚠️ Deprecated | Project discontinued |
| biome | ✅ Modern | Fast Rust-based linter (rome successor) |
| oxlint | ✅ Emerging | Ultra-fast, written in Rust |

### Code Formatters

| Package | Status | Notes |
|---------|--------|-------|
| prettier | ✅ Standard | Opinionated, zero config, widely adopted |
| dprint | ✅ Fast | Rust-based, 30x faster than prettier |
| biome | ✅ All-in-one | Linter + formatter in one |

## Recommendations by Use Case

### For Ralph Tasks (General Purpose)
```bash
npm install -g typescript prettier
npm install -g vitest  # If testing needed
```

### For Modern JavaScript/TypeScript Projects
```bash
npm install -g typescript prettier vitest
npm install -g @types/node
```

### For High-Performance Requirements
```bash
npm install -g typescript dprint oxlint
npm install -g vitest
```

### Minimal Setup (Node 18+)
```bash
npm install -g typescript prettier
# Use node:test for testing (built-in)
```

## Using Node.js Built-in Test Runner

Node 18+ has a built-in test runner with zero dependencies:

```javascript
import { test, describe } from 'node:test'
import assert from 'node:assert'

describe('my test', () => {
  test('works', () => {
    assert.strictEqual(1 + 1, 2)
  })
})
```

**Run with:**
```bash
node --test
node --test --watch  # Watch mode
```

**Benefits:**
- Zero dependencies
- Native performance
- Always available in Node 18+
- No installation needed

## Deprecated Packages to Avoid

| Package | Issue | Alternative |
|---------|-------|-------------|
| jest | Deprecated deps, memory leaks | vitest, node:test |
| inflight | Memory leaks, unmaintained | lru-cache, p-queue |
| glob@7.x | Unsupported version | glob@10+, fast-glob |
| request | Deprecated since 2020 | node-fetch, axios, got |
| colors | Malware incident | chalk, picocolors |
| faker | Malware incident | @faker-js/faker |

## Checking for Deprecated Dependencies

```bash
# Check your project
npm audit

# Check global packages
npm list -g --depth=0

# Update outdated packages
npm outdated -g
npm update -g
```

## Ralph's Package Selection Philosophy

1. **Listen to warnings** - Deprecation warnings exist for a reason
2. **Prefer modern alternatives** - Use actively maintained packages
3. **Minimize dependencies** - Fewer packages = fewer issues
4. **Use system packages** - When available (Python via apt)
5. **Native over third-party** - Built-in features when possible (node:test)
6. **Performance matters** - Memory leaks and slow tools waste time

## Migration Guide: Jest → Vitest

### Install
```bash
npm uninstall -g jest
npm install -g vitest
```

### Update package.json
```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:ui": "vitest --ui"
  }
}
```

### API Compatibility
Most Jest tests work without changes. For differences:
- [Vitest Migration Guide](https://vitest.dev/guide/migration.html)

### Benefits
- ⚡ 10-100x faster test execution
- 🔥 Better HMR and watch mode
- 📦 Smaller install (no deprecated deps)
- 🎯 Native ESM and TypeScript support

## Future-Proofing

Ralph's base toolset will be updated as new recommendations emerge:
- Monitor npm advisories
- Track ecosystem trends
- Replace deprecated packages proactively
- Document migration paths

---

**Last Updated**: 2026-01-17  
**Current Recommendations**: typescript, prettier, vitest  
**Deprecated**: jest (memory leaks), inflight (unsupported)

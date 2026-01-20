#!/bin/bash
# Test script for Ralph base toolset installation
# Verifies that all expected tools are installed and properly configured

set -uo pipefail  # Removed -e so script continues on test failures

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Base Toolset Test                       ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

PASSED=0
FAILED=0
WARNINGS=0

# Helper function to test command existence
test_command() {
    local name="$1"
    local cmd="$2"
    local critical="${3:-true}"
    
    if command -v "$cmd" &> /dev/null; then
        echo "✓ $name: $(command -v "$cmd")"
        ((PASSED++)) || true
        return 0
    else
        if [ "$critical" = "true" ]; then
            echo "✗ $name: NOT FOUND (critical)"
            ((FAILED++)) || true
        else
            echo "⚠ $name: NOT FOUND (optional)"
            ((WARNINGS++)) || true
        fi
        return 0  # Changed from return 1 to prevent script exit
    fi
}

# Helper function to test Python package
test_python_package() {
    local name="$1"
    local import_name="${2:-$1}"
    
    if python3 -c "import ${import_name//-/_}" 2>/dev/null; then
        echo "✓ Python: $name (importable)"
        ((PASSED++)) || true
        return 0
    elif pip3 show "$name" &>/dev/null; then
        echo "✓ Python: $name (installed)"
        ((PASSED++)) || true
        return 0
    else
        echo "✗ Python: $name NOT FOUND"
        ((FAILED++)) || true
        return 0  # Changed from return 1
    fi
}

# Helper function to test pipx package
test_pipx_package() {
    local name="$1"
    local cmd="${2:-$1}"
    
    if command -v "$cmd" &> /dev/null; then
        echo "✓ pipx: $name (command available)"
        ((PASSED++)) || true
        return 0
    elif pipx list 2>/dev/null | grep -q "package $name"; then
        echo "✓ pipx: $name (installed)"
        ((PASSED++)) || true
        return 0
    else
        echo "✗ pipx: $name NOT FOUND"
        ((FAILED++)) || true
        return 0  # Changed from return 1
    fi
}

echo "═══════════════════════════════════════════════════"
echo "System Packages"
echo "═══════════════════════════════════════════════════"
test_command "curl" "curl"
test_command "wget" "wget"
test_command "git" "git"
test_command "jq" "jq"
test_command "unzip" "unzip"
echo ""

echo "═══════════════════════════════════════════════════"
echo "Python Environment"
echo "═══════════════════════════════════════════════════"
test_command "python3" "python3"
test_command "pip3" "pip3"
test_command "pipx" "pipx"

if command -v python3 &> /dev/null; then
    echo "  Python version: $(python3 --version)"
fi
if command -v pipx &> /dev/null; then
    echo "  pipx version: $(pipx --version 2>/dev/null || echo 'unknown')"
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "Python CLI Tools (via pipx)"
echo "═══════════════════════════════════════════════════"
test_pipx_package "pytest" "pytest"
test_pipx_package "black" "black"
test_pipx_package "ruff" "ruff"
test_pipx_package "mypy" "mypy"
test_pipx_package "ipython" "ipython"
echo ""

echo "═══════════════════════════════════════════════════"
echo "Python Libraries (via pip)"
echo "═══════════════════════════════════════════════════"
test_python_package "requests"
test_python_package "pyyaml" "yaml"
test_python_package "python-dotenv" "dotenv"
echo ""

echo "═══════════════════════════════════════════════════"
echo "Node.js Environment"
echo "═══════════════════════════════════════════════════"
test_command "node" "node"
test_command "npm" "npm"

if command -v node &> /dev/null; then
    echo "  Node version: $(node --version)"
fi
if command -v npm &> /dev/null; then
    echo "  npm version: $(npm --version)"
    echo "  npm prefix: $(npm config get prefix)"
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "npm Global Packages"
echo "═══════════════════════════════════════════════════"
test_command "tsc" "tsc" "false"
test_command "prettier" "prettier" "false"
test_command "eslint" "eslint" "false"
test_command "vitest" "vitest" "false"
echo ""

echo "═══════════════════════════════════════════════════"
echo "Docker (Optional)"
echo "═══════════════════════════════════════════════════"
if test_command "docker" "docker" "false"; then
    if docker ps &>/dev/null; then
        echo "  ✓ Docker daemon is running"
    else
        echo "  ⚠ Docker installed but daemon not running"
        ((WARNINGS++))
    fi
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "Ralph Helper Tools"
echo "═══════════════════════════════════════════════════"
test_command "ralph-install-dependency" "ralph-install-dependency" "false"
echo ""

echo "═══════════════════════════════════════════════════"
echo "PATH Configuration"
echo "═══════════════════════════════════════════════════"
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✓ ~/.local/bin is in PATH"
    ((PASSED++)) || true
else
    echo "✗ ~/.local/bin is NOT in PATH"
    echo "  Add to ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ((FAILED++)) || true
fi

# Check if npm prefix is set to ~/.local
if command -v npm &> /dev/null; then
    NPM_PREFIX=$(npm config get prefix)
    if [ "$NPM_PREFIX" = "$HOME/.local" ]; then
        echo "✓ npm prefix set to ~/.local"
        ((PASSED++)) || true
    else
        echo "⚠ npm prefix is: $NPM_PREFIX"
        echo "  Consider setting: npm config set prefix ~/.local"
        ((WARNINGS++)) || true
    fi
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "Test Summary"
echo "═══════════════════════════════════════════════════"
echo "Passed:   $PASSED"
echo "Failed:   $FAILED"
echo "Warnings: $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ All critical tests passed!"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  Some optional features are not configured"
    fi
    exit 0
else
    echo "❌ Some critical tests failed"
    echo ""
    echo "To install missing dependencies, run:"
    echo "  cd .ralph/scripts"
    echo "  sudo ./ralph-base-toolset.sh"
    exit 1
fi

#!/bin/bash
# Ralph Autonomous Setup for WSL

echo "Setting up Cursor Agent in WSL for autonomous Ralph..."

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"

# Check if cursor-agent is available
if ! command -v cursor-agent &> /dev/null; then
    echo "❌ cursor-agent not found. Installing..."
    curl https://cursor.com/install -fsS | bash
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verify
echo ""
echo "Checking cursor-agent..."
cursor-agent --version

echo ""
echo "Checking authentication..."
cursor-agent status

echo ""
echo "✅ Setup complete!"
echo ""
echo "To run autonomous Ralph:"
echo "  1. Make sure you're logged in: cursor-agent login"
echo "  2. Run: ./ralph-autonomous.sh"

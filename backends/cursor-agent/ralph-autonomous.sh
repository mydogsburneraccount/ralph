#!/bin/bash
# Ralph Autonomous Loop - Multi-Task Support
# Run this in WSL for autonomous, go-AFK development

set -euo pipefail

# Ensure ~/.local/bin is in PATH (for pipx and user installs)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Auto-detect workspace root (find git root or directory containing .ralph/)
find_workspace_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.ralph" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done

    # Fallback to git root
    if git rev-parse --show-toplevel &>/dev/null; then
        git rev-parse --show-toplevel
        return 0
    fi

    # Last resort: current directory
    echo "$PWD"
}

WORKSPACE=$(find_workspace_root)

# Parse arguments
TASK_NAME="${1:-}"
if [ -z "$TASK_NAME" ]; then
    echo "Usage: $0 <task-name>"
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    echo ""
    echo "Example: $0 flippanet-security"
    exit 1
fi

# Determine task directory
if [ -d "$WORKSPACE/.ralph/active/$TASK_NAME" ]; then
    TASK_DIR="$WORKSPACE/.ralph/active/$TASK_NAME"
elif [ -d "$TASK_NAME" ]; then
    TASK_DIR="$TASK_NAME"
else
    echo "❌ Task not found: $TASK_NAME"
    echo ""
    echo "Available tasks:"
    ls -1 "$WORKSPACE/.ralph/active/" 2>/dev/null || echo "  (no active tasks)"
    exit 1
fi

TASK_FILE="$TASK_DIR/TASK.md"
ITERATION_FILE="$TASK_DIR/.iteration"
PROGRESS_FILE="$TASK_DIR/progress.md"
ACTIVITY_LOG="$TASK_DIR/activity.log"
COST_LOG="$TASK_DIR/costs.log"
GUARDRAILS_FILE="$WORKSPACE/.ralph/guardrails.md"
MAX_ITERATIONS=20

# Failure tracking for Sign prompting
LAST_FAILURE_ITERATION=0
SIGN_PROMPTED=false
GUARDRAILS_CHECKSUM=""

# Cost estimation constants (Claude Sonnet pricing)
INPUT_COST_PER_MILLION=3    # $3 per 1M input tokens
OUTPUT_COST_PER_MILLION=15  # $15 per 1M output tokens
CHARS_PER_TOKEN=4           # Rough estimate: 4 characters per token

# Add cursor-agent to PATH, plus user's local bin for pip --user installs
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# TASK VALIDATION
# =============================================================================

validate_task() {
    local task_dir="$1"
    local task_file="$task_dir/TASK.md"
    local progress_file="$task_dir/progress.md"
    local errors=0
    
    echo ""
    echo "🔍 Validating task structure..."
    echo ""
    
    # 1. Check TASK.md exists
    if [ ! -f "$task_file" ]; then
        echo "  ❌ TASK.md not found"
        errors=$((errors + 1))
    else
        echo "  ✓ TASK.md exists"
        
        # 2. Check TASK.md has criteria (checkboxes)
        local checkbox_count
        checkbox_count=$(tr -d '\r' < "$task_file" | grep -cE '\[ \]|\[x\]' || echo "0")
        checkbox_count=$(echo "$checkbox_count" | tr -d '[:space:]')
        checkbox_count=${checkbox_count:-0}
        
        if [ "$checkbox_count" -eq 0 ]; then
            echo "  ❌ TASK.md has no checkboxes (criteria)"
            echo "     Add criteria like: - [ ] First thing to do"
            errors=$((errors + 1))
        else
            echo "  ✓ TASK.md has $checkbox_count criteria"
        fi
        
        # 3. Check TASK.md has a title
        local has_title
        has_title=$(tr -d '\r' < "$task_file" | grep -c '^# ' || echo "0")
        has_title=$(echo "$has_title" | tr -d '[:space:]')
        has_title=${has_title:-0}
        if [ "$has_title" -eq 0 ]; then
            echo "  ⚠️  TASK.md has no title (# heading)"
        fi
        
        # 4. Check for promise marker OR checkboxes
        local has_promise
        has_promise=$(tr -d '\r' < "$task_file" | grep -c '<promise>' || echo "0")
        has_promise=$(echo "$has_promise" | tr -d '[:space:]')
        has_promise=${has_promise:-0}
        if [ "$has_promise" -gt 0 ]; then
            echo "  ✓ TASK.md has promise marker"
        fi
    fi
    
    # 5. Check progress.md exists (will be created if not, but warn)
    if [ ! -f "$progress_file" ]; then
        echo "  ⚠️  progress.md not found (will be created)"
    else
        echo "  ✓ progress.md exists"
    fi
    
    # 6. Check guardrails.md exists at workspace level
    if [ ! -f "$GUARDRAILS_FILE" ]; then
        echo "  ⚠️  guardrails.md not found at workspace level (will be created)"
    else
        echo "  ✓ guardrails.md exists"
    fi
    
    echo ""
    
    if [ $errors -gt 0 ]; then
        echo "❌ Task validation failed with $errors error(s)"
        echo ""
        echo "Fix these issues before running Ralph."
        return 1
    else
        echo "✓ Task validation passed"
        return 0
    fi
}

# =============================================================================
# PREREQUISITES
# =============================================================================

# Check cursor-agent CLI
if ! command -v cursor-agent &> /dev/null; then
    echo "❌ cursor-agent not found. Run ralph-wsl-setup.sh first"
    exit 1
fi

# Validate task structure
if ! validate_task "$TASK_DIR"; then
    exit 1
fi

# Initialize files if they don't exist
[ ! -f "$ITERATION_FILE" ] && echo "0" > "$ITERATION_FILE"
[ ! -f "$PROGRESS_FILE" ] && echo "# Progress Log" > "$PROGRESS_FILE"
[ ! -f "$ACTIVITY_LOG" ] && touch "$ACTIVITY_LOG"
[ ! -f "$COST_LOG" ] && echo "# Cost Tracking Log" > "$COST_LOG"

# Auto-branching: Create safety branch if on main/master
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -n "$CURRENT_BRANCH" ]; then
    if [[ "$CURRENT_BRANCH" =~ ^ralph- ]]; then
        # Already on a Ralph branch
        RALPH_BRANCH="$CURRENT_BRANCH"
        echo "✓ Already on Ralph branch: $RALPH_BRANCH"
    elif [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
        # On main/master, create a new Ralph branch
        RALPH_BRANCH="ralph-${TASK_NAME}-$(date +%Y%m%d)"
        echo "📌 Creating safety branch: $RALPH_BRANCH"
        if git checkout -b "$RALPH_BRANCH" 2>/dev/null; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created branch: $RALPH_BRANCH" >> "$ACTIVITY_LOG"
            echo "✓ Now on branch: $RALPH_BRANCH"
        else
            echo "⚠️  Could not create branch (may already exist). Continuing on $CURRENT_BRANCH"
            RALPH_BRANCH="$CURRENT_BRANCH"
        fi
    else
        # On some other branch (not main/master/ralph-*)
        RALPH_BRANCH="$CURRENT_BRANCH"
        echo "✓ Working on branch: $RALPH_BRANCH (not main/master)"
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Working on branch: $RALPH_BRANCH" >> "$ACTIVITY_LOG"
else
    echo "⚠️  Not in a git repository or git not available"
    RALPH_BRANCH=""
fi

# Function: Estimate tokens from character count
estimate_tokens() {
    local char_count=$1
    # Ensure numeric value
    char_count=$(echo "$char_count" | tr -d '[:space:]')
    char_count=${char_count:-0}
    echo $(( char_count / CHARS_PER_TOKEN ))
}

# Function: Estimate cost in dollars (returns cents for precision)
estimate_cost_cents() {
    local input_tokens=$1
    local output_tokens=${2:-$input_tokens}  # Assume output ~= input if not specified

    # Ensure numeric values
    input_tokens=$(echo "$input_tokens" | tr -d '[:space:]')
    output_tokens=$(echo "$output_tokens" | tr -d '[:space:]')
    input_tokens=${input_tokens:-0}
    output_tokens=${output_tokens:-0}

    # Calculate cost in cents (multiply by 100 to avoid floating point)
    # Formula: (tokens / 1000000) * cost_per_million * 100 cents
    local input_cost=$(( input_tokens * INPUT_COST_PER_MILLION / 10000 ))
    local output_cost=$(( output_tokens * OUTPUT_COST_PER_MILLION / 10000 ))

    echo $(( input_cost + output_cost ))
}

# Function: Format cents as dollars
format_cost() {
    local cents=$1
    # Ensure numeric value
    cents=$(echo "$cents" | tr -d '[:space:]')
    cents=${cents:-0}
    local dollars=$(( cents / 100 ))
    local remainder=$(( cents % 100 ))
    printf "%d.%02d" $dollars $remainder
}

# Function: Log iteration cost
log_iteration_cost() {
    local iteration=$1
    local prompt_chars=$2
    local tokens=$(estimate_tokens $prompt_chars)
    local cost_cents=$(estimate_cost_cents $tokens $tokens)
    local cost_formatted=$(format_cost $cost_cents)

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iteration: ~$tokens tokens, ~\$$cost_formatted" >> "$COST_LOG"
}

# Function: Calculate total cost from log
calculate_total_cost() {
    if [ -f "$COST_LOG" ]; then
        local total_cents=0
        # Strip CRLF when reading log file
        while IFS= read -r line || [ -n "$line" ]; do
            # Remove any carriage returns
            line=$(echo "$line" | tr -d '\r')
            # Extract cost value from line like "~$0.05"
            if [[ $line =~ \~\$([0-9]+)\.([0-9]+) ]]; then
                local dollars="${BASH_REMATCH[1]}"
                local cents="${BASH_REMATCH[2]}"
                # Clean extracted values
                dollars=$(echo "$dollars" | tr -d '[:space:]')
                cents=$(echo "$cents" | tr -d '[:space:]')
                dollars=${dollars:-0}
                cents=${cents:-0}
                total_cents=$(( total_cents + dollars * 100 + cents ))
            fi
        done < "$COST_LOG"
        format_cost $total_cents
    else
        echo "0.00"
    fi
}

# =============================================================================
# DEPENDENCY MANAGEMENT
# =============================================================================

# Dependency auto-install mode (env var)
RALPH_AUTO_INSTALL="${RALPH_AUTO_INSTALL:-prompt}"  # prompt|true|false

# Function: Parse dependencies from TASK.md frontmatter
parse_task_dependencies() {
    local task_file="$1"
    local section="$2"  # system|python|npm|check_commands

    # Extract YAML frontmatter (between first --- and second ---)
    local in_frontmatter=false
    local in_dependencies=false
    local in_section=false
    local deps=()

    while IFS= read -r line; do
        # Check for frontmatter boundaries
        if [[ "$line" == "---" ]]; then
            if [ "$in_frontmatter" = false ]; then
                in_frontmatter=true
                continue
            else
                # End of frontmatter
                break
            fi
        fi

        if [ "$in_frontmatter" = true ]; then
            # Check for dependencies section
            if [[ "$line" =~ ^dependencies: ]]; then
                in_dependencies=true
                continue
            fi

            # Check for our specific section
            if [ "$in_dependencies" = true ]; then
                if [[ "$line" =~ ^[[:space:]]+${section}: ]]; then
                    in_section=true
                    continue
                elif [[ "$line" =~ ^[[:space:]]+[a-z_]+: ]]; then
                    # Different section, stop if we were in our section
                    [ "$in_section" = true ] && break
                    continue
                fi

                # Collect items from our section
                if [ "$in_section" = true ] && [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.+) ]]; then
                    local dep="${BASH_REMATCH[1]}"
                    # Remove comments
                    dep="${dep%%#*}"
                    dep="${dep%"${dep##*[![:space:]]}"}"  # Trim trailing whitespace
                    [ -n "$dep" ] && deps+=("$dep")
                fi
            fi
        fi
    done < "$task_file"

    # Return dependencies as newline-separated list
    printf '%s\n' "${deps[@]}"
}

# Function: Detect package manager for system packages
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Function: Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function: Install a system package
install_system_package() {
    local package="$1"
    local pm=$(detect_package_manager)

    echo "Installing system package: $package (using $pm)"

    case "$pm" in
        apt)
            sudo apt-get update -qq && sudo apt-get install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        brew)
            brew install "$package"
            ;;
        *)
            echo "❌ Unknown package manager. Please install manually: $package"
            return 1
            ;;
    esac
}

# Function: Install a Python package
install_python_package() {
    local package="$1"

    # List of packages that should be installed via pipx (CLI tools)
    local pipx_packages=(
        "aider-chat" "aider"
        "black" "ruff" "mypy"
        "pytest" "ipython"
        "poetry" "pipenv"
        "cookiecutter" "pre-commit"
        "httpie" "youtube-dl" "yt-dlp"
    )

    # Extract package name without version specifiers
    local pkg_name="${package%%[<>=]*}"

    # Check if this should be installed via pipx
    local use_pipx=false
    for pipx_pkg in "${pipx_packages[@]}"; do
        if [ "$pkg_name" = "$pipx_pkg" ]; then
            use_pipx=true
            break
        fi
    done

    if [ "$use_pipx" = true ]; then
        echo "Installing Python CLI tool via pipx: $package"

        # Check if pipx exists
        if ! command_exists pipx; then
            echo "pipx not found, installing..."
            if command_exists pip3; then
                python3 -m pip install --user pipx
                python3 -m pipx ensurepath --force
                export PATH="$HOME/.local/bin:$PATH"
            else
                echo "❌ pip not found. Please install Python and pip first."
                echo "Run: ./.ralph/core/scripts/ralph-base-toolset.sh"
                return 1
            fi
        fi

        # Install via pipx
        pipx install "$package" 2>&1 | grep -v "^  installed package" || true

        # Ensure PATH includes pipx binaries
        export PATH="$HOME/.local/bin:$PATH"

        return 0
    else
        echo "Installing Python library: $package"

        # Check if pip3 exists
        if ! command_exists pip3 && ! command_exists pip; then
            echo "❌ pip not found. Please install Python and pip first."
            echo "Run: ./.ralph/core/scripts/ralph-base-toolset.sh"
            return 1
        fi

        # Use pip3 if available, otherwise pip
        local pip_cmd="pip3"
        if ! command_exists pip3; then
            pip_cmd="pip"
        fi

        # Always use --user flag for safety (best practice)
        if ! $pip_cmd install --user "$package" 2>&1; then
            # If --user fails, try with --break-system-packages as last resort
            echo "⚠️  Standard install failed, trying --break-system-packages..."
            $pip_cmd install --break-system-packages "$package"
        fi

        return 0
    fi
}

# Function: Install an npm package
install_npm_package() {
    local package="$1"

    echo "Installing npm package: $package"

    if ! command_exists npm; then
        echo "❌ npm not found. Please install Node.js first."
        return 1
    fi

    npm install -g "$package"
}

# Function: Verify a check command
verify_check_command() {
    local check_cmd="$1"

    echo "Verifying: $check_cmd"

    # Run the command with timeout
    if timeout 5s bash -c "$check_cmd" &> /dev/null; then
        echo "  ✓ Check passed"
        return 0
    else
        echo "  ✗ Check failed"
        return 1
    fi
}

# Function: Prompt user for install confirmation
prompt_install() {
    local dep_type="$1"
    local package="$2"

    if [ "$RALPH_AUTO_INSTALL" = "true" ]; then
        return 0  # Auto-install enabled
    elif [ "$RALPH_AUTO_INSTALL" = "false" ]; then
        return 1  # Auto-install disabled
    else
        # Prompt mode
        echo ""
        echo "Missing $dep_type dependency: $package"
        read -p "Install now? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Function: Check and install all dependencies
check_and_install_dependencies() {
    local task_file="$1"

    echo ""
    echo "🔍 Checking task dependencies..."
    echo ""

    local failed_deps=()
    local failed_checks=()

    # Check system dependencies
    local system_deps=$(parse_task_dependencies "$task_file" "system")
    if [ -n "$system_deps" ]; then
        echo "System packages:"
        while IFS= read -r package; do
            [ -z "$package" ] && continue

            # Extract package name (before any version spec)
            local pkg_name="${package%%[<>=]*}"

            if command_exists "$pkg_name"; then
                echo "  ✓ $package"
            else
                echo "  ✗ $package (missing)"

                if prompt_install "system" "$package"; then
                    if install_system_package "$pkg_name"; then
                        echo "  ✓ $package (installed)"
                    else
                        failed_deps+=("system: $package")
                    fi
                else
                    failed_deps+=("system: $package")
                fi
            fi
        done <<< "$system_deps"
        echo ""
    fi

    # Check Python dependencies
    local python_deps=$(parse_task_dependencies "$task_file" "python")
    if [ -n "$python_deps" ]; then
        echo "Python packages:"
        while IFS= read -r package; do
            [ -z "$package" ] && continue

            # Extract package name (before version spec)
            local pkg_name="${package%%[<>=]*}"

            # Check if Python package is importable
            if python3 -c "import ${pkg_name//-/_}" 2>/dev/null || pip3 show "$pkg_name" &>/dev/null; then
                echo "  ✓ $package"
            else
                echo "  ✗ $package (missing)"

                if prompt_install "python" "$package"; then
                    if install_python_package "$package"; then
                        echo "  ✓ $package (installed)"
                    else
                        failed_deps+=("python: $package")
                    fi
                else
                    failed_deps+=("python: $package")
                fi
            fi
        done <<< "$python_deps"
        echo ""
    fi

    # Check npm dependencies
    local npm_deps=$(parse_task_dependencies "$task_file" "npm")
    if [ -n "$npm_deps" ]; then
        echo "npm packages:"
        while IFS= read -r package; do
            [ -z "$package" ] && continue

            # Remove quotes from scoped packages
            local pkg_name="${package//\"/}"
            local cmd_name="${pkg_name##*/}"  # Get command name from @scope/package

            if command_exists "$cmd_name" || npm list -g "$pkg_name" &>/dev/null; then
                echo "  ✓ $package"
            else
                echo "  ✗ $package (missing)"

                if prompt_install "npm" "$package"; then
                    if install_npm_package "$pkg_name"; then
                        echo "  ✓ $package (installed)"
                    else
                        failed_deps+=("npm: $package")
                    fi
                else
                    failed_deps+=("npm: $package")
                fi
            fi
        done <<< "$npm_deps"
        echo ""
    fi

    # Run verification commands
    local check_commands=$(parse_task_dependencies "$task_file" "check_commands")
    if [ -n "$check_commands" ]; then
        echo "Verification checks:"
        while IFS= read -r check_cmd; do
            [ -z "$check_cmd" ] && continue

            if verify_check_command "$check_cmd"; then
                :  # Success logged by verify function
            else
                failed_checks+=("$check_cmd")
            fi
        done <<< "$check_commands"
        echo ""
    fi

    # Report results
    if [ ${#failed_deps[@]} -eq 0 ] && [ ${#failed_checks[@]} -eq 0 ]; then
        echo "✅ All dependencies satisfied"
        echo ""
        return 0
    else
        echo "❌ Dependency check failed"
        echo ""

        if [ ${#failed_deps[@]} -gt 0 ]; then
            echo "Missing dependencies:"
            for dep in "${failed_deps[@]}"; do
                echo "  - $dep"
            done
            echo ""
        fi

        if [ ${#failed_checks[@]} -gt 0 ]; then
            echo "Failed verification checks:"
            for check in "${failed_checks[@]}"; do
                echo "  - $check"
            done
            echo ""
        fi

        echo "Fix these issues and re-run Ralph."
        echo ""
        echo "To skip dependency checks, set: RALPH_SKIP_DEPS=true"
        echo "To auto-install dependencies, set: RALPH_AUTO_INSTALL=true"
        echo ""

        return 1
    fi
}

# =============================================================================
# PROGRESS TRACKING
# =============================================================================

# Function: Summarize last N iterations from progress.md
# Creates a condensed summary for context rotation
summarize_progress() {
    local start_iter=$1
    local end_iter=$2

    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "No progress file found"
        return
    fi

    # Extract content between "Iteration $start_iter" and "Iteration $end_iter" sections
    # If that's not possible, summarize the whole file
    local summary="## Summary (Iterations $start_iter-$end_iter)\n\n"
    summary+="**Generated**: $(date '+%Y-%m-%d %H:%M:%S')\n\n"

    # Extract completed work mentions
    local completed_items=$(grep -E "^\*\*Completed|^- \[x\]|^[0-9]+\." "$PROGRESS_FILE" | head -20 || echo "")
    if [ -n "$completed_items" ]; then
        summary+="**Key accomplishments**:\n$completed_items\n\n"
    fi

    # Extract any error mentions
    local errors=$(grep -i -E "error|fail|issue|problem" "$PROGRESS_FILE" | head -5 || echo "")
    if [ -n "$errors" ]; then
        summary+="**Issues encountered**:\n$errors\n\n"
    fi

    summary+="---\n"
    echo -e "$summary"
}

# Function: Get checksum of guardrails file (for Sign detection)
get_guardrails_checksum() {
    if [ -f "$GUARDRAILS_FILE" ]; then
        md5sum "$GUARDRAILS_FILE" 2>/dev/null | cut -d' ' -f1 || echo ""
    else
        echo ""
    fi
}

# Function: Check if guardrails was modified (Sign added)
check_for_new_sign() {
    local old_checksum=$1
    local new_checksum=$(get_guardrails_checksum)

    if [ -n "$old_checksum" ] && [ "$old_checksum" != "$new_checksum" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function: Rotate context at milestone iterations
# Appends a summary to progress.md to compress context
rotate_context() {
    local current_iter=$1
    local start_iter=$((current_iter - 9))
    [ $start_iter -lt 1 ] && start_iter=1

    echo ""
    echo "🔄 Context rotation at iteration $current_iter"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Context rotation at iteration $current_iter" >> "$ACTIVITY_LOG"

    # Generate and append summary
    local summary=$(summarize_progress $start_iter $current_iter)
    echo "" >> "$PROGRESS_FILE"
    echo -e "$summary" >> "$PROGRESS_FILE"

    echo "Summary for iterations $start_iter-$current_iter added to progress.md"
}

# RAG Integration Functions
RAG_CONTEXT_FILE="$TASK_DIR/rag-context.txt"
RAG_ENDPOINT="${RAG_ENDPOINT:-http://localhost:8080}"
RAG_AVAILABLE=""

# Function: Check if Local RAG is available
check_rag_available() {
    # Try to reach RAG endpoint (with 2 second timeout)
    if curl -s --connect-timeout 2 "$RAG_ENDPOINT/status" > /dev/null 2>&1; then
        echo "true"
    elif curl -s --connect-timeout 2 "$RAG_ENDPOINT/health" > /dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

# Function: Query RAG for relevant context
query_rag_context() {
    local query="$1"
    local result=""

    # Try the query endpoint
    result=$(curl -s --connect-timeout 5 -X POST "$RAG_ENDPOINT/query" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\", \"top_k\": 5}" 2>/dev/null)

    if [ -n "$result" ] && [ "$result" != "null" ]; then
        echo "$result"
    else
        echo ""
    fi
}

# Function: Get RAG context for current task and save it
fetch_rag_context() {
    local task_name="$1"

    if [ "$RAG_AVAILABLE" != "true" ]; then
        return
    fi

    echo "🔍 Querying Local RAG for relevant context..."

    # Query for task-related context
    local query="$task_name Ralph task workflow guidelines documentation"
    local context=$(query_rag_context "$query")

    if [ -n "$context" ]; then
        echo "# RAG Context for $task_name" > "$RAG_CONTEXT_FILE"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$RAG_CONTEXT_FILE"
        echo "" >> "$RAG_CONTEXT_FILE"
        echo "$context" >> "$RAG_CONTEXT_FILE"
        echo "✓ RAG context saved to rag-context.txt"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] RAG context queried and saved" >> "$ACTIVITY_LOG"
    else
        echo "⚠️  No RAG results returned"
    fi
}

# Check RAG availability at startup (optional HTTP endpoint - MCP RAG is used via prompt)
RAG_AVAILABLE=$(check_rag_available)
if [ "$RAG_AVAILABLE" = "true" ]; then
    echo "✓ Local RAG HTTP endpoint available at $RAG_ENDPOINT"
fi
# Note: MCP local-rag is always available to cursor-agent via the prompt instruction

# Check task dependencies (unless explicitly skipped)
if [ "${RALPH_SKIP_DEPS:-false}" != "true" ]; then
    if ! check_and_install_dependencies "$TASK_FILE"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependency check failed" >> "$ACTIVITY_LOG"
        exit 1
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All dependencies satisfied" >> "$ACTIVITY_LOG"
fi

# Get current iteration (strip CRLF for Windows line endings)
ITERATION=$(tr -d '\r' < "$ITERATION_FILE" 2>/dev/null || echo "0")
ITERATION=$(echo "$ITERATION" | tr -d '[:space:]')
ITERATION=${ITERATION:-0}

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Wiggum - AUTONOMOUS MODE (Multi-Task)   ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Task: $TASK_NAME"
echo "Task directory: $TASK_DIR"
echo "Starting autonomous loop..."
echo "Max iterations: $MAX_ITERATIONS"
echo "Current iteration: $ITERATION"
echo ""
echo "Press Ctrl+C to stop at any time"
echo ""
sleep 2

# Main autonomous loop
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "$ITERATION" > "$ITERATION_FILE"

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "Task: $TASK_NAME | Iteration $ITERATION / $MAX_ITERATIONS"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════"
    echo ""

    # Log to activity log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION started" >> "$ACTIVITY_LOG"

    # Store guardrails checksum before iteration (for Sign detection)
    GUARDRAILS_CHECKSUM=$(get_guardrails_checksum)

    # Fetch RAG context if available (every iteration for fresh context)
    if [ "$RAG_AVAILABLE" = "true" ]; then
        fetch_rag_context "$TASK_NAME"
    fi

    # Build the prompt (and track its size for cost estimation)
    PROMPT="Start Ralph iteration $ITERATION for task: $TASK_NAME

Follow the Ralph protocol:

1. Read $TASK_FILE for task definition
2. Read $GUARDRAILS_FILE for lessons learned
3. Read $PROGRESS_FILE to see current state
4. Work on next unchecked [ ] criterion
5. Commit frequently: git commit -m 'ralph($TASK_NAME): [criterion] - change'
6. Update $PROGRESS_FILE when done
7. Check off criterion in $TASK_FILE
8. Commit state files

Current focus: First unchecked criterion in $TASK_FILE

Task directory: $TASK_DIR

CONTEXT ENRICHMENT (do this FIRST before reading task files):
Use the local-rag MCP tool 'query_documents' to search for relevant context:
- Query: '$TASK_NAME project context user preferences'
- This may return helpful information about the user's projects, preferences, and related documentation
- Use any relevant results to inform your approach to the task"

    # If previous iteration failed, add Sign prompt
    if [ $LAST_FAILURE_ITERATION -gt 0 ] && [ "$SIGN_PROMPTED" = "false" ]; then
        PROMPT="$PROMPT

IMPORTANT - PREVIOUS ITERATION FAILED:
Iteration $LAST_FAILURE_ITERATION failed. Before continuing with the task:
1. Analyze what went wrong in the previous iteration
2. Add a Sign to $GUARDRAILS_FILE explaining this failure
3. Use this format in the 'Active Signs' section:
   ### Sign: [Short description]
   - **Trigger**: When this rule should be applied
   - **Instruction**: What to do instead
   - **Added after**: Iteration $LAST_FAILURE_ITERATION - [brief cause description]
4. Commit the guardrails update
5. Then continue with the task"

        SIGN_PROMPTED=true
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sign prompt added (failure at iteration $LAST_FAILURE_ITERATION)" >> "$ACTIVITY_LOG"
        echo ""
        echo "📝 Prompting for Sign creation (previous iteration failed)"
    fi

    # Run cursor-agent in print mode (non-interactive, autonomous)
    cursor-agent -p --force --output-format text "$PROMPT"
    EXIT_CODE=$?

    # Log estimated cost for this iteration
    PROMPT_LENGTH=${#PROMPT}
    log_iteration_cost $ITERATION $PROMPT_LENGTH

    if [ $EXIT_CODE -ne 0 ]; then
        echo ""
        echo "⚠️  Iteration $ITERATION failed with exit code $EXIT_CODE"
        echo "Logged to $ACTIVITY_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION failed (exit $EXIT_CODE)" >> "$ACTIVITY_LOG"

        # Track failure for Sign prompting in next iteration
        LAST_FAILURE_ITERATION=$ITERATION
        SIGN_PROMPTED=false
        echo "📋 Will prompt for Sign creation in next iteration"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $ITERATION completed" >> "$ACTIVITY_LOG"

        # Check if Sign was added (guardrails modified) after we prompted for one
        if [ "$SIGN_PROMPTED" = "true" ]; then
            SIGN_ADDED=$(check_for_new_sign "$GUARDRAILS_CHECKSUM")
            if [ "$SIGN_ADDED" = "true" ]; then
                echo "✅ Sign added to guardrails.md"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sign added to guardrails (failure at iteration $LAST_FAILURE_ITERATION)" >> "$ACTIVITY_LOG"
                # Reset failure tracking
                LAST_FAILURE_ITERATION=0
            else
                echo "⚠️  Sign prompt was given but guardrails.md was not modified"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sign prompt given but guardrails not modified" >> "$ACTIVITY_LOG"
            fi
        fi
    fi

    # Context rotation: Every 10 iterations, summarize progress for fresh context
    if [ $((ITERATION % 10)) -eq 0 ]; then
        rotate_context $ITERATION
    fi

    # Check if task is complete (checkboxes OR promise marker)
    # Strip CRLF to handle Windows line endings
    UNCHECKED=$(tr -d '\r' < "$TASK_FILE" | grep -c '\[ \]' || echo "0")
    CHECKED=$(tr -d '\r' < "$TASK_FILE" | grep -c '\[x\]' || echo "0")
    # Ensure numeric values
    UNCHECKED=$(echo "$UNCHECKED" | tr -d '[:space:]')
    CHECKED=$(echo "$CHECKED" | tr -d '[:space:]')
    UNCHECKED=${UNCHECKED:-0}
    CHECKED=${CHECKED:-0}
    TOTAL=$((UNCHECKED + CHECKED))

    # Check for promise marker as alternative completion method
    PROMISE_COMPLETE=$(tr -d '\r' < "$TASK_FILE" | grep -c '<promise>COMPLETE</promise>' || echo "0")
    PROMISE_COMPLETE=$(echo "$PROMISE_COMPLETE" | tr -d '[:space:]')
    PROMISE_COMPLETE=${PROMISE_COMPLETE:-0}

    # Determine completion method and status
    COMPLETION_METHOD=""
    TASK_COMPLETE=false

    if [ "$PROMISE_COMPLETE" -gt 0 ]; then
        TASK_COMPLETE=true
        if [ "$UNCHECKED" = "0" ] && [ "$TOTAL" -gt 0 ]; then
            COMPLETION_METHOD="both checkboxes and promise marker"
        else
            COMPLETION_METHOD="promise marker"
        fi
    elif [ "$UNCHECKED" = "0" ] && [ "$TOTAL" -gt 0 ]; then
        TASK_COMPLETE=true
        COMPLETION_METHOD="checkboxes"
    fi

    if [ "$TASK_COMPLETE" = true ]; then
        echo ""
        echo "✅ TASK COMPLETE!"
        if [ "$TOTAL" -gt 0 ]; then
            echo "Completed: $CHECKED / $TOTAL criteria"
        fi
        echo "Completion method: $COMPLETION_METHOD"
        echo ""
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Task completed! Completed via: $COMPLETION_METHOD" >> "$ACTIVITY_LOG"
        break
    fi

    echo ""
    echo "Progress: $CHECKED / $TOTAL criteria complete ($UNCHECKED remaining)"
    echo "Continuing to next iteration..."
    sleep 2
done

if [ $ITERATION -ge $MAX_ITERATIONS ]; then
    echo ""
    echo "⚠️  Max iterations ($MAX_ITERATIONS) reached"
    echo "Task may not be complete. Check $TASK_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max iterations reached" >> "$ACTIVITY_LOG"
fi

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Autonomous Loop Complete                 ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Task: $TASK_NAME"
echo "Total iterations: $ITERATION"

# Show cost summary
TOTAL_COST=$(calculate_total_cost)
echo "Estimated total cost: ~\$$TOTAL_COST"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Total estimated cost: ~\$$TOTAL_COST" >> "$COST_LOG"

echo ""
echo "Review commits: git log --oneline --grep='ralph($TASK_NAME):'"
echo "Activity log: $ACTIVITY_LOG"
echo "Cost log: $COST_LOG"
echo ""

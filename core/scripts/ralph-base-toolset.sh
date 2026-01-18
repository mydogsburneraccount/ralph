#!/bin/bash
# Ralph Base Toolset Installer
# Installs the standard development tools needed for most Ralph tasks
# Uses pipx for Python CLI tools and follows WSL/Linux best practices

set -euo pipefail

echo "╔════════════════════════════════════════════════════╗"
echo "║     Ralph Base Toolset Installer                  ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "This script installs common development tools for Ralph tasks."
echo "Uses pipx for Python CLI tools (best practice for isolated installs)."
echo ""

# Detect OS and package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Check if running in WSL
is_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        return 0
    fi
    return 1
}

PM=$(detect_package_manager)
IS_WSL=false
if is_wsl; then
    IS_WSL=true
    echo "🐧 Detected WSL environment"
fi

if [ "$PM" = "unknown" ]; then
    echo "❌ Could not detect package manager (apt/yum/dnf/brew)"
    echo "Please install tools manually."
    exit 1
fi

echo "📦 Detected package manager: $PM"
echo ""

# Check if running with sudo (for apt/yum/dnf)
if [ "$PM" = "apt" ] || [ "$PM" = "yum" ] || [ "$PM" = "dnf" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  This script requires sudo for system package installation."
        echo "Please run with: sudo $0"
        echo ""
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# =============================================================================
# SYSTEM PACKAGES
# =============================================================================

echo "═══════════════════════════════════════════════════"
echo "1. System Packages"
echo "═══════════════════════════════════════════════════"
echo ""

SYSTEM_PACKAGES=(
    "curl"          # HTTP client
    "wget"          # File downloader
    "git"           # Version control
    "jq"            # JSON processor
    "unzip"         # Archive extraction
    "ca-certificates" # SSL certificates
    "build-essential" # Compilation tools (apt)
)

case "$PM" in
    apt)
        echo "Updating package list..."
        sudo apt-get update -qq

        # Core packages for apt
        APT_PACKAGES=(
            "curl"
            "wget"
            "git"
            "jq"
            "unzip"
            "ca-certificates"
            "build-essential"
            "software-properties-common"
        )

        for pkg in "${APT_PACKAGES[@]}"; do
            if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
                echo "  ✓ $pkg (already installed)"
            else
                echo "  Installing $pkg..."
                sudo apt-get install -y "$pkg" 2>&1 | grep -v "^Reading\|^Building\|^The following"
            fi
        done
        ;;

    yum|dnf)
        echo "Installing system packages..."
        YUM_PACKAGES=(
            "curl"
            "wget"
            "git"
            "jq"
            "unzip"
            "ca-certificates"
        )

        for pkg in "${YUM_PACKAGES[@]}"; do
            if $PM list installed "$pkg" &>/dev/null; then
                echo "  ✓ $pkg (already installed)"
            else
                echo "  Installing $pkg..."
                sudo $PM install -y "$pkg"
            fi
        done

        # Development tools
        if $PM grouplist installed 2>/dev/null | grep -q "Development Tools"; then
            echo "  ✓ Development Tools (already installed)"
        else
            echo "  Installing Development Tools..."
            sudo $PM groupinstall -y "Development Tools"
        fi
        ;;

    brew)
        echo "Installing system packages..."
        BREW_PACKAGES=("curl" "wget" "git" "jq")
        
        for pkg in "${BREW_PACKAGES[@]}"; do
            if brew list "$pkg" &>/dev/null; then
                echo "  ✓ $pkg (already installed)"
            else
                echo "  Installing $pkg..."
                brew install "$pkg"
            fi
        done
        ;;
esac

echo ""
echo "✅ System packages installed"
echo ""

# =============================================================================
# PYTHON ENVIRONMENT
# =============================================================================

echo "═══════════════════════════════════════════════════"
echo "2. Python Environment"
echo "═══════════════════════════════════════════════════"
echo ""

# Determine the actual user (not root if using sudo)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    echo "Note: Running with sudo, but will install user packages for: $ACTUAL_USER"
else
    ACTUAL_USER="$USER"
    ACTUAL_HOME="$HOME"
fi

echo "User-level packages will be installed for: $ACTUAL_USER"
echo "Home directory: $ACTUAL_HOME"
echo ""

# Check for Python 3
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "✓ Python 3 installed: $PYTHON_VERSION"
else
    echo "Installing Python 3..."
    case "$PM" in
        apt)
            sudo apt-get install -y python3 python3-pip python3-venv python3-dev
            ;;
        yum|dnf)
            sudo $PM install -y python3 python3-pip python3-devel
            ;;
        brew)
            brew install python3
            ;;
    esac
fi

# Ensure ~/.local/bin is in PATH (WSL/Linux best practice)
if [[ ":$PATH:" != *":$ACTUAL_HOME/.local/bin:"* ]]; then
    echo ""
    echo "Adding ~/.local/bin to PATH..."
    
    # Determine shell config file for actual user
    SHELL_CONFIG=""
    if [ -n "$SUDO_USER" ]; then
        # Running with sudo, use actual user's shell config
        USER_SHELL=$(getent passwd "$SUDO_USER" | cut -d: -f7)
        if [[ "$USER_SHELL" == *"bash"* ]]; then
            SHELL_CONFIG="$ACTUAL_HOME/.bashrc"
        elif [[ "$USER_SHELL" == *"zsh"* ]]; then
            SHELL_CONFIG="$ACTUAL_HOME/.zshrc"
        fi
    else
        # Not using sudo
        if [ -n "$BASH_VERSION" ]; then
            SHELL_CONFIG="$ACTUAL_HOME/.bashrc"
        elif [ -n "$ZSH_VERSION" ]; then
            SHELL_CONFIG="$ACTUAL_HOME/.zshrc"
        fi
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Add to config if not already there
        if ! grep -q "\.local/bin" "$SHELL_CONFIG" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
            if [ -n "$SUDO_USER" ]; then
                chown "$SUDO_USER:$SUDO_USER" "$SHELL_CONFIG"
            fi
            echo "  ✓ Added to $SHELL_CONFIG"
        else
            echo "  ✓ Already in $SHELL_CONFIG"
        fi
        export PATH="$ACTUAL_HOME/.local/bin:$PATH"
        echo "  ℹ️  User '$ACTUAL_USER' should run 'source $SHELL_CONFIG' or restart shell"
    fi
fi

# Check for pip
if command -v pip3 &> /dev/null; then
    echo "✓ pip3 installed"
else
    echo "Installing pip..."
    case "$PM" in
        apt)
            sudo apt-get install -y python3-pip
            ;;
        yum|dnf)
            sudo $PM install -y python3-pip
            ;;
        brew)
            # pip comes with python3 on brew
            :
            ;;
    esac
fi

# Install pipx (best practice for Python CLI tools)
echo ""
echo "Installing pipx (for isolated Python CLI tool installation)..."

if command -v pipx &> /dev/null; then
    echo "  ✓ pipx already installed: $(pipx --version)"
else
    case "$PM" in
        apt)
            # Ubuntu/Debian: use system package
            if sudo apt-cache show pipx &>/dev/null; then
                echo "  Installing pipx via apt..."
                sudo apt-get install -y pipx
            else
                echo "  Installing pipx via pip..."
                if [ -n "$SUDO_USER" ]; then
                    # Install for actual user, not root
                    sudo -u "$SUDO_USER" python3 -m pip install --user pipx
                else
                    python3 -m pip install --user pipx
                fi
            fi
            ;;
        yum|dnf)
            echo "  Installing pipx via pip..."
            if [ -n "$SUDO_USER" ]; then
                sudo -u "$SUDO_USER" python3 -m pip install --user pipx
            else
                python3 -m pip install --user pipx
            fi
            ;;
        brew)
            echo "  Installing pipx via brew..."
            brew install pipx
            ;;
    esac
    
    # Ensure pipx paths are set up (as actual user)
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" pipx ensurepath --force 2>/dev/null || true
    else
        pipx ensurepath --force 2>/dev/null || true
    fi
    
    export PATH="$ACTUAL_HOME/.local/bin:$PATH"
    
    if command -v pipx &> /dev/null; then
        echo "  ✓ pipx installed successfully"
    fi
fi

# Common Python CLI tools (installed via pipx for isolation)
echo ""
echo "Installing Python CLI tools via pipx..."

PIPX_TOOLS=(
    "pytest"        # Testing framework
    "black"         # Code formatter
    "ruff"          # Fast linter
    "mypy"          # Type checker
    "ipython"       # Enhanced Python REPL
)

for tool in "${PIPX_TOOLS[@]}"; do
    # Check if already installed (for actual user)
    TOOL_INSTALLED=false
    if [ -n "$SUDO_USER" ]; then
        if sudo -u "$SUDO_USER" bash -c "command -v $tool &> /dev/null || pipx list 2>/dev/null | grep -q 'package $tool'"; then
            TOOL_INSTALLED=true
        fi
    else
        if command -v "$tool" &> /dev/null || pipx list 2>/dev/null | grep -q "package $tool"; then
            TOOL_INSTALLED=true
        fi
    fi
    
    if [ "$TOOL_INSTALLED" = true ]; then
        echo "  ✓ $tool (already installed)"
    else
        echo "  Installing $tool via pipx..."
        if [ -n "$SUDO_USER" ]; then
            # Install as actual user, not root
            sudo -u "$SUDO_USER" pipx install "$tool" --quiet 2>&1 | grep -v "^  installed package" || true
        else
            pipx install "$tool" --quiet 2>&1 | grep -v "^  installed package" || true
        fi
    fi
done

# Common Python libraries (for use in scripts, not CLI tools)
echo ""
echo "Installing common Python libraries..."

# On PEP 668 systems, prefer system packages for libraries
PYTHON_LIBRARIES=(
    "requests"      # HTTP library
    "pyyaml"        # YAML parser
    "python-dotenv" # .env file support
)

for lib in "${PYTHON_LIBRARIES[@]}"; do
    # Convert package name to import name
    import_name="${lib//-/_}"
    
    if python3 -c "import ${import_name}" &>/dev/null; then
        echo "  ✓ $lib (already installed)"
    else
        echo "  Installing $lib..."
        
        # Try system package first (for PEP 668 systems)
        if [ "$PM" = "apt" ]; then
            # Map common package names to apt packages
            case "$lib" in
                "requests")
                    apt_pkg="python3-requests"
                    ;;
                "pyyaml")
                    apt_pkg="python3-yaml"
                    ;;
                "python-dotenv")
                    apt_pkg="python3-dotenv"
                    ;;
                *)
                    apt_pkg="python3-${lib}"
                    ;;
            esac
            
            if sudo apt-cache show "$apt_pkg" &>/dev/null; then
                echo "    Using system package: $apt_pkg"
                sudo apt-get install -y "$apt_pkg" 2>&1 | grep -v "^Reading\|^Building\|^The following" || true
            else
                echo "    System package not available, trying pip..."
                # Try pip with --break-system-packages as last resort
                if ! python3 -m pip install --user "$lib" --quiet 2>&1; then
                    python3 -m pip install --user "$lib" --break-system-packages --quiet 2>&1 || echo "    ⚠️  Could not install $lib"
                fi
            fi
        else
            # Non-apt systems: try pip
            if ! python3 -m pip install --user "$lib" --quiet 2>&1; then
                python3 -m pip install --user "$lib" --break-system-packages --quiet 2>&1 || echo "    ⚠️  Could not install $lib"
            fi
        fi
    fi
done

echo ""
echo "✅ Python environment configured with pipx"
echo ""

# =============================================================================
# NODE.JS ENVIRONMENT
# =============================================================================

echo "═══════════════════════════════════════════════════"
echo "3. Node.js Environment"
echo "═══════════════════════════════════════════════════"
echo ""

# Check for Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js installed: $NODE_VERSION"
else
    echo "Node.js not found. Installing..."

    case "$PM" in
        apt)
            # Install via NodeSource (latest LTS)
            echo "Installing Node.js from NodeSource..."
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        yum)
            echo "Installing Node.js from NodeSource..."
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs
            ;;
        dnf)
            echo "Installing Node.js from NodeSource..."
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo dnf install -y nodejs
            ;;
        brew)
            brew install node
            ;;
    esac
fi

# Check for npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✓ npm installed: $NPM_VERSION"
else
    echo "⚠️  npm not found (should come with Node.js)"
fi

# Configure npm for user-level global installs (best practice)
if command -v npm &> /dev/null; then
    echo ""
    echo "Configuring npm for user-level global installs..."
    
    # Configure for actual user (not root if using sudo)
    if [ -n "$SUDO_USER" ]; then
        # Get actual user's npm prefix
        NPM_PREFIX=$(sudo -u "$SUDO_USER" npm config get prefix)
        if [ "$NPM_PREFIX" != "$ACTUAL_HOME/.local" ]; then
            sudo -u "$SUDO_USER" npm config set prefix "$ACTUAL_HOME/.local"
            echo "  ✓ Set npm prefix to ~/.local for $ACTUAL_USER"
        else
            echo "  ✓ npm prefix already configured for $ACTUAL_USER"
        fi
    else
        # Set npm prefix to ~/.local if not already set
        NPM_PREFIX=$(npm config get prefix)
        if [ "$NPM_PREFIX" != "$HOME/.local" ]; then
            npm config set prefix "$HOME/.local"
            echo "  ✓ Set npm prefix to ~/.local"
        else
            echo "  ✓ npm prefix already configured"
        fi
    fi
    
    # Ensure ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$ACTUAL_HOME/.local/bin:"* ]]; then
        export PATH="$ACTUAL_HOME/.local/bin:$PATH"
        echo "  ✓ ~/.local/bin added to PATH for this session"
    fi
fi

# Common npm packages
if command -v npm &> /dev/null; then
    echo ""
    echo "Installing common npm packages..."
    echo ""
    echo "These packages will be installed globally for Ralph tasks."
    echo "You can skip any of them if not needed for your workflow."
    echo ""

    # Core packages (usually needed)
    NPM_CORE_PACKAGES=(
        "typescript"    # TypeScript compiler - widely used
        "prettier"      # Code formatter - no dependencies, fast
    )

    # Optional packages (ask before installing)
    NPM_OPTIONAL_PACKAGES=(
        "eslint"        # JavaScript linter - large but useful
        "vitest"        # Modern test framework (replaces jest, no deprecated deps)
        "@types/node"   # TypeScript definitions for Node.js
    )

    # Install core packages
    for pkg in "${NPM_CORE_PACKAGES[@]}"; do
        # Check if already installed
        PKG_INSTALLED=false
        if [ -n "$SUDO_USER" ]; then
            if sudo -u "$SUDO_USER" npm list -g --depth=0 "$pkg" &>/dev/null; then
                PKG_INSTALLED=true
            fi
        else
            if npm list -g --depth=0 "$pkg" &>/dev/null; then
                PKG_INSTALLED=true
            fi
        fi
        
        if [ "$PKG_INSTALLED" = true ]; then
            echo "  ✓ $pkg (already installed)"
        else
            echo "  Installing $pkg..."
            if [ -n "$SUDO_USER" ]; then
                sudo -u "$SUDO_USER" npm install -g "$pkg" 2>&1 | grep -v "^npm warn" || true
            else
                npm install -g "$pkg" 2>&1 | grep -v "^npm warn" || true
            fi
        fi
    done

    echo ""
    echo "Optional packages (recommended but not required):"
    
    # Ask about optional packages
    for pkg in "${NPM_OPTIONAL_PACKAGES[@]}"; do
        # Check if already installed
        PKG_INSTALLED=false
        if [ -n "$SUDO_USER" ]; then
            if sudo -u "$SUDO_USER" npm list -g --depth=0 "$pkg" &>/dev/null; then
                PKG_INSTALLED=true
            fi
        else
            if npm list -g --depth=0 "$pkg" &>/dev/null; then
                PKG_INSTALLED=true
            fi
        fi
        
        if [ "$PKG_INSTALLED" = true ]; then
            echo "  ✓ $pkg (already installed)"
        else
            read -p "Install $pkg? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "  Installing $pkg..."
                if [ -n "$SUDO_USER" ]; then
                    sudo -u "$SUDO_USER" npm install -g "$pkg" 2>&1 | grep -v "^npm warn" || true
                else
                    npm install -g "$pkg" 2>&1 | grep -v "^npm warn" || true
                fi
            else
                echo "  Skipped $pkg"
            fi
        fi
    done
fi

echo ""
echo "✅ Node.js environment configured"
echo ""
echo "Note: Replaced 'jest' with 'vitest' - modern alternative with no deprecated dependencies"
echo "      vitest is faster, has better ESM support, and actively maintained"
echo ""

# =============================================================================
# DOCKER (OPTIONAL)
# =============================================================================

echo "═══════════════════════════════════════════════════"
echo "4. Docker (Optional)"
echo "═══════════════════════════════════════════════════"
echo ""

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo "✓ Docker installed: $DOCKER_VERSION"

    # Check if Docker daemon is running
    if docker ps &>/dev/null; then
        echo "✓ Docker daemon is running"
    else
        echo "⚠️  Docker installed but daemon not running"
        if [ "$IS_WSL" = true ]; then
            echo "   For WSL: Ensure Docker Desktop for Windows is running"
            echo "   Or install Docker inside WSL with: sudo systemctl start docker"
        else
            echo "   Start Docker with: sudo systemctl start docker"
        fi
    fi
else
    echo "Docker not installed."
    echo ""
    read -p "Install Docker? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        case "$PM" in
            apt)
                echo "Installing Docker..."
                
                # Remove old Docker packages
                sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
                
                # Add Docker's official GPG key
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg

                # Detect Ubuntu/Debian version
                if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    DISTRO="ubuntu"
                    VERSION_CODENAME="${VERSION_CODENAME:-jammy}"
                fi

                # Add Docker repository
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
                  $VERSION_CODENAME stable" | \
                  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                # Install Docker
                sudo apt-get update -qq
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                # Add user to docker group
                sudo usermod -aG docker "$USER"
                
                # Start Docker service
                if [ "$IS_WSL" = true ]; then
                    echo "✅ Docker installed for WSL."
                    echo "   Note: You may want to use Docker Desktop for Windows instead."
                    echo "   If using Docker in WSL, start with: sudo systemctl start docker"
                else
                    sudo systemctl enable docker
                    sudo systemctl start docker
                    echo "✅ Docker installed and started."
                fi
                
                echo "   Log out and back in for group changes to take effect."
                ;;

            yum|dnf)
                echo "Installing Docker..."
                sudo $PM install -y yum-utils 2>/dev/null || true
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || \
                sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo $PM install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker "$USER"
                echo "✅ Docker installed. Log out and back in for group changes to take effect."
                ;;

            brew)
                echo "Installing Docker..."
                brew install --cask docker
                echo "✅ Docker installed. Start Docker Desktop from Applications."
                ;;
        esac
    else
        echo "Skipping Docker installation."
    fi
fi

echo ""

# =============================================================================
# HELPER FUNCTIONS FOR DYNAMIC DEPENDENCY INSTALLATION
# =============================================================================

echo "═══════════════════════════════════════════════════"
echo "5. Dependency Installation Helpers"
echo "═══════════════════════════════════════════════════"
echo ""

# Create a helper script for Ralph to install dependencies on-the-fly
# Install to actual user's .local/bin, not root's
HELPER_SCRIPT="$ACTUAL_HOME/.local/bin/ralph-install-dependency"

# Create directory if needed
mkdir -p "$ACTUAL_HOME/.local/bin"
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$ACTUAL_HOME/.local/bin"
fi

cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/bin/bash
# Ralph Dependency Installer Helper
# Allows Ralph agents to install dependencies as needed
# Usage: ralph-install-dependency <type> <package>
#   Types: system, python, pipx, npm

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: ralph-install-dependency <type> <package>"
    echo "Types: system, python, pipx, npm"
    echo ""
    echo "Examples:"
    echo "  ralph-install-dependency system jq"
    echo "  ralph-install-dependency python requests"
    echo "  ralph-install-dependency pipx aider-chat"
    echo "  ralph-install-dependency npm typescript"
    exit 1
fi

TYPE="$1"
PACKAGE="$2"

# Detect package manager
if command -v apt-get &> /dev/null; then
    PM="apt"
elif command -v dnf &> /dev/null; then
    PM="dnf"
elif command -v yum &> /dev/null; then
    PM="yum"
elif command -v brew &> /dev/null; then
    PM="brew"
else
    echo "❌ No supported package manager found"
    exit 1
fi

case "$TYPE" in
    system)
        echo "Installing system package: $PACKAGE"
        case "$PM" in
            apt)
                sudo apt-get update -qq
                sudo apt-get install -y "$PACKAGE"
                ;;
            yum|dnf)
                sudo $PM install -y "$PACKAGE"
                ;;
            brew)
                brew install "$PACKAGE"
                ;;
        esac
        ;;
    
    python)
        echo "Installing Python library: $PACKAGE"
        
        # Try system package first on apt systems (for PEP 668 compatibility)
        if [ "$PM" = "apt" ]; then
            # Map common packages to apt package names
            case "$PACKAGE" in
                "requests")
                    APT_PKG="python3-requests"
                    ;;
                "pyyaml"|"PyYAML")
                    APT_PKG="python3-yaml"
                    ;;
                "python-dotenv")
                    APT_PKG="python3-dotenv"
                    ;;
                *)
                    APT_PKG="python3-${PACKAGE}"
                    ;;
            esac
            
            if sudo apt-cache show "$APT_PKG" &>/dev/null; then
                echo "Using system package: $APT_PKG"
                sudo apt-get update -qq
                sudo apt-get install -y "$APT_PKG"
                exit 0
            fi
        fi
        
        # Fall back to pip
        if ! python3 -m pip install --user "$PACKAGE" 2>&1; then
            echo "⚠️  Standard install failed, trying --break-system-packages..."
            python3 -m pip install --user "$PACKAGE" --break-system-packages
        fi
        ;;
    
    pipx)
        echo "Installing Python CLI tool via pipx: $PACKAGE"
        if ! command -v pipx &> /dev/null; then
            echo "pipx not found, installing..."
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath --force
        fi
        pipx install "$PACKAGE"
        ;;
    
    npm)
        echo "Installing npm package: $PACKAGE"
        if ! command -v npm &> /dev/null; then
            echo "❌ npm not found. Install Node.js first."
            exit 1
        fi
        npm install -g "$PACKAGE"
        ;;
    
    *)
        echo "❌ Unknown type: $TYPE"
        echo "Supported types: system, python, pipx, npm"
        exit 1
        ;;
esac

echo "✅ Successfully installed: $PACKAGE"
HELPER_EOF

chmod +x "$HELPER_SCRIPT"
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$HELPER_SCRIPT"
fi

echo "✓ Created helper script: $HELPER_SCRIPT"
echo ""
echo "Ralph agents can now install dependencies with:"
echo "  ralph-install-dependency system <package>"
echo "  ralph-install-dependency python <package>"
echo "  ralph-install-dependency pipx <package>"
echo "  ralph-install-dependency npm <package>"
echo ""
echo "✅ Dependency installation helpers configured"
echo ""

if [ -n "$SUDO_USER" ]; then
    echo "Note: This script was run with sudo, but user packages were installed for: $ACTUAL_USER"
    echo "      User '$ACTUAL_USER' can now use all installed tools."
    echo ""
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo "═══════════════════════════════════════════════════"
echo "Installation Complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Installed tools:"
echo "  ✓ System utilities (curl, wget, git, jq, etc.)"
echo "  ✓ Python 3 + pip + pipx"
echo "  ✓ Python CLI tools via pipx (pytest, black, ruff, mypy, ipython)"
echo "  ✓ Python libraries (requests, pyyaml, python-dotenv)"
echo "  ✓ Node.js + npm (with user-level global installs)"
echo "  ✓ Common npm packages (typescript, eslint, prettier, jest)"
echo "  ✓ Dependency installation helper (ralph-install-dependency)"

if command -v docker &> /dev/null; then
    echo "  ✓ Docker"
else
    echo "  ⊘ Docker (skipped)"
fi

echo ""
echo "Best practices applied:"
echo "  ✓ pipx used for Python CLI tools (isolated environments)"
echo "  ✓ User-level installs (~/.local) instead of system-wide"
echo "  ✓ PATH configured for ~/.local/bin"
echo "  ✓ npm configured for user-level global installs"

if [ "$IS_WSL" = true ]; then
    echo "  ✓ WSL-specific optimizations applied"
fi

echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "  2. Verify installations:"
echo "     - python3 --version"
echo "     - pipx --version"
echo "     - node --version"
echo "     - npm --version"
echo "  3. Install additional dependencies:"
echo "     - ralph-install-dependency <type> <package>"
echo "  4. Run Ralph tasks:"
echo "     - cd .ralph && ./scripts/ralph-autonomous.sh <task-name>"
echo ""
echo "For task-specific dependencies, add them to TASK.md frontmatter."
echo "See .ralph/docs/RALPH_RULES.md for dependency declaration format."
echo ""

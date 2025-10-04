#!/bin/bash
# Task Tracker - Quick Start Script
# Automates setup for Ubuntu and other Linux systems

set -e

echo "================================================================"
echo "  📸 Task Tracker - Quick Start Setup"
echo "================================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${YELLOW}⚠️  This script is for Linux systems.${NC}"
    echo "For Windows, please follow the manual setup in README.md"
    exit 1
fi

# Step 1: Check for Go installation
echo -e "${YELLOW}Step 1: Checking for Go installation...${NC}"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo -e "${GREEN}✅ Go is installed: $GO_VERSION${NC}"
else
    echo -e "${RED}❌ Go is not installed${NC}"
    echo ""
    echo "Installing Go..."
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        GO_ARCH="amd64"
    elif [ "$ARCH" == "aarch64" ]; then
        GO_ARCH="arm64"
    else
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
    fi
    
    # Download and install Go
    GO_VERSION="1.21.6"
    wget "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    # Add to PATH
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    
    echo -e "${GREEN}✅ Go installed successfully${NC}"
fi

# Step 2: Install system dependencies
echo ""
echo -e "${YELLOW}Step 2: Installing system dependencies...${NC}"

if command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu system"
    sudo apt-get update -qq
    sudo apt-get install -y libx11-dev xorg-dev libxtst-dev build-essential
    echo -e "${GREEN}✅ Dependencies installed${NC}"
elif command -v dnf &> /dev/null; then
    echo "Detected Fedora/RHEL system"
    sudo dnf install -y libX11-devel libXtst-devel
    echo -e "${GREEN}✅ Dependencies installed${NC}"
elif command -v pacman &> /dev/null; then
    echo "Detected Arch system"
    sudo pacman -S --noconfirm libx11 libxtst
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  Unknown package manager. Please install X11 dev packages manually.${NC}"
fi

# Step 3: Build the project
echo ""
echo -e "${YELLOW}Step 3: Building Task Tracker...${NC}"

if [ ! -f "go.mod" ]; then
    echo -e "${RED}❌ go.mod not found. Are you in the project directory?${NC}"
    exit 1
fi

echo "Installing Go dependencies..."
go mod download
go mod tidy

echo "Building binaries..."
mkdir -p bin
go build -ldflags "-s -w" -o bin/task-tracker cmd/task-tracker/main.go
go build -ldflags "-s -w" -o bin/monitor-helper cmd/monitor-helper/main.go

chmod +x bin/task-tracker bin/monitor-helper

echo -e "${GREEN}✅ Build complete!${NC}"

# Step 4: Install to system (optional)
echo ""
echo -e "${YELLOW}Step 4: Installation${NC}"
echo "Where would you like to install?"
echo "  1) /usr/local/bin (system-wide, requires sudo)"
echo "  2) ~/.local/bin (user only, no sudo)"
echo "  3) Skip installation (use from ./bin/)"

read -p "Choice [1-3]: " INSTALL_CHOICE

case $INSTALL_CHOICE in
    1)
        echo "Installing to /usr/local/bin..."
        sudo cp bin/task-tracker /usr/local/bin/
        sudo cp bin/monitor-helper /usr/local/bin/
        echo -e "${GREEN}✅ Installed to /usr/local/bin${NC}"
        INSTALL_PATH="/usr/local/bin"
        ;;
    2)
        echo "Installing to ~/.local/bin..."
        mkdir -p ~/.local/bin
        cp bin/task-tracker ~/.local/bin/
        cp bin/monitor-helper ~/.local/bin/
        
        # Add to PATH if not already there
        if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            echo -e "${YELLOW}Added ~/.local/bin to PATH in ~/.bashrc${NC}"
            echo -e "${YELLOW}Run: source ~/.bashrc${NC}"
        fi
        
        echo -e "${GREEN}✅ Installed to ~/.local/bin${NC}"
        INSTALL_PATH="~/.local/bin"
        ;;
    3)
        echo "Skipping installation. Binaries are in ./bin/"
        INSTALL_PATH="./bin"
        ;;
    *)
        echo -e "${RED}Invalid choice. Skipping installation.${NC}"
        INSTALL_PATH="./bin"
        ;;
esac

# Step 5: Configure API key
echo ""
echo -e "${YELLOW}Step 5: Configure Anthropic API Key${NC}"
echo "Do you have an Anthropic API key?"
read -p "Enter API key (or press Enter to skip): " API_KEY

if [ ! -z "$API_KEY" ]; then
    # Add to .bashrc
    if ! grep -q "ANTHROPIC_API_KEY" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Task Tracker API Key" >> ~/.bashrc
        echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> ~/.bashrc
        echo -e "${GREEN}✅ API key added to ~/.bashrc${NC}"
        echo -e "${YELLOW}Run: source ~/.bashrc${NC}"
    else
        echo -e "${YELLOW}⚠️  ANTHROPIC_API_KEY already in ~/.bashrc${NC}"
    fi
    
    # Export for current session
    export ANTHROPIC_API_KEY="$API_KEY"
else
    echo -e "${YELLOW}⚠️  Skipping API key setup${NC}"
    echo "You can add it later with:"
    echo "  export ANTHROPIC_API_KEY=\"your-key-here\""
fi

# Step 6: Run monitor detection
echo ""
echo -e "${YELLOW}Step 6: Detect Monitors${NC}"
read -p "Would you like to detect your monitors now? (y/n): " DETECT_MONITORS

if [ "$DETECT_MONITORS" = "y" ] || [ "$DETECT_MONITORS" = "Y" ]; then
    if [ "$INSTALL_PATH" = "./bin" ]; then
        ./bin/monitor-helper detect
    else
        monitor-helper detect
    fi
    
    echo ""
    read -p "Run the interactive setup wizard? (y/n): " RUN_WIZARD
    
    if [ "$RUN_WIZARD" = "y" ] || [ "$RUN_WIZARD" = "Y" ]; then
        if [ "$INSTALL_PATH" = "./bin" ]; then
            ./bin/monitor-helper setup
        else
            monitor-helper setup
        fi
    fi
fi

# Step 7: Create desktop shortcut (optional)
echo ""
echo -e "${YELLOW}Step 7: Create Desktop Shortcut (optional)${NC}"
read -p "Create desktop shortcut? (y/n): " CREATE_SHORTCUT

if [ "$CREATE_SHORTCUT" = "y" ] || [ "$CREATE_SHORTCUT" = "Y" ]; then
    DESKTOP_FILE="$HOME/.local/share/applications/task-tracker.desktop"
    mkdir -p "$HOME/.local/share/applications"
    
    if [ "$INSTALL_PATH" = "./bin" ]; then
        EXEC_PATH="$(pwd)/bin/task-tracker"
    elif [ "$INSTALL_PATH" = "~/.local/bin" ]; then
        EXEC_PATH="$HOME/.local/bin/task-tracker"
    else
        EXEC_PATH="/usr/local/bin/task-tracker"
    fi
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Task Tracker
Comment=AI-powered task tracking with screen capture
Exec=$EXEC_PATH start --monitors all
Icon=camera-photo
Terminal=true
Type=Application
Categories=Utility;Development;
EOF
    
    chmod +x "$DESKTOP_FILE"
    echo -e "${GREEN}✅ Desktop shortcut created${NC}"
fi

# Summary
echo ""
echo "================================================================"
echo -e "  ${GREEN}✅ Setup Complete!${NC}"
echo "================================================================"
echo ""
echo -e "${GREEN}Installation Summary:${NC}"
echo "  • Binaries location: $INSTALL_PATH"
echo "  • Task Tracker: $INSTALL_PATH/task-tracker"
echo "  • Monitor Helper: $INSTALL_PATH/monitor-helper"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo "1. If you added API key, run:"
echo "   source ~/.bashrc"
echo ""
echo "2. Try it out:"
if [ "$INSTALL_PATH" = "./bin" ]; then
    echo "   ./bin/task-tracker start \"Test task\" --monitors all"
else
    echo "   task-tracker start \"Test task\" --monitors all"
fi
echo ""
echo "3. Get help:"
if [ "$INSTALL_PATH" = "./bin" ]; then
    echo "   ./bin/task-tracker --help"
    echo "   ./bin/monitor-helper --help"
else
    echo "   task-tracker --help"
    echo "   monitor-helper --help"
fi
echo ""
echo -e "${GREEN}Useful commands:${NC}"
if [ "$INSTALL_PATH" = "./bin" ]; then
    echo "  ./bin/monitor-helper detect       # Detect monitors"
    echo "  ./bin/monitor-helper setup        # Interactive setup"
    echo "  ./bin/task-tracker start 'Task'   # Start tracking"
else
    echo "  monitor-helper detect       # Detect monitors"
    echo "  monitor-helper setup        # Interactive setup"
    echo "  task-tracker start 'Task'   # Start tracking"
fi
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  README.md for full documentation"
echo "  https://docs.anthropic.com for Claude API"
echo ""
echo -e "${GREEN}Happy tracking! 🚀${NC}"
echo ""
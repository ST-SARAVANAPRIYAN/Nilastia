#!/usr/bin/env bash
set -e

# Log all output to install.log while keeping stdout/stderr visible
LOG_FILE="$(pwd)/install.log"
echo "Logging installer output to: $LOG_FILE"
exec > >(tee -i "$LOG_FILE") 2>&1

# Setup colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
  _   ___ _             _   _
 | \ | (_) |           | | (_)
 |  \| |_| | __ _  ___ | |_ _  __ _
 | . ` | | |/ _` |/ __|| __| |/ _` |
 | |\  | | | (_| |\__ \| |_| | (_| |
 |_| \_|_|_|\__,_||___/ \__|_|\__,_|
EOF
echo -e "${NC}"
echo -e "${CYAN}=== Starting Automated One-Line Installer ===${NC}"

# Check for Arch Linux (Nilastia requires Arch-based pacman & AUR setup)
if ! command -v pacman &> /dev/null; then
    echo -e "${RED}Error: Nilastia is designed for Arch Linux and Arch-based distributions (pacman required).${NC}"
    exit 1
fi

# Install minimal prerequisites for setup
echo -e "${GREEN}[1/4] Installing git, cmake, base-devel, and hostapd if missing...${NC}"
sudo pacman -S --needed --noconfirm git cmake base-devel hostapd

# Install hotspot repeater support if AUR helper is present
if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm linux-wifi-hotspot-bin || true
elif command -v yay &> /dev/null; then
    yay -S --needed --noconfirm linux-wifi-hotspot-bin || true
fi

# Get the directory where install.sh itself is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# The repository root is the parent folder of the extras/ directory
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Define download location
if [ -f "$REPO_ROOT/setup_nilastia.sh" ]; then
    INSTALL_DIR="$REPO_ROOT"
    echo -e "${GREEN}[2/4] Running from local repository directory: $INSTALL_DIR${NC}"
    cd "$INSTALL_DIR"
else
    INSTALL_DIR="$(pwd)/nilastia"
    echo -e "${GREEN}[2/4] Cloning Nilastia repository to $INSTALL_DIR...${NC}"
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Directory $INSTALL_DIR already exists, pulling latest updates...${NC}"
        cd "$INSTALL_DIR"
        git pull
    else
        git clone https://github.com/${1:-ST-SARAVANAPRIYAN}/Nilastia.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
fi

# Run CMake compilation and local shell registrations
echo -e "${GREEN}[3/4] Running local plugin compilation...${NC}"
./setup_nilastia.sh

# Run interactive installer command
echo -e "${GREEN}[4/4] Launching Nilastia Installer...${NC}"
export PATH="$HOME/.local/bin:$PATH"
nilastia install "$@"

echo -e "${CYAN}=== One-Line Installer Finished ===${NC}"

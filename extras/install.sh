#!/usr/bin/env bash
set -e

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
echo -e "${GREEN}[1/4] Installing git, cmake, and base-devel if missing...${NC}"
sudo pacman -S --needed --noconfirm git cmake base-devel

# Define download location
INSTALL_DIR="$HOME/projects/calestia/nilastia"
echo -e "${GREEN}[2/4] Cloning Nilastia repository to $INSTALL_DIR...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory $INSTALL_DIR already exists, pulling latest updates...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/${1:-nilastia-dots}/nilastia.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Run CMake compilation and local shell registrations
echo -e "${GREEN}[3/4] Running local plugin compilation...${NC}"
./setup_nilastia.sh

# Run interactive installer command
echo -e "${GREEN}[4/4] Launching Nilastia Installer...${NC}"
export PATH="$HOME/.local/bin:$PATH"
nilastia install

echo -e "${CYAN}=== One-Line Installer Finished ===${NC}"

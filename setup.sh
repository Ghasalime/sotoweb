#!/bin/bash

# SotoWeb - One-liner Installer
# Author: Ghasali

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> SotoWeb Installation Starting...${NC}"

# Internal Logging for Setup Script
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# 1. Dependency Check
echo -e "Checking for required tools (git, curl)..."
apt update -qq > /dev/null
apt install -y -qq git curl > /dev/null

# 2. Installation Path
INSTALL_PATH="/etc/sotoweb"

# 3. Clone or Update
if [[ -d "$INSTALL_PATH" ]]; then
    echo -e "Updating SotoWeb in $INSTALL_PATH..."
    cd "$INSTALL_PATH" && git pull -q
else
    echo -e "Cloning SotoWeb to $INSTALL_PATH..."
    # Correct public repository URL
    git clone https://github.com/Ghasalime/sotoweb.git "$INSTALL_PATH" -q
fi

# 4. Make binary executable
chmod +x "$INSTALL_PATH/bin/soto"

# 5. Symlink to /usr/local/bin
# 6. Automatic LEMP Stack Installation
echo -e "${BLUE}>>> Installing LEMP Stack (Nginx, MariaDB, PHP 8.3)...${NC}"
soto stack -install

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}>>> SotoWeb has been installed successfully!${NC}"
    echo "You can now run 'sudo soto help' to get started."
else
    echo "Installation failed. Please run with sudo."
fi

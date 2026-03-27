#!/bin/bash

# SotoWeb - One-liner Installer
# Author: Antigravity

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> SotoWeb Installation Starting...${NC}"

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
    # Replace the URL below with your actual GitHub Repo URL after you push it
    # For now, it might point to this local workspace's clone if you were doing it manually
    # But for the user, it should be: git clone https://github.com/USER/REPO.git $INSTALL_PATH
    log_warn "Please ensure you update the repo URL in setup.sh after pushing to GitHub!"
    # Default placeholder
    git clone https://github.com/ghasali/SotoWeb.git "$INSTALL_PATH" -q
fi

# 4. Make binary executable
chmod +x "$INSTALL_PATH/bin/soto"

# 5. Symlink to /usr/local/bin
ln -sf "$INSTALL_PATH/bin/soto" /usr/local/bin/soto

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}>>> SotoWeb has been installed successfully!${NC}"
    echo "You can now run 'sudo soto help' to get started."
else
    echo "Installation failed. Please run with sudo."
fi

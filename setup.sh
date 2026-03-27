#!/bin/bash

# SotoWeb Installation Script
# Author: Antigravity

# Set colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "Installing SotoWeb..."

# Make binary executable
chmod +x "$(pwd)/bin/soto"

# Symlink to /usr/local/bin
sudo ln -sf "$(pwd)/bin/soto" /usr/local/bin/soto

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}SotoWeb has been installed successfully!${NC}"
    echo "You can now run 'sudo soto help' to get started."
else
    echo "Installation failed. Please run with sudo."
fi

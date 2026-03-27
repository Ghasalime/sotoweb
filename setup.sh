#!/bin/bash

# SotoWeb - The Next-Gen Premium LEMP Stack CLI
# Author: Ghasali
# Version: 1.0.0

# Colors & Styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ASCII Banner
show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "  ____       _        __        __   _     "
    echo " / ___|  ___| |_ ___  \ \      / /__| |__  "
    echo " \___ \ / _ \ __/ _ \  \ \ /\ / / _ \ '_ \ "
    echo "  ___) |  __/ |_ (_) |  \ V  V /  __/ |_) |"
    echo " |____/ \___|\__\___/    \_/\_/ \___|_.__/ "
    echo -e "   ${CYAN}Premium LEMP Stack Management CLI${NC}"
    echo "------------------------------------------"
}

# Logging Functions
log_info() { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }

show_banner
log_info "SotoWeb Installation Starting..."

# 1. Dependency Check
log_info "Checking for required system tools (git, curl, lsof)..."
apt update -qq > /dev/null
apt install -y -qq git curl software-properties-common unzip lsof > /dev/null

# 2. Installation Path
INSTALL_PATH="/etc/sotoweb"
log_info "Target Directory: $INSTALL_PATH"

# 3. Clone or Update
if [[ -d "$INSTALL_PATH" ]]; then
    log_info "SotoWeb already exists. Updating via GitHub..."
    cd "$INSTALL_PATH" && git pull -q origin main
else
    log_info "Cloning SotoWeb from official repository..."
    git clone https://github.com/Ghasalime/sotoweb.git "$INSTALL_PATH" -q
fi

# 4. Make binary executable & Symlink
chmod +x "$INSTALL_PATH/bin/soto"
ln -sf "$INSTALL_PATH/bin/soto" /usr/local/bin/soto

# 5. Core Stack Installation (Zero-Touch)
log_info "Initializing SotoWeb Core Stack (Nginx, MariaDB, PHP 8.4)..."
soto stack -install

if [[ $? -eq 0 ]]; then
    show_banner
    log_success "SotoWeb has been installed successfully!"
    echo -e "\n${BOLD}🚀 NEXT STEPS:${NC}"
    
    local ip_addr=$(hostname -I | awk '{print $1}')
    echo -e "  • ${CYAN}SotoDash:${NC}    http://$ip_addr:22222"
    echo -e "  • ${CYAN}Dashboard Auth:${NC} Run 'sudo soto auth global -add youruser' to secure it."
    echo -e "  • ${CYAN}Create Site:${NC}  'sudo soto web example.com -wp'"
    echo -e "  • ${CYAN}Check Health:${NC} 'sudo soto tools -verify'"
    
    echo -e "\n${BOLD}Need help?${NC} Run 'sudo soto help'"
    echo "------------------------------------------"
else
    log_error "Installation failed. Please ensure you are running with 'sudo bash'."
    exit 1
fi

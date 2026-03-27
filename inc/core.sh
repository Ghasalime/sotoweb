#!/bin/bash

# SotoWeb Core Utilities
# Author: Ghasali

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This command must be run as root."
        exit 1
    fi
}

# Banner
display_banner() {
    echo -e "${YELLOW}"
    echo "  ____        _          __        __   _     "
    echo " / ___|  ___ | |_ ___    \ \      / /__| |__  "
    echo " \___ \ / _ \| __/ _ \    \ \ /\ / / _ \ '_ \ "
    echo "  ___) | (_) | || (_) |    \ V  V /  __/ |_) |"
    echo " |____/ \___/ \__\___/      \_/\_/ \___|_.__/ "
    echo "   SotoWeb CLI v1.0    "
    echo -e "${NC}"

    # Check for update alerts
    if [[ -f "/etc/sotoweb/.update_available" ]]; then
        local updates=$(cat /etc/sotoweb/.update_available)
        if [[ "$updates" -gt 0 ]]; then
            echo -e "${YELLOW}${BOLD}[UPDATE]${NC} $updates pembaruan tersedia! Jalankan 'sudo soto update' untuk memperbarui."
            echo ""
        fi
    fi
    
    # Run throttled check in background
    check_for_updates &
}

# Check for required commands
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Ensure htpasswd is available
ensure_htpasswd() {
    if ! check_command htpasswd; then
        log_info "Installing apache2-utils for authentication support..."
        apt update -qq > /dev/null
        apt install -y apache2-utils -qq > /dev/null
    fi
}

# Detect installed PHP version
get_php_version() {
    if command -v php &> /dev/null; then
        php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"
    else
        # Fallback to directory listing if php command not in PATH
        local version=$(ls /etc/php 2>/dev/null | sort -V | tail -n 1)
        # UI Fixes (completed)
        # - [x] **Phase 1: SotoDash UI Fixes**
        # - [x] Add background-clip standard properties and fallback to `index.html`
        # - [x] Fix Version Tag visibility in `index.html`
        # - [x] Improve Grid responsiveness in `index.html`
        if [[ -z "$version" ]]; then
            echo "8.4" # Default fallback
        else
            echo "$version"
        fi
    fi
}

# Get PHP-FPM socket path
get_php_fpm_sock() {
    local version=$(get_php_version)
    local sock="/var/run/php/php$version-fpm.sock"
    echo "$sock"
}
# Throttled Update Check
check_for_updates() {
    local check_file="/etc/sotoweb/.last_update_check"
    local alert_file="/etc/sotoweb/.update_available"
    local now=$(date +%s)
    
    # Throttle: 24 hours (86400 seconds)
    if [[ -f "$check_file" ]]; then
        local last_check=$(cat "$check_file")
        if (( now - last_check < 86400 )); then
            return 0
        fi
    fi
    
    # Skip if not a git repo
    if [[ ! -d "/etc/sotoweb/.git" ]]; then return 0; fi
    
    # Perform silent fetch
    cd /etc/sotoweb && git fetch origin main --quiet &> /dev/null
    local changes=$(git rev-list HEAD...origin/main --count)
    
    echo "$changes" > "$alert_file"
    echo "$now" > "$check_file"
}

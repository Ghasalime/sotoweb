#!/bin/bash

# SotoWeb HTTP Authentication Management
# Author: Ghasali

handle_auth() {
    # Check for root
    check_root

    # Ensure apache2-utils is installed
    install_auth_tools

    OPTION="$1"
    USER="$2"

    if [[ -z "$OPTION" ]]; then
        echo "Usage: soto auth -[option] [username]"
        echo "Options:"
        echo "  -add        Add or update an HTTP auth user"
        echo "  -delete     Remove an HTTP auth user"
        echo "  -list       List all HTTP auth users"
        return 0
    fi

    HTPASSWD_FILE="/etc/nginx/.htpasswd"

    case "$OPTION" in
        -add)
            if [[ -z "$USER" ]]; then
                log_error "Username required. (e.g., soto auth -add ghasali)"
                return 1
            fi
            log_info "Setting password for user: $USER"
            if [[ ! -f "$HTPASSWD_FILE" ]]; then
                htpasswd -c "$HTPASSWD_FILE" "$USER"
            else
                htpasswd "$HTPASSWD_FILE" "$USER"
            fi
            log_success "User $USER added/updated successfully."
            ;;
        -delete)
            if [[ -z "$USER" ]]; then
                log_error "Username required. (e.g., soto auth -delete ghasali)"
                return 1
            fi
            if [[ ! -f "$HTPASSWD_FILE" ]]; then
                log_error "No auth users exist."
                return 1
            fi
            sed -i "/^$USER:/d" "$HTPASSWD_FILE"
            log_success "User $USER removed."
            ;;
        -list)
            if [[ ! -f "$HTPASSWD_FILE" ]]; then
                log_info "No auth users configured."
                return 0
            fi
            log_info "Registered HTTP Auth Users:"
            awk -F: '{print " - " $1}' "$HTPASSWD_FILE"
            ;;
        *)
            log_error "Unknown auth option: $OPTION"
            ;;
    esac
}

install_auth_tools() {
    if ! check_command htpasswd; then
        log_info "Installing apache2-utils for htpasswd support..."
        apt install -y -qq apache2-utils
    fi
}

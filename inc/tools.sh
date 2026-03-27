#!/bin/bash

# SotoWeb Tools & Dashboard
# Author: Ghasali

handle_tools() {
    # Check for root
    check_root

    local option="$1"

    if [[ -z "$option" ]]; then
        echo "Usage: soto tools -[option]"
        echo "Options:"
        echo "  -dash       Install/Activate SotoDash (Port 22222)"
        echo "  -shield     Activate Soto Shield hardening"
        echo "  -verify     System self-diagnosis & health check"
        echo "  -blockip <ip>  Block an IP address (UFW)"
        echo "  -unblockip <ip> Unblock an IP address"
        echo "  -update     Update SotoWeb to latest version"
        echo "  -uninstall  Completely remove SotoWeb"
        echo "  -timezone   Set server timezone"
        echo "  -smtp       Setup global SMTP relay"
        return 0
    fi

    case "$option" in
        -dash)
            install_dashboard
            ;;
        -status)
            show_status
            ;;
        -shield)
            source "$SOTO_BASE_DIR/inc/stack.sh"
            setup_shield
            ;;
        -verify)
            verify_system
            ;;
        -update)
            update_soto
            ;;
        -uninstall)
            uninstall_soto
            ;;
        -blockip)
            block_ip "$2"
            ;;
        -unblockip)
            unblock_ip "$2"
            ;;
        -timezone)
            set_timezone "$2"
            ;;
        -smtp)
            setup_smtp
            ;;
        -auth)
            handle_auth "global" "$3" # Assuming 'soto tools -auth <username>' for global auth
            ;;
        *)
            log_error "Unknown tool option: $option"
            ;;
    esac
}

install_dashboard() {
    log_info "Installing SotoDash..."
    
    # 1. Create directory
    mkdir -p /var/www/soto-dash
    cp -rf "$SOTO_BASE_DIR/dashboard/"* /var/www/soto-dash/
    chown -R www-data:www-data /var/www/soto-dash
    
    # 2. Create Nginx config for dashboard on port 22222
    log_info "Configuring Nginx for SotoDash on port 22222..."
    local php_sock="/var/run/php/php$(get_php_version)-fpm.sock"
    cat > /etc/nginx/sites-available/soto-dash <<EOF
server {
    listen 22222;
    server_name _;
    root /var/www/soto-dash;
    index index.html stats.php;

    # HTTP Basic Authentication
    auth_basic "SotoDash Restricted Area";
    auth_basic_user_file /etc/sotoweb/auth/global.htpasswd;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$php_sock;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/soto-dash /etc/nginx/sites-enabled/soto-dash
    nginx -t && systemctl reload nginx
    
    local ip_addr=$(hostname -I | awk '{print $1}')
    log_success "SotoDash installed successfully!"
    log_info "Access it at: http://$ip_addr:22222"
}

show_status() {
    display_banner
    echo "--- Server Status ---"
    uptime -p
    free -h | grep Mem
    df -h / | grep /
    echo "--------------------"
}

block_ip() {
    local ip=$1
    if [[ -z "$ip" ]]; then
        log_error "Please specify an IP address to block."
        return 1
    fi
    log_info "Blocking IP: $ip..."
    if ! check_command ufw; then
        apt install -y -qq ufw
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
    fi
    ufw insert 1 deny from "$ip"
    log_success "IP $ip blocked successfully."
}

unblock_ip() {
    local ip=$1
    if [[ -z "$ip" ]]; then
        log_error "Please specify an IP address to unblock."
        return 1
    fi
    log_info "Unblocking IP: $ip..."
    ufw delete deny from "$ip"
    log_success "IP $ip unblocked successfully."
}

check_wp_cli() {
    if ! check_command wp; then
        log_info "Downloading WP-CLI..."
        curl -L -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod 755 wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
    # Always force correct owner and permissions
    chown root:root /usr/local/bin/wp
    chmod 755 /usr/local/bin/wp
}

verify_system() {
    log_info "Running SotoWeb Self-Diagnosis..."
    echo "------------------------------------------"
    
    # 1. Services Check
    local services=("nginx" "mariadb" "redis-server" "php$(get_php_version)-fpm")
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo "[OK] $svc is running."
        else
            echo "[FAIL] $svc is NOT running."
        fi
    done
    
    # 2. Ports Check
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null; then echo "[OK] Port 80 is listening."; else echo "[WARN] Port 80 is closed."; fi
    if lsof -Pi :22222 -sTCP:LISTEN -t >/dev/null; then echo "[OK] Dashboard (22222) is listening."; else echo "[WARN] Dashboard is offline."; fi
    
    # 3. Nginx Traffic Check
    if nginx -t >/dev/null 2>&1; then
        echo "[OK] Nginx configuration syntax is valid."
    else
        echo "[FAIL] Nginx configuration has errors!"
        nginx -t
    fi
    
    # 4. Disk Check
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ "$disk_usage" -gt 90 ]]; then
        echo "[CRITICAL] Disk usage is at $disk_usage%!"
    else
        echo "[OK] Disk usage is at $disk_usage%."
    fi
    
    # 5. Permission Check
    if [[ -x "/usr/local/bin/soto" ]]; then
        echo "[OK] Binary permission is correct."
    else
        echo "[WARN] Binary permission might be restricted."
    fi
    
    echo "------------------------------------------"
}

update_soto() {
    log_info "Updating SotoWeb..."
    if [[ ! -d "$SOTO_BASE_DIR/.git" ]]; then
        log_error "Not a git repository. Cannot update automatically."
        return 1
    fi
    
    cd "$SOTO_BASE_DIR" || return 1
    git fetch origin
    local changes=$(git rev-list HEAD...origin/main --count)
    
    if [[ "$changes" -eq 0 ]]; then
        log_success "SotoWeb is already at the latest version."
        return 0
    fi
    
    log_info "Found $changes new updates. Pulling..."
    git pull origin main
    
    # Re-link for safety
    chmod +x "$SOTO_BASE_DIR/bin/soto"
    ln -sf "$SOTO_BASE_DIR/bin/soto" /usr/local/bin/soto
    
    # Clear update alert
    rm -f /etc/sotoweb/.update_available
    
    log_success "SotoWeb updated successfully!"
}

uninstall_soto() {
    echo -e "\n\e[31m[DANGER] This will completely remove SotoWeb, your websites, and databases.\e[0m"
    read -p "Are you absolutely sure you want to uninstall? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Uninstall cancelled."
        return 1
    fi
    
    log_info "Uninstalling SotoWeb..."
    source "$SOTO_BASE_DIR/inc/stack.sh"
    purge_stack
    
    rm -rf "$SOTO_BASE_DIR"
    rm -f /usr/local/bin/soto
    rm -rf /etc/sotoweb
    
    log_success "SotoWeb has been uninstalled from your system."
}

set_timezone() {
    local tz=$1
    if [[ -z "$tz" ]]; then
        log_info "Current timezone: $(timedatectl show --property=Timezone --value)"
        log_info "Use 'soto tools -timezone <Region/City>' to change."
        return 0
    fi
    log_info "Setting timezone to $tz..."
    timedatectl set-timezone "$tz"
    log_success "Timezone updated to $tz."
}

setup_smtp() {
    log_info "Global SMTP Setup..."
    log_warn "SMTP relay feature is coming in the next micro-update."
}

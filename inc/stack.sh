#!/bin/bash

# SotoWeb Stack Management
# Author: Ghasali

handle_stack() {
    # Check for root
    check_root

    if [[ -z "$1" ]]; then
        echo "Usage: soto stack -[option]"
        echo "Options:"
        echo "  -install    Install LEMP stack (Nginx, MariaDB, PHP)
  -php=X.X    Install a specific PHP version (e.g., 8.2)
  -mysql      Install MariaDB
  -cache      Setup global FastCGI Cache
"
        return 0
    fi

    # Parse stack options
    case "$1" in
        -install)
            log_info "Starting LEMP stack installation..."
            install_lemp
            ;;
        -php=*)
            PHP_VER="${1#*=}"
            log_info "Installing PHP $PHP_VER..."
            install_php "$PHP_VER"
            ;;
        -mysql)
            log_info "Installing MariaDB..."
            install_mysql
            ;;
        -tune)
            log_info "Tuning server resources..."
            tune_server
            ;;
        -firewall)
            log_info "Hardening server firewall..."
            harden_firewall
            ;;
        -redis)
            log_info "Installing Redis..."
            install_redis
            ;;
        -shield)
            log_info "Installing Soto Shield..."
            install_shield
            ;;
        -cache)
            log_info "Setting up global FastCGI Cache..."
            setup_cache
            ;;
        -fix)
            log_info "Attempting to fix broken stack components..."
            fix_stack
            ;;
        *)
            log_error "Unknown stack option: $1"
            ;;
    esac
}

install_lemp() {
    log_info "Updating system repositories..."
    apt update -qq
    
    log_info "Installing common dependencies..."
    apt install -y -qq software-properties-common curl git unzip

    log_info "Installing Nginx..."
    apt install -y nginx

    log_info "Installing MariaDB..."
    install_mysql

    # Ensure Nginx directories are ready
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d

    log_info "Installing PHP (Default: 8.4)..."
    install_php "8.4"

    # Final fix/check for Nginx
    fix_stack

    log_success "LEMP stack installed successfully."
}

install_php() {
    local version=$1
    log_info "Adding PHP repository (Ondřej Surý)..."
    # Unified add-apt-repository for modern Ubuntu
    add-apt-repository -y ppa:ondrej/php
    apt update -qq
    
    log_info "Installing PHP $version and common extensions..."
    apt install -y -qq "php$version-fpm" "php$version-mysql" "php$version-curl" "php$version-gd" "php$version-mbstring" "php$version-xml" "php$version-zip" "php$version-bcmath"

    log_success "PHP $version installed."
}

install_mysql() {
    apt install -y -qq mariadb-server
    log_success "MariaDB installed."
}

tune_server() {
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    log_info "Total RAM: ${total_ram}MB"

    # PHP Tuning (Simple heuristic)
    # Assume 1 PHP process = 60MB
    # Reserve 256MB for OS, the rest for PHP
    local php_children=$(( (total_ram - 256) / 60 ))
    if [[ $php_children -lt 5 ]]; then php_children=5; fi
    
    local php_ver=$(get_php_version)
    local pool_file="/etc/php/$php_ver/fpm/pool.d/www.conf"
    
    if [[ -f "$pool_file" ]]; then
        log_info "Updating PHP $php_ver pool settings (max_children: $php_children)..."
        sed -i "s/^pm.max_children =.*/pm.max_children = $php_children/" "$pool_file"
        systemctl restart "php$php_ver-fpm"
    fi

    # MariaDB Tuning (InnoDB Buffer Pool)
    # Set to 50% of RAM if RAM > 1GB, else 25%
    local db_buffer_pool_size=$(( total_ram / 2 ))
    if [[ $total_ram -lt 1024 ]]; then
        db_buffer_pool_size=$(( total_ram / 4 ))
    fi
    
    log_info "Updating MariaDB innodb_buffer_pool_size to ${db_buffer_pool_size}M..."
    # Usually in /etc/mysql/mariadb.conf.d/50-server.cnf
    # We might need to add it if it doesn't exist
    local mysql_conf="/etc/mysql/mariadb.conf.d/soto-tuning.cnf"
    mkdir -p "$(dirname "$mysql_conf")"
    echo -e "[mysqld]\ninnodb_buffer_pool_size = ${db_buffer_pool_size}M" > "$mysql_conf"
    systemctl restart mariadb

    log_success "Server tuning applied based on available resources."
}

harden_firewall() {
    if ! check_command ufw; then
        apt install -y -qq ufw
    fi

    log_info "Configuring UFW rules..."
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 22222/tcp comment 'SotoDash'
    
    echo "y" | ufw enable
    log_success "Firewall enabled and hardened."
}

install_redis() {
    apt install -y -qq redis-server php-redis
    systemctl enable redis-server
    log_success "Redis installed and PHP extension enabled."
}

install_shield() {
    apt install -y -qq fail2ban
    log_info "Configuring Fail2Ban for SSH and WordPress..."
    # Basic SSH protection
    cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF
    systemctl restart fail2ban
    log_success "Soto Shield (Fail2Ban) active."
}

setup_cache() {
    log_info "Initializing global FastCGI Cache..."
    mkdir -p /var/cache/nginx/sotocache
    chown -R www-data:www-data /var/cache/nginx/sotocache
    cp "$SOTO_BASE_DIR/etc/soto-cache.conf" /etc/nginx/conf.d/soto-cache.conf
    
    # Ensure Nginx is healthy before reload
    fix_stack
    nginx -t && systemctl reload nginx
}

fix_stack() {
    if [[ ! -f "/etc/nginx/nginx.conf" ]]; then
        log_warn "Nginx configuration missing! Forcing Nginx reinstallation..."
        # First try to fix broken packages
        apt install -f -y -qq
        # Reinstall Nginx to restore default configs
        apt install --reinstall -y -qq nginx nginx-common
        # Ensure directories exist
        mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d
        log_success "Nginx files restored."
    fi
}

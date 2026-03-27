#!/bin/bash

# SotoWeb Stack Management
# Author: Ghasali

handle_stack() {
    # Check for root
    check_root

    if [[ -z "$1" ]]; then
        echo "Usage: soto stack -[option]"
        echo "Options:"
        echo "  -install    Install full LEMP stack"
        echo "  -tune       Intelligent resource tuning"
        echo "  -shield     Activate Server Shield hardening"
        echo "  -firewall   Apply firewall rules"
        echo "  -cache      Setup global FastCGI Cache"
        echo "  -pma        Install phpMyAdmin globally"
        echo "  -fix        Attempt to fix broken components"
        echo "  -clean      Clean PPA and repository conflicts"
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
            tune_stack
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
        -shield)
            log_info "Activating Server Shield..."
            setup_shield
            ;;
        -pma)
            log_info "Installing phpMyAdmin..."
            install_pma
            ;;
        -fix)
            log_info "Attempting to fix broken stack components..."
            fix_stack
            ;;
        -clean)
            log_info "Cleaning up conflicting repositories..."
            clean_ppa
            ;;
        -purge)
            log_info "Purging all stack components for clean install..."
            purge_stack
            ;;
        *)
            log_error "Unknown stack option: $1"
            ;;
    esac
}

install_lemp() {
    # 0. Nuclear Purge & Deep Clean
    purge_stack
    clean_ppa

    log_info "Updating system repositories..."
    apt update -qq
    
    log_info "Installing common dependencies..."
    apt install -y software-properties-common curl git unzip

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
    
    # Deep clean PPA before adding to avoid "Signed-By" conflicts
    clean_ppa
    
    log_info "Adding PHP repository (Ondřej Surý)..."
    # Unified add-apt-repository with proper locale for Noble (24.04)
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt update -qq
    
    log_info "Installing PHP $version and common extensions..."
    apt install -y -qq "php$version-fpm" "php$version-common" "php$version-mysql" "php$version-curl" "php$version-gd" "php$version-mbstring" "php$version-xml" "php$version-zip" "php$version-bcmath" php-mysql
    
    log_info "Enabling PHP MySQL extensions for CLI..."
    phpenmod -v "$version" -s cli mysqli mysqlnd
    
    log_success "PHP $version installed and extensions hardened."
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
    local mysql_conf="/etc/mysql/mariadb.conf.d/99-soto-tune.cnf"
    mkdir -p "$(dirname "$mysql_conf")"
    echo -e "[mysqld]\ninnodb_buffer_pool_size = ${db_buffer_pool_size}M\ninnodb_flush_method = O_DIRECT\ninnodb_file_per_table = 1" > "$mysql_conf"
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
        # Clear any potential lock issues
        rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock
        
        # First try to fix broken packages
        apt install -f -y -qq
        # Reinstall Nginx to restore default configs
        apt install --reinstall -y -qq nginx nginx-common
        # Ensure directories exist
        mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d
        log_success "Nginx files restored."
    fi
}

purge_stack() {
    log_warn "Purging all Nginx and PHP version packages for a fresh start..."
    # 1. Stop services
    systemctl stop nginx php*-fpm 2>/dev/null
    
    # 2. Purge packages
    apt purge -y "nginx*" "php*" "libnginx-mod-*" "mariadb-server*" "mariadb-client*" 2>/dev/null
    
    # 3. Autoremove leftover dependencies
    apt autoremove -y -qq
    
    # 4. Remove directories
    rm -rf /etc/nginx /etc/php /var/www/html /var/lib/mysql /var/log/nginx /var/log/mysql /var/www/22222/pma
    
    log_success "System purged of existing stack components."
}

install_pma() {
    local pma_dir="/var/www/22222/pma"
    mkdir -p "$pma_dir"
    
    log_info "Downloading latest phpMyAdmin..."
    cd /tmp
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz -q
    tar -xzf phpMyAdmin-latest-all-languages.tar.gz
    rm -rf "$pma_dir"/*
    mv phpMyAdmin-*-all-languages/* "$pma_dir/"
    rm -rf phpMyAdmin-latest-all-languages.tar.gz phpMyAdmin-*-all-languages
    
    # Configure
    cp "$pma_dir/config.sample.inc.php" "$pma_dir/config.inc.php"
    local blowfish=$(openssl rand -base64 32)
    sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg\['blowfish_secret'\] = '$blowfish';/" "$pma_dir/config.inc.php"
    
    chown -R www-data:www-data "$pma_dir"
    
    # Create Nginx snippet for subfolder access
    log_info "Creating Nginx snippet for /pma access..."
    local php_sock="/var/run/php/php$(get_php_version)-fpm.sock"
    cat > /etc/nginx/snippets/pma.conf <<EOF
location /pma {
    alias $pma_dir;
    index index.php;

    location ~ ^/pma/(.+\.php)$ {
        alias $pma_dir/\$1;
        fastcgi_pass unix:$php_sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
    }

    location ~* ^/pma/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        alias $pma_dir/\$1;
    }
}
EOF

    log_success "phpMyAdmin installed and snippet created at /etc/nginx/snippets/pma.conf"
    log_info "Use 'sudo soto web <domain> -pma' to enable it on a site."
}

clean_ppa() {
    log_info "Searching for conflicting Ondřej PPA entries..."
    
    # 1. Remove .list and .sources files containing "ondrej"
    find /etc/apt/sources.list.d/ -type f \( -name "*ondrej*" -o -name "*php*" \) -delete
    
    # 2. Remove "ondrej" entries from main sources.list if any
    if grep -q "ondrej" /etc/apt/sources.list; then
        sed -i '/ondrej/d' /etc/apt/sources.list
    fi
    
    # 3. Remove conflicting keyrings
    rm -f /usr/share/keyrings/php-archive-keyring.gpg
    rm -f /etc/apt/keyrings/ppa-ondrej-php-noble.gpg
    
    log_success "APT repositories cleaned."
}

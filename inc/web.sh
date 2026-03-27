#!/bin/bash

# SotoWeb Website Management
# Author: Ghasali

handle_web() {
    # Check for root
    check_root

    DOMAIN="$1"
    OPTION="$2"

    # Pre-check: Ensure Nginx is installed
    if ! command -v nginx &> /dev/null; then
        log_error "Nginx is not installed. Please run 'sudo soto stack -install' first."
        return 1
    fi

    if [[ -z "$DOMAIN" ]]; then
        echo "Usage: soto web [domain] -[option]"
        echo "Options:"
        echo "  -wp         Create a WordPress site"
        echo "  -php        Create a standard PHP site"
        echo "  -static     Set up a static HTML site"
        echo "  -proxy=url  Set up a reverse proxy (e.g. -proxy=http://127.0.0.1:3000)"
        echo "  -redirect=url Set up a 301 redirection (e.g. -redirect=https://google.com)"
        echo "  -pma        Enable phpMyAdmin access (/pma)"
        echo "  -alias=url  Add a domain alias/parked domain"
        echo "  -db-import=file.sql Import a database dump"
        echo "  -on / -off  Enable or disable site access"
        echo "  -info       Show detailed site information"
        echo "  -delete     Remove a site and its database"
        echo ""
        echo "Global Options:"
        echo "  soto web -list  List all registered sites"
        return 0
    fi

    # Global: List sites
    if [[ "$DOMAIN" == "-list" ]]; then
        list_sites
        return 0
    fi

    case "$OPTION" in
        -php)
            log_info "Creating PHP site for $DOMAIN..."
            create_site "$DOMAIN" "php"
            ;;
        -php=*)
            VERSION="${OPTION#*=}"
            if [[ ! -f "/etc/nginx/sites-available/$DOMAIN" ]]; then
                log_info "Creating new PHP $VERSION site for $DOMAIN..."
                create_site "$DOMAIN" "php" "$VERSION"
            else
                log_info "Changing PHP version for $DOMAIN to $VERSION..."
                update_site_php "$DOMAIN" "$VERSION"
            fi
            ;;
        -wp)
            log_info "Creating WordPress site for $DOMAIN..."
            create_site "$DOMAIN" "wp"
            ;;
        -proxy=*)
            PORT="${OPTION#*=}"
            log_info "Creating Nginx Proxy for $DOMAIN to port $PORT..."
            create_proxy "$DOMAIN" "$PORT"
            ;;
        -ssl)
            log_info "Activating SSL for $DOMAIN..."
            source_ssl
            activate_ssl "$DOMAIN"
            ;;
        -clone=*)
            NEW_DOMAIN="${OPTION#*=}"
            log_info "Cloning site from $DOMAIN to $NEW_DOMAIN..."
            clone_site "$DOMAIN" "$NEW_DOMAIN"
            ;;
        -cache=on)
            log_info "Enabling FastCGI Cache for $DOMAIN..."
            enable_cache "$DOMAIN"
            ;;
        -cache=off)
            log_info "Disabling FastCGI Cache for $DOMAIN..."
            disable_cache "$DOMAIN"
            ;;
        -proxy=*)
            local target="${OPTION#*=}"
            log_info "Creating reverse proxy for $DOMAIN -> $target..."
            create_site "$DOMAIN" "proxy" "$target"
            ;;
        -redirect=*)
            local target="${OPTION#*=}"
            log_info "Creating redirection for $DOMAIN -> $target..."
            create_site "$DOMAIN" "redirect" "$target"
            ;;
        -on)
            enable_site "$DOMAIN"
            ;;
        -off)
            disable_site "$DOMAIN"
            ;;
        -pma)
            enable_pma "$DOMAIN"
            ;;
        -alias=*)
            local alias_domain="${OPTION#*=}"
            add_site_alias "$DOMAIN" "$alias_domain"
            ;;
        -db-import=*)
            local sql_file="${OPTION#*=}"
            import_site_db "$DOMAIN" "$sql_file"
            ;;
        -info)
            site_info "$DOMAIN"
            ;;
        -delete)
            log_warn "Deleting site $DOMAIN..."
            delete_site "$DOMAIN"
            ;;
        *)
            log_error "Unknown site option: $OPTION"
            ;;
    esac
}

create_site() {
    local domain=$1
    local type=$2
    local php_ver="${3:-$(get_php_version)}"

    # 1. Create directory
    log_info "Setting up directory at /var/www/$domain..."
    mkdir -p "/var/www/$domain"
    chown -R www-data:www-data "/var/www/$domain"

    # 1.1. Ensure PHP-FPM is healthy to prevent 502 (Nuclear Recovery)
    ensure_php_fpm_healthy

    # 2. Add PHP index file if not existing
    if [[ ! -f "/var/www/$domain/index.php" ]]; then
        echo "<?php phpinfo(); ?>" > "/var/www/$domain/index.php"
        chown www-data:www-data "/var/www/$domain/index.php"
    fi

    # 3. Create Nginx vhost
    log_info "Generating Nginx virtual host..."
    VHOST_FILE="/etc/nginx/sites-available/$domain"
    
    if [[ "$type" == "proxy" ]]; then
        TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-proxy.conf"
        cp "$TEMPLATE_FILE" "$VHOST_FILE"
        sed -i "s|{{DOMAIN}}|$domain|g" "$VHOST_FILE"
        sed -i "s|{{TARGET}}|$php_ver|g" "$VHOST_FILE" # php_ver used as target URL here
    elif [[ "$type" == "redirect" ]]; then
        TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-redirect.conf"
        cp "$TEMPLATE_FILE" "$VHOST_FILE"
        sed -i "s|{{DOMAIN}}|$domain|g" "$VHOST_FILE"
        sed -i "s|{{TARGET}}|$php_ver|g" "$VHOST_FILE"
    else
        TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-php.conf"
        cp "$TEMPLATE_FILE" "$VHOST_FILE"
        sed -i "s|{{DOMAIN}}|$domain|g" "$VHOST_FILE"
        sed -i "s|{{PHP_VER}}|$php_ver|g" "$VHOST_FILE"
    fi

    # Enable site
    ln -sf "$VHOST_FILE" "/etc/nginx/sites-enabled/$domain"

    # 4. WordPress specific
    if [[ "$type" == "wp" ]]; then
        install_wordpress "$domain"
    fi

    # 5. Reload Nginx
    log_info "Reloading Nginx..."
    nginx -t && systemctl reload nginx
    log_success "Website $domain created successfully."
}

create_proxy() {
    local domain=$1
    local port=$2

    # 1. Create Nginx vhost
    log_info "Generating Nginx reverse proxy host..."
    VHOST_FILE="/etc/nginx/sites-available/$domain"
    TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-proxy.conf"

    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Nginx proxy template not found."
        return 1
    fi

    # Replace placeholders using sed
    sed "s/{{DOMAIN}}/$domain/g; s/{{PORT}}/$port/g" "$TEMPLATE_FILE" > "$VHOST_FILE"

    # Enable site
    ln -sf "$VHOST_FILE" "/etc/nginx/sites-enabled/$domain"

    # 2. Reload Nginx
    log_info "Reloading Nginx..."
    nginx -t && systemctl reload nginx
    log_success "Reverse proxy for $domain on port $port created successfully."
}

clone_site() {
    local old_domain=$1
    local new_domain=$2

    if [[ ! -d "/var/www/$old_domain" ]]; then
        log_error "Source site /var/www/$old_domain does not exist."
        return 1
    fi

    # 1. Create new site (standard PHP for now, then sync files)
    create_site "$new_domain" "php"

    # 2. Sync files
    log_info "Copying files from /var/www/$old_domain to /var/www/$new_domain..."
    cp -rf "/var/www/$old_domain/"* "/var/www/$new_domain/"
    chown -R www-data:www-data "/var/www/$new_domain"

    # 3. WordPress adjustments (if applicable)
    if [[ -f "/var/www/$new_domain/wp-config.php" ]]; then
        log_info "WordPress detected. Updating database and domain..."
        check_wp_cli
        
        # New DB details
        local db_name=$(echo "${new_domain//./_}" | cut -c1-64)
        local db_user=$(echo "user_${db_name}" | cut -c1-16)
        local db_pass=$(openssl rand -base64 12)
        
        create_mysql_db "$db_name" "$db_user" "$db_pass"
        
        # Change DB in wp-config.php (this is tricky with sed, wp-cli is better)
        cd "/var/www/$new_domain" || exit
        sudo -u www-data wp config set DB_NAME "$db_name" --allow-root
        sudo -u www-data wp config set DB_USER "$db_user" --allow-root
        sudo -u www-data wp config set DB_PASSWORD "$db_pass" --allow-root
        
        # Search and replace domain
        sudo -u www-data wp search-replace "$old_domain" "$new_domain" --allow-root
    fi

    log_success "Site cloned from $old_domain to $new_domain."
}

enable_cache() {
    local domain=$1
    local php_ver=$(get_php_version)
    
    VHOST_FILE="/etc/nginx/sites-available/$domain"
    # Ensure cache is setup globally
    [[ ! -f "/etc/nginx/conf.d/soto-cache.conf" ]] && source "$SOTO_BASE_DIR/inc/stack.sh" && setup_cache
    
    TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-php-cache.conf"
    sed "s/{{DOMAIN}}/$domain/g; s/{{PHP_VER}}/$php_ver/g" "$TEMPLATE_FILE" > "$VHOST_FILE"
    
    nginx -t && systemctl reload nginx
    log_success "FastCGI Cache enabled for $domain."
}

disable_cache() {
    local domain=$1
    local php_ver=$(get_php_version)
    
    VHOST_FILE="/etc/nginx/sites-available/$domain"
    TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-php.conf"
    sed "s/{{DOMAIN}}/$domain/g; s/{{PHP_VER}}/$php_ver/g" "$TEMPLATE_FILE" > "$VHOST_FILE"
    
    nginx -t && systemctl reload nginx
    log_success "FastCGI Cache disabled for $domain. Reverted to standard PHP config."
}

install_wordpress() {
    local domain=$1
    check_wp_cli

    log_info "Creating database for $domain..."
    local db_name=$(echo "${domain//./_}" | cut -c1-64)
    local db_user=$(echo "user_${db_name}" | cut -c1-16)
    local db_pass=$(openssl rand -base64 12)

    create_mysql_db "$db_name" "$db_user" "$db_pass"

    # Premium High-Performance Setup (Redis & Cache)
    log_info "Enabling High-Performance stack (Redis & FastCGI Cache)..."
    source "$SOTO_BASE_DIR/inc/stack.sh"
    
    # Install Redis if not active
    if ! systemctl is-active --quiet redis-server; then
        install_redis
    fi
    
    # Setup Global Cache if missing
    if [[ ! -f "/etc/nginx/conf.d/soto-cache.conf" ]]; then
        setup_cache
    fi

    log_info "Downloading and configuring WordPress..."
    cd "/var/www/$domain" || exit
    
    # Fix ownership before WP-CLI steps
    chown -R www-data:www-data "/var/www/$domain"
    
    # Download WP using /tmp for cache to avoid permissions issues
    sudo -u www-data HOME=/tmp WP_CLI_CACHE_DIR=/tmp wp core download --allow-root
    
    # Create wp-config.php (Nuclear fix for mysqli_init)
    sudo -u www-data HOME=/tmp WP_CLI_CACHE_DIR=/tmp wp config create --dbname="$db_name" --dbuser="$db_user" --dbpass="$db_pass" --allow-root --skip-check
    
    # Enable per-site FastCGI Cache
    enable_cache "$domain"

    # Install and Activate Redis Object Cache Plugin
    log_info "Installing Redis Object Cache plugin..."
    sudo -u www-data HOME=/tmp WP_CLI_CACHE_DIR=/tmp wp plugin install redis-cache --activate --allow-root
    
    log_success "WordPress 'Ultra' ready for $domain!"
    echo "------------------------------------------"
    echo "Access your site at: http://$domain"
    echo "to finish the browser setup."
    echo "------------------------------------------"
}

check_wp_cli() {
    if ! check_command wp; then
        log_info "Downloading WP-CLI..."
        curl -L -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
    # Always force permissions even if it already exists
    chmod 755 /usr/local/bin/wp
    
    # Proactive NUCLEAR fix for missing extensions
    if ! php -m | grep -q mysqli; then
        log_info "Hardening PHP MySQL extension globally..."
        apt-get install -y -qq php-mysql &> /dev/null
        phpenmod -s cli mysqli mysqlnd &> /dev/null
        phpenmod -s fpm mysqli mysqlnd &> /dev/null
    fi
}

create_mysql_db() {
    local name=$1
    local user=$2
    local pass=$3
    
    mariadb -e "CREATE DATABASE IF NOT EXISTS $name;"
    mariadb -e "CREATE USER IF NOT EXISTS '$user'@'localhost' IDENTIFIED BY '$pass';"
    mariadb -e "GRANT ALL PRIVILEGES ON $name.* TO '$user'@'localhost';"
    mariadb -e "FLUSH PRIVILEGES;"
}

update_site_php() {
    local domain=$1
    local version=$2
    local vhost="/etc/nginx/sites-available/$domain"

    if [[ ! -f "$vhost" ]]; then
        log_error "Domain $domain not found."
        return 1
    fi

    # Check/Install PHP if not present
    if [[ ! -d "/etc/php/$version" ]]; then
        source "$SOTO_BASE_DIR/inc/stack.sh"
        install_php "$version"
    fi

    log_info "Updating PHP version to $version in Nginx configuration..."
    # Replace the phpX.X-fpm.sock line
    sed -i "s/php[0-9.]\+-fpm.sock/php$version-fpm.sock/g" "$vhost"
    
    # Align CLI version as well
    log_info "Aligning system PHP CLI to $version..."
    update-alternatives --set php "/usr/bin/php$version" &> /dev/null
    
    nginx -t && systemctl reload nginx
    log_success "PHP version for $domain updated to $version."
}

delete_site() {
    local domain=$1
    local db_name=$(echo "${domain//./_}" | cut -c1-64)

    # 1. Remove Nginx config
    rm -f "/etc/nginx/sites-enabled/$domain"
    rm -f "/etc/nginx/sites-available/$domain"
    
    # 2. Remove Files
    rm -rf "/var/www/$domain"
    
    # 3. Remove Database (if exists)
    log_info "Removing database $db_name..."
    mariadb -e "DROP DATABASE IF EXISTS $db_name;"
    # We might leave the user, as users can be shared, but usually, they are unique here.
    # To be safe, we just drop the DB.
    
    systemctl reload nginx
    log_success "Site $domain and its database deleted."
}

list_sites() {
    log_info "Registered Websites:"
    printf "%-30s %-10s %-10s\n" "Domain" "Type" "Status"
    echo "------------------------------------------------------------"
    
    for vhost in /etc/nginx/sites-available/*; do
        [[ ! -f "$vhost" ]] && continue
        local domain=$(basename "$vhost")
        [[ "$domain" == "default" || "$domain" == "soto-dash" ]] && continue
        
        local status="OFF"
        [[ -L "/etc/nginx/sites-enabled/$domain" ]] && status="ON"
        
        local type="PHP"
        if grep -q "wp-config.php" "$vhost" 2>/dev/null || [[ -f "/var/www/$domain/wp-config.php" ]]; then
            type="WP"
        elif grep -q "proxy_pass" "$vhost" 2>/dev/null; then
            type="PROXY"
        elif ! grep -q "fastcgi_pass" "$vhost" 2>/dev/null; then
            type="STATIC"
        fi
        
        printf "%-30s %-10s %-10s\n" "$domain" "$type" "$status"
    done
}

site_info() {
    local domain=$1
    local vhost="/etc/nginx/sites-available/$domain"
    
    if [[ ! -f "$vhost" ]]; then
        log_error "Site $domain not found."
        return 1
    fi
    
    display_banner
    echo "--- Site Info: $domain ---"
    echo "Root Dir:    /var/www/$domain"
    
    # PHP Version
    local php_ver=$(grep -o "php[0-9.]\+-fpm" "$vhost" | head -n 1 | sed 's/php//;s/-fpm//')
    echo "PHP Version: ${php_ver:-N/A}"
    
    # SSL Status
    if grep -q "listen 443 ssl" "$vhost"; then
        echo "SSL Status:  Active (HTTPS)"
    else
        echo "SSL Status:  Disabled (HTTP)"
    fi
    
    # Database Info for WP
    if [[ -f "/var/www/$domain/wp-config.php" ]]; then
        local db_name=$(grep "DB_NAME" "/var/www/$domain/wp-config.php" | cut -d\' -f4)
        local db_user=$(grep "DB_USER" "/var/www/$domain/wp-config.php" | cut -d\' -f4)
        echo "Database:    $db_name (User: $db_user)"
    fi
    
    echo "--------------------------------"
}

enable_site() {
    local domain=$1
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Site $domain not found."
        return 1
    fi
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
    nginx -t && systemctl reload nginx
    log_success "Site $domain enabled."
}

disable_site() {
    local domain=$1
    rm -f "/etc/nginx/sites-enabled/$domain"
    systemctl reload nginx
    log_warn "Site $domain disabled."
}

enable_pma() {
    local domain=$1
    local vhost="/etc/nginx/sites-available/$domain"
    
    if [[ ! -f "$vhost" ]]; then
        log_error "Site $domain not found."
        return 1
    fi
    
    # Ensure PMA is installed globally
    if [[ ! -f "/etc/nginx/snippets/pma.conf" ]]; then
        source "$SOTO_BASE_DIR/inc/stack.sh"
        install_pma
    fi
    
    log_info "Enabling phpMyAdmin for $domain..."
    
    # Add include if not present
    if ! grep -q "snippets/pma.conf" "$vhost"; then
        sed -i "/server_name/a \    include snippets/pma.conf;" "$vhost"
    fi
    
    nginx -t && systemctl reload nginx
    log_success "phpMyAdmin enabled for $domain. Access at http://$domain/pma"
}

add_site_alias() {
    local domain=$1
    local alias=$2
    local vhost="/etc/nginx/sites-available/$domain"
    
    if [[ ! -f "$vhost" ]]; then
        log_error "Site $domain not found."
        return 1
    fi
    
    log_info "Adding alias $alias to $domain..."
    # Insert alias into server_name line if not present
    if ! grep -q "server_name .*$alias" "$vhost"; then
        sed -i "s/server_name \(.*\);/server_name \1 $alias;/" "$vhost"
    fi
    
    nginx -t && systemctl reload nginx
    log_success "Alias $alias added to $domain. Please ensure DNS highlights to this server."
}

import_site_db() {
    local domain=$1
    local sql_file=$2
    
    if [[ ! -f "$sql_file" ]]; then
        log_error "SQL file $sql_file not found."
        return 1
    fi
    
    # Try to find DB name from wp-config or use domain-based name
    local db_name=""
    if [[ -f "/var/www/$domain/wp-config.php" ]]; then
        db_name=$(grep "DB_NAME" "/var/www/$domain/wp-config.php" | cut -d\' -f4)
    fi
    
    if [[ -z "$db_name" ]]; then
        db_name=$(echo "${domain//./_}" | cut -c1-64)
    fi
    
    log_info "Importing $sql_file into database $db_name..."
    # Ensure DB exists
    mariadb -e "CREATE DATABASE IF NOT EXISTS $db_name;"
    
    # Import
    if mariadb "$db_name" < "$sql_file"; then
        log_success "Database import completed for $domain."
    else
        log_error "Database import failed."
    fi
}

source_ssl() {
    # Lazy include ssl.sh
    if [[ -f "$SOTO_BASE_DIR/inc/ssl.sh" ]]; then
        source "$SOTO_BASE_DIR/inc/ssl.sh"
    fi
}

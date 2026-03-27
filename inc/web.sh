#!/bin/bash

# SotoWeb Website Management
# Author: Ghasali

handle_web() {
    # Check for root
    check_root

    DOMAIN="$1"
    OPTION="$2"

    if [[ -z "$DOMAIN" ]]; then
        echo "Usage: soto web [domain] -[option]"
        echo "Options:"
        echo "  -wp         Create a WordPress site"
        echo "  -php        Create a standard PHP site"
        echo "  -ssl        Enable Let's Encrypt SSL"
        echo "  -delete     Remove a site"
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

    # 2. Add PHP index file if not existing
    if [[ ! -f "/var/www/$domain/index.php" ]]; then
        echo "<?php phpinfo(); ?>" > "/var/www/$domain/index.php"
        chown www-data:www-data "/var/www/$domain/index.php"
    fi

    # 3. Create Nginx vhost
    log_info "Generating Nginx virtual host..."
    VHOST_FILE="/etc/nginx/sites-available/$domain"
    TEMPLATE_FILE="$SOTO_BASE_DIR/templates/nginx-php.conf"

    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Nginx template not found."
        return 1
    fi

    # Replace placeholders using sed
    sed "s/{{DOMAIN}}/$domain/g; s/{{PHP_VER}}/$php_ver/g" "$TEMPLATE_FILE" > "$VHOST_FILE"

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
    
    # Download WP
    sudo -u www-data wp core download --allow-root
    
    # Create wp-config.php
    sudo -u www-data wp config create --dbname="$db_name" --dbuser="$db_user" --dbpass="$db_pass" --allow-root
    
    # Enable per-site FastCGI Cache
    enable_cache "$domain"

    # Install and Activate Redis Object Cache Plugin
    log_info "Installing Redis Object Cache plugin..."
    sudo -u www-data wp plugin install redis-cache --activate --allow-root
    
    log_success "WordPress 'Ultra' ready for $domain!"
    echo "------------------------------------------"
    echo "Access your site at: http://$domain"
    echo "to finish the browser setup."
    echo "------------------------------------------"
}

check_wp_cli() {
    if ! check_command wp; then
        log_info "Installing WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
}

create_mysql_db() {
    local name=$1
    local user=$2
    local pass=$3
    
    mysql -e "CREATE DATABASE IF NOT EXISTS $name;"
    mysql -e "CREATE USER IF NOT EXISTS '$user'@'localhost' IDENTIFIED BY '$pass';"
    mysql -e "GRANT ALL PRIVILEGES ON $name.* TO '$user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
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
    
    nginx -t && systemctl reload nginx
    log_success "PHP version for $domain updated to $version."
}

delete_site() {
    local domain=$1
    rm -f "/etc/nginx/sites-enabled/$domain"
    rm -f "/etc/nginx/sites-available/$domain"
    rm -rf "/var/www/$domain"
    systemctl reload nginx
    log_success "Site $domain deleted."
}

source_ssl() {
    # Lazy include ssl.sh
    if [[ -f "$SOTO_BASE_DIR/inc/ssl.sh" ]]; then
        source "$SOTO_BASE_DIR/inc/ssl.sh"
    fi
}

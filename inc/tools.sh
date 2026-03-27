#!/bin/bash

# SotoWeb Tools & Dashboard
# Author: Ghasali

handle_tools() {
    # Check for root
    check_root

    OPTION="$1"

    if [[ -z "$OPTION" ]]; then
        echo "Usage: soto tools -[option]"
        echo "Options:"
        echo "  -dash       Install/Activate SotoDash (Port 22222)"
        echo "  -status     Show quick server status"
        return 0
    fi

    case "$OPTION" in
        -dash)
            install_dashboard
            ;;
        -status)
            show_status
            ;;
        *)
            log_error "Unknown tool option: $OPTION"
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
    local php_sock=$(get_php_fpm_sock)
    cat > /etc/nginx/sites-available/soto-dash <<EOF
server {
    listen 22222;
    server_name _;
    root /var/www/soto-dash;
    index index.html stats.php;

    # HTTP Basic Authentication
    auth_basic "SotoDash Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;

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

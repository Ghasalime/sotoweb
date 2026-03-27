#!/bin/bash

# SotoWeb HTTP Authentication Management
# Author: Ghasali

handle_auth() {
    check_root
    ensure_htpasswd

    local target="$1"
    local option="$2"
    local username="$3"

    # Default to global if first arg is an option
    if [[ "$target" == -* ]]; then
        username="$option"
        option="$target"
        target="global"
    fi

    if [[ -z "$target" || "$target" == "-h" || "$target" == "--help" ]]; then
        echo "Usage: soto auth [domain|global] -[option] [username]"
        echo ""
        echo "Options:"
        echo "  -add        Add or update a user (Global by default)"
        echo "  -delete     Delete a user"
        echo "  -list       List all users"
        echo "  -wp-admin   Protect the WordPress Admin area (/wp-admin)"
        echo "  -off        Remove all HTTP auth from a domain"
        echo ""
        echo "Example:"
        echo "  sudo soto auth -add ghasali"
        echo "  sudo soto auth example.com -wp-admin"
        return 0
    fi

    local auth_file="/etc/sotoweb/.htpasswd"
    mkdir -p "/etc/sotoweb"
        echo "Options:"
        echo "  -add        Add or update a user"
        echo "  -delete     Delete a user"
        echo "  -list       List all users"
        echo "  -wp-admin   Protect the WordPress Admin area (/wp-admin)"
        echo "  -path       Protect a custom directory (domain required)"
        echo "  -off        Remove all HTTP auth from a domain"
        echo ""
        echo "Example:"
        echo "  sudo soto auth example.com -add ghasali"
        echo "  sudo soto auth example.com -wp-admin"
        return 0
    fi

    local htpasswd_file="$auth_file"

    case "$option" in
        -add)
            if [[ -z "$username" ]]; then
                log_error "Username required. (e.g., soto auth $target -add ghasali)"
                return 1
            fi
            log_info "Setting password for user: $username"
            if [[ ! -f "$htpasswd_file" ]]; then
                htpasswd -c "$htpasswd_file" "$username"
            else
                htpasswd "$htpasswd_file" "$username"
            fi
            log_success "User $username added/updated for $target."
            ;;
        -delete)
            if [[ -z "$username" ]]; then
                log_error "Username required. (e.g., soto auth $target -delete ghasali)"
                return 1
            fi
            if [[ ! -f "$htpasswd_file" ]]; then
                log_error "No auth users exist for $target."
                return 1
            fi
            sed -i "/^$username:/d" "$htpasswd_file"
            log_success "User $username removed from $target."
            ;;
        -list)
            if [[ ! -f "$htpasswd_file" ]]; then
                log_info "No auth users configured for $target."
                return 0
            fi
            log_info "Auth Users for $target:"
            awk -F: '{print " - " $1}' "$htpasswd_file"
            ;;
        -wp-admin)
            if [[ "$target" == "global" ]]; then
                log_error "-wp-admin requires a specific domain."
                return 1
            fi
            enable_wp_auth "$target" "$htpasswd_file"
            ;;
        -path=*)
            local path="${option#*=}"
            if [[ "$target" == "global" ]]; then
                log_error "-path requires a specific domain."
                return 1
            fi
            enable_path_auth "$target" "$path" "$htpasswd_file"
            ;;
        -off)
            disable_auth "$target"
            ;;
        *)
            log_error "Unknown auth option: $option"
            ;;
    esac
}

enable_wp_auth() {
    local domain=$1
    local htpasswd=$2
    local vhost="/etc/nginx/sites-available/$domain"

    if [[ ! -f "$vhost" ]]; then
        log_error "Site $domain not found."
        return 1
    fi

    if [[ ! -f "$htpasswd" ]]; then
        log_warn "No global users configured yet. Run 'sudo soto auth -add [user]' now."
        # Create empty file to avoid Nginx error
        touch "$htpasswd"
    fi

    log_info "Protecting WordPress admin for $domain..."
    
    # Create or update auth snippet
    local snippet="/etc/nginx/conf.d/auth-$domain.conf"
    cat > "$snippet" <<EOF
location ~* /(wp-admin/|wp-login\.php) {
    auth_basic "Restricted Area";
    auth_basic_user_file $htpasswd;
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php$(get_php_version)-fpm.sock;
}
EOF

    # Include snippet in vhost if not present
    if ! grep -q "auth-$domain.conf" "$vhost"; then
        sed -i "/server_name/a \    include /etc/nginx/conf.d/auth-$domain.conf;" "$vhost"
    fi

    nginx -t && systemctl reload nginx
    log_success "WordPress admin protection enabled for $domain."
}

enable_path_auth() {
    local domain=$1
    local path=$2
    local htpasswd=$3
    local vhost="/etc/nginx/sites-available/$domain"

    if [[ ! -f "$vhost" ]]; then
        log_error "Site $domain not found."
        return 1
    fi

    log_info "Protecting path $path for $domain..."
    
    # Simple injection for basic paths
    # (In a real app, we'd use a more robust template system)
    local slug=$(echo "$path" | tr '/' '_')
    local snippet="/etc/nginx/conf.d/auth-$domain-$slug.conf"
    
    cat > "$snippet" <<EOF
location $path {
    auth_basic "Restricted Area";
    auth_basic_user_file $htpasswd;
}
EOF

    if ! grep -q "auth-$domain-$slug.conf" "$vhost"; then
        sed -i "/server_name/a \    include /etc/nginx/conf.d/auth-$domain-$slug.conf;" "$vhost"
    fi

    nginx -t && systemctl reload nginx
    log_success "Path $path protection enabled for $domain."
}

disable_auth() {
    local domain=$1
    local vhost="/etc/nginx/sites-available/$domain"

    log_info "Removing all HTTP auth from $domain..."
    
    # Remove includes from vhost
    sed -i "/auth-$domain/d" "$vhost"
    
    # Remove snippets
    rm -f /etc/nginx/conf.d/auth-$domain*.conf
    
    nginx -t && systemctl reload nginx
    log_success "HTTP auth removed from $domain."
}

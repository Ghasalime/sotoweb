#!/bin/bash

# SotoWeb SSL Management (Certbot)
# Author: Antigravity

activate_ssl() {
    local domain=$1
    check_root

    log_info "Confirming domain $domain..."
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Domain $domain not found in Nginx configuration."
        return 1
    fi

    # Check for certbot
    if ! check_command certbot; then
        log_info "Installing certbot and python3-certbot-nginx..."
        apt install -y -qq certbot python3-certbot-nginx
    fi

    log_info "Requesting SSL certificate for $domain..."
    # --nginx handles the nginx configuration update automatically
    # --non-interactive requires an email address if --register-unsafely-without-email not used
    certbot --nginx -d "$domain" -d "www.$domain" --non-interactive --agree-tos --register-unsafely-without-email

    if [[ $? -eq 0 ]]; then
        log_success "SSL certificate successfully installed for $domain."
        log_info "Nginx reloaded automatically."
    else
        log_error "Failed to obtain SSL for $domain. Check your domain's DNS settings."
    fi
}

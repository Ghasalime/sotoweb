#!/bin/bash

# SotoWeb Log Viewer
# Author: Ghasali

handle_log() {
    # Check for root
    check_root

    OPTION="$1"
    DOMAIN="$2"

    if [[ -z "$OPTION" ]]; then
        echo "Usage: soto log -[option] [domain]"
        echo "Options:"
        echo "  -error      View Nginx global error logs"
        echo "  -access     View Nginx global access logs"
        echo "  -site       View site-specific logs (requires domain)"
        echo "  -php        View PHP error logs"
        return 0
    fi

    case "$OPTION" in
        -error)
            log_info "Reading Nginx error logs..."
            tail -n 100 /var/log/nginx/error.log
            ;;
        -access)
            log_info "Reading Nginx access logs..."
            tail -n 100 /var/log/nginx/access.log
            ;;
        -site)
            if [[ -z "$DOMAIN" ]]; then
                log_error "Domain name required for site logs."
                return 1
            fi
            log_info "Reading access logs for $DOMAIN..."
            if [[ -f "/var/log/nginx/$DOMAIN.access.log" ]]; then
                tail -n 100 "/var/log/nginx/$DOMAIN.access.log"
            else
                log_error "Log file for $DOMAIN not found."
            fi
            ;;
        -php)
            # Fetch latest PHP version log
            PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
            log_info "Reading PHP $PHP_VER logs..."
            if [[ -f "/var/log/php$PHP_VER-fpm.log" ]]; then
                tail -n 100 "/var/log/php$PHP_VER-fpm.log"
            else
                log_error "PHP log file not found."
            fi
            ;;
        *)
            log_error "Unknown log option: $OPTION"
            ;;
    esac
}

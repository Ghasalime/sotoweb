#!/bin/bash

# SotoWeb Log Viewer
# Author: Ghasali

handle_log() {
    # Check for root
    check_root

    OPTION="$1"
    DOMAIN="$2"

    if [[ -z "$OPTION" ]]; then
        echo "Usage: soto log <domain> -[option]"
        echo "Options:"
        echo "  -error      View Nginx error logs"
        echo "  -access     View Nginx access logs"
        echo "  -php        View PHP-FPM logs"
        echo "  -mysql      View MariaDB logs"
        echo "  -wp         View WordPress debug logs"
        echo "  -purge      Clear (truncate) logs for this site"
        return 0
    fi
    
    local DOMAIN=$1
    local OPTION=$2

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
        -mysql)
            log_info "Viewing MariaDB logs..."
            tail -f /var/log/mysql/error.log
            ;;
        -purge)
            purge_logs "$DOMAIN"
            ;;
        -wp)
            show_wp_debug_logs "$DOMAIN"
            ;;
        *)
            log_error "Unknown log option: $OPTION"
            ;;
    esac
}

show_wp_debug_logs() {
    local domain=$1
    local debug_log="/var/www/$domain/wp-content/debug.log"
    
    if [[ -z "$domain" ]]; then
        log_error "Domain name required for WordPress logs."
        return 1
    fi
    
    if [[ ! -f "$debug_log" ]]; then
        log_warn "WordPress debug log not found at $debug_log"
        log_info "Make sure WP_DEBUG and WP_DEBUG_LOG are enabled in wp-config.php."
        echo "Add these lines to wp-config.php:"
        echo "  define( 'WP_DEBUG', true );"
        echo "  define( 'WP_DEBUG_LOG', true );"
        echo "  define( 'WP_DEBUG_DISPLAY', false );"
        return 1
    fi
    
    log_info "Tailing WordPress debug logs for $domain..."
    tail -f "$debug_log"
}

purge_logs() {
    local domain=$1
    if [[ -z "$domain" ]]; then
        log_error "Domain name required for purging logs."
        return 1
    fi
    log_info "Purging logs for $domain..."
    truncate -s 0 "/var/log/nginx/$domain.access.log" 2>/dev/null
    truncate -s 0 "/var/log/nginx/$domain.error.log" 2>/dev/null
    log_success "Logs for $domain have been cleared."
}

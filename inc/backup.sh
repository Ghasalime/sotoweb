#!/bin/bash

# SotoWeb Cloud Backup (rclone)
# Author: Ghasali

handle_backup() {
    # Check for root
    check_root

    OPTION="$1"
    REMOTE="$2"

    if [[ -z "$OPTION" ]]; then
        echo "Usage: soto backup -[option] [remote_name]"
        echo "Options:"
        echo "  -config     Configure cloud storage (interactive rclone)"
        echo "  -run        Run backup now to a remote"
        echo "  -list       List configured remotes"
        return 0
    fi

    # Check for rclone
    if ! check_command rclone; then
        log_info "Installing rclone..."
        curl https://rclone.org/install.sh | sudo bash
    fi

    case "$OPTION" in
        -config)
            rclone config
            ;;
        -list)
            rclone listremotes
            ;;
        -run)
            if [[ -z "$REMOTE" ]]; then
                log_error "Remote name required for backup. (e.g., soto backup -run s3_backup)"
                return 1
            fi
            
            # 1. Prepare backup directory
            BACKUP_DIR="/var/www/soto-backups"
            mkdir -p "$BACKUP_DIR/db"
            
            # 2. Dump Databases
            log_info "Dumping databases to $BACKUP_DIR/db..."
            databases=$(mysql -e "SHOW DATABASES;" | grep -Ev "Database|information_schema|performance_schema|mysql|sys")
            for db in $databases; do
                log_info "Backing up database: $db"
                mysqldump "$db" > "$BACKUP_DIR/db/$db-$(date +%F).sql"
            done
            
            # 3. Sync to Cloud
            log_info "Syncing files to $REMOTE:sotoweb/..."
            rclone sync /var/www "$REMOTE:sotoweb/www" --exclude "soto-backups/**" --progress
            rclone sync "$BACKUP_DIR" "$REMOTE:sotoweb/backups" --progress
            rclone sync /etc/nginx/sites-available "$REMOTE:sotoweb/nginx"
            
            # 4. Cleanup old local backups (7 days)
            find "$BACKUP_DIR/db" -type f -name "*.sql" -mtime +7 -delete
            
            log_success "Backup completed and synced to $REMOTE."
            ;;
        *)
            log_error "Unknown backup option: $OPTION"
            ;;
    esac
}

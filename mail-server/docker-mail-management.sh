#!/bin/bash

# Docker Mail Server Management Script
set -e

DOMAIN="bdgsoftware.com"

# Function to add user
add_user() {
    local email=$1
    local password=$2
    
    if [ -z "$email" ] || [ -z "$password" ]; then
        echo "Usage: add_user email password"
        return 1
    fi
    
    docker-compose exec mailserver setup email add "$email" "$password"
    echo "✅ User $email created successfully"
}

# Function to delete user
delete_user() {
    local email=$1
    
    if [ -z "$email" ]; then
        echo "Usage: delete_user email"
        return 1
    fi
    
    docker-compose exec mailserver setup email del "$email"
    echo "✅ User $email deleted successfully"
}

# Function to update password
update_password() {
    local email=$1
    local password=$2
    
    if [ -z "$email" ] || [ -z "$password" ]; then
        echo "Usage: update_password email new_password"
        return 1
    fi
    
    docker-compose exec mailserver setup email update "$email" "$password"
    echo "✅ Password updated for $email"
}

# Function to add alias
add_alias() {
    local source=$1
    local destination=$2
    
    if [ -z "$source" ] || [ -z "$destination" ]; then
        echo "Usage: add_alias source_email destination_email"
        return 1
    fi
    
    docker-compose exec mailserver setup alias add "$source" "$destination"
    echo "✅ Alias $source -> $destination created successfully"
}

# Function to list users
list_users() {
    echo "📋 Current users:"
    docker-compose exec mailserver setup email list
}

# Function to show status
show_status() {
    echo "📊 Docker Mail Server Status:"
    docker-compose ps
    echo ""
    echo "📈 Service Health:"
    docker-compose exec mailserver ss -tlnp | grep -E ':25|:465|:587|:993|:143'
}

# Function to show logs
show_logs() {
    local service=${1:-mailserver}
    echo "📋 Logs for $service:"
    docker-compose logs --tail=50 "$service"
}

# Function to restart services
restart_services() {
    echo "🔄 Restarting Docker mail services..."
    docker-compose restart
    echo "✅ Services restarted"
}

# Function to backup
backup_mail() {
    local backup_dir="/backup/docker-mail-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    echo "💾 Creating backup in $backup_dir..."
    
    # Backup mail data
    docker-compose exec mailserver tar -czf - /var/mail > "$backup_dir/mail-data.tar.gz"
    
    # Backup configuration
    docker-compose exec mailserver tar -czf - /tmp/docker-mailserver > "$backup_dir/config.tar.gz"
    
    # Backup docker-compose configuration
    cp docker-compose.yml "$backup_dir/"
    cp mailserver.env "$backup_dir/"
    
    echo "✅ Backup completed: $backup_dir"
}

# Function to show DKIM key
show_dkim() {
    echo "🔑 DKIM Public Key for $DOMAIN:"
    docker-compose exec mailserver cat /tmp/docker-mailserver/opendkim/keys/$DOMAIN/mail.txt
    echo ""
    echo "Add this as a TXT record in your DNS:"
    echo "Host: mail._domainkey.$DOMAIN"
    echo "Value: (copy the content above, remove quotes and newlines)"
}

# Main script
case "$1" in
    add)
        add_user "$2" "$3"
        ;;
    delete)
        delete_user "$2"
        ;;
    password)
        update_password "$2" "$3"
        ;;
    alias)
        add_alias "$2" "$3"
        ;;
    list)
        list_users
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    restart)
        restart_services
        ;;
    backup)
        backup_mail
        ;;
    dkim)
        show_dkim
        ;;
    *)
        echo "Docker Mail Server Management Script"
        echo "Usage: $0 {add|delete|password|alias|list|status|logs|restart|backup|dkim}"
        echo ""
        echo "Commands:"
        echo "  add <email> <password>           - Add new user"
        echo "  delete <email>                   - Delete user"
        echo "  password <email> <new_password>  - Update password"
        echo "  alias <source> <destination>     - Add alias"
        echo "  list                             - List all users"
        echo "  status                           - Show service status"
        echo "  logs [service]                   - Show logs"
        echo "  restart                          - Restart services"
        echo "  backup                           - Create backup"
        echo "  dkim                             - Show DKIM public key"
        echo ""
        echo "Examples:"
        echo "  $0 add john@$DOMAIN mypassword123"
        echo "  $0 alias contact@$DOMAIN john@$DOMAIN"
        echo "  $0 list"
        echo "  $0 status"
        echo "  $0 dkim"
        exit 1
        ;;
esac

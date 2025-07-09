#!/bin/bash

# User Management Script
set -e

DOMAIN="bdgsoftware.com"
MYSQL_ROOT_PASSWORD=$(grep "MySQL root password:" /root/mysql_passwords.txt | cut -d' ' -f4)

# Function to generate password hash
generate_password_hash() {
    local password=$1
    echo $(openssl passwd -1 "$password")
}

# Function to add user
add_user() {
    local email=$1
    local password=$2
    local quota=${3:-1073741824}  # Default 1GB
    
    local password_hash=$(generate_password_hash "$password")
    local domain_part=$(echo "$email" | cut -d'@' -f2)
    local local_part=$(echo "$email" | cut -d'@' -f1)
    
    # Get domain ID
    local domain_id=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -s -N mailserver -e "SELECT id FROM domains WHERE domain='$domain_part'")
    
    if [ -z "$domain_id" ]; then
        echo "Domain $domain_part not found. Adding it..."
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "INSERT INTO domains (domain) VALUES ('$domain_part')"
        domain_id=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -s -N mailserver -e "SELECT id FROM domains WHERE domain='$domain_part'")
    fi
    
    # Add user
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "INSERT INTO users (domain_id, email, password, quota) VALUES ($domain_id, '$email', '$password_hash', $quota)"
    
    # Create mail directory
    mkdir -p "/var/mail/$domain_part/$local_part"
    chown -R vmail:mail "/var/mail/$domain_part/$local_part"
    chmod -R 770 "/var/mail/$domain_part/$local_part"
    
    echo "✅ User $email created successfully"
}

# Function to delete user
delete_user() {
    local email=$1
    local domain_part=$(echo "$email" | cut -d'@' -f2)
    local local_part=$(echo "$email" | cut -d'@' -f1)
    
    # Delete from database
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "DELETE FROM users WHERE email='$email'"
    
    # Remove mail directory
    rm -rf "/var/mail/$domain_part/$local_part"
    
    echo "✅ User $email deleted successfully"
}

# Function to change password
change_password() {
    local email=$1
    local new_password=$2
    local password_hash=$(generate_password_hash "$new_password")
    
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "UPDATE users SET password='$password_hash' WHERE email='$email'"
    
    echo "✅ Password changed for $email"
}

# Function to add alias
add_alias() {
    local source=$1
    local destination=$2
    local domain_part=$(echo "$source" | cut -d'@' -f2)
    
    # Get domain ID
    local domain_id=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -s -N mailserver -e "SELECT id FROM domains WHERE domain='$domain_part'")
    
    if [ -z "$domain_id" ]; then
        echo "Domain $domain_part not found!"
        return 1
    fi
    
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "INSERT INTO aliases (domain_id, source, destination) VALUES ($domain_id, '$source', '$destination')"
    
    echo "✅ Alias $source -> $destination created successfully"
}

# Function to list users
list_users() {
    echo "📋 Current users:"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "SELECT u.email, d.domain, u.active, u.created_at FROM users u JOIN domains d ON u.domain_id = d.id ORDER BY u.email"
}

# Function to list aliases
list_aliases() {
    echo "📋 Current aliases:"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver -e "SELECT a.source, a.destination, d.domain, a.active FROM aliases a JOIN domains d ON a.domain_id = d.id ORDER BY a.source"
}

# Main script
case "$1" in
    add)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 add <email> <password> [quota_in_bytes]"
            exit 1
        fi
        add_user "$2" "$3" "$4"
        ;;
    delete)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 delete <email>"
            exit 1
        fi
        delete_user "$2"
        ;;
    password)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 password <email> <new_password>"
            exit 1
        fi
        change_password "$2" "$3"
        ;;
    alias)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 alias <source_email> <destination_email>"
            exit 1
        fi
        add_alias "$2" "$3"
        ;;
    list)
        list_users
        ;;
    aliases)
        list_aliases
        ;;
    *)
        echo "Usage: $0 {add|delete|password|alias|list|aliases}"
        echo "Examples:"
        echo "  $0 add john@$DOMAIN mypassword123"
        echo "  $0 delete john@$DOMAIN"
        echo "  $0 password john@$DOMAIN newpassword456"
        echo "  $0 alias info@$DOMAIN john@$DOMAIN"
        echo "  $0 list"
        echo "  $0 aliases"
        exit 1
        ;;
esac

#!/bin/bash

# Admin Email Forwarding Setup Script
# This script configures the mail server to forward ALL emails to the admin email
# Compatible with docker-mailserver (Postfix + Dovecot)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"
CONFIG_DIR="./docker-data/dms/config"

echo -e "${BLUE}🔧 Setting up admin email forwarding for ${DOMAIN}${NC}"
echo -e "${GREEN}Admin email: ${ADMIN_EMAIL}${NC}"
echo ""

# Function to print colored output
print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Create config directory if it doesn't exist
mkdir -p "${CONFIG_DIR}"

# Step 1: Create postfix virtual alias map for catch-all forwarding
print_step "Creating virtual alias map for catch-all forwarding..."

# Create virtual alias file that forwards everything to admin
cat > "${CONFIG_DIR}/postfix-virtual.cf" << EOF
# Virtual alias map for ${DOMAIN}
# This forwards ALL emails to admin@${DOMAIN}

# Catch-all forwarding - any email to @${DOMAIN} goes to admin
@${DOMAIN} ${ADMIN_EMAIL}

# Specific forwards for common addresses (in case you want different handling later)
postmaster@${DOMAIN} ${ADMIN_EMAIL}
abuse@${DOMAIN} ${ADMIN_EMAIL}
hostmaster@${DOMAIN} ${ADMIN_EMAIL}
webmaster@${DOMAIN} ${ADMIN_EMAIL}
admin@${DOMAIN} ${ADMIN_EMAIL}
root@${DOMAIN} ${ADMIN_EMAIL}
info@${DOMAIN} ${ADMIN_EMAIL}
support@${DOMAIN} ${ADMIN_EMAIL}
sales@${DOMAIN} ${ADMIN_EMAIL}
contact@${DOMAIN} ${ADMIN_EMAIL}
hello@${DOMAIN} ${ADMIN_EMAIL}
noreply@${DOMAIN} ${ADMIN_EMAIL}
no-reply@${DOMAIN} ${ADMIN_EMAIL}
EOF

print_success "Virtual alias map created"

# Step 2: Create postfix main.cf override for virtual aliases
print_step "Creating postfix main.cf override..."

cat > "${CONFIG_DIR}/postfix-main.cf" << EOF
# Postfix main.cf override for virtual alias forwarding
# This enables catch-all forwarding to admin email

# Virtual alias configuration
virtual_alias_domains = ${DOMAIN}
virtual_alias_maps = hash:/tmp/docker-mailserver/postfix-virtual.cf

# Ensure virtual aliases are processed
recipient_delimiter = +
EOF

print_success "Postfix main.cf override created"

# Step 3: Create user accounts creation script with forwarding
print_step "Creating enhanced user creation script..."

cat > "${CONFIG_DIR}/create-user-with-forwarding.sh" << 'EOF'
#!/bin/bash

# Enhanced user creation script that creates users AND sets up forwarding
# Usage: ./create-user-with-forwarding.sh email@domain.com password

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 email@domain.com password"
    echo "This script creates a user account and sets up forwarding to admin"
    exit 1
fi

EMAIL="$1"
PASSWORD="$2"
DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"

echo "Creating user account: $EMAIL"
echo "Setting up forwarding to: $ADMIN_EMAIL"

# Create the user account
docker-compose exec mailserver setup email add "$EMAIL" "$PASSWORD"

# Add to virtual aliases (append to existing file)
echo "$EMAIL $ADMIN_EMAIL" >> /tmp/docker-mailserver/postfix-virtual.cf

# Reload postfix to apply changes
docker-compose exec mailserver postfix reload

echo "✅ User $EMAIL created with forwarding to $ADMIN_EMAIL"
EOF

chmod +x "${CONFIG_DIR}/create-user-with-forwarding.sh"

print_success "Enhanced user creation script created"

# Step 4: Create management script for forwarding (separate file)
print_step "Creating forwarding management script..."

cat > "./create-manage-forwarding.sh" << 'EOF'
#!/bin/bash
# This script creates the manage-forwarding.sh script
cat > "./manage-forwarding.sh" << 'SCRIPT_EOF'
#!/bin/bash

# Email Forwarding Management Script
# Manages email forwarding for the Docker mail server

set -e

DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"
CONFIG_DIR="./docker-data/dms/config"
VIRTUAL_FILE="${CONFIG_DIR}/postfix-virtual.cf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_help() {
    echo "Email Forwarding Management Script"
    echo "Usage: $0 {enable-catchall|disable-catchall|add-forward|remove-forward|list-forwards|reload}"
    echo ""
    echo "Commands:"
    echo "  enable-catchall                    - Forward ALL emails to admin"
    echo "  disable-catchall                   - Disable catch-all forwarding"
    echo "  add-forward <from> <to>           - Add specific forwarding rule"
    echo "  remove-forward <from>             - Remove forwarding rule"
    echo "  list-forwards                     - List all forwarding rules"
    echo "  reload                            - Reload postfix configuration"
    echo "  create-user <email> <password>    - Create user with auto-forwarding"
    echo ""
    echo "Examples:"
    echo "  $0 enable-catchall"
    echo "  $0 add-forward sales@${DOMAIN} admin@${DOMAIN}"
    echo "  $0 create-user john@${DOMAIN} mypassword123"
}

enable_catchall() {
    echo -e "${BLUE}🔧 Enabling catch-all forwarding to ${ADMIN_EMAIL}${NC}"
    
    # Backup existing file
    if [ -f "${VIRTUAL_FILE}" ]; then
        cp "${VIRTUAL_FILE}" "${VIRTUAL_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Create new virtual file with catch-all
    cat > "${VIRTUAL_FILE}" << VIRTUAL_EOF
# Virtual alias map for ${DOMAIN}
# Catch-all forwarding - forwards ALL emails to admin

@${DOMAIN} ${ADMIN_EMAIL}

# Standard aliases
postmaster@${DOMAIN} ${ADMIN_EMAIL}
abuse@${DOMAIN} ${ADMIN_EMAIL}
hostmaster@${DOMAIN} ${ADMIN_EMAIL}
webmaster@${DOMAIN} ${ADMIN_EMAIL}
admin@${DOMAIN} ${ADMIN_EMAIL}
root@${DOMAIN} ${ADMIN_EMAIL}
VIRTUAL_EOF
    
    reload_postfix
    echo -e "${GREEN}✅ Catch-all forwarding enabled${NC}"
}

disable_catchall() {
    echo -e "${BLUE}🔧 Disabling catch-all forwarding${NC}"
    
    # Remove catch-all line
    if [ -f "${VIRTUAL_FILE}" ]; then
        sed -i "/^@${DOMAIN}/d" "${VIRTUAL_FILE}"
        reload_postfix
        echo -e "${GREEN}✅ Catch-all forwarding disabled${NC}"
    else
        echo -e "${YELLOW}⚠️  No virtual alias file found${NC}"
    fi
}

add_forward() {
    local from_email="$1"
    local to_email="$2"
    
    if [ -z "$from_email" ] || [ -z "$to_email" ]; then
        echo -e "${RED}❌ Usage: add-forward <from_email> <to_email>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔧 Adding forwarding: ${from_email} -> ${to_email}${NC}"
    
    # Create virtual file if it doesn't exist
    if [ ! -f "${VIRTUAL_FILE}" ]; then
        touch "${VIRTUAL_FILE}"
    fi
    
    # Remove existing entry if present
    sed -i "/^${from_email}/d" "${VIRTUAL_FILE}"
    
    # Add new entry
    echo "${from_email} ${to_email}" >> "${VIRTUAL_FILE}"
    
    reload_postfix
    echo -e "${GREEN}✅ Forwarding added${NC}"
}

remove_forward() {
    local from_email="$1"
    
    if [ -z "$from_email" ]; then
        echo -e "${RED}❌ Usage: remove-forward <from_email>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔧 Removing forwarding for: ${from_email}${NC}"
    
    if [ -f "${VIRTUAL_FILE}" ]; then
        sed -i "/^${from_email}/d" "${VIRTUAL_FILE}"
        reload_postfix
        echo -e "${GREEN}✅ Forwarding removed${NC}"
    else
        echo -e "${YELLOW}⚠️  No virtual alias file found${NC}"
    fi
}

list_forwards() {
    echo -e "${BLUE}📋 Current forwarding rules:${NC}"
    
    if [ -f "${VIRTUAL_FILE}" ]; then
        grep -v "^#" "${VIRTUAL_FILE}" | grep -v "^$" | while read line; do
            echo -e "${GREEN}  ${line}${NC}"
        done
    else
        echo -e "${YELLOW}⚠️  No virtual alias file found${NC}"
    fi
}

reload_postfix() {
    echo -e "${BLUE}🔄 Reloading postfix configuration...${NC}"
    
    # Generate postfix hash database
    docker-compose exec mailserver postmap /tmp/docker-mailserver/postfix-virtual.cf
    
    # Reload postfix
    docker-compose exec mailserver postfix reload
    
    echo -e "${GREEN}✅ Postfix configuration reloaded${NC}"
}

create_user_with_forwarding() {
    local email="$1"
    local password="$2"
    
    if [ -z "$email" ] || [ -z "$password" ]; then
        echo -e "${RED}❌ Usage: create-user <email> <password>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔧 Creating user: ${email}${NC}"
    echo -e "${BLUE}🔧 Setting up forwarding to: ${ADMIN_EMAIL}${NC}"
    
    # Create user account
    docker-compose exec mailserver setup email add "$email" "$password"
    
    # Add forwarding rule
    add_forward "$email" "$ADMIN_EMAIL"
    
    echo -e "${GREEN}✅ User ${email} created with forwarding to ${ADMIN_EMAIL}${NC}"
}

# Main script logic
case "$1" in
    enable-catchall)
        enable_catchall
        ;;
    disable-catchall)
        disable_catchall
        ;;
    add-forward)
        add_forward "$2" "$3"
        ;;
    remove-forward)
        remove_forward "$2"
        ;;
    list-forwards)
        list_forwards
        ;;
    reload)
        reload_postfix
        ;;
    create-user)
        create_user_with_forwarding "$2" "$3"
        ;;
    *)
        print_help
        exit 1
        ;;
esac
SCRIPT_EOF

chmod +x "./manage-forwarding.sh"
EOF

chmod +x "./create-manage-forwarding.sh"
./create-manage-forwarding.sh

print_success "Forwarding management script created"

# Step 5: Update existing user creation scripts
print_step "Updating existing user creation scripts..."

# Update docker-mail-management.sh to include forwarding
if [ -f "./docker-mail-management.sh" ]; then
    # Add forwarding function to existing script
    cat >> "./docker-mail-management.sh" << 'EOF'

# Enhanced function to add user with forwarding
add_user_with_forwarding() {
    local email=$1
    local password=$2
    local forward_to=${3:-"admin@bdgsoftware.com"}
    
    if [ -z "$email" ] || [ -z "$password" ]; then
        echo "Usage: add_user_with_forwarding email password [forward_to]"
        return 1
    fi
    
    # Create user account
    docker-compose exec mailserver setup email add "$email" "$password"
    
    # Add forwarding rule
    echo "$email $forward_to" >> "./docker-data/dms/config/postfix-virtual.cf"
    
    # Reload postfix
    docker-compose exec mailserver postmap /tmp/docker-mailserver/postfix-virtual.cf
    docker-compose exec mailserver postfix reload
    
    echo "✅ User $email created with forwarding to $forward_to"
}
EOF

    # Update the help section
    sed -i '/exit 1/i\
        add-forward)            add_user_with_forwarding "$2" "$3" "$4";;' "./docker-mail-management.sh"
    
    print_success "Updated existing docker-mail-management.sh"
else
    print_warning "docker-mail-management.sh not found, skipping update"
fi

# Step 6: Create verification script
print_step "Creating setup verification script..."

cat > "./verify-forwarding-setup.sh" << 'EOF'
#!/bin/bash

# Verify Admin Forwarding Setup
set -e

DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"

echo "🔍 Verifying admin forwarding setup..."
echo ""

# Check if mail server is running
echo "📊 Checking mail server status..."
if docker-compose ps | grep -q "mailserver.*Up"; then
    echo "✅ Mail server is running"
else
    echo "❌ Mail server is not running"
    echo "   Run: docker-compose up -d mailserver"
    exit 1
fi

# Check virtual alias configuration
echo ""
echo "📋 Checking virtual alias configuration..."
if [ -f "./docker-data/dms/config/postfix-virtual.cf" ]; then
    echo "✅ Virtual alias file exists"
    echo "📧 Current forwarding rules:"
    grep -v "^#" "./docker-data/dms/config/postfix-virtual.cf" | grep -v "^$" | while read line; do
        echo "   $line"
    done
else
    echo "❌ Virtual alias file not found"
    echo "   Run: ./setup-admin-forwarding.sh"
fi

# Check if admin account exists
echo ""
echo "👤 Checking admin account..."
if docker-compose exec mailserver setup email list | grep -q "$ADMIN_EMAIL"; then
    echo "✅ Admin account exists: $ADMIN_EMAIL"
else
    echo "❌ Admin account not found: $ADMIN_EMAIL"
    echo "   Run: ./setup-email-accounts-with-forwarding.sh"
fi

# Check postfix configuration
echo ""
echo "⚙️  Checking postfix configuration..."
if docker-compose exec mailserver postconf virtual_alias_maps | grep -q "virtual"; then
    echo "✅ Virtual alias maps configured"
else
    echo "❌ Virtual alias maps not configured"
    echo "   Run: ./setup-admin-forwarding.sh"
fi

# Test email connectivity
echo ""
echo "🔌 Testing email connectivity..."
if docker-compose exec mailserver ss -tlnp | grep -q ":587"; then
    echo "✅ SMTP port 587 is open"
else
    echo "❌ SMTP port 587 is not accessible"
fi

if docker-compose exec mailserver ss -tlnp | grep -q ":993"; then
    echo "✅ IMAP port 993 is open"
else
    echo "❌ IMAP port 993 is not accessible"
fi

echo ""
echo "🎉 Setup verification complete!"
echo ""
echo "📧 To test forwarding:"
echo "   1. Send email to any address @${DOMAIN}"
echo "   2. Check ${ADMIN_EMAIL} inbox"
echo "   3. Verify forwarded email appears"
echo ""
echo "🛠️  Management commands:"
echo "   • ./manage-forwarding.sh list-forwards"
echo "   • ./manage-forwarding.sh create-user email@${DOMAIN} password"
echo "   • docker-compose logs mailserver"
EOF

chmod +x "./verify-forwarding-setup.sh"

print_success "Verification script created"

# Step 7: Apply the configuration
print_step "Applying forwarding configuration..."

# Check if mail server is running
if docker-compose ps | grep -q "mailserver.*Up"; then
    print_step "Mail server is running, applying configuration..."
    
    # Copy config files to running container
    docker-compose exec mailserver mkdir -p /tmp/docker-mailserver
    
    # Generate postfix hash database
    docker-compose exec mailserver postmap /tmp/docker-mailserver/postfix-virtual.cf
    
    # Reload postfix
    docker-compose exec mailserver postfix reload
    
    print_success "Configuration applied successfully"
else
    print_warning "Mail server is not running. Configuration will be applied when you start the server."
    print_warning "Run: docker-compose up -d mailserver"
fi

echo ""
echo -e "${GREEN}🎉 Admin email forwarding setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 What was configured:${NC}"
echo "• Catch-all forwarding: ALL emails to @${DOMAIN} → ${ADMIN_EMAIL}"
echo "• Virtual alias map created: ${CONFIG_DIR}/postfix-virtual.cf"
echo "• Enhanced user creation with auto-forwarding"
echo "• Management script: ./manage-forwarding.sh"
echo ""
echo -e "${BLUE}🛠️  Usage Examples:${NC}"
echo "• Create user with forwarding: ./manage-forwarding.sh create-user john@${DOMAIN} password123"
echo "• Enable catch-all: ./manage-forwarding.sh enable-catchall"
echo "• List forwards: ./manage-forwarding.sh list-forwards"
echo "• Add specific forward: ./manage-forwarding.sh add-forward sales@${DOMAIN} admin@${DOMAIN}"
echo ""
echo -e "${BLUE}🔧 To verify configuration:${NC}"
echo "• Check forwards: ./manage-forwarding.sh list-forwards"
echo "• Test email: Send test email to any address @${DOMAIN}"
echo "• Check logs: docker-compose logs mailserver"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "• All emails sent to ANY address @${DOMAIN} will be forwarded to ${ADMIN_EMAIL}"
echo "• This includes both existing and newly created accounts"
echo "• The admin account (${ADMIN_EMAIL}) must exist and be accessible"
echo "• Configuration persists across container restarts"

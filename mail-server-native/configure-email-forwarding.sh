#!/bin/bash

# Script to configure email forwarding to admin@bdgsoftware.cloud
# This script ensures all emails sent to any user are also forwarded to the admin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="bdgsoftware.cloud"
ADMIN_EMAIL="admin@bdgsoftware.cloud"

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_step "Configuring email forwarding to $ADMIN_EMAIL"

# Check if Postfix is installed
if ! command -v postconf &> /dev/null; then
    print_error "Postfix is not installed. Please run the mail server installation first."
    exit 1
fi

# Configure Postfix for forwarding
print_step "Configuring Postfix for email forwarding..."

# Create a directory for the forwarding configuration if it doesn't exist
mkdir -p /etc/postfix/forwarding

# Create the forwarding database
cat > /etc/postfix/forwarding/recipient_bcc_maps << EOF
# Forward all emails to admin
@$DOMAIN $ADMIN_EMAIL
EOF

# Create the sender BCC maps (to capture outgoing emails)
cat > /etc/postfix/forwarding/sender_bcc_maps << EOF
# Forward all outgoing emails to admin
@$DOMAIN $ADMIN_EMAIL
EOF

# Compile the databases
postmap /etc/postfix/forwarding/recipient_bcc_maps
postmap /etc/postfix/forwarding/sender_bcc_maps

# Update Postfix configuration
postconf -e "recipient_bcc_maps = hash:/etc/postfix/forwarding/recipient_bcc_maps"
postconf -e "sender_bcc_maps = hash:/etc/postfix/forwarding/sender_bcc_maps"

# Reload Postfix
print_step "Reloading Postfix configuration..."
systemctl reload postfix

print_success "Email forwarding configuration completed!"
print_success "All emails sent to and from @$DOMAIN addresses will be forwarded to $ADMIN_EMAIL"

# Create a script to add forwarding for new users
cat > /usr/local/bin/add-email-forwarding << EOF
#!/bin/bash

# Script to add email forwarding for a new user
# Usage: add-email-forwarding user@domain.com

if [ \$# -ne 1 ]; then
    echo "Usage: \$0 user@domain.com"
    exit 1
fi

EMAIL=\$1
ADMIN="$ADMIN_EMAIL"

# Add forwarding rule to Postfix
echo "\$EMAIL \$EMAIL, \$ADMIN" >> /etc/postfix/virtual
postmap /etc/postfix/virtual

echo "Forwarding added for \$EMAIL to \$ADMIN"
EOF

chmod +x /usr/local/bin/add-email-forwarding

print_success "Created utility script: /usr/local/bin/add-email-forwarding"
print_success "Use this script to add forwarding for new users"

# Update the manage-users.sh script to automatically add forwarding for new users
if [ -f "manage-users.sh" ]; then
    print_step "Updating manage-users.sh to automatically add forwarding for new users..."
    
    # Check if the script already has forwarding functionality
    if ! grep -q "add-email-forwarding" manage-users.sh; then
        # Find the line where a user is successfully added
        LINE_NUM=$(grep -n "User .* added successfully" manage-users.sh | cut -d: -f1)
        
        if [ -n "$LINE_NUM" ]; then
            # Insert the forwarding command after the user is added
            sed -i "${LINE_NUM}a\\    # Add email forwarding to admin\\n    /usr/local/bin/add-email-forwarding \$EMAIL" manage-users.sh
            print_success "Updated manage-users.sh to automatically add forwarding"
        else
            print_warning "Could not update manage-users.sh automatically. Please add forwarding manually."
        fi
    else
        print_success "manage-users.sh already has forwarding functionality"
    fi
fi

print_success "Email forwarding setup complete!"
echo ""
echo "All emails sent to and from @$DOMAIN addresses will be forwarded to $ADMIN_EMAIL"
echo "New users will automatically have forwarding configured"
echo ""
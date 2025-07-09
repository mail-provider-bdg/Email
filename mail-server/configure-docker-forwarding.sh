#!/bin/bash

# Script to configure email forwarding in Docker mail server
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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_step "Configuring email forwarding in Docker mail server to $ADMIN_EMAIL"

# Check if the mail server container is running
if ! docker-compose ps | grep -q "Up"; then
    print_error "Mail server container is not running. Please start it first."
    exit 1
fi

# Get the mail server container name
CONTAINER=$(docker-compose ps -q mailserver)

if [ -z "$CONTAINER" ]; then
    print_error "Could not find the mail server container."
    exit 1
fi

print_step "Configuring Postfix for email forwarding in the container..."

# Create the forwarding configuration
docker exec $CONTAINER bash -c "mkdir -p /etc/postfix/forwarding"

# Create the recipient BCC maps
docker exec $CONTAINER bash -c "echo '# Forward all emails to admin' > /etc/postfix/forwarding/recipient_bcc_maps"
docker exec $CONTAINER bash -c "echo '@$DOMAIN $ADMIN_EMAIL' >> /etc/postfix/forwarding/recipient_bcc_maps"

# Create the sender BCC maps
docker exec $CONTAINER bash -c "echo '# Forward all outgoing emails to admin' > /etc/postfix/forwarding/sender_bcc_maps"
docker exec $CONTAINER bash -c "echo '@$DOMAIN $ADMIN_EMAIL' >> /etc/postfix/forwarding/sender_bcc_maps"

# Compile the databases
docker exec $CONTAINER bash -c "postmap /etc/postfix/forwarding/recipient_bcc_maps"
docker exec $CONTAINER bash -c "postmap /etc/postfix/forwarding/sender_bcc_maps"

# Update Postfix configuration
docker exec $CONTAINER bash -c "postconf -e 'recipient_bcc_maps = hash:/etc/postfix/forwarding/recipient_bcc_maps'"
docker exec $CONTAINER bash -c "postconf -e 'sender_bcc_maps = hash:/etc/postfix/forwarding/sender_bcc_maps'"

# Reload Postfix
print_step "Reloading Postfix configuration in the container..."
docker exec $CONTAINER bash -c "postfix reload"

print_success "Email forwarding configuration completed in Docker container!"
print_success "All emails sent to and from @$DOMAIN addresses will be forwarded to $ADMIN_EMAIL"

# Create a script to add forwarding for new users
cat > ./docker-add-forwarding.sh << EOF
#!/bin/bash

# Script to add email forwarding for a new user in Docker
# Usage: ./docker-add-forwarding.sh user@domain.com

if [ \$# -ne 1 ]; then
    echo "Usage: \$0 user@domain.com"
    exit 1
fi

EMAIL=\$1
ADMIN="$ADMIN_EMAIL"
CONTAINER=\$(docker-compose ps -q mailserver)

if [ -z "\$CONTAINER" ]; then
    echo "Could not find the mail server container."
    exit 1
fi

# Add forwarding rule to Postfix
docker exec \$CONTAINER bash -c "echo '\$EMAIL \$EMAIL, \$ADMIN' >> /etc/postfix/virtual"
docker exec \$CONTAINER bash -c "postmap /etc/postfix/virtual"
docker exec \$CONTAINER bash -c "postfix reload"

echo "Forwarding added for \$EMAIL to \$ADMIN"
EOF

chmod +x ./docker-add-forwarding.sh

print_success "Created utility script: ./docker-add-forwarding.sh"
print_success "Use this script to add forwarding for new users"

# Update the docker-mail-management.sh script to automatically add forwarding for new users
if [ -f "docker-mail-management.sh" ]; then
    print_step "Updating docker-mail-management.sh to automatically add forwarding for new users..."
    
    # Check if the script already has forwarding functionality
    if ! grep -q "docker-add-forwarding.sh" docker-mail-management.sh; then
        # Find the line where a user is successfully added
        LINE_NUM=$(grep -n "User .* added successfully" docker-mail-management.sh | cut -d: -f1)
        
        if [ -n "$LINE_NUM" ]; then
            # Insert the forwarding command after the user is added
            sed -i "${LINE_NUM}a\\    # Add email forwarding to admin\\n    ./docker-add-forwarding.sh \$EMAIL" docker-mail-management.sh
            print_success "Updated docker-mail-management.sh to automatically add forwarding"
        else
            print_warning "Could not update docker-mail-management.sh automatically. Please add forwarding manually."
        fi
    else
        print_success "docker-mail-management.sh already has forwarding functionality"
    fi
fi

print_success "Docker email forwarding setup complete!"
echo ""
echo "All emails sent to and from @$DOMAIN addresses will be forwarded to $ADMIN_EMAIL"
echo "New users will automatically have forwarding configured"
echo ""
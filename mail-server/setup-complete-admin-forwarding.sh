#!/bin/bash

# Complete Admin Email Forwarding Setup Script
# This script sets up the complete admin forwarding system for BDG Software

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================${NC}"
    echo ""
}

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

print_header "Complete Admin Email Forwarding Setup"
echo "This script will set up a complete admin email forwarding system where:"
echo "• ALL emails sent to ANY address @${DOMAIN} are forwarded to ${ADMIN_EMAIL}"
echo "• Email accounts can be easily created with automatic forwarding"
echo "• Roundcube web interface includes forwarding awareness"
echo "• Management tools for ongoing administration"
echo ""
echo -e "${BLUE}📋 What will be configured:${NC}"
echo "1. Admin email forwarding (catch-all to admin)"
echo "2. Email accounts creation with auto-forwarding"
echo "3. Roundcube web interface with forwarding features"
echo "4. Management and verification tools"
echo ""
read -p "Continue with setup? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the mail-server directory."
    exit 1
fi

print_header "Step 1: Setting up Admin Email Forwarding"
print_step "Running admin forwarding setup..."

if [ -f "./setup-admin-forwarding.sh" ]; then
    ./setup-admin-forwarding.sh
    print_success "Admin forwarding setup completed"
else
    print_error "setup-admin-forwarding.sh not found"
    exit 1
fi

print_header "Step 2: Creating Email Accounts with Forwarding"
print_step "Creating email accounts with automatic forwarding..."

if [ -f "./setup-email-accounts-with-forwarding.sh" ]; then
    ./setup-email-accounts-with-forwarding.sh
    print_success "Email accounts created with forwarding"
else
    print_error "setup-email-accounts-with-forwarding.sh not found"
    exit 1
fi

print_header "Step 3: Configuring Roundcube Web Interface"
print_step "Setting up Roundcube with forwarding awareness..."

if [ -f "./configure-roundcube-forwarding.sh" ]; then
    ./configure-roundcube-forwarding.sh
    print_success "Roundcube configuration completed"
else
    print_error "configure-roundcube-forwarding.sh not found"
    exit 1
fi

print_header "Step 4: Verifying Complete Setup"
print_step "Running setup verification..."

if [ -f "./verify-forwarding-setup.sh" ]; then
    ./verify-forwarding-setup.sh
    print_success "Setup verification completed"
else
    print_error "verify-forwarding-setup.sh not found"
    exit 1
fi

print_header "🎉 Setup Complete!"

print_success "Admin email forwarding system is now fully configured!"
echo ""
echo -e "${BLUE}📧 Email Configuration Summary:${NC}"
echo "• Domain: ${DOMAIN}"
echo "• Admin Email: ${ADMIN_EMAIL}"
echo "• Catch-all forwarding: ALL emails → ${ADMIN_EMAIL}"
echo "• Accounts created with auto-forwarding to admin"
echo "• Roundcube web interface configured with forwarding awareness"
echo ""

# Show account information
if [ -f "/root/bdg_email_accounts.txt" ]; then
    echo -e "${BLUE}📋 Account Information:${NC}"
    echo "Account details saved to: /root/bdg_email_accounts.txt"
    echo ""
    echo -e "${BLUE}🔑 Admin Account (receives all emails):${NC}"
    grep "admin@${DOMAIN}" /root/bdg_email_accounts.txt | head -1
    echo ""
    echo -e "${BLUE}📧 Business Accounts (all forward to admin):${NC}"
    grep -E "(support|info|sales|contact|hello|marketing)@${DOMAIN}" /root/bdg_email_accounts.txt | head -6
else
    print_warning "Account information file not found"
fi

echo ""
echo -e "${BLUE}🌐 Access Information:${NC}"
echo "• Roundcube Web Interface: http://your-server-ip:8080"
echo "• IMAP Server: mail.${DOMAIN}:993 (SSL)"
echo "• SMTP Server: mail.${DOMAIN}:587 (STARTTLS)"
echo ""

echo -e "${BLUE}🛠️  Management Commands:${NC}"
echo "• Create new user with forwarding:"
echo "  ./manage-forwarding.sh create-user newuser@${DOMAIN} password123"
echo ""
echo "• List all forwarding rules:"
echo "  ./manage-forwarding.sh list-forwards"
echo ""
echo "• Check system status:"
echo "  ./verify-forwarding-setup.sh"
echo ""
echo "• View mail server logs:"
echo "  docker-compose logs mailserver"
echo ""
echo "• Manage existing accounts:"
echo "  ./docker-mail-management.sh list"
echo ""

echo -e "${BLUE}📚 Documentation:${NC}"
echo "• Complete documentation: README-ADMIN-FORWARDING.md"
echo "• Usage examples: USAGE-EXAMPLES.md"
echo ""

echo -e "${BLUE}🧪 Testing Your Setup:${NC}"
echo "1. Send a test email to any address @${DOMAIN}"
echo "2. Check the admin inbox (${ADMIN_EMAIL})"
echo "3. Verify the forwarded email appears"
echo ""

echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Configure DNS records for your domain"
echo "2. Test email sending and receiving"
echo "3. Set up SSL certificates for production"
echo "4. Configure firewall rules"
echo "5. Change default passwords"
echo ""

echo -e "${YELLOW}⚠️  Important Security Notes:${NC}"
echo "• ALL emails to @${DOMAIN} are forwarded to admin"
echo "• Change default passwords immediately"
echo "• Keep admin account credentials secure"
echo "• Monitor forwarded emails regularly"
echo "• Consider privacy implications of email forwarding"
echo ""

echo -e "${BLUE}🎯 How Email Forwarding Works:${NC}"
echo "1. Someone sends email to ANY address @${DOMAIN}"
echo "2. Mail server receives the email"
echo "3. Postfix virtual aliases forward it to admin"
echo "4. Admin receives the email in their inbox"
echo "5. Admin can respond or take action as needed"
echo ""

echo -e "${GREEN}🚀 Your admin email forwarding system is ready to use!${NC}"
echo -e "${GREEN}All emails sent to @${DOMAIN} will now be forwarded to ${ADMIN_EMAIL}${NC}"
echo ""
echo -e "${BLUE}For support and troubleshooting, see README-ADMIN-FORWARDING.md${NC}"

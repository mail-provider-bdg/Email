#!/bin/bash

# Enhanced Email Account Setup with Admin Forwarding
# This script creates email accounts and ensures all emails are forwarded to admin

set -e

DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📧 Creating email accounts with admin forwarding for ${DOMAIN}${NC}"
echo -e "${GREEN}Admin email: ${ADMIN_EMAIL}${NC}"
echo ""

# Generate secure passwords
ADMIN_PASSWORD=$(openssl rand -base64 16)
SUPPORT_PASSWORD=$(openssl rand -base64 16)
INFO_PASSWORD=$(openssl rand -base64 16)
SALES_PASSWORD=$(openssl rand -base64 16)
NOREPLY_PASSWORD=$(openssl rand -base64 16)

# Function to create user with forwarding
create_user_with_forwarding() {
    local email="$1"
    local password="$2"
    local description="$3"
    
    echo -e "${BLUE}🔧 Creating: ${email} (${description})${NC}"
    
    # Create the user account
    docker-compose exec mailserver setup email add "$email" "$password"
    
    # Add to virtual aliases for forwarding
    echo "$email $ADMIN_EMAIL" >> "./docker-data/dms/config/postfix-virtual.cf"
    
    echo -e "${GREEN}✅ Created: ${email}${NC}"
}

# Create admin account first
echo -e "${BLUE}🔧 Creating admin account: ${ADMIN_EMAIL}${NC}"
docker-compose exec mailserver setup email add "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
echo -e "${GREEN}✅ Admin account created${NC}"

# Create business email accounts with forwarding
create_user_with_forwarding "support@${DOMAIN}" "$SUPPORT_PASSWORD" "Customer Support"
create_user_with_forwarding "info@${DOMAIN}" "$INFO_PASSWORD" "General Information"
create_user_with_forwarding "sales@${DOMAIN}" "$SALES_PASSWORD" "Sales Inquiries"
create_user_with_forwarding "noreply@${DOMAIN}" "$NOREPLY_PASSWORD" "No Reply"

# Create additional common accounts
create_user_with_forwarding "contact@${DOMAIN}" "$ADMIN_PASSWORD" "Contact Form"
create_user_with_forwarding "hello@${DOMAIN}" "$ADMIN_PASSWORD" "Hello"
create_user_with_forwarding "marketing@${DOMAIN}" "$ADMIN_PASSWORD" "Marketing"

# Create system aliases (these go directly to admin)
echo -e "${BLUE}🔧 Creating system aliases...${NC}"
docker-compose exec mailserver setup alias add "postmaster@${DOMAIN}" "$ADMIN_EMAIL"
docker-compose exec mailserver setup alias add "abuse@${DOMAIN}" "$ADMIN_EMAIL"
docker-compose exec mailserver setup alias add "hostmaster@${DOMAIN}" "$ADMIN_EMAIL"
docker-compose exec mailserver setup alias add "webmaster@${DOMAIN}" "$ADMIN_EMAIL"
docker-compose exec mailserver setup alias add "root@${DOMAIN}" "$ADMIN_EMAIL"

# Reload postfix to apply forwarding rules
echo -e "${BLUE}🔄 Applying forwarding configuration...${NC}"
docker-compose exec mailserver postmap /tmp/docker-mailserver/postfix-virtual.cf
docker-compose exec mailserver postfix reload

# Save all passwords securely
echo -e "${BLUE}💾 Saving account information...${NC}"
cat > "/root/bdg_email_accounts.txt" << EOF
BDG Software Email Accounts - $(date)
====================================

ADMIN ACCOUNT (receives all emails):
${ADMIN_EMAIL}: ${ADMIN_PASSWORD}

BUSINESS ACCOUNTS (all forward to admin):
support@${DOMAIN}: ${SUPPORT_PASSWORD}
info@${DOMAIN}: ${INFO_PASSWORD}
sales@${DOMAIN}: ${SALES_PASSWORD}
contact@${DOMAIN}: ${ADMIN_PASSWORD}
hello@${DOMAIN}: ${ADMIN_PASSWORD}
marketing@${DOMAIN}: ${ADMIN_PASSWORD}
noreply@${DOMAIN}: ${NOREPLY_PASSWORD}

SYSTEM ALIASES (forward to admin):
postmaster@${DOMAIN} → ${ADMIN_EMAIL}
abuse@${DOMAIN} → ${ADMIN_EMAIL}
hostmaster@${DOMAIN} → ${ADMIN_EMAIL}
webmaster@${DOMAIN} → ${ADMIN_EMAIL}
root@${DOMAIN} → ${ADMIN_EMAIL}

FORWARDING CONFIGURATION:
• ALL emails sent to ANY address @${DOMAIN} are forwarded to ${ADMIN_EMAIL}
• This includes both existing accounts and any new accounts created
• Admin account receives original emails + forwarded emails

MAIL SERVER SETTINGS:
• IMAP Server: mail.${DOMAIN}:993 (SSL)
• SMTP Server: mail.${DOMAIN}:587 (STARTTLS)
• Username: full email address
• Password: as listed above

MANAGEMENT:
• Create new user with forwarding: ./manage-forwarding.sh create-user email@${DOMAIN} password
• List all forwards: ./manage-forwarding.sh list-forwards
• Check server status: ./docker-mail-management.sh status
• View logs: docker-compose logs mailserver

IMPORTANT NOTES:
• Change these passwords immediately after first login
• All emails are automatically forwarded to admin
• Keep this file secure and backup regularly
• Configure DNS records for proper email delivery
EOF

chmod 600 "/root/bdg_email_accounts.txt"

echo ""
echo -e "${GREEN}🎉 Email accounts created successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Account Summary:${NC}"
echo -e "${GREEN}Admin (receives all emails): ${ADMIN_EMAIL}${NC}"
echo -e "${GREEN}Password: ${ADMIN_PASSWORD}${NC}"
echo ""
echo -e "${BLUE}Business Accounts (all forward to admin):${NC}"
echo -e "• support@${DOMAIN}: ${SUPPORT_PASSWORD}"
echo -e "• info@${DOMAIN}: ${INFO_PASSWORD}"
echo -e "• sales@${DOMAIN}: ${SALES_PASSWORD}"
echo -e "• contact@${DOMAIN}: ${ADMIN_PASSWORD}"
echo -e "• hello@${DOMAIN}: ${ADMIN_PASSWORD}"
echo -e "• marketing@${DOMAIN}: ${ADMIN_PASSWORD}"
echo -e "• noreply@${DOMAIN}: ${NOREPLY_PASSWORD}"
echo ""
echo -e "${BLUE}📁 Account details saved to: /root/bdg_email_accounts.txt${NC}"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Run: ./setup-admin-forwarding.sh (to enable catch-all forwarding)"
echo "2. Test email forwarding by sending to any address @${DOMAIN}"
echo "3. Check admin inbox for forwarded emails"
echo "4. Configure Roundcube to connect to your mail server"
echo ""
echo -e "${YELLOW}⚠️  Important: ALL emails sent to @${DOMAIN} will be forwarded to ${ADMIN_EMAIL}${NC}"

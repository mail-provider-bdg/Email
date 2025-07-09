#!/bin/bash

# Mail server setup script for bdgsoftware.com
# This script sets up a complete self-hosted mail server

set -e

echo "🚀 Setting up self-hosted mail server for bdgsoftware.com..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"
ADMIN_EMAIL="admin@bdgsoftware.com"

echo -e "${GREEN}Domain: $DOMAIN${NC}"
echo -e "${GREEN}Mail Server: $MAIL_DOMAIN${NC}"
echo -e "${GREEN}Admin Email: $ADMIN_EMAIL${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p docker-data/{dms/{mail-data,mail-state,mail-logs,config},redis,fail2ban,postfixadmin}
mkdir -p certs certbot-webroot

# Set permissions
chmod 755 docker-data
chmod -R 755 docker-data/dms

# Start services
echo -e "${YELLOW}Starting mail server services...${NC}"
docker-compose up -d nginx redis

# Wait for nginx to be ready
echo -e "${YELLOW}Waiting for nginx to be ready...${NC}"
sleep 10

# Get SSL certificates
echo -e "${YELLOW}Getting SSL certificates...${NC}"
docker-compose run --rm certbot

# Start main mail server
echo -e "${YELLOW}Starting main mail server...${NC}"
docker-compose up -d mailserver

# Wait for mail server to be ready
echo -e "${YELLOW}Waiting for mail server to initialize...${NC}"
sleep 30

# Create email accounts
echo -e "${YELLOW}Creating email accounts...${NC}"

# Admin account
docker-compose exec mailserver setup email add $ADMIN_EMAIL
echo -e "${GREEN}Created admin account: $ADMIN_EMAIL${NC}"

# User accounts (examples)
docker-compose exec mailserver setup email add info@$DOMAIN
docker-compose exec mailserver setup email add support@$DOMAIN
docker-compose exec mailserver setup email add noreply@$DOMAIN

echo -e "${GREEN}Created additional accounts:${NC}"
echo -e "  - info@$DOMAIN"
echo -e "  - support@$DOMAIN"
echo -e "  - noreply@$DOMAIN"

# Set up aliases
echo -e "${YELLOW}Setting up email aliases...${NC}"
docker-compose exec mailserver setup alias add postmaster@$DOMAIN $ADMIN_EMAIL
docker-compose exec mailserver setup alias add abuse@$DOMAIN $ADMIN_EMAIL
docker-compose exec mailserver setup alias add hostmaster@$DOMAIN $ADMIN_EMAIL

# Configure DKIM
echo -e "${YELLOW}Generating DKIM keys...${NC}"
docker-compose exec mailserver setup config dkim domain $DOMAIN

# Start remaining services
echo -e "${YELLOW}Starting security services...${NC}"
docker-compose up -d fail2ban postfixadmin

# Show status
echo -e "${GREEN}Mail server setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure DNS records (see DNS-RECORDS.md)"
echo "2. Test email sending and receiving"
echo "3. Update Roundcube configuration"
echo "4. Monitor logs: docker-compose logs -f mailserver"
echo ""
echo -e "${YELLOW}Services running:${NC}"
docker-compose ps

echo ""
echo -e "${YELLOW}DKIM public key (add to DNS):${NC}"
docker-compose exec mailserver cat /tmp/docker-mailserver/opendkim/keys/$DOMAIN/mail.txt

echo ""
echo -e "${RED}IMPORTANT: Don't forget to configure your DNS records!${NC}"

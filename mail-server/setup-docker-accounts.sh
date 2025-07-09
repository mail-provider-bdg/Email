#!/bin/bash

# Docker Mail Server Account Setup Script
set -e

DOMAIN="bdgsoftware.com"
ADMIN_PASSWORD=$(openssl rand -base64 16)
SUPPORT_PASSWORD=$(openssl rand -base64 16)
INFO_PASSWORD=$(openssl rand -base64 16)

echo "📧 Creating initial email accounts for $DOMAIN using Docker..."

# Create main accounts
docker-compose exec mailserver setup email add "admin@$DOMAIN" "$ADMIN_PASSWORD"
docker-compose exec mailserver setup email add "support@$DOMAIN" "$SUPPORT_PASSWORD"
docker-compose exec mailserver setup email add "info@$DOMAIN" "$INFO_PASSWORD"
docker-compose exec mailserver setup email add "noreply@$DOMAIN" "$(openssl rand -base64 16)"

# Create aliases
docker-compose exec mailserver setup alias add "postmaster@$DOMAIN" "admin@$DOMAIN"
docker-compose exec mailserver setup alias add "abuse@$DOMAIN" "admin@$DOMAIN"
docker-compose exec mailserver setup alias add "hostmaster@$DOMAIN" "admin@$DOMAIN"
docker-compose exec mailserver setup alias add "webmaster@$DOMAIN" "admin@$DOMAIN"
docker-compose exec mailserver setup alias add "contact@$DOMAIN" "info@$DOMAIN"
docker-compose exec mailserver setup alias add "hello@$DOMAIN" "info@$DOMAIN"
docker-compose exec mailserver setup alias add "sales@$DOMAIN" "info@$DOMAIN"

# Generate DKIM keys
docker-compose exec mailserver setup config dkim domain "$DOMAIN"

# Save passwords
cat > /root/docker_email_passwords.txt << EOF
Docker Email Account Passwords for $DOMAIN
==========================================

admin@$DOMAIN: $ADMIN_PASSWORD
support@$DOMAIN: $SUPPORT_PASSWORD
info@$DOMAIN: $INFO_PASSWORD

Aliases created:
- postmaster@$DOMAIN -> admin@$DOMAIN
- abuse@$DOMAIN -> admin@$DOMAIN
- hostmaster@$DOMAIN -> admin@$DOMAIN
- webmaster@$DOMAIN -> admin@$DOMAIN
- contact@$DOMAIN -> info@$DOMAIN
- hello@$DOMAIN -> info@$DOMAIN
- sales@$DOMAIN -> info@$DOMAIN

Access your email at:
- IMAP: mail.$DOMAIN:993 (SSL)
- SMTP: mail.$DOMAIN:587 (STARTTLS)

Docker Commands:
- List users: docker-compose exec mailserver setup email list
- Add user: docker-compose exec mailserver setup email add user@$DOMAIN password
- Add alias: docker-compose exec mailserver setup alias add alias@$DOMAIN user@$DOMAIN
- View logs: docker-compose logs mailserver
EOF

chmod 600 /root/docker_email_passwords.txt

echo "✅ Docker accounts created!"
echo "📋 Account details saved to: /root/docker_email_passwords.txt"
echo ""
echo "🔑 Account Summary:"
echo "admin@$DOMAIN: $ADMIN_PASSWORD"
echo "support@$DOMAIN: $SUPPORT_PASSWORD"
echo "info@$DOMAIN: $INFO_PASSWORD"
echo ""
echo "🔐 DKIM Public Key (add to DNS):"
docker-compose exec mailserver cat /tmp/docker-mailserver/opendkim/keys/$DOMAIN/mail.txt

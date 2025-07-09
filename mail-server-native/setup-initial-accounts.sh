#!/bin/bash

# Initial Account Setup Script
set -e

DOMAIN="bdgsoftware.cloud"
ADMIN_PASSWORD=$(openssl rand -base64 16)
SUPPORT_PASSWORD=$(openssl rand -base64 16)
INFO_PASSWORD=$(openssl rand -base64 16)

echo "📧 Creating initial email accounts for $DOMAIN..."

# Create main accounts
./manage-users.sh add "admin@$DOMAIN" "$ADMIN_PASSWORD"
./manage-users.sh add "support@$DOMAIN" "$SUPPORT_PASSWORD"
./manage-users.sh add "info@$DOMAIN" "$INFO_PASSWORD"
./manage-users.sh add "noreply@$DOMAIN" "$(openssl rand -base64 16)"

# Create aliases
./manage-users.sh alias "postmaster@$DOMAIN" "admin@$DOMAIN"
./manage-users.sh alias "abuse@$DOMAIN" "admin@$DOMAIN"
./manage-users.sh alias "hostmaster@$DOMAIN" "admin@$DOMAIN"
./manage-users.sh alias "webmaster@$DOMAIN" "admin@$DOMAIN"
./manage-users.sh alias "contact@$DOMAIN" "info@$DOMAIN"
./manage-users.sh alias "hello@$DOMAIN" "info@$DOMAIN"
./manage-users.sh alias "sales@$DOMAIN" "info@$DOMAIN"

# Save passwords
cat > /root/email_passwords.txt << EOF
Email Account Passwords for $DOMAIN
====================================

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
EOF

chmod 600 /root/email_passwords.txt

echo "✅ Initial accounts created!"
echo "📋 Account details saved to: /root/email_passwords.txt"
echo ""
echo "🔑 Account Summary:"
echo "admin@$DOMAIN: $ADMIN_PASSWORD"
echo "support@$DOMAIN: $SUPPORT_PASSWORD"
echo "info@$DOMAIN: $INFO_PASSWORD"

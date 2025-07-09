#!/bin/bash

# DKIM Configuration Script
set -e

DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"

echo "🔑 Configuring DKIM..."

# Create OpenDKIM directories
mkdir -p /etc/opendkim/keys/$DOMAIN
chown -R opendkim:opendkim /etc/opendkim
chmod -R 700 /etc/opendkim

# Generate DKIM key
opendkim-genkey -t -s mail -d $DOMAIN -D /etc/opendkim/keys/$DOMAIN

# Set proper ownership
chown opendkim:opendkim /etc/opendkim/keys/$DOMAIN/mail.private
chmod 600 /etc/opendkim/keys/$DOMAIN/mail.private

# OpenDKIM main configuration
cat > /etc/opendkim.conf << EOF
# OpenDKIM Configuration

# Basic settings
Syslog yes
SyslogSuccess yes
LogWhy yes
Canonicalization relaxed/simple
Mode sv
SubDomains no
OversignHeaders From

# Domain settings
Domain $DOMAIN
KeyFile /etc/opendkim/keys/$DOMAIN/mail.private
Selector mail

# Network settings
Socket inet:12301@localhost
PidFile /var/run/opendkim/opendkim.pid

# Security settings
UserID opendkim
UMask 007
EOF

# Create systemd override for OpenDKIM
mkdir -p /etc/systemd/system/opendkim.service.d
cat > /etc/systemd/system/opendkim.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/opendkim -f -x /etc/opendkim.conf
EOF

# Reload systemd and restart services
systemctl daemon-reload
systemctl restart opendkim
systemctl enable opendkim
systemctl restart postfix

echo "✅ DKIM configuration completed!"
echo ""
echo "🔧 Add this DKIM record to your DNS:"
echo "Record Type: TXT"
echo "Host: mail._domainkey.$DOMAIN"
echo "Value:"
cat /etc/opendkim/keys/$DOMAIN/mail.txt
echo ""
echo "Note: Remove quotes and combine the key parts into one line for most DNS providers"

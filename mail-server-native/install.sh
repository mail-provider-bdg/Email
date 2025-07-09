#!/bin/bash

# Native Mail Server Installation Script for bdgsoftware.com
# Ubuntu/Debian compatible - No Docker required

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"
ADMIN_EMAIL="admin@bdgsoftware.com"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
ROUNDCUBE_DB_PASSWORD=$(openssl rand -base64 32)
POSTFIX_DB_PASSWORD=$(openssl rand -base64 32)

echo -e "${BLUE}🚀 Installing Native Mail Server for $DOMAIN${NC}"
echo -e "${YELLOW}This will install Postfix, Dovecot, MySQL, and security components${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt update && apt upgrade -y

# Install required packages
echo -e "${YELLOW}📦 Installing mail server packages...${NC}"
export DEBIAN_FRONTEND=noninteractive

# Pre-configure Postfix
echo "postfix postfix/mailname string $MAIL_DOMAIN" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

# Install packages
apt install -y \
    postfix \
    postfix-mysql \
    dovecot-core \
    dovecot-imapd \
    dovecot-lmtpd \
    dovecot-mysql \
    mysql-server \
    spamassassin \
    clamav \
    clamav-daemon \
    opendkim \
    opendkim-tools \
    opendmarc \
    fail2ban \
    ufw \
    certbot \
    nginx \
    redis-server \
    rsyslog \
    mailutils \
    dnsutils \
    curl \
    wget \
    unzip

# Secure MySQL installation
echo -e "${YELLOW}🔒 Securing MySQL installation...${NC}"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Save MySQL root password
echo "MySQL root password: $MYSQL_ROOT_PASSWORD" > /root/mysql_passwords.txt
chmod 600 /root/mysql_passwords.txt

# Create mail database and user
echo -e "${YELLOW}🗄️ Setting up mail database...${NC}"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CREATE DATABASE mailserver;
CREATE USER 'mailuser'@'localhost' IDENTIFIED BY '$POSTFIX_DB_PASSWORD';
GRANT ALL PRIVILEGES ON mailserver.* TO 'mailuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create database tables
mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver << 'EOF'
CREATE TABLE domains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain VARCHAR(255) NOT NULL UNIQUE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    quota BIGINT DEFAULT 1073741824,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE
);

CREATE TABLE aliases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT,
    source VARCHAR(255) NOT NULL,
    destination TEXT NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE
);
EOF

# Insert default domain
mysql -u root -p"$MYSQL_ROOT_PASSWORD" mailserver << EOF
INSERT INTO domains (domain) VALUES ('$DOMAIN');
EOF

echo "Postfix database password: $POSTFIX_DB_PASSWORD" >> /root/mysql_passwords.txt

# Create mail user
echo -e "${YELLOW}👤 Creating mail system user...${NC}"
useradd -r -u 5000 -g mail -d /var/mail -s /sbin/nologin -c "Virtual Mail User" vmail
mkdir -p /var/mail
chown vmail:mail /var/mail
chmod 770 /var/mail

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 993/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Get SSL certificates
echo -e "${YELLOW}🔐 Obtaining SSL certificates...${NC}"
certbot certonly --standalone --non-interactive --agree-tos --email $ADMIN_EMAIL -d $MAIL_DOMAIN

# Configure Postfix
echo -e "${YELLOW}📬 Configuring Postfix...${NC}"
cp /etc/postfix/main.cf /etc/postfix/main.cf.backup

cat > /etc/postfix/main.cf << EOF
# Basic Configuration
myhostname = $MAIL_DOMAIN
mydomain = $DOMAIN
myorigin = \$mydomain
inet_interfaces = all
inet_protocols = ipv4
mydestination = localhost

# Network and Security
smtpd_banner = \$myhostname ESMTP
disable_vrfy_command = yes
smtpd_helo_required = yes
smtpd_helo_restrictions = permit_mynetworks, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname
smtpd_sender_restrictions = permit_mynetworks, reject_non_fqdn_sender, reject_unknown_sender_domain

# Virtual domains and users
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf
virtual_mailbox_base = /var/mail
virtual_uid_maps = static:5000
virtual_gid_maps = static:8
virtual_minimum_uid = 100
virtual_mailbox_limit = 1073741824

# SSL/TLS Configuration
smtpd_tls_cert_file = /etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem
smtpd_use_tls = yes
smtpd_tls_security_level = may
smtpd_tls_protocols = !SSLv2, !SSLv3
smtp_tls_protocols = !SSLv2, !SSLv3
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3

# SASL Authentication
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = \$myhostname
broken_sasl_auth_clients = yes

# Recipient restrictions
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_rbl_client zen.spamhaus.org, reject_rbl_client bl.spamcop.net

# Message size limit
message_size_limit = 52428800

# Local delivery via Dovecot
virtual_transport = lmtp:unix:private/dovecot-lmtp

# Milters for DKIM
milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301
EOF

# Create Postfix MySQL configuration files
echo -e "${YELLOW}⚙️ Creating Postfix MySQL configuration...${NC}"

cat > /etc/postfix/mysql-virtual-mailbox-domains.cf << EOF
user = mailuser
password = $POSTFIX_DB_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT 1 FROM domains WHERE domain='%s' AND active=1
EOF

cat > /etc/postfix/mysql-virtual-mailbox-maps.cf << EOF
user = mailuser
password = $POSTFIX_DB_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT 1 FROM users WHERE email='%s' AND active=1
EOF

cat > /etc/postfix/mysql-virtual-alias-maps.cf << EOF
user = mailuser
password = $POSTFIX_DB_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT destination FROM aliases WHERE source='%s' AND active=1
EOF

# Set proper permissions
chmod 640 /etc/postfix/mysql-*.cf
chown root:postfix /etc/postfix/mysql-*.cf

# Configure master.cf for submission
echo -e "${YELLOW}📮 Configuring Postfix submission...${NC}"
cat >> /etc/postfix/master.cf << 'EOF'

# Submission port (587)
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
EOF

echo -e "${GREEN}✅ Mail server installation completed!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Configure Dovecot (run ./configure-dovecot.sh)"
echo "2. Set up DKIM (run ./configure-dkim.sh)"
echo "3. Configure SpamAssassin and ClamAV"
echo "4. Create email accounts"
echo "5. Test the setup"
echo ""
echo -e "${BLUE}🔑 Passwords saved to: /root/mysql_passwords.txt${NC}"

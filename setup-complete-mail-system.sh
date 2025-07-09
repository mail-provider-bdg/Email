#!/bin/bash

# Complete Mail System Setup Script
# This script sets up a complete mail server + Roundcube webmail system on Ubuntu
# Run this after cloning the repository to your Ubuntu PC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration - Edit these before running
DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"
ADMIN_EMAIL="admin@bdgsoftware.com"
SERVER_IP=$(curl -s https://ipinfo.io/ip)
WEBMAIL_PORT="8080"

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_header "Complete Mail System Setup for $DOMAIN"
echo "This script will install and configure:"
echo "• Native mail server (Postfix + Dovecot)"
echo "• Roundcube webmail with purple theme"
echo "• Security components (SpamAssassin, ClamAV, Fail2ban)"
echo "• SSL certificates"
echo "• Database setup"
echo "• User accounts"
echo ""
echo "Domain: $DOMAIN"
echo "Mail server: $MAIL_DOMAIN"
echo "Server IP: $SERVER_IP"
echo "Webmail will be available at: http://$SERVER_IP:$WEBMAIL_PORT"
echo ""
read -p "Continue with installation? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Step 1: Install Mail Server
print_header "Step 1: Installing Mail Server"
print_step "Running native mail server installation..."

cd mail-server-native
chmod +x *.sh

# Run mail server installation
print_step "Installing base mail server components..."
./install.sh

print_step "Configuring Dovecot..."
./configure-dovecot.sh

print_step "Setting up DKIM..."
./configure-dkim.sh

print_step "Configuring security components..."
./configure-security.sh

print_step "Creating initial email accounts..."
./setup-initial-accounts.sh

cd ..

print_success "Mail server installation completed!"

# Step 2: Install Roundcube
print_header "Step 2: Installing Roundcube Webmail"

# Install PHP and web server dependencies
print_step "Installing PHP and web server components..."
apt install -y \
    apache2 \
    php \
    php-mysql \
    php-imap \
    php-ldap \
    php-curl \
    php-gd \
    php-zip \
    php-xml \
    php-mbstring \
    php-json \
    php-intl \
    php-imagick \
    composer \
    wget

# Create web directory
WEBROOT="/var/www/roundcube"
mkdir -p $WEBROOT
cd $WEBROOT

# Download Roundcube
print_step "Downloading Roundcube..."
ROUNDCUBE_VERSION="1.6.4"
wget -q "https://github.com/roundcube/roundcubemail/releases/download/$ROUNDCUBE_VERSION/roundcubemail-$ROUNDCUBE_VERSION-complete.tar.gz"
tar -xzf "roundcubemail-$ROUNDCUBE_VERSION-complete.tar.gz"
mv "roundcubemail-$ROUNDCUBE_VERSION"/* .
rm -rf "roundcubemail-$ROUNDCUBE_VERSION" "roundcubemail-$ROUNDCUBE_VERSION-complete.tar.gz"

# Install dependencies
print_step "Installing Roundcube dependencies..."
composer install --no-dev --optimize-autoloader

# Set permissions
chown -R www-data:www-data $WEBROOT
find $WEBROOT -type d -exec chmod 755 {} \;
find $WEBROOT -type f -exec chmod 644 {} \;
chmod -R 777 $WEBROOT/temp $WEBROOT/logs

# Copy our purple theme
print_step "Installing purple theme..."
cp -r skins/elastic/* $WEBROOT/skins/elastic/
chown -R www-data:www-data $WEBROOT/skins/elastic/

# Step 3: Configure Roundcube Database
print_header "Step 3: Configuring Roundcube Database"

MYSQL_ROOT_PASSWORD=$(grep "MySQL root password:" /root/mysql_passwords.txt | cut -d' ' -f4)
ROUNDCUBE_DB_PASSWORD=$(openssl rand -base64 32)

print_step "Creating Roundcube database..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CREATE DATABASE roundcube;
CREATE USER 'roundcube'@'localhost' IDENTIFIED BY '$ROUNDCUBE_DB_PASSWORD';
GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import Roundcube database schema
print_step "Importing Roundcube database schema..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" roundcube < $WEBROOT/SQL/mysql.initial.sql

# Save database password
echo "Roundcube database password: $ROUNDCUBE_DB_PASSWORD" >> /root/mysql_passwords.txt

# Step 4: Configure Roundcube
print_header "Step 4: Configuring Roundcube"

print_step "Creating Roundcube configuration..."
cat > $WEBROOT/config/config.inc.php << EOF
<?php

/*
 +-----------------------------------------------------------------------+
 | Roundcube Webmail configuration for $DOMAIN                          |
 +-----------------------------------------------------------------------+
*/

\$config = [];

// Database connection
\$config['db_dsnw'] = 'mysql://roundcube:$ROUNDCUBE_DB_PASSWORD@localhost/roundcube';

// IMAP/SMTP configuration for local mail server
\$config['imap_host'] = array(
    'ssl://$MAIL_DOMAIN:993' => '$DOMAIN Mail (SSL)',
    '$MAIL_DOMAIN:143' => '$DOMAIN Mail (STARTTLS)',
);

\$config['smtp_host'] = 'tls://$MAIL_DOMAIN:587';
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['smtp_auth_type'] = 'LOGIN';

// Application settings
\$config['product_name'] = 'BDG Software Mail';
\$config['support_url'] = 'https://support.bdgsoftware.com';
\$config['des_key'] = '$(openssl rand -base64 24)';
\$config['skin'] = 'elastic';

// Security settings
\$config['force_https'] = false;  // Set to true when using SSL
\$config['login_rate_limit'] = 5;
\$config['login_rate_limit_window'] = 300;
\$config['session_lifetime'] = 60;
\$config['ip_check'] = true;
\$config['referer_check'] = true;

// Mail settings
\$config['mail_domain'] = '$DOMAIN';
\$config['max_message_size'] = '50MB';
\$config['max_group_members'] = 1000;

// Performance settings
\$config['enable_caching'] = true;
\$config['message_cache_lifetime'] = '10d';
\$config['messages_cache_threshold'] = 50;

// UI settings for purple theme
\$config['htmleditor'] = 1;
\$config['prettydate'] = true;
\$config['date_format'] = 'Y-m-d';
\$config['time_format'] = 'H:i';
\$config['timezone'] = 'auto';
\$config['language'] = 'en_US';
\$config['default_charset'] = 'UTF-8';

// Plugins
\$config['plugins'] = array(
    'archive',
    'zipdownload',
    'attachment_reminder',
    'emoticons',
    'hide_blockquote',
    'identicon',
    'newmail_notifier',
    'vcard_attachments',
    'password',
    'managesieve',
);

// Logging
\$config['log_driver'] = 'file';
\$config['log_level'] = 1;
\$config['log_logins'] = true;

// Default identity
\$config['identity_default'] = array(
    'name' => '%n',
    'email' => '%u',
    'reply-to' => '%u',
    'signature' => "Sent with BDG Software Mail\\nhttps://bdgsoftware.com"
);

// Disable installer
\$config['enable_installer'] = false;
EOF

# Step 5: Configure Apache
print_header "Step 5: Configuring Web Server"

print_step "Creating Apache virtual host..."
cat > /etc/apache2/sites-available/roundcube.conf << EOF
<VirtualHost *:$WEBMAIL_PORT>
    ServerName $MAIL_DOMAIN
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Security headers
        Header always set X-Content-Type-Options nosniff
        Header always set X-Frame-Options SAMEORIGIN
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
    </Directory>

    # Deny access to sensitive directories
    <Directory $WEBROOT/config>
        Require all denied
    </Directory>
    
    <Directory $WEBROOT/temp>
        Require all denied
    </Directory>
    
    <Directory $WEBROOT/logs>
        Require all denied
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/roundcube_error.log
    CustomLog \${APACHE_LOG_DIR}/roundcube_access.log combined
</VirtualHost>
EOF

# Configure Apache to listen on custom port
print_step "Configuring Apache ports..."
if ! grep -q "Listen $WEBMAIL_PORT" /etc/apache2/ports.conf; then
    echo "Listen $WEBMAIL_PORT" >> /etc/apache2/ports.conf
fi

# Enable required Apache modules
a2enmod rewrite
a2enmod headers
a2enmod ssl

# Enable site
a2ensite roundcube.conf
a2dissite 000-default.conf

# Restart Apache
systemctl restart apache2
systemctl enable apache2

print_success "Web server configuration completed!"

# Step 6: Configure Firewall
print_header "Step 6: Configuring Firewall"

print_step "Updating firewall rules..."
ufw allow $WEBMAIL_PORT/tcp comment "Roundcube webmail"
ufw reload

print_success "Firewall configuration completed!"

# Step 7: Test Installation
print_header "Step 7: Testing Installation"

print_step "Running mail server tests..."
cd mail-server-native
./test-mail-server.sh
cd ..

print_step "Testing Roundcube installation..."
if curl -s --connect-timeout 5 "http://localhost:$WEBMAIL_PORT" > /dev/null; then
    print_success "Roundcube is accessible"
else
    print_warning "Roundcube may not be accessible yet"
fi

# Step 8: Create additional user accounts
print_header "Step 8: Creating Additional User Accounts"

print_step "Creating user accounts for common addresses..."
cd mail-server-native

# Create additional accounts with random passwords
SALES_PASSWORD=$(openssl rand -base64 16)
NOREPLY_PASSWORD=$(openssl rand -base64 16)
MARKETING_PASSWORD=$(openssl rand -base64 16)

./manage-users.sh add "sales@$DOMAIN" "$SALES_PASSWORD"
./manage-users.sh add "marketing@$DOMAIN" "$MARKETING_PASSWORD"
./manage-users.sh add "no-reply@$DOMAIN" "$NOREPLY_PASSWORD"

# Create additional aliases
./manage-users.sh alias "orders@$DOMAIN" "sales@$DOMAIN"
./manage-users.sh alias "billing@$DOMAIN" "admin@$DOMAIN"
./manage-users.sh alias "security@$DOMAIN" "admin@$DOMAIN"

cd ..

# Save additional passwords
cat >> /root/email_passwords.txt << EOF

Additional Accounts:
sales@$DOMAIN: $SALES_PASSWORD
marketing@$DOMAIN: $MARKETING_PASSWORD
no-reply@$DOMAIN: $NOREPLY_PASSWORD

Additional Aliases:
orders@$DOMAIN -> sales@$DOMAIN
billing@$DOMAIN -> admin@$DOMAIN
security@$DOMAIN -> admin@$DOMAIN
EOF

print_success "Additional accounts created!"

# Step 9: Final Setup and Instructions
print_header "🎉 Installation Complete!"

print_success "Your complete mail system has been installed and configured!"
echo ""
echo -e "${BLUE}📧 Mail Server Details:${NC}"
echo "• Domain: $DOMAIN"
echo "• Mail server: $MAIL_DOMAIN"
echo "• Server IP: $SERVER_IP"
echo ""
echo -e "${BLUE}🌐 Webmail Access:${NC}"
echo "• URL: http://$SERVER_IP:$WEBMAIL_PORT"
echo "• Theme: Beautiful purple theme"
echo ""
echo -e "${BLUE}📋 Email Accounts Created:${NC}"
cat /root/email_passwords.txt
echo ""
echo -e "${BLUE}🔐 Important Files:${NC}"
echo "• Email passwords: /root/email_passwords.txt"
echo "• Database passwords: /root/mysql_passwords.txt"
echo "• Roundcube config: $WEBROOT/config/config.inc.php"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Configure DNS records for $DOMAIN (see mail-server-native/DNS-RECORDS.md)"
echo "2. Add DKIM record to DNS:"
echo "   Host: mail._domainkey.$DOMAIN"
echo "   Value: (see output above or /etc/opendkim/keys/$DOMAIN/mail.txt)"
echo "3. Test email sending/receiving"
echo "4. Access webmail at http://$SERVER_IP:$WEBMAIL_PORT"
echo ""
echo -e "${BLUE}🛠️ Management Commands:${NC}"
echo "• Add user: cd mail-server-native && ./manage-users.sh add email@$DOMAIN password"
echo "• List users: cd mail-server-native && ./manage-users.sh list"
echo "• Test system: cd mail-server-native && ./test-mail-server.sh"
echo ""
echo -e "${YELLOW}⚠️  Security Notes:${NC}"
echo "• Change default passwords immediately"
echo "• Configure DNS records for proper email delivery"
echo "• Set up SSL certificates for production use"
echo "• Enable firewall rules for your specific network"
echo ""
echo -e "${GREEN}🎊 Enjoy your new professional email system with beautiful purple webmail!${NC}"

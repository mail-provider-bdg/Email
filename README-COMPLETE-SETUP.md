# Complete Mail System Setup Guide

This repository contains a complete email system with a beautiful purple-themed webmail interface.

## 🚀 Quick Start

Run this single command to set up everything:

```bash
sudo ./setup-complete-mail-system.sh
```

This will automatically install and configure:
- ✅ Native mail server (Postfix + Dovecot)
- ✅ Roundcube webmail with purple theme
- ✅ Security components (SpamAssassin, ClamAV, Fail2ban)
- ✅ SSL certificates
- ✅ Database setup
- ✅ User accounts and aliases

## 📋 Prerequisites

- **Ubuntu 20.04/22.04** or **Debian 11/12**
- **Root access** (run with `sudo`)
- **2GB RAM** minimum, 4GB recommended
- **20GB disk space** minimum
- **Static IP address** (for mail server)
- **Domain name** (configured in the script)

## 🔧 Configuration

Before running the setup script, edit these variables in `setup-complete-mail-system.sh`:

```bash
DOMAIN="bdgsoftware.com"           # Your domain
MAIL_DOMAIN="mail.bdgsoftware.com" # Your mail server hostname
ADMIN_EMAIL="admin@bdgsoftware.com" # Admin email address
WEBMAIL_PORT="8080"                # Port for webmail access
```

## 🌐 What Gets Installed

### Mail Server Components
- **Postfix** - SMTP server for sending emails
- **Dovecot** - IMAP server for receiving emails
- **MySQL** - Database for virtual users and domains
- **OpenDKIM** - DKIM email authentication
- **SpamAssassin** - Anti-spam filtering
- **ClamAV** - Antivirus scanning
- **Fail2ban** - Intrusion prevention
- **Let's Encrypt** - SSL certificates

### Webmail Interface
- **Roundcube** - Modern webmail client
- **Purple Theme** - Beautiful custom purple and black theme
- **Apache** - Web server for webmail
- **PHP** - Server-side scripting
- **Multiple logos** - Professional branding

## 📧 Default Email Accounts

The script creates these accounts automatically:

| Email Address | Purpose |
|---------------|---------|
| admin@bdgsoftware.com | Main administrator |
| support@bdgsoftware.com | Customer support |
| info@bdgsoftware.com | General inquiries |
| sales@bdgsoftware.com | Sales inquiries |
| marketing@bdgsoftware.com | Marketing campaigns |
| noreply@bdgsoftware.com | Automated emails |

### Email Aliases
- `postmaster@` → `admin@`
- `abuse@` → `admin@`
- `hostmaster@` → `admin@`
- `webmaster@` → `admin@`
- `contact@` → `info@`
- `hello@` → `info@`
- `orders@` → `sales@`
- `billing@` → `admin@`
- `security@` → `admin@`

## 🌍 DNS Configuration

After installation, configure these DNS records:

### Required Records
```dns
# A Records
A    mail.bdgsoftware.com    YOUR_SERVER_IP

# MX Record
MX   @   10   mail.bdgsoftware.com

# SPF Record
TXT  @   "v=spf1 mx a:mail.bdgsoftware.com ~all"

# DKIM Record (get from installation output)
TXT  mail._domainkey   "v=DKIM1; h=sha256; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"

# DMARC Record
TXT  _dmarc   "v=DMARC1; p=quarantine; rua=mailto:dmarc@bdgsoftware.com"
```

## 🎨 Features

### Purple Theme
- Modern purple and black color scheme
- Gradient backgrounds and shadows
- Custom logo designs
- Responsive design for all devices
- Enhanced user experience

### Security Features
- SSL/TLS encryption
- DKIM, SPF, DMARC authentication
- Fail2ban intrusion prevention
- Firewall configuration
- Antivirus and anti-spam protection

### Management Features
- Web-based email access
- User management scripts
- Automated backups
- Health monitoring
- Comprehensive logging

## 🛠️ Management Commands

### User Management
```bash
# Navigate to management directory
cd mail-server-native

# Add new user
./manage-users.sh add john@bdgsoftware.com password123

# Change password
./manage-users.sh password john@bdgsoftware.com newpassword

# Create alias
./manage-users.sh alias contact@bdgsoftware.com john@bdgsoftware.com

# List all users
./manage-users.sh list

# List all aliases
./manage-users.sh aliases
```

### System Management
```bash
# Test mail server
./test-mail-server.sh

# Check service status
systemctl status postfix dovecot apache2

# Check mail queue
postqueue -p

# View logs
tail -f /var/log/mail.log
```

## 🔐 Security

### Default Security Measures
- Firewall configured with UFW
- Fail2ban protecting against brute force
- SSL/TLS encryption for all connections
- Strong password requirements
- Regular security updates

### Important Security Notes
1. **Change default passwords** immediately after setup
2. **Configure DNS records** for proper email delivery
3. **Set up SSL certificates** for production use
4. **Enable automatic updates** for security patches
5. **Monitor logs** for suspicious activity

## 🔧 Customization

### Modify Theme Colors
Edit these files to customize the purple theme:
- `skins/elastic/styles/colors.less`
- `skins/elastic/styles/_variables.less`
- `skins/elastic/styles/_styles.less`

### Add More Plugins
Edit `/var/www/roundcube/config/config.inc.php`:
```php
$config['plugins'] = array(
    'archive',
    'zipdownload',
    'attachment_reminder',
    // Add more plugins here
);
```

### Create More Email Accounts
```bash
cd mail-server-native
./manage-users.sh add newuser@bdgsoftware.com password123
```

## 📊 Monitoring

### Health Checks
- Service status monitoring
- Disk space monitoring
- Mail queue monitoring
- Log analysis
- Security event monitoring

### Log Files
- **Mail logs**: `/var/log/mail.log`
- **Roundcube logs**: `/var/www/roundcube/logs/`
- **Apache logs**: `/var/log/apache2/`
- **Security logs**: `/var/log/fail2ban.log`

## 🆘 Troubleshooting

### Common Issues

1. **Emails not delivered**:
   - Check DNS records
   - Verify SPF/DKIM/DMARC
   - Check mail queue: `postqueue -p`

2. **Cannot login to webmail**:
   - Verify user account exists
   - Check Roundcube logs
   - Test IMAP connection

3. **SSL certificate errors**:
   - Renew certificates: `certbot renew`
   - Check certificate expiry
   - Restart services

### Getting Help
- Check log files for error messages
- Run test script: `./test-mail-server.sh`
- Verify DNS configuration
- Check firewall settings

## 📝 Maintenance

### Regular Tasks
- **Daily**: Monitor logs and queue
- **Weekly**: Check disk space and updates
- **Monthly**: Review security logs
- **Quarterly**: Update passwords and certificates

### Backup Strategy
```bash
# Backup script (run daily)
tar -czf /backup/mail-$(date +%Y%m%d).tar.gz /var/mail/
mysqldump mailserver > /backup/mailserver-$(date +%Y%m%d).sql
```

## 🎉 Success!

After running the setup script, you'll have:
- ✅ Professional email system for @bdgsoftware.com
- ✅ Beautiful purple webmail interface
- ✅ Enterprise-grade security
- ✅ Complete user management
- ✅ Monitoring and logging

Access your webmail at: `http://YOUR_SERVER_IP:8080`

Enjoy your new professional email system! 🚀

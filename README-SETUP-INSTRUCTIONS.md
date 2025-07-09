# Complete Mail System Setup Instructions

This repository contains a fully customized Roundcube webmail system with a beautiful purple theme and complete mail server setup scripts.

## 🚀 Quick Setup (One Command)

After cloning this repository to your Ubuntu server, run:

```bash
sudo ./setup-complete-mail-system.sh
```

This single command will:
- ✅ Set up your complete mail server (Native or Docker)
- ✅ Install your custom purple-themed Roundcube webmail
- ✅ Configure all security components
- ✅ Create email accounts for your domain
- ✅ Set up SSL certificates
- ✅ Configure firewall and security

## 📋 What's Included in This Repository

### Custom Roundcube with Purple Theme
- **Complete Roundcube installation** with all your modifications
- **Purple theme** with gradient backgrounds and modern design
- **Custom logos** and branding
- **Enhanced UI components** with your styling
- **All plugins** and configurations

### Mail Server Options
Choose between two installation methods:

#### 1. Native Installation (Production)
- Direct installation on Ubuntu/Debian
- Better performance, full system control
- Located in `mail-server-native/`

#### 2. Docker Installation (Development)
- Containerized with Docker Compose
- Easy management and isolation
- Located in `mail-server/`

### Setup and Management Scripts
- **`setup-complete-mail-system.sh`** - Main setup script
- **User management scripts** for both Native and Docker
- **Testing and monitoring tools**
- **Backup and maintenance scripts**

## 🔧 Before You Start

### Prerequisites
- **Ubuntu 20.04/22.04** or **Debian 11/12**
- **Root access** (run with `sudo`)
- **2GB RAM** minimum, 4GB recommended
- **20GB disk space** minimum
- **Static IP address** for mail server
- **Domain name** you own

### Configuration
Edit these variables in `setup-complete-mail-system.sh` before running:

```bash
DOMAIN="bdgsoftware.com"           # Your domain
MAIL_DOMAIN="mail.bdgsoftware.com" # Your mail server hostname  
ADMIN_EMAIL="admin@bdgsoftware.com" # Admin email address
WEBMAIL_PORT="8080"                # Port for webmail access
```

## 📊 Installation Methods

### Native Installation (Recommended for Production)
```bash
sudo ./setup-complete-mail-system.sh
# Choose option 1 when prompted
```

**Advantages:**
- Better performance
- Full system control
- Lower resource usage
- Direct system integration

### Docker Installation (Recommended for Development)
```bash
sudo ./setup-complete-mail-system.sh
# Choose option 2 when prompted
```

**Advantages:**
- Easy management
- Service isolation
- Consistent environment
- Quick updates

## 🎨 Your Custom Features

This repository includes all your customizations:

### Purple Theme Features
- **Modern color scheme** - Purple gradients with black backgrounds
- **Enhanced UI components** - Buttons, forms, lists with your styling
- **Custom logos** - Multiple logo variants (standard, dark, small)
- **Responsive design** - Works perfectly on all devices
- **Professional branding** - "BDG Software Mail" with custom messaging

### Webmail Enhancements
- **Improved user experience** with smooth animations
- **Better readability** with high contrast text
- **Modern interface** with rounded corners and shadows
- **Enhanced functionality** with additional plugins

## 📧 What You Get After Setup

### Email Accounts Created
- `admin@yourdomain.com` - Main administrator
- `support@yourdomain.com` - Customer support
- `info@yourdomain.com` - General inquiries
- `sales@yourdomain.com` - Sales team
- `marketing@yourdomain.com` - Marketing campaigns
- `noreply@yourdomain.com` - Automated emails

### Email Aliases
- `postmaster@` → `admin@`
- `abuse@` → `admin@`
- `contact@` → `info@`
- `hello@` → `info@`
- `orders@` → `sales@`
- And more professional aliases

### Security Features
- **SSL/TLS encryption** for all connections
- **DKIM, SPF, DMARC** email authentication
- **Anti-spam protection** with SpamAssassin
- **Antivirus scanning** with ClamAV
- **Intrusion prevention** with Fail2ban
- **Firewall configuration** with UFW

## 🛠️ Management After Setup

### Native Installation Management
```bash
cd mail-server-native

# User management
./manage-users.sh add john@yourdomain.com password123
./manage-users.sh list
./manage-users.sh password john@yourdomain.com newpassword

# System management  
./test-mail-server.sh
systemctl status postfix dovecot
tail -f /var/log/mail.log
```

### Docker Installation Management
```bash
cd mail-server

# User management
./docker-mail-management.sh add john@yourdomain.com password123
./docker-mail-management.sh list
./docker-mail-management.sh password john@yourdomain.com newpassword

# System management
./docker-mail-management.sh status
./docker-mail-management.sh logs
./docker-mail-management.sh restart
```

## 🌐 DNS Configuration

After setup, configure these DNS records with your domain registrar:

```dns
# A Record
A    mail.yourdomain.com    YOUR_SERVER_IP

# MX Record  
MX   @   10   mail.yourdomain.com

# SPF Record
TXT  @   "v=spf1 mx a:mail.yourdomain.com ~all"

# DKIM Record (get from setup output)
TXT  mail._domainkey   "v=DKIM1; h=sha256; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"

# DMARC Record
TXT  _dmarc   "v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com"
```

## 🔐 Security Notes

- **Change default passwords** immediately after setup
- **Configure DNS records** for proper email delivery
- **Monitor logs** regularly for security events
- **Keep system updated** with security patches
- **Use strong passwords** for all accounts

## 🆘 Troubleshooting

### Common Issues
1. **DNS not configured** - Set up MX, A, and TXT records
2. **Ports blocked** - Check firewall and hosting provider
3. **SSL certificate issues** - Verify domain points to server
4. **Email delivery problems** - Check SPF/DKIM/DMARC records

### Getting Help
- Check setup script output for errors
- Review log files in `/var/log/`
- Run test scripts to verify configuration
- Check DNS propagation with online tools

## 🎉 Success!

After running the setup script, you'll have:
- ✅ Professional email system for your domain
- ✅ Your custom purple-themed webmail interface
- ✅ Enterprise-grade security and anti-spam
- ✅ Complete user management tools
- ✅ Monitoring and maintenance scripts

Access your beautiful webmail at: `http://YOUR_SERVER_IP:8080`

Enjoy your professional email system with your custom purple theme! 🚀💜

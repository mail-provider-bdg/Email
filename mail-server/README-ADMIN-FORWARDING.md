# Admin Email Forwarding Setup for BDG Software Mail Server

This documentation explains how to set up and use the admin email forwarding system for your BDG Software mail server. This system ensures that ALL emails sent to ANY address on your domain are automatically forwarded to the admin email address.

## 🎯 What This System Does

- **Catch-all forwarding**: ALL emails sent to `@bdgsoftware.com` go to `admin@bdgsoftware.com`
- **Account creation**: Easy creation of email accounts with automatic forwarding
- **Centralized management**: Admin receives all emails for monitoring and management
- **Roundcube integration**: Web interface with forwarding awareness

## 📋 Prerequisites

- Docker and Docker Compose installed
- Mail server running (see main setup documentation)
- Admin email account created

## 🚀 Quick Start

### 1. Set up Admin Forwarding

```bash
cd mail-server
./setup-admin-forwarding.sh
```

This script:
- Creates virtual alias configuration for catch-all forwarding
- Sets up Postfix configuration
- Creates management scripts
- Applies configuration to running mail server

### 2. Create Email Accounts with Forwarding

```bash
./setup-email-accounts-with-forwarding.sh
```

This script:
- Creates admin account
- Creates business email accounts (support, sales, info, etc.)
- Sets up forwarding for all accounts
- Saves passwords securely

### 3. Configure Roundcube

```bash
./configure-roundcube-forwarding.sh
```

This script:
- Configures Roundcube for your mail server
- Creates admin forwarding awareness plugin
- Updates web interface with forwarding notices

### 4. Verify Setup

```bash
./verify-forwarding-setup.sh
```

This script checks:
- Mail server status
- Forwarding configuration
- Account existence
- Connectivity

## 🛠️ Management Commands

### Forwarding Management

```bash
# Enable catch-all forwarding (ALL emails to admin)
./manage-forwarding.sh enable-catchall

# Disable catch-all forwarding
./manage-forwarding.sh disable-catchall

# List all forwarding rules
./manage-forwarding.sh list-forwards

# Add specific forwarding rule
./manage-forwarding.sh add-forward sales@bdgsoftware.com admin@bdgsoftware.com

# Remove forwarding rule
./manage-forwarding.sh remove-forward sales@bdgsoftware.com

# Create user with auto-forwarding
./manage-forwarding.sh create-user john@bdgsoftware.com password123

# Reload postfix configuration
./manage-forwarding.sh reload
```

### Email Account Management

```bash
# Create user with existing script
./docker-mail-management.sh add user@bdgsoftware.com password123

# List all users
./docker-mail-management.sh list

# Check mail server status
./docker-mail-management.sh status

# View logs
./docker-mail-management.sh logs
```

## 📧 How Email Forwarding Works

### Catch-all Forwarding
When enabled, the system uses Postfix virtual aliases to forward ALL emails:

```
@bdgsoftware.com → admin@bdgsoftware.com
```

This means:
- `anything@bdgsoftware.com` → `admin@bdgsoftware.com`
- `sales@bdgsoftware.com` → `admin@bdgsoftware.com`
- `randomname@bdgsoftware.com` → `admin@bdgsoftware.com`

### Account-specific Forwarding
Each created account also has individual forwarding rules:

```
support@bdgsoftware.com → admin@bdgsoftware.com
sales@bdgsoftware.com → admin@bdgsoftware.com
info@bdgsoftware.com → admin@bdgsoftware.com
```

### Email Flow
1. External user sends email to `support@bdgsoftware.com`
2. Postfix receives the email
3. Virtual alias map forwards it to `admin@bdgsoftware.com`
4. Admin receives the email in their inbox
5. Admin can respond from the admin account

## 🔧 Configuration Files

### Virtual Alias Map
**Location**: `./docker-data/dms/config/postfix-virtual.cf`

```
# Catch-all forwarding
@bdgsoftware.com admin@bdgsoftware.com

# Specific forwards
postmaster@bdgsoftware.com admin@bdgsoftware.com
abuse@bdgsoftware.com admin@bdgsoftware.com
support@bdgsoftware.com admin@bdgsoftware.com
sales@bdgsoftware.com admin@bdgsoftware.com
```

### Postfix Configuration
**Location**: `./docker-data/dms/config/postfix-main.cf`

```
virtual_alias_domains = bdgsoftware.com
virtual_alias_maps = hash:/tmp/docker-mailserver/postfix-virtual.cf
recipient_delimiter = +
```

### Roundcube Configuration
**Location**: `../config/config.inc.php`

Contains mail server settings and admin forwarding plugin configuration.

## 🌐 Roundcube Web Interface

### Admin Account Features
- Shows "Admin Account" status on login
- Displays forwarding notices
- Settings page with forwarding information
- Email composition reminders

### Regular Account Features
- Shows forwarding notices
- Indicates emails are copied to admin
- Standard email functionality

## 📊 Monitoring and Logs

### Check Forwarding Status
```bash
./manage-forwarding.sh list-forwards
```

### View Mail Server Logs
```bash
docker-compose logs mailserver
```

### Check Postfix Queue
```bash
docker-compose exec mailserver postqueue -p
```

### Monitor Failed Deliveries
```bash
docker-compose exec mailserver tail -f /var/log/mail/mail.err
```

## 🔒 Security Considerations

### Admin Account Security
- Use strong password for admin account
- Enable two-factor authentication if available
- Regularly monitor forwarded emails
- Keep admin account credentials secure

### Email Privacy
- Admin receives ALL emails (consider privacy implications)
- Inform users about forwarding policy
- Implement email retention policies
- Consider encryption for sensitive communications

## 🚨 Troubleshooting

### Common Issues

#### 1. Forwarding Not Working
**Problem**: Emails not being forwarded to admin

**Solutions**:
```bash
# Check if catch-all is enabled
./manage-forwarding.sh list-forwards

# Verify mail server is running
docker-compose ps

# Check postfix logs
docker-compose logs mailserver | grep postfix

# Reload configuration
./manage-forwarding.sh reload
```

#### 2. Admin Account Not Receiving Emails
**Problem**: Admin account exists but no emails received

**Solutions**:
```bash
# Verify admin account exists
docker-compose exec mailserver setup email list

# Check virtual alias configuration
cat ./docker-data/dms/config/postfix-virtual.cf

# Test email connectivity
./verify-forwarding-setup.sh
```

#### 3. New Users Not Getting Forwarding
**Problem**: Newly created users don't forward to admin

**Solutions**:
```bash
# Use the forwarding-enabled user creation
./manage-forwarding.sh create-user newuser@bdgsoftware.com password123

# Or add forwarding for existing user
./manage-forwarding.sh add-forward newuser@bdgsoftware.com admin@bdgsoftware.com
```

#### 4. Postfix Configuration Issues
**Problem**: Postfix not processing virtual aliases

**Solutions**:
```bash
# Check postfix configuration
docker-compose exec mailserver postconf virtual_alias_maps

# Regenerate hash database
docker-compose exec mailserver postmap /tmp/docker-mailserver/postfix-virtual.cf

# Restart mail server
docker-compose restart mailserver
```

### Log Analysis

#### Successful Forwarding
Look for logs like:
```
postfix/virtual: user@bdgsoftware.com -> admin@bdgsoftware.com
```

#### Failed Forwarding
Look for errors like:
```
postfix/virtual: warning: virtual_alias_maps lookup failure
```

## 🔄 Maintenance

### Regular Tasks

#### Weekly
- Check forwarding rules: `./manage-forwarding.sh list-forwards`
- Review mail server logs: `docker-compose logs mailserver`
- Verify admin account accessibility

#### Monthly
- Update email account passwords
- Review forwarding policy
- Check disk space usage
- Backup configuration files

### Backup Important Files
```bash
# Backup virtual alias configuration
cp ./docker-data/dms/config/postfix-virtual.cf ./backups/

# Backup email account information
cp /root/bdg_email_accounts.txt ./backups/

# Backup Roundcube configuration
cp ../config/config.inc.php ./backups/
```

## 📞 Support

### Getting Help
1. Check this documentation
2. Run verification script: `./verify-forwarding-setup.sh`
3. Check logs: `docker-compose logs mailserver`
4. Contact system administrator

### Useful Commands Summary
```bash
# Setup
./setup-admin-forwarding.sh                    # Initial setup
./setup-email-accounts-with-forwarding.sh      # Create accounts
./configure-roundcube-forwarding.sh            # Configure web interface

# Management
./manage-forwarding.sh enable-catchall         # Enable forwarding
./manage-forwarding.sh create-user EMAIL PASS  # Create user
./manage-forwarding.sh list-forwards           # List rules

# Verification
./verify-forwarding-setup.sh                   # Check setup
docker-compose logs mailserver                 # View logs
docker-compose ps                              # Check status
```

## 📝 Notes

- All scripts are designed to be idempotent (safe to run multiple times)
- Configuration changes are applied immediately to running mail server
- Admin account must exist before enabling forwarding
- Forwarding rules persist across container restarts
- Custom domains can be configured by modifying the DOMAIN variable in scripts

---

**Created by**: BDG Software Mail Setup Scripts
**Last Updated**: July 2025
**Version**: 1.0

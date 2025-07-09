# Usage Examples - Admin Email Forwarding

This document provides practical examples of how to use the admin email forwarding system.

## 🚀 Getting Started Examples

### Complete Setup from Scratch

```bash
# 1. Navigate to mail server directory
cd mail-server

# 2. Set up admin forwarding system
./setup-admin-forwarding.sh

# 3. Create email accounts with forwarding
./setup-email-accounts-with-forwarding.sh

# 4. Configure Roundcube web interface
./configure-roundcube-forwarding.sh

# 5. Verify everything is working
./verify-forwarding-setup.sh
```

### Quick Enable Forwarding (if accounts exist)

```bash
# Enable catch-all forwarding
./manage-forwarding.sh enable-catchall

# Verify it's working
./manage-forwarding.sh list-forwards
```

## 👥 User Management Examples

### Creating Business Email Accounts

```bash
# Create department email accounts
./manage-forwarding.sh create-user support@bdgsoftware.com SupportPass123
./manage-forwarding.sh create-user sales@bdgsoftware.com SalesPass123
./manage-forwarding.sh create-user info@bdgsoftware.com InfoPass123
./manage-forwarding.sh create-user hr@bdgsoftware.com HRPass123

# Create personal accounts for team members
./manage-forwarding.sh create-user john@bdgsoftware.com JohnPass123
./manage-forwarding.sh create-user sarah@bdgsoftware.com SarahPass123
./manage-forwarding.sh create-user mike@bdgsoftware.com MikePass123
```

### Creating Project-specific Accounts

```bash
# Create accounts for different projects
./manage-forwarding.sh create-user project1@bdgsoftware.com Project1Pass
./manage-forwarding.sh create-user project2@bdgsoftware.com Project2Pass
./manage-forwarding.sh create-user billing@bdgsoftware.com BillingPass123
./manage-forwarding.sh create-user invoices@bdgsoftware.com InvoicesPass123
```

## 📧 Email Forwarding Examples

### Individual Email Forwarding

```bash
# Forward specific email to admin
./manage-forwarding.sh add-forward contact@bdgsoftware.com admin@bdgsoftware.com

# Forward to multiple recipients (comma-separated)
./manage-forwarding.sh add-forward sales@bdgsoftware.com "admin@bdgsoftware.com,manager@bdgsoftware.com"

# Forward external domain emails (if configured)
./manage-forwarding.sh add-forward info@anotherdomain.com admin@bdgsoftware.com
```

### Department-specific Forwarding

```bash
# All marketing emails to admin
./manage-forwarding.sh add-forward marketing@bdgsoftware.com admin@bdgsoftware.com
./manage-forwarding.sh add-forward newsletter@bdgsoftware.com admin@bdgsoftware.com
./manage-forwarding.sh add-forward campaigns@bdgsoftware.com admin@bdgsoftware.com

# All technical emails to admin
./manage-forwarding.sh add-forward tech@bdgsoftware.com admin@bdgsoftware.com
./manage-forwarding.sh add-forward dev@bdgsoftware.com admin@bdgsoftware.com
./manage-forwarding.sh add-forward api@bdgsoftware.com admin@bdgsoftware.com
```

## 🔧 Management Examples

### Daily Management Tasks

```bash
# Check all forwarding rules
./manage-forwarding.sh list-forwards

# Check mail server status
./docker-mail-management.sh status

# View recent logs
docker-compose logs --tail=50 mailserver

# Check email queue
docker-compose exec mailserver postqueue -p
```

### Weekly Maintenance

```bash
# Backup configuration
cp ./docker-data/dms/config/postfix-virtual.cf ./backups/virtual-aliases-$(date +%Y%m%d).cf

# Check disk usage
docker-compose exec mailserver df -h

# Review email accounts
./docker-mail-management.sh list

# Test system functionality
./verify-forwarding-setup.sh
```

### Troubleshooting Examples

```bash
# If forwarding stops working
./manage-forwarding.sh reload

# If emails are not being received
docker-compose logs mailserver | grep -i error

# Check postfix configuration
docker-compose exec mailserver postconf virtual_alias_maps

# Restart mail server if needed
docker-compose restart mailserver
```

## 🧪 Testing Examples

### Test Email Forwarding

```bash
# Send test email from within container
docker-compose exec mailserver bash -c "echo 'Test message' | mail -s 'Test Subject' test@bdgsoftware.com"

# Check if admin received the email
# (Use Roundcube or IMAP client to check admin@bdgsoftware.com inbox)
```

### Test Different Scenarios

```bash
# Test 1: Send to non-existent address
# Should be forwarded to admin due to catch-all

# Test 2: Send to existing account
# Should be delivered to account AND forwarded to admin

# Test 3: Send to alias
# Should be forwarded according to alias rules
```

## 🌐 Roundcube Usage Examples

### Admin Login Experience

1. **Login to Roundcube**: `http://your-server:8080`
2. **Username**: `admin@bdgsoftware.com`
3. **Password**: Use password from `/root/bdg_email_accounts.txt`

**What admin sees:**
- "Admin Account: You receive all emails sent to @bdgsoftware.com addresses"
- All forwarded emails in inbox
- Forwarding status in settings

### Regular User Experience

1. **Login with any account**: `support@bdgsoftware.com`
2. **Username**: `support@bdgsoftware.com`  
3. **Password**: Use password from account file

**What user sees:**
- "Note: Emails to this account are also forwarded to admin@bdgsoftware.com"
- Normal email functionality
- Forwarding reminder when composing

## 🔒 Security Examples

### Strong Password Generation

```bash
# Generate secure passwords for new accounts
openssl rand -base64 16  # Generates 16-character password

# Create account with generated password
SECURE_PASS=$(openssl rand -base64 16)
./manage-forwarding.sh create-user secure@bdgsoftware.com "$SECURE_PASS"
echo "Password for secure@bdgsoftware.com: $SECURE_PASS"
```

### Account Security

```bash
# Change password for existing account
./docker-mail-management.sh password admin@bdgsoftware.com NewSecurePassword123

# List all accounts to audit
./docker-mail-management.sh list

# Check login attempts
docker-compose logs mailserver | grep -i "authentication"
```

## 📊 Monitoring Examples

### Real-time Monitoring

```bash
# Watch mail logs in real-time
docker-compose logs -f mailserver

# Monitor forwarding activity
docker-compose logs -f mailserver | grep "virtual"

# Watch for errors
docker-compose logs -f mailserver | grep -i error
```

### Performance Monitoring

```bash
# Check email queue size
docker-compose exec mailserver postqueue -p | wc -l

# Monitor disk usage
docker-compose exec mailserver du -sh /var/mail/

# Check memory usage
docker stats mailserver
```

## 🔧 Advanced Configuration Examples

### Custom Domain Configuration

```bash
# If you want to use a different domain
# Edit the scripts and change DOMAIN="bdgsoftware.com" to your domain

# Example for customdomain.com
sed -i 's/bdgsoftware.com/customdomain.com/g' ./manage-forwarding.sh
```

### Multiple Admin Configuration

```bash
# Forward to multiple admins
./manage-forwarding.sh add-forward @bdgsoftware.com "admin1@bdgsoftware.com,admin2@bdgsoftware.com"
```

### Selective Forwarding

```bash
# Disable catch-all and use selective forwarding
./manage-forwarding.sh disable-catchall

# Add specific forwarding rules
./manage-forwarding.sh add-forward support@bdgsoftware.com admin@bdgsoftware.com
./manage-forwarding.sh add-forward sales@bdgsoftware.com admin@bdgsoftware.com
./manage-forwarding.sh add-forward info@bdgsoftware.com admin@bdgsoftware.com
```

## 📝 Backup and Recovery Examples

### Configuration Backup

```bash
# Create backup directory
mkdir -p ./backups/$(date +%Y%m%d)

# Backup all configuration
cp ./docker-data/dms/config/postfix-virtual.cf ./backups/$(date +%Y%m%d)/
cp /root/bdg_email_accounts.txt ./backups/$(date +%Y%m%d)/
cp ../config/config.inc.php ./backups/$(date +%Y%m%d)/

# Create backup archive
tar -czf ./backups/mail-config-$(date +%Y%m%d).tar.gz ./backups/$(date +%Y%m%d)/
```

### Configuration Recovery

```bash
# Restore from backup
cp ./backups/20250709/postfix-virtual.cf ./docker-data/dms/config/

# Reload configuration
./manage-forwarding.sh reload

# Verify restoration
./verify-forwarding-setup.sh
```

## 🎯 Common Scenarios

### Scenario 1: New Employee Onboarding

```bash
# Create account for new employee
./manage-forwarding.sh create-user newemployee@bdgsoftware.com TempPass123

# The employee can now:
# - Send/receive emails at newemployee@bdgsoftware.com
# - Admin automatically receives copies of all emails
# - Employee should change password on first login
```

### Scenario 2: Project Management

```bash
# Create project-specific email
./manage-forwarding.sh create-user project-alpha@bdgsoftware.com ProjectAlpha123

# All project emails go to admin for oversight
# Project team can still access project-alpha@bdgsoftware.com directly
```

### Scenario 3: Customer Service

```bash
# Multiple customer service addresses
./manage-forwarding.sh create-user support@bdgsoftware.com Support123
./manage-forwarding.sh create-user help@bdgsoftware.com Help123  
./manage-forwarding.sh create-user tickets@bdgsoftware.com Tickets123

# All customer emails forwarded to admin for quality control
```

### Scenario 4: Temporary Forwarding

```bash
# Enable forwarding for specific period
./manage-forwarding.sh add-forward temp@bdgsoftware.com admin@bdgsoftware.com

# Remove when no longer needed
./manage-forwarding.sh remove-forward temp@bdgsoftware.com
```

---

These examples should help you get started with the admin email forwarding system. Remember to always verify your configuration with `./verify-forwarding-setup.sh` after making changes!

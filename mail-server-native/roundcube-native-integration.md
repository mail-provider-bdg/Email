# Native Mail Server Integration with Roundcube

## Update Render.com Configuration

Update your `render.yaml` file to use your native mail server:

```yaml
envVars:
  # Native mail server configuration
  - key: IMAP_HOST
    value: mail.bdgsoftware.com:993
  - key: SMTP_HOST  
    value: mail.bdgsoftware.com:587
  - key: SMTP_USER
    value: %u
  - key: SMTP_PASS
    value: %p
  
  # Update branding
  - key: PRODUCT_NAME
    value: BDG Software Mail
  - key: SUPPORT_URL
    value: https://support.bdgsoftware.com
```

## Update Roundcube Configuration

Modify `config/config.inc.php.render`:

```php
// Native mail server configuration
$config['imap_host'] = array(
    'ssl://mail.bdgsoftware.com:993' => 'BDG Software Mail (SSL)',
);

$config['smtp_host'] = 'tls://mail.bdgsoftware.com:587';
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['smtp_auth_type'] = 'LOGIN';

// Domain-specific settings
$config['mail_domain'] = 'bdgsoftware.com';
$config['product_name'] = 'BDG Software Mail';

// Enhanced security for native setup
$config['force_https'] = true;
$config['login_rate_limit'] = 3;
$config['login_rate_limit_window'] = 300;

// Performance settings
$config['max_message_size'] = '50MB';
$config['enable_caching'] = true;
$config['message_cache_lifetime'] = '10d';

// Additional plugins for native setup
$config['plugins'] = array(
    'archive',
    'zipdownload',
    'attachment_reminder',
    'emoticons',
    'hide_blockquote',
    'identicon',
    'newmail_notifier',
    'vcard_attachments',
    'password',     // For password changes
);
```

## Server Requirements

### Minimum Server Specifications
- **RAM**: 2GB minimum, 4GB recommended
- **CPU**: 2 cores minimum
- **Storage**: 20GB minimum, SSD recommended
- **OS**: Ubuntu 20.04/22.04 or Debian 11/12
- **Network**: Static IP address required

### Recommended Hosting Providers
- **DigitalOcean**: $12/month droplet
- **Linode**: $12/month VPS
- **Vultr**: $12/month instance
- **Hetzner**: €4.51/month VPS

## Installation Process

1. **Prepare Server**:
```bash
# Update system
apt update && apt upgrade -y

# Set hostname
hostnamectl set-hostname mail.bdgsoftware.com
echo "127.0.0.1 mail.bdgsoftware.com" >> /etc/hosts
```

2. **Configure DNS** (before installation):
```dns
A     mail.bdgsoftware.com    YOUR_SERVER_IP
MX    @                       10 mail.bdgsoftware.com
TXT   @                       "v=spf1 mx a:mail.bdgsoftware.com ~all"
```

3. **Run Installation**:
```bash
# Clone repository and navigate to native setup
cd mail-server-native

# Make scripts executable
chmod +x *.sh

# Run main installation
./install.sh

# Configure components
./configure-dovecot.sh
./configure-dkim.sh
./configure-security.sh

# Create initial accounts
./setup-initial-accounts.sh

# Test installation
./test-mail-server.sh
```

## Account Management

### Create New User
```bash
./manage-users.sh add john@bdgsoftware.com secretpassword123
```

### Change Password
```bash
./manage-users.sh password john@bdgsoftware.com newpassword456
```

### Create Alias
```bash
./manage-users.sh alias contact@bdgsoftware.com john@bdgsoftware.com
```

### List Users
```bash
./manage-users.sh list
```

## DNS Configuration for DKIM

After running `./configure-dkim.sh`, add this TXT record:

```dns
Host: mail._domainkey.bdgsoftware.com
Value: v=DKIM1; h=sha256; k=rsa; p=YOUR_DKIM_PUBLIC_KEY
```

Get the exact record with:
```bash
cat /etc/opendkim/keys/bdgsoftware.com/mail.txt
```

## Maintenance Tasks

### Daily Monitoring
```bash
# Check service status
systemctl status postfix dovecot opendkim

# Check mail queue
postqueue -p

# Check logs
tail -f /var/log/mail.log
```

### Weekly Tasks
```bash
# Update system
apt update && apt upgrade -y

# Check disk space
df -h

# Review security logs
fail2ban-client status
```

### Certificate Renewal
```bash
# Renew Let's Encrypt certificates
certbot renew --quiet

# Restart services after renewal
systemctl restart postfix dovecot
```

## Backup Strategy

### Create Backup Script
```bash
#!/bin/bash
# /root/backup-mail.sh

BACKUP_DIR="/backup/mail-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup mail data
tar -czf "$BACKUP_DIR/mail-data.tar.gz" /var/mail/

# Backup configuration
tar -czf "$BACKUP_DIR/mail-config.tar.gz" \
    /etc/postfix/ \
    /etc/dovecot/ \
    /etc/opendkim/ \
    /etc/fail2ban/

# Backup database
mysqldump -u root -p$(grep 'MySQL root password:' /root/mysql_passwords.txt | cut -d' ' -f4) \
    mailserver > "$BACKUP_DIR/mailserver.sql"

# Clean old backups (keep 30 days)
find /backup/ -name "mail-*" -mtime +30 -exec rm -rf {} \;
```

### Automate Backups
```bash
# Add to crontab
echo "0 2 * * * /root/backup-mail.sh" | crontab -
```

## Troubleshooting

### Common Issues

1. **Mail not delivered**:
   - Check DNS records: `dig MX bdgsoftware.com`
   - Check mail queue: `postqueue -p`
   - Check logs: `tail -f /var/log/mail.log`

2. **Authentication failed**:
   - Verify user exists: `./manage-users.sh list`
   - Check Dovecot logs: `tail -f /var/log/dovecot.log`
   - Test password: Reset with `./manage-users.sh password`

3. **Marked as spam**:
   - Verify SPF record: `dig TXT bdgsoftware.com`
   - Check DKIM: `opendkim-testkey -d bdgsoftware.com -s mail`
   - Add DMARC record

### Performance Optimization

#### For High Volume
```bash
# Increase Postfix limits
postconf -e 'default_process_limit = 200'
postconf -e 'smtpd_client_connection_count_limit = 50'

# Optimize Dovecot
echo 'mail_max_userip_connections = 50' >> /etc/dovecot/conf.d/20-imap.conf

# Restart services
systemctl restart postfix dovecot
```

## Security Best Practices

### Regular Updates
```bash
# Enable automatic security updates
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

### Monitor Security
```bash
# Check fail2ban status
fail2ban-client status

# Review authentication logs
grep "authentication failed" /var/log/dovecot.log

# Check for brute force attempts
grep "warning.*SASL" /var/log/mail.log
```

Your native mail server is now ready to integrate with Roundcube! 🚀

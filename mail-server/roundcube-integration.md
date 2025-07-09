# Integrating Self-Hosted Mail Server with Roundcube

## Update Render.com Configuration

Update your `render.yaml` file to use your self-hosted mail server:

```yaml
envVars:
  # Self-hosted mail server configuration
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

## Update Roundcube Config

Modify `config/config.inc.php.render`:

```php
// Mail server configuration for self-hosted setup
$config['imap_host'] = array(
    'ssl://mail.bdgsoftware.com:993' => 'BDG Software Mail (SSL)',
    'mail.bdgsoftware.com:143' => 'BDG Software Mail (STARTTLS)',
);

$config['smtp_host'] = 'tls://mail.bdgsoftware.com:587';
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['smtp_auth_type'] = 'LOGIN';

// Domain-specific settings
$config['mail_domain'] = 'bdgsoftware.com';
$config['product_name'] = 'BDG Software Mail';

// Auto-create default identity
$config['identity_default'] = array(
    'name' => '%n',
    'email' => '%u@bdgsoftware.com',
    'reply-to' => '%u@bdgsoftware.com',
    'signature' => "Sent with BDG Software Mail\nhttps://bdgsoftware.com"
);

// Security settings for self-hosted
$config['force_https'] = true;
$config['login_rate_limit'] = 3;
$config['login_rate_limit_window'] = 300;

// Increase limits for business use
$config['max_message_size'] = '50MB';
$config['max_group_members'] = 1000;

// Enable additional plugins for business features
$config['plugins'] = array(
    'archive',
    'zipdownload',
    'attachment_reminder',
    'emoticons',
    'hide_blockquote',
    'identicon',
    'newmail_notifier',
    'vcard_attachments',
    'managesieve',  // For mail filters
    'password',     // For password changes
    'acl',          // For shared folders
);
```

## Email Account Setup

Create email accounts for your team:

```bash
# Navigate to mail server directory
cd mail-server

# Create user accounts
docker-compose exec mailserver setup email add john@bdgsoftware.com
docker-compose exec mailserver setup email add jane@bdgsoftware.com
docker-compose exec mailserver setup email add sales@bdgsoftware.com
docker-compose exec mailserver setup email add support@bdgsoftware.com

# Set up aliases
docker-compose exec mailserver setup alias add info@bdgsoftware.com sales@bdgsoftware.com
docker-compose exec mailserver setup alias add contact@bdgsoftware.com sales@bdgsoftware.com
docker-compose exec mailserver setup alias add hello@bdgsoftware.com sales@bdgsoftware.com

# Create mailing lists
docker-compose exec mailserver setup alias add team@bdgsoftware.com john@bdgsoftware.com,jane@bdgsoftware.com
```

## Testing the Integration

1. **Test SMTP sending**:
```bash
# Test from your mail server
echo "Test message" | docker-compose exec -T mailserver mail -s "Test Subject" test@gmail.com
```

2. **Test IMAP connection**:
```bash
# Test IMAP connectivity
openssl s_client -connect mail.bdgsoftware.com:993 -crlf
```

3. **Check Roundcube logs**:
```bash
# Check logs in Render dashboard or locally
tail -f logs/roundcube.log
```

## Firewall Configuration

Ensure these ports are open on your mail server:

```bash
# SMTP
ufw allow 25
ufw allow 587
ufw allow 465

# IMAP
ufw allow 143
ufw allow 993

# HTTP/HTTPS for certificates
ufw allow 80
ufw allow 443
```

## Monitoring and Maintenance

### Check Mail Server Status
```bash
docker-compose ps
docker-compose logs mailserver
```

### Monitor Mail Queue
```bash
docker-compose exec mailserver postqueue -p
```

### Check Security Logs
```bash
docker-compose logs fail2ban
```

### Backup Configuration
```bash
# Backup mail data
tar -czf mail-backup-$(date +%Y%m%d).tar.gz docker-data/
```

## Troubleshooting

### Common Issues

1. **Cannot connect to IMAP/SMTP**:
   - Check firewall settings
   - Verify DNS records
   - Check SSL certificates

2. **Emails marked as spam**:
   - Verify SPF/DKIM/DMARC records
   - Check server reputation
   - Use mail-tester.com

3. **Authentication failed**:
   - Verify user accounts exist
   - Check password requirements
   - Review Roundcube error logs

### Useful Commands

```bash
# Check mail server configuration
docker-compose exec mailserver postconf -n

# Test DKIM signing
docker-compose exec mailserver opendkim-testkey -d bdgsoftware.com -s mail

# View current users
docker-compose exec mailserver setup email list

# Check SSL certificate
docker-compose exec mailserver openssl x509 -in /etc/letsencrypt/live/mail.bdgsoftware.com/cert.pem -text -noout
```

## Performance Optimization

Add to `mailserver.env`:
```bash
# Performance tuning
POSTFIX_INET_PROTOCOLS=ipv4
DOVECOT_PROCESS_LIMIT=500
POSTFIX_SMTPD_CLIENT_CONNECTION_COUNT_LIMIT=50
```

Your self-hosted mail server is now integrated with Roundcube! 🚀

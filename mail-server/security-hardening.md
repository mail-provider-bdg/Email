# Mail Server Security Hardening Guide

## Firewall Configuration

### UFW (Ubuntu Firewall)
```bash
# Reset firewall
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# SSH access (change port if needed)
ufw allow 22/tcp

# Mail server ports
ufw allow 25/tcp    # SMTP
ufw allow 587/tcp   # Submission (STARTTLS)
ufw allow 465/tcp   # SMTPS (SSL)
ufw allow 143/tcp   # IMAP (STARTTLS)
ufw allow 993/tcp   # IMAPS (SSL)

# Web ports for certificates
ufw allow 80/tcp    # HTTP (Let's Encrypt)
ufw allow 443/tcp   # HTTPS

# Enable firewall
ufw enable
```

### iptables Rules
```bash
# Save current rules
iptables-save > /etc/iptables/rules.v4

# Additional protection
iptables -A INPUT -p tcp --dport 25 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --dport 587 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
```

## Fail2Ban Configuration

Create custom jail for mail server:

```ini
# /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[postfix-sasl]
enabled = true
port = smtp,465,submission
filter = postfix-sasl
logpath = /var/log/mail.log
backend = auto

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
filter = dovecot
logpath = /var/log/mail.log
backend = auto

[postfix-rbl]
enabled = true
filter = postfix-rbl
port = smtp,465,submission
logpath = /var/log/mail.log
maxretry = 1
```

## SSL/TLS Hardening

### Enhanced SSL Configuration
Add to `mailserver.env`:
```bash
# Strong SSL configuration
TLS_LEVEL=modern
SSL_TYPE=letsencrypt

# Disable weak protocols
POSTFIX_SMTP_TLS_SECURITY_LEVEL=encrypt
POSTFIX_SMTPD_TLS_SECURITY_LEVEL=encrypt
POSTFIX_SMTP_TLS_PROTOCOLS=!SSLv2,!SSLv3
POSTFIX_SMTPD_TLS_PROTOCOLS=!SSLv2,!SSLv3

# Strong ciphers only
DOVECOT_SSL_PROTOCOLS=!SSLv3
DOVECOT_SSL_CIPHER_LIST=ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!MD5:!DSS:!3DES
```

## User Account Security

### Strong Password Policy
```bash
# Set minimum password length
docker-compose exec mailserver setup config set PASSWD_MIN_LEN 12

# Require complex passwords
docker-compose exec mailserver setup config set PASSWD_COMPLEXITY 1
```

### Account Lockout Policy
```bash
# Lock account after failed attempts
echo "auth_failure_delay = 2s" >> docker-data/dms/config/dovecot.cf
echo "auth_cache_negative_ttl = 1 hour" >> docker-data/dms/config/dovecot.cf
```

## Anti-Spam Configuration

### SpamAssassin Tuning
Create `docker-data/dms/config/spamassassin/local.cf`:
```perl
# SpamAssassin local configuration
required_score 5.0
report_safe 0
rewrite_header Subject [SPAM]

# DNS blocklists
use_razor2 1
use_pyzor 1
use_bayes 1
bayes_auto_learn 1

# Custom rules
body CUSTOM_SPAM_RULE /viagra|cialis|pharmacy/i
score CUSTOM_SPAM_RULE 3.0
```

### Postfix Anti-Spam
Add to postfix configuration:
```bash
# Rate limiting
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 100

# Greylisting
check_policy_service = inet:127.0.0.1:10023

# RBL checks
reject_rbl_client zen.spamhaus.org
reject_rbl_client bl.spamcop.net
```

## Backup Security

### Automated Backups
```bash
#!/bin/bash
# backup-mail.sh

BACKUP_DIR="/backup/mail"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup mail data
tar -czf $BACKUP_DIR/mail-data-$DATE.tar.gz docker-data/dms/mail-data/

# Backup configuration
tar -czf $BACKUP_DIR/mail-config-$DATE.tar.gz docker-data/dms/config/

# Encrypt backups
gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
    --s2k-digest-algo SHA512 --s2k-count 65536 --symmetric \
    --output $BACKUP_DIR/mail-data-$DATE.tar.gz.gpg \
    $BACKUP_DIR/mail-data-$DATE.tar.gz

# Clean up unencrypted files
rm $BACKUP_DIR/mail-data-$DATE.tar.gz
rm $BACKUP_DIR/mail-config-$DATE.tar.gz

# Keep only last 30 days
find $BACKUP_DIR -name "*.gpg" -mtime +30 -delete
```

## Monitoring and Alerting

### Log Monitoring
```bash
# Install logwatch
apt install logwatch

# Configure logwatch for mail
echo "Service = postfix" >> /etc/logwatch/conf/services/postfix.conf
echo "Service = dovecot" >> /etc/logwatch/conf/services/dovecot.conf
```

### Security Monitoring Script
```bash
#!/bin/bash
# security-check.sh

# Check for suspicious login attempts
FAILED_LOGINS=$(grep "authentication failed" /var/log/mail.log | wc -l)
if [ $FAILED_LOGINS -gt 100 ]; then
    echo "WARNING: $FAILED_LOGINS failed login attempts detected"
fi

# Check disk space
DISK_USAGE=$(df -h /var/mail | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Mail storage is $DISK_USAGE% full"
fi

# Check mail queue
QUEUE_SIZE=$(docker-compose exec mailserver postqueue -p | tail -n1 | awk '{print $5}')
if [ "$QUEUE_SIZE" != "empty" ]; then
    echo "WARNING: Mail queue has $QUEUE_SIZE messages"
fi
```

## Network Security

### Reverse DNS (PTR Record)
Ensure your server IP has proper reverse DNS:
```bash
# Check current PTR record
dig -x YOUR_SERVER_IP

# Should return: mail.bdgsoftware.com
```

### IP Reputation Monitoring
```bash
# Check IP reputation
curl -s "https://api.spamhaus.org/api/v1/reputation/YOUR_SERVER_IP"

# Monitor blacklists
dig YOUR_SERVER_IP.zen.spamhaus.org
dig YOUR_SERVER_IP.bl.spamcop.net
```

## Regular Security Tasks

### Daily Tasks
- Monitor fail2ban logs
- Check mail queue status
- Review authentication logs
- Verify SSL certificate status

### Weekly Tasks
- Update system packages
- Review user account activity
- Check backup integrity
- Monitor storage usage

### Monthly Tasks
- Rotate log files
- Update mail server software
- Review and update firewall rules
- Test backup restoration

## Incident Response

### Compromised Account Response
```bash
# Disable compromised account
docker-compose exec mailserver setup email del compromised@bdgsoftware.com

# Change passwords for all accounts
docker-compose exec mailserver setup email update user@bdgsoftware.com

# Check for unauthorized configuration changes
git diff HEAD~1 docker-data/dms/config/
```

### Security Breach Response
1. Disconnect server from network
2. Preserve logs and evidence
3. Change all passwords
4. Review access logs
5. Update security configurations
6. Monitor for continued threats

This comprehensive security setup will protect your self-hosted mail server from common threats and attacks. 🔒

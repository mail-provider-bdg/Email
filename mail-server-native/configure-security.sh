#!/bin/bash

# Security Configuration Script
set -e

DOMAIN="bdgsoftware.com"

echo "🔒 Configuring security components..."

# Configure SpamAssassin
echo "📧 Setting up SpamAssassin..."
cat > /etc/default/spamassassin << 'EOF'
ENABLED=1
OPTIONS="--create-prefs --max-children 5 --helper-home-dir"
PIDFILE="/var/run/spamd.pid"
NICE="--nicelevel 15"
EOF

# SpamAssassin local configuration
cat > /etc/spamassassin/local.cf << 'EOF'
# Local SpamAssassin configuration
required_score 5.0
report_safe 0
rewrite_header Subject [SPAM]

# Use Bayesian filtering
use_bayes 1
bayes_auto_learn 1
bayes_auto_learn_threshold_nonspam 0.1
bayes_auto_learn_threshold_spam 12.0

# Use network tests
use_pyzor 1
use_razor2 1
use_dcc 1

# DNS blacklists
skip_rbl_checks 0
use_razor2 1
use_pyzor 1

# Custom rules
body CUSTOM_VIAGRA /viagra|cialis|levitra/i
score CUSTOM_VIAGRA 3.0
EOF

# Start and enable SpamAssassin
systemctl restart spamassassin
systemctl enable spamassassin

# Configure ClamAV
echo "🦠 Setting up ClamAV..."
freshclam
systemctl restart clamav-daemon
systemctl enable clamav-daemon
systemctl restart clamav-freshclam
systemctl enable clamav-freshclam

# Configure Fail2ban
echo "🛡️ Setting up Fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban hosts for 1 hour
bantime = 3600
# 5 failures within 10 minutes triggers ban
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[postfix-sasl]
enabled = true
port = smtp,465,submission
filter = postfix-sasl
logpath = /var/log/mail.log
backend = auto

[postfix-auth]
enabled = true
port = smtp,465,submission
filter = postfix-auth
logpath = /var/log/mail.log
backend = auto

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
filter = dovecot
logpath = /var/log/dovecot.log
backend = auto
EOF

# Create custom Fail2ban filters
cat > /etc/fail2ban/filter.d/postfix-auth.conf << 'EOF'
[Definition]
failregex = warning: [-._\w]+\[<HOST>\]: SASL \w+ authentication failed:
ignoreregex =
EOF

# Restart Fail2ban
systemctl restart fail2ban
systemctl enable fail2ban

# Configure automatic security updates
echo "🔄 Setting up automatic security updates..."
apt install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Create log rotation
cat > /etc/logrotate.d/mailserver << 'EOF'
/var/log/mail.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload postfix dovecot
    endscript
}

/var/log/dovecot*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload dovecot
    endscript
}
EOF

echo "✅ Security configuration completed!"

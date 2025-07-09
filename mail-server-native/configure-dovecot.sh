#!/bin/bash

# Dovecot Configuration Script
set -e

DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"
POSTFIX_DB_PASSWORD=$(grep "Postfix database password:" /root/mysql_passwords.txt | cut -d' ' -f4)

echo "🕊️ Configuring Dovecot..."

# Backup original configuration
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.backup

# Main Dovecot configuration
cat > /etc/dovecot/dovecot.conf << 'EOF'
# Dovecot configuration for virtual mail server

# Protocols
protocols = imap lmtp

# Logging
log_timestamp = "%Y-%m-%d %H:%M:%S "
log_path = /var/log/dovecot.log
info_log_path = /var/log/dovecot-info.log

# SSL Configuration
ssl = required
ssl_cert = </etc/letsencrypt/live/mail.bdgsoftware.com/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.bdgsoftware.com/privkey.pem
ssl_protocols = !SSLv2 !SSLv3
ssl_cipher_list = ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!MD5:!DSS:!3DES
ssl_prefer_server_ciphers = yes
ssl_dh_parameters_length = 2048

# Authentication
auth_mechanisms = plain login
disable_plaintext_auth = yes

# Mail location
mail_location = maildir:/var/mail/%d/%n
mail_uid = vmail
mail_gid = mail
first_valid_uid = 5000
last_valid_uid = 5000

# Namespace
namespace inbox {
  inbox = yes
  location = 
  mailbox Drafts {
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }
  mailbox Sent {
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox Trash {
    special_use = \Trash
  }
  prefix = 
}

# Services
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    group = postfix
    mode = 0600
    user = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0666
    user = postfix
  }
  unix_listener auth-userdb {
    group = vmail
    mode = 0600
    user = vmail
  }
}

service auth-worker {
  user = vmail
}

# Plugins
protocol imap {
  mail_plugins = quota imap_quota
}

protocol lmtp {
  mail_plugins = quota
}

# Include other configuration files
!include conf.d/*.conf
EOF

# MySQL authentication configuration
cat > /etc/dovecot/conf.d/auth-sql.conf.ext << EOF
# MySQL authentication

passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
EOF

# MySQL connection configuration
cat > /etc/dovecot/dovecot-sql.conf.ext << EOF
# Database connection
driver = mysql
connect = host=localhost dbname=mailserver user=mailuser password=$POSTFIX_DB_PASSWORD

# Default password scheme
default_pass_scheme = CRYPT

# User query
user_query = SELECT '/var/mail/%d/%n' as home, 'maildir:/var/mail/%d/%n' as mail, 5000 AS uid, 8 AS gid, concat('dirsize:storage=', quota) AS quota FROM users WHERE email = '%u' AND active = 1

# Password query
password_query = SELECT email as user, password, '/var/mail/%d/%n' as userdb_home, 'maildir:/var/mail/%d/%n' as userdb_mail, 5000 as userdb_uid, 8 as userdb_gid FROM users WHERE email = '%u' AND active = 1
EOF

# Set proper permissions
chmod 640 /etc/dovecot/dovecot-sql.conf.ext
chown root:dovecot /etc/dovecot/dovecot-sql.conf.ext

# Quota configuration
cat > /etc/dovecot/conf.d/90-quota.conf << 'EOF'
plugin {
  quota = maildir:User quota
  quota_exceeded_message = Storage quota for this account has been exceeded.
}
EOF

# Create mail directories
mkdir -p /var/mail/$DOMAIN
chown -R vmail:mail /var/mail
chmod -R 770 /var/mail

# Restart and enable services
systemctl restart dovecot
systemctl enable dovecot
systemctl restart postfix
systemctl enable postfix

echo "✅ Dovecot configuration completed!"

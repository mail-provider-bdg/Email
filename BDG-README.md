# BDG Software Email System

A complete email system with Roundcube webmail, user registration, and automatic email forwarding.

## Quick Start

After cloning this repository, simply run:

```bash
sudo ./start.sh
```

This single command will:
1. Set up the complete mail server (either native or Docker-based)
2. Install and configure Roundcube webmail
3. Set up the user registration system
4. Configure email forwarding to admin@bdgsoftware.cloud
5. Set up all security components

## Features

- **Complete Mail Server**: Postfix, Dovecot, SpamAssassin, and ClamAV
- **Beautiful Webmail Interface**: Customized Roundcube with purple theme
- **User Registration System**: Allow users to create @bdgsoftware.cloud email accounts
- **Email Forwarding**: All emails are automatically forwarded to admin@bdgsoftware.cloud
- **Admin Dashboard**: Manage all user accounts from a central interface
- **Security**: SPF, DKIM, DMARC, and other security measures

## DNS Configuration

After running the setup, you'll need to configure these DNS records:

```
A    mail.bdgsoftware.cloud    YOUR_SERVER_IP
MX   @   10   mail.bdgsoftware.cloud
TXT  @   "v=spf1 mx a:mail.bdgsoftware.cloud ~all"
TXT  mail._domainkey   "v=DKIM1; h=sha256; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
TXT  _dmarc   "v=DMARC1; p=quarantine; rua=mailto:admin@bdgsoftware.cloud; ruf=mailto:admin@bdgsoftware.cloud; fo=1"
```

## System Requirements

- Ubuntu/Debian Linux
- Minimum 2GB RAM
- 20GB storage
- Open ports: 25, 587, 465, 993, 143, 80, 443

## Support

For support, contact admin@bdgsoftware.cloud
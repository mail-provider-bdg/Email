#!/bin/bash

# Mail Server Testing Script
set -e

DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"
TEST_EMAIL="admin@$DOMAIN"

echo "🧪 Testing mail server configuration..."

# Test 1: Check if services are running
echo "1️⃣ Checking services status..."
services=("postfix" "dovecot" "opendkim" "spamassassin" "clamav-daemon" "fail2ban")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "   ✅ $service is running"
    else
        echo "   ❌ $service is not running"
    fi
done

# Test 2: Check ports
echo ""
echo "2️⃣ Checking open ports..."
ports=("25:SMTP" "587:Submission" "993:IMAPS")
for port_info in "${ports[@]}"; do
    port=$(echo $port_info | cut -d: -f1)
    name=$(echo $port_info | cut -d: -f2)
    if ss -tlnp | grep -q ":$port "; then
        echo "   ✅ Port $port ($name) is open"
    else
        echo "   ❌ Port $port ($name) is not open"
    fi
done

# Test 3: Check SSL certificates
echo ""
echo "3️⃣ Checking SSL certificates..."
if [ -f "/etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem" ]; then
    cert_expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem" | cut -d= -f2)
    echo "   ✅ SSL certificate exists, expires: $cert_expiry"
else
    echo "   ❌ SSL certificate not found"
fi

# Test 4: Test SMTP connection
echo ""
echo "4️⃣ Testing SMTP connection..."
if timeout 5 bash -c "</dev/tcp/$MAIL_DOMAIN/587" 2>/dev/null; then
    echo "   ✅ SMTP port 587 is accessible"
else
    echo "   ❌ SMTP port 587 is not accessible"
fi

# Test 5: Test IMAP connection
echo ""
echo "5️⃣ Testing IMAP connection..."
if timeout 5 bash -c "</dev/tcp/$MAIL_DOMAIN/993" 2>/dev/null; then
    echo "   ✅ IMAP port 993 is accessible"
else
    echo "   ❌ IMAP port 993 is not accessible"
fi

# Test 6: Check DKIM configuration
echo ""
echo "6️⃣ Checking DKIM configuration..."
if [ -f "/etc/opendkim/keys/$DOMAIN/mail.private" ]; then
    echo "   ✅ DKIM private key exists"
    if opendkim-testkey -d "$DOMAIN" -s mail -vvv; then
        echo "   ✅ DKIM key validation passed"
    else
        echo "   ⚠️  DKIM key validation failed (DNS record may not be set)"
    fi
else
    echo "   ❌ DKIM private key not found"
fi

# Test 7: Check DNS records
echo ""
echo "7️⃣ Checking DNS records..."
mx_record=$(dig +short MX "$DOMAIN" | head -1)
if [[ "$mx_record" == *"$MAIL_DOMAIN"* ]]; then
    echo "   ✅ MX record points to $MAIL_DOMAIN"
else
    echo "   ❌ MX record issue: $mx_record"
fi

spf_record=$(dig +short TXT "$DOMAIN" | grep "v=spf1")
if [ -n "$spf_record" ]; then
    echo "   ✅ SPF record found: $spf_record"
else
    echo "   ⚠️  SPF record not found"
fi

# Test 8: Test mail delivery (if test email exists)
echo ""
echo "8️⃣ Testing mail delivery..."
if mysql -u root -p"$(grep 'MySQL root password:' /root/mysql_passwords.txt | cut -d' ' -f4)" mailserver -e "SELECT email FROM users WHERE email='$TEST_EMAIL'" | grep -q "$TEST_EMAIL"; then
    echo "   📧 Sending test email to $TEST_EMAIL..."
    echo "This is a test email from your mail server. If you receive this, your mail server is working correctly!" | mail -s "Mail Server Test" "$TEST_EMAIL"
    echo "   ✅ Test email sent (check the mailbox)"
else
    echo "   ⚠️  Test email account $TEST_EMAIL not found"
fi

# Test 9: Check log files
echo ""
echo "9️⃣ Checking recent log entries..."
echo "   Recent Postfix logs:"
tail -5 /var/log/mail.log | sed 's/^/      /'

echo ""
echo "   Recent Dovecot logs:"
if [ -f /var/log/dovecot.log ]; then
    tail -5 /var/log/dovecot.log | sed 's/^/      /'
else
    echo "      No Dovecot log file found"
fi

# Summary
echo ""
echo "🏁 Test Summary"
echo "==============="
echo "✅ = Working correctly"
echo "⚠️  = Warning (may need attention)"
echo "❌ = Error (needs fixing)"
echo ""
echo "💡 Tips:"
echo "- Ensure DNS records are properly configured"
echo "- Check firewall settings if ports are not accessible"
echo "- Monitor logs for any error messages"
echo "- Test actual email sending/receiving with mail clients"

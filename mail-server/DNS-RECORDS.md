# DNS Records for bdgsoftware.com Mail Server

Configure these DNS records in your domain registrar's control panel:

## Required DNS Records

### A Records
```
A    mail.bdgsoftware.com    YOUR_SERVER_IP
A    bdgsoftware.com         YOUR_SERVER_IP  (optional, for web)
```

### MX Record
```
MX   @   10   mail.bdgsoftware.com
```

### SPF Record (TXT)
```
TXT  @   "v=spf1 mx a:mail.bdgsoftware.com ~all"
```

### DKIM Record (TXT)
After setup, get the DKIM key with:
```bash
docker-compose exec mailserver cat /tmp/docker-mailserver/opendkim/keys/bdgsoftware.com/mail.txt
```

Then add it as:
```
TXT  mail._domainkey   "v=DKIM1; h=sha256; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
```

### DMARC Record (TXT)
```
TXT  _dmarc   "v=DMARC1; p=quarantine; rua=mailto:dmarc@bdgsoftware.com; ruf=mailto:dmarc@bdgsoftware.com; fo=1"
```

### PTR Record (Reverse DNS)
Configure with your hosting provider:
```
PTR  YOUR_SERVER_IP   mail.bdgsoftware.com
```

## Additional Records (Optional)

### CAA Record (Certificate Authority Authorization)
```
CAA  @   0 issue "letsencrypt.org"
CAA  @   0 issuewild "letsencrypt.org"
```

### SRV Records (for auto-configuration)
```
SRV  _imaps._tcp   0 1 993 mail.bdgsoftware.com
SRV  _submission._tcp   0 1 587 mail.bdgsoftware.com
```

## Verification

Use these tools to verify your DNS setup:

1. **MX Records**: `dig MX bdgsoftware.com`
2. **SPF Records**: `dig TXT bdgsoftware.com`
3. **DKIM Records**: `dig TXT mail._domainkey.bdgsoftware.com`
4. **DMARC Records**: `dig TXT _dmarc.bdgsoftware.com`

## Online Tools

- **MXToolbox**: https://mxtoolbox.com/
- **Mail Tester**: https://www.mail-tester.com/
- **DKIM Validator**: https://dkimvalidator.com/
- **SPF Record Check**: https://www.kitterman.com/spf/validate.html

## Example with Cloudflare

If using Cloudflare DNS:

1. Go to Cloudflare Dashboard
2. Select your domain
3. Go to DNS tab
4. Add the records above
5. Set mail.bdgsoftware.com to "DNS Only" (grey cloud)
6. Keep other records as needed

## Propagation

DNS changes can take 24-48 hours to fully propagate worldwide. Use `dig` command to check local propagation:

```bash
dig MX bdgsoftware.com @8.8.8.8
dig TXT bdgsoftware.com @8.8.8.8
```

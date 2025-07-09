# Roundcube Webmail Deployment on Render.com

This guide explains how to deploy the redesigned Roundcube webmail with the purple theme on Render.com.

## Prerequisites

1. A Render.com account
2. Access to mail servers (IMAP/SMTP) for email functionality
3. This repository with the purple theme modifications

## Deployment Steps

### 1. Prepare Your Repository

Ensure your repository contains:
- `render.yaml` - Render deployment configuration
- `config/config.inc.php.render` - Render-specific configuration

### 2. Configure Mail Servers

Before deployment, you need to configure your mail server settings in `render.yaml`:

```yaml
envVars:
  - key: IMAP_HOST
    value: your-imap-server.com:993  # Replace with your IMAP server
  - key: SMTP_HOST
    value: your-smtp-server.com:587  # Replace with your SMTP server
```

### 3. Deploy to Render

1. **Connect Repository**: Link your GitHub repository to Render.com
2. **Automatic Deployment**: Render will read `render.yaml` and deploy automatically
3. **Environment Variables**: The database and Redis will be automatically configured

### 4. Post-Deployment Configuration

After deployment:

1. **Test Email**: Verify IMAP/SMTP connectivity
2. **Configure Plugins**: Enable/disable plugins as needed
3. **Custom Domain**: Set up your custom domain in Render dashboard
4. **SSL Certificate**: Render provides free SSL certificates automatically

## Services Created

The deployment creates:

- **Web Service**: PHP application running Roundcube
- **PostgreSQL Database**: For storing user data and settings
- **Redis Cache**: For sessions and caching (optional)

## Environment Variables

Key environment variables (automatically configured):

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`: Database connection
- `IMAP_HOST`, `SMTP_HOST`: Mail server configuration
- `DES_KEY`: Encryption key (auto-generated)
- `PRODUCT_NAME`: Application name
- `SKIN`: Theme selection (set to 'elastic' for purple theme)

## Features Included

- **Purple Theme**: Custom-designed purple and black theme
- **Responsive Design**: Works on all devices
- **Security**: HTTPS, secure sessions, and security headers
- **Performance**: Redis caching and optimized PHP configuration
- **Plugins**: Common plugins pre-configured

## Troubleshooting

### Common Issues

1. **Database Connection**: Ensure database service is running
2. **Mail Server**: Verify IMAP/SMTP credentials and ports
3. **PHP Extensions**: Check if required extensions are loaded
4. **Permissions**: Ensure temp and logs directories are writable

### Logs

Check logs in Render dashboard:
- Application logs for PHP errors
- Database logs for connection issues
- Build logs for deployment problems

## Customization

### Theme Modifications

The purple theme files are in:
- `skins/elastic/styles/colors.less`
- `skins/elastic/styles/_styles.less`
- `skins/elastic/styles/_variables.less`

### Plugin Configuration

Edit `config/config.inc.php.render` to add/remove plugins:

```php
$config['plugins'] = [
    'archive',
    'zipdownload',
    'attachment_reminder',
    // Add more plugins here
];
```

### Mail Server Settings

For different mail providers:

**Gmail**:
```yaml
- key: IMAP_HOST
  value: imap.gmail.com:993
- key: SMTP_HOST
  value: smtp.gmail.com:587
```

**Outlook**:
```yaml
- key: IMAP_HOST
  value: outlook.office365.com:993
- key: SMTP_HOST
  value: smtp.office365.com:587
```

## Security Considerations

- Change default DES_KEY in production
- Use environment variables for sensitive data
- Enable 2FA for admin access
- Regular security updates
- Monitor logs for suspicious activity

## Support

For issues:
1. Check Render.com documentation
2. Review Roundcube documentation
3. Check application logs
4. Contact your mail server provider for mail-related issues

## Updates

To update:
1. Push changes to your repository
2. Render will automatically redeploy
3. Database migrations will run automatically if needed

---

Your Roundcube webmail with the beautiful purple theme is now ready for deployment on Render.com!

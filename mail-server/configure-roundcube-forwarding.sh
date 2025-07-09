#!/bin/bash

# Roundcube Configuration Script for Admin Forwarding Setup
# This script configures Roundcube to work with the admin forwarding mail server

set -e

DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.${DOMAIN}"
ADMIN_EMAIL="admin@${DOMAIN}"
ROUNDCUBE_CONFIG="../config/config.inc.php"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Configuring Roundcube for admin forwarding setup${NC}"
echo ""

# Check if Roundcube config exists
if [ ! -f "$ROUNDCUBE_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Roundcube config not found at $ROUNDCUBE_CONFIG${NC}"
    echo -e "${BLUE}Creating new Roundcube configuration...${NC}"
    
    # Create config directory if it doesn't exist
    mkdir -p "../config"
    
    # Generate a secure DES key
    DES_KEY=$(openssl rand -base64 24)
    
    # Create Roundcube configuration
    cat > "$ROUNDCUBE_CONFIG" << EOF
<?php

/*
 +-----------------------------------------------------------------------+
 | Roundcube Webmail Configuration for BDG Software                     |
 | Mail Server with Admin Forwarding                                    |
 +-----------------------------------------------------------------------+
*/

\$config = [];

// Database connection - update with your database credentials
\$config['db_dsnw'] = 'mysql://roundcube:your_password@localhost/roundcube';

// Mail server configuration
\$config['imap_host'] = array(
    'ssl://${MAIL_DOMAIN}:993' => 'BDG Software Mail (SSL)',
    '${MAIL_DOMAIN}:143' => 'BDG Software Mail (STARTTLS)',
);

\$config['smtp_host'] = 'tls://${MAIL_DOMAIN}:587';
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['smtp_auth_type'] = 'LOGIN';

// Application settings
\$config['product_name'] = 'BDG Software Mail';
\$config['support_url'] = 'https://support.bdgsoftware.com';
\$config['des_key'] = '${DES_KEY}';

// Security settings
\$config['force_https'] = false;  // Set to true in production
\$config['login_rate_limit'] = 3;
\$config['login_rate_limit_window'] = 300;
\$config['session_lifetime'] = 60;
\$config['ip_check'] = true;
\$config['referer_check'] = true;

// Mail domain and forwarding settings
\$config['mail_domain'] = '${DOMAIN}';
\$config['max_message_size'] = '50MB';

// UI settings
\$config['skin'] = 'elastic';
\$config['htmleditor'] = 1;
\$config['prettydate'] = true;
\$config['date_format'] = 'Y-m-d';
\$config['time_format'] = 'H:i';
\$config['timezone'] = 'auto';
\$config['language'] = 'en_US';

// Performance settings
\$config['enable_caching'] = true;
\$config['message_cache_lifetime'] = '10d';
\$config['messages_cache_threshold'] = 50;

// Plugins for enhanced functionality
\$config['plugins'] = array(
    'archive',
    'zipdownload',
    'attachment_reminder',
    'emoticons',
    'hide_blockquote',
    'identicon',
    'newmail_notifier',
    'vcard_attachments',
    'password',
    'managesieve',
);

// Default identity settings
\$config['identity_default'] = array(
    'name' => '%n',
    'email' => '%u',
    'reply-to' => '%u',
    'signature' => "Sent with BDG Software Mail\\nhttps://bdgsoftware.com"
);

// Admin forwarding notification (custom setting)
\$config['admin_forwarding_enabled'] = true;
\$config['admin_email'] = '${ADMIN_EMAIL}';

// Logging
\$config['log_driver'] = 'file';
\$config['log_level'] = 1;
\$config['log_logins'] = true;

// Disable installer for security
\$config['enable_installer'] = false;
EOF

    echo -e "${GREEN}✅ Roundcube configuration created${NC}"
else
    echo -e "${GREEN}✅ Roundcube configuration found${NC}"
fi

# Create a custom plugin for admin forwarding awareness
echo -e "${BLUE}🔧 Creating admin forwarding awareness plugin...${NC}"

PLUGIN_DIR="../plugins/admin_forwarding"
mkdir -p "$PLUGIN_DIR"

# Create plugin main file
cat > "$PLUGIN_DIR/admin_forwarding.php" << 'EOF'
<?php

/**
 * Admin Forwarding Awareness Plugin
 * 
 * This plugin adds awareness that all emails are forwarded to admin
 * and provides admin-specific features for BDG Software mail system
 */

class admin_forwarding extends rcube_plugin
{
    public $task = 'mail|settings';
    
    private $admin_email = 'admin@bdgsoftware.com';
    
    function init()
    {
        $this->add_hook('render_page', array($this, 'render_page'));
        $this->add_hook('message_compose', array($this, 'message_compose'));
        $this->add_hook('login_after', array($this, 'login_after'));
        
        // Add admin forwarding info to settings
        $this->add_hook('preferences_sections_list', array($this, 'prefs_sections'));
        $this->add_hook('preferences_list', array($this, 'prefs_list'));
        
        $this->include_stylesheet('admin_forwarding.css');
    }
    
    function render_page($args)
    {
        $rcmail = rcmail::get_instance();
        
        // Add admin forwarding notice to mail view
        if ($args['template'] == 'mail') {
            $notice = html::div(array('class' => 'admin-forwarding-notice'),
                html::span(array('class' => 'notice-icon'), '📧') . ' ' .
                'Note: All emails sent to @bdgsoftware.com addresses are forwarded to the admin account for monitoring and management.'
            );
            
            $args['content'] = str_replace('</body>', $notice . '</body>', $args['content']);
        }
        
        return $args;
    }
    
    function message_compose($args)
    {
        $rcmail = rcmail::get_instance();
        
        // Add forwarding notice when composing emails
        if ($args['mode'] == 'compose') {
            $rcmail->output->show_message(
                'Reminder: All emails sent to @bdgsoftware.com addresses are forwarded to admin@bdgsoftware.com',
                'notice'
            );
        }
        
        return $args;
    }
    
    function login_after($args)
    {
        $rcmail = rcmail::get_instance();
        
        // Show admin forwarding status on login
        if ($rcmail->user->get_username() == $this->admin_email) {
            $rcmail->output->show_message(
                'Admin Account: You receive all emails sent to @bdgsoftware.com addresses',
                'confirmation'
            );
        } else {
            $rcmail->output->show_message(
                'Note: Emails to this account are also forwarded to admin@bdgsoftware.com',
                'notice'
            );
        }
        
        return $args;
    }
    
    function prefs_sections($args)
    {
        $args['list']['admin_forwarding'] = array(
            'id' => 'admin_forwarding',
            'section' => 'Admin Forwarding'
        );
        
        return $args;
    }
    
    function prefs_list($args)
    {
        if ($args['section'] == 'admin_forwarding') {
            $args['blocks']['forwarding'] = array(
                'name' => 'Email Forwarding Status',
                'options' => array(
                    'forwarding_status' => array(
                        'title' => 'Forwarding Status',
                        'content' => html::div(array('class' => 'forwarding-info'),
                            html::p(array(), 'All emails sent to @bdgsoftware.com addresses are automatically forwarded to:') .
                            html::p(array('class' => 'admin-email'), $this->admin_email) .
                            html::p(array(), 'This ensures centralized email management and monitoring.')
                        )
                    )
                )
            );
        }
        
        return $args;
    }
}
EOF

# Create plugin CSS
cat > "$PLUGIN_DIR/admin_forwarding.css" << 'EOF'
.admin-forwarding-notice {
    background-color: #e3f2fd;
    border: 1px solid #2196f3;
    border-radius: 4px;
    padding: 10px;
    margin: 10px;
    color: #1976d2;
    font-size: 14px;
}

.notice-icon {
    font-size: 16px;
    margin-right: 5px;
}

.forwarding-info {
    background-color: #f5f5f5;
    padding: 15px;
    border-radius: 4px;
    border-left: 4px solid #4caf50;
}

.admin-email {
    font-family: monospace;
    font-size: 16px;
    font-weight: bold;
    color: #2e7d32;
    background-color: #e8f5e8;
    padding: 5px 10px;
    border-radius: 4px;
    display: inline-block;
}
EOF

# Create plugin composer file
cat > "$PLUGIN_DIR/composer.json" << 'EOF'
{
    "name": "bdgsoftware/admin_forwarding",
    "description": "Admin forwarding awareness plugin for BDG Software mail system",
    "type": "roundcube-plugin",
    "keywords": ["mail", "forwarding", "admin"],
    "homepage": "https://bdgsoftware.com",
    "license": "MIT",
    "authors": [
        {
            "name": "BDG Software",
            "email": "admin@bdgsoftware.com"
        }
    ],
    "require": {
        "php": ">=7.0",
        "roundcube/framework": ">=1.4.0"
    }
}
EOF

echo -e "${GREEN}✅ Admin forwarding plugin created${NC}"

# Update Roundcube config to include the new plugin
echo -e "${BLUE}🔧 Adding plugin to Roundcube configuration...${NC}"

# Check if plugin is already in config
if grep -q "admin_forwarding" "$ROUNDCUBE_CONFIG"; then
    echo -e "${YELLOW}⚠️  Plugin already configured${NC}"
else
    # Add plugin to plugins array
    sed -i "/plugins.*array(/a\\    'admin_forwarding'," "$ROUNDCUBE_CONFIG"
    echo -e "${GREEN}✅ Plugin added to configuration${NC}"
fi

# Create setup verification script
echo -e "${BLUE}🔧 Creating setup verification script...${NC}"

cat > "./verify-forwarding-setup.sh" << 'EOF'
#!/bin/bash

# Verify Admin Forwarding Setup
set -e

DOMAIN="bdgsoftware.com"
ADMIN_EMAIL="admin@${DOMAIN}"

echo "🔍 Verifying admin forwarding setup..."
echo ""

# Check if mail server is running
echo "📊 Checking mail server status..."
if docker-compose ps | grep -q "mailserver.*Up"; then
    echo "✅ Mail server is running"
else
    echo "❌ Mail server is not running"
    echo "   Run: docker-compose up -d mailserver"
    exit 1
fi

# Check virtual alias configuration
echo ""
echo "📋 Checking virtual alias configuration..."
if [ -f "./docker-data/dms/config/postfix-virtual.cf" ]; then
    echo "✅ Virtual alias file exists"
    echo "📧 Current forwarding rules:"
    grep -v "^#" "./docker-data/dms/config/postfix-virtual.cf" | grep -v "^$" | while read line; do
        echo "   $line"
    done
else
    echo "❌ Virtual alias file not found"
    echo "   Run: ./setup-admin-forwarding.sh"
fi

# Check if admin account exists
echo ""
echo "👤 Checking admin account..."
if docker-compose exec mailserver setup email list | grep -q "$ADMIN_EMAIL"; then
    echo "✅ Admin account exists: $ADMIN_EMAIL"
else
    echo "❌ Admin account not found: $ADMIN_EMAIL"
    echo "   Run: ./setup-email-accounts-with-forwarding.sh"
fi

# Check postfix configuration
echo ""
echo "⚙️  Checking postfix configuration..."
if docker-compose exec mailserver postconf virtual_alias_maps | grep -q "virtual"; then
    echo "✅ Virtual alias maps configured"
else
    echo "❌ Virtual alias maps not configured"
    echo "   Run: ./setup-admin-forwarding.sh"
fi

# Test email connectivity
echo ""
echo "🔌 Testing email connectivity..."
if docker-compose exec mailserver ss -tlnp | grep -q ":587"; then
    echo "✅ SMTP port 587 is open"
else
    echo "❌ SMTP port 587 is not accessible"
fi

if docker-compose exec mailserver ss -tlnp | grep -q ":993"; then
    echo "✅ IMAP port 993 is open"
else
    echo "❌ IMAP port 993 is not accessible"
fi

# Check Roundcube configuration
echo ""
echo "🌐 Checking Roundcube configuration..."
if [ -f "../config/config.inc.php" ]; then
    echo "✅ Roundcube configuration exists"
    
    if grep -q "admin_forwarding" "../config/config.inc.php"; then
        echo "✅ Admin forwarding plugin configured"
    else
        echo "❌ Admin forwarding plugin not configured"
        echo "   Run: ./configure-roundcube-forwarding.sh"
    fi
else
    echo "❌ Roundcube configuration not found"
    echo "   Run: ./configure-roundcube-forwarding.sh"
fi

echo ""
echo "🎉 Setup verification complete!"
echo ""
echo "📧 To test forwarding:"
echo "   1. Send email to any address @${DOMAIN}"
echo "   2. Check ${ADMIN_EMAIL} inbox"
echo "   3. Verify forwarded email appears"
echo ""
echo "🛠️  Management commands:"
echo "   • ./manage-forwarding.sh list-forwards"
echo "   • ./manage-forwarding.sh create-user email@${DOMAIN} password"
echo "   • docker-compose logs mailserver"
EOF

chmod +x "./verify-forwarding-setup.sh"

echo ""
echo -e "${GREEN}🎉 Roundcube forwarding configuration complete!${NC}"
echo ""
echo -e "${BLUE}📋 What was configured:${NC}"
echo "• Roundcube configuration for BDG Software mail server"
echo "• Admin forwarding awareness plugin"
echo "• Custom styling for forwarding notices"
echo "• Setup verification script"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Update database credentials in: $ROUNDCUBE_CONFIG"
echo "2. Run: ./verify-forwarding-setup.sh"
echo "3. Test Roundcube login with admin account"
echo "4. Verify forwarding notices appear in web interface"
echo ""
echo -e "${BLUE}🌐 Admin Features:${NC}"
echo "• Admin account shows centralized email status"
echo "• Forwarding notices in compose window"
echo "• Settings page shows forwarding configuration"
echo "• Visual indicators for forwarded emails"
echo ""
echo -e "${YELLOW}⚠️  Remember to:${NC}"
echo "• Update database password in Roundcube config"
echo "• Test all email forwarding functionality"
echo "• Configure SSL certificates for production"

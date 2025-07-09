<?php

/**
 * Account Registration Plugin Configuration
 */

// Enable or disable registration
$config['account_registration']['enabled'] = true;

// Domain for email accounts
$config['account_registration']['domain'] = 'bdgsoftware.cloud';

// Admin email address
$config['account_registration']['admin_email'] = 'admin@bdgsoftware.cloud';

// Require email verification
$config['account_registration']['require_verification'] = true;

// Minimum password length
$config['account_registration']['min_password_length'] = 8;

// Maximum accounts per IP address (per 24 hours)
$config['account_registration']['max_accounts_per_ip'] = 3;

// Forbidden usernames (reserved)
$config['account_registration']['forbidden_usernames'] = array(
    'admin', 'postmaster', 'hostmaster', 'webmaster', 'abuse', 
    'root', 'noreply', 'no-reply', 'mail', 'spam', 'virus',
    'info', 'support', 'sales', 'contact', 'billing'
);

// Allowed domains for registration
$config['account_registration']['allowed_domains'] = array('bdgsoftware.cloud');

// Forward new registrations to admin
$config['account_registration']['forward_to_admin'] = true;

// Use CAPTCHA for registration
$config['account_registration']['use_captcha'] = true;
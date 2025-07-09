<?php

$labels = array();
$labels['account_management'] = 'Account Management';
$labels['register_for_account'] = 'Register for a new email account';
$labels['create_email_account'] = 'Create Your BDG Software Email Account';
$labels['registration_intro'] = 'Fill out the form below to create your own @bdgsoftware.cloud email address.';
$labels['username'] = 'Username';
$labels['name'] = 'Full Name';
$labels['recovery_email'] = 'Recovery Email';
$labels['password'] = 'Password';
$labels['confirm_password'] = 'Confirm Password';
$labels['captcha'] = 'Security Check';
$labels['captcha_math'] = 'What is %d + %d?';
$labels['accept_terms'] = 'I accept the';
$labels['terms_of_service'] = 'Terms of Service';
$labels['register'] = 'Register';
$labels['back_to_login'] = 'Back to Login';
$labels['registered_accounts'] = 'Registered Accounts';
$labels['add_new_account'] = 'Add New Account';
$labels['add_account'] = 'Add Account';
$labels['email'] = 'Email Address';
$labels['created'] = 'Created';
$labels['status'] = 'Status';
$labels['actions'] = 'Actions';
$labels['edit'] = 'Edit';
$labels['delete'] = 'Delete';
$labels['active'] = 'Active';
$labels['inactive'] = 'Inactive';
$labels['pending'] = 'Pending Verification';
$labels['no_accounts'] = 'No accounts found';
$labels['confirm_delete'] = 'Are you sure you want to delete this account?';

$messages = array();
$messages['registration_disabled'] = 'Account registration is currently disabled.';
$messages['already_logged_in'] = 'You are already logged in.';
$messages['username_required'] = 'Username is required.';
$messages['username_invalid'] = 'Username contains invalid characters. Use only letters, numbers, dots, underscores, hyphens, and plus signs.';
$messages['username_forbidden'] = 'This username is reserved and cannot be used.';
$messages['domain_not_allowed'] = 'This domain is not allowed for registration.';
$messages['name_required'] = 'Full name is required.';
$messages['email_required'] = 'Recovery email is required.';
$messages['email_invalid'] = 'Please enter a valid email address.';
$messages['password_required'] = 'Password is required.';
$messages['password_too_short'] = 'Password must be at least %d characters long.';
$messages['passwords_not_match'] = 'Passwords do not match.';
$messages['terms_required'] = 'You must accept the Terms of Service.';
$messages['captcha_invalid'] = 'Security check failed. Please try again.';
$messages['account_exists'] = 'An account with this email address already exists.';
$messages['max_accounts_reached'] = 'You have reached the maximum number of accounts (%d) that can be created from your IP address.';
$messages['registration_success'] = 'Your account has been created successfully. You can now log in.';
$messages['registration_success_verify'] = 'Your account has been created. Please check your recovery email for verification instructions.';
$messages['registration_failed'] = 'Account creation failed. Please try again later.';
$messages['invalid_verification'] = 'Invalid verification link.';
$messages['verification_success'] = 'Your account has been verified successfully. You can now log in.';
$messages['verification_failed'] = 'Account verification failed. Please contact support.';
$messages['access_denied'] = 'Access denied. You do not have permission to view this page.';
$messages['account_created'] = 'Account created successfully.';
$messages['account_create_failed'] = 'Failed to create account.';
$messages['account_deleted'] = 'Account deleted successfully.';
$messages['account_delete_failed'] = 'Failed to delete account.';
$messages['invalid_request'] = 'Invalid request.';
$messages['password_weak'] = 'Weak password';
$messages['password_medium'] = 'Medium strength password';
$messages['password_strong'] = 'Strong password';

// Email subjects
$messages['verify_account_subject'] = 'Verify your BDG Software email account';
$messages['new_registration_subject'] = 'New account registration: %s';

// Email bodies
$messages['verify_account_body'] = "Hello,\n\nThank you for registering for a BDG Software email account. To complete your registration, please click on the link below to verify your email address:";
$messages['verify_account_footer'] = "\n\nIf you did not register for this account, please ignore this email.\n\nBest regards,\nBDG Software Team";
$messages['new_registration_body'] = "A new account has been registered:\n\nEmail: %s\nName: %s\nRecovery Email: %s\nIP Address: %s\n\nThis is an automated notification.";
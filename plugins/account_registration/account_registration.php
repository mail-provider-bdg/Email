<?php

/**
 * Account Registration Plugin for Roundcube
 *
 * Allows users to register for new email accounts on bdgsoftware.cloud
 *
 * @version 1.0
 * @author BDG Software
 * @license GPL-3.0+
 */

class account_registration extends rcube_plugin
{
    public $task = 'login|settings|mail';
    private $rc;
    private $config;

    /**
     * Plugin initialization
     */
    function init()
    {
        $this->rc = rcube::get_instance();
        $this->load_config();

        // Add registration link to login page
        $this->add_hook('template_object_loginform', array($this, 'add_register_link'));
        
        // Register actions
        $this->register_action('plugin.account_registration', array($this, 'registration_page'));
        $this->register_action('plugin.account_registration.register', array($this, 'register_account'));
        $this->register_action('plugin.account_registration.verify', array($this, 'verify_account'));
        
        // Add admin interface
        if ($this->rc->task == 'settings') {
            $this->add_hook('settings_actions', array($this, 'settings_actions'));
            $this->register_action('plugin.account_registration.admin', array($this, 'admin_page'));
            $this->register_action('plugin.account_registration.admin_action', array($this, 'admin_action'));
        }
        
        // Include CSS
        $this->include_stylesheet($this->local_skin_path() . '/account_registration.css');
    }

    /**
     * Load plugin configuration
     */
    private function load_config()
    {
        $this->load_config('config.inc.php');
        $this->config = $this->rc->config->get('account_registration', array(
            'enabled' => true,
            'domain' => 'bdgsoftware.cloud',
            'admin_email' => 'admin@bdgsoftware.cloud',
            'require_verification' => true,
            'min_password_length' => 8,
            'max_accounts_per_ip' => 3,
            'forbidden_usernames' => array('admin', 'postmaster', 'hostmaster', 'webmaster', 'abuse', 'root'),
            'allowed_domains' => array('bdgsoftware.cloud'),
            'forward_to_admin' => true,
        ));
    }

    /**
     * Add registration link to login form
     */
    function add_register_link($content)
    {
        if ($this->config['enabled']) {
            $register_link = html::a(
                array(
                    'href' => $this->rc->url(array('_task' => 'login', '_action' => 'plugin.account_registration')),
                    'class' => 'registration-link',
                ),
                $this->gettext('register_for_account')
            );
            
            $content['content'] = str_replace('</form>', '</form><div class="register-section">' . $register_link . '</div>', $content['content']);
        }
        
        return $content;
    }

    /**
     * Display registration form
     */
    function registration_page()
    {
        $this->register_localization();
        
        // Check if registration is enabled
        if (!$this->config['enabled']) {
            $this->rc->output->show_message($this->gettext('registration_disabled'), 'error');
            $this->rc->output->send('login');
            return;
        }
        
        // Check if user is already logged in
        if ($this->rc->user->ID) {
            $this->rc->output->show_message($this->gettext('already_logged_in'), 'notice');
            $this->rc->output->redirect(array('_task' => 'mail'));
            return;
        }
        
        // Add CSS and JS
        $this->include_script('account_registration.js');
        
        // Set page title
        $this->rc->output->set_pagetitle($this->gettext('registration_form'));
        
        // Build the registration form
        $this->rc->output->add_handler('register_form', array($this, 'registration_form'));
        
        // Display the template
        $this->rc->output->send('account_registration.registration');
    }

    /**
     * Generate registration form
     */
    function registration_form()
    {
        $domain_select = '';
        if (count($this->config['allowed_domains']) > 1) {
            $domain_select = new html_select(array('name' => '_domain', 'id' => 'reg-domain'));
            foreach ($this->config['allowed_domains'] as $domain) {
                $domain_select->add($domain, $domain);
            }
            $domain_select = $domain_select->show($this->config['allowed_domains'][0]);
        } else {
            $domain = $this->config['allowed_domains'][0];
            $domain_select = html::span(array('class' => 'domain-name'), '@' . $domain) .
                             html::tag('input', array('type' => 'hidden', 'name' => '_domain', 'value' => $domain));
        }
        
        // CAPTCHA integration
        $captcha = '';
        if ($this->config['use_captcha']) {
            // Simple math captcha as fallback
            $num1 = rand(1, 10);
            $num2 = rand(1, 10);
            $sum = $num1 + $num2;
            $this->rc->session->set('captcha_sum', $sum);
            
            $captcha = html::div(array('class' => 'captcha-container'),
                html::label(array('for' => 'captcha'), $this->gettext('captcha')) .
                html::div(array('class' => 'captcha-question'), 
                    sprintf($this->gettext('captcha_math'), $num1, $num2)
                ) .
                html::tag('input', array(
                    'type' => 'text',
                    'name' => '_captcha',
                    'id' => 'captcha',
                    'size' => 5,
                    'required' => true
                ))
            );
        }
        
        // Build the form
        $form = html::div(array('class' => 'registration-form'),
            html::div(array('class' => 'form-section'),
                html::div(array('class' => 'header'),
                    html::tag('h2', null, $this->gettext('create_email_account'))
                ) .
                html::p(null, $this->gettext('registration_intro'))
            ) .
            html::div(array('class' => 'form-section'),
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'reg-username'), $this->gettext('username')) .
                    html::tag('input', array(
                        'type' => 'text',
                        'name' => '_username',
                        'id' => 'reg-username',
                        'size' => 30,
                        'required' => true,
                        'autocomplete' => 'off'
                    )) .
                    $domain_select
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'reg-name'), $this->gettext('name')) .
                    html::tag('input', array(
                        'type' => 'text',
                        'name' => '_name',
                        'id' => 'reg-name',
                        'size' => 30,
                        'required' => true
                    ))
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'reg-email'), $this->gettext('recovery_email')) .
                    html::tag('input', array(
                        'type' => 'email',
                        'name' => '_email',
                        'id' => 'reg-email',
                        'size' => 30,
                        'required' => true
                    ))
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'reg-password'), $this->gettext('password')) .
                    html::tag('input', array(
                        'type' => 'password',
                        'name' => '_password',
                        'id' => 'reg-password',
                        'size' => 30,
                        'required' => true,
                        'autocomplete' => 'new-password'
                    ))
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'reg-password-confirm'), $this->gettext('confirm_password')) .
                    html::tag('input', array(
                        'type' => 'password',
                        'name' => '_password_confirm',
                        'id' => 'reg-password-confirm',
                        'size' => 30,
                        'required' => true,
                        'autocomplete' => 'new-password'
                    ))
                ) .
                $captcha .
                html::div(array('class' => 'row'),
                    html::div(array('class' => 'terms-checkbox'),
                        html::tag('input', array(
                            'type' => 'checkbox',
                            'name' => '_terms',
                            'id' => 'reg-terms',
                            'value' => '1',
                            'required' => true
                        )) .
                        html::label(array('for' => 'reg-terms'), 
                            $this->gettext('accept_terms') . ' ' .
                            html::a(array('href' => '#', 'target' => '_blank', 'class' => 'terms-link'), 
                                $this->gettext('terms_of_service')
                            )
                        )
                    )
                )
            ) .
            html::div(array('class' => 'form-section formbuttons'),
                html::tag('button', array(
                    'type' => 'submit',
                    'class' => 'submit button mainaction',
                    'id' => 'register-button'
                ), $this->gettext('register'))
            )
        );
        
        $form = html::tag('form', array(
            'action' => $this->rc->url(array('_action' => 'plugin.account_registration.register')),
            'method' => 'post',
            'id' => 'registration-form'
        ), $form);
        
        return $form;
    }

    /**
     * Process registration form submission
     */
    function register_account()
    {
        $this->register_localization();
        
        // Check if registration is enabled
        if (!$this->config['enabled']) {
            $this->rc->output->show_message($this->gettext('registration_disabled'), 'error');
            $this->rc->output->redirect(array('_task' => 'login'));
            return;
        }
        
        // Get form data
        $username = rcube_utils::get_input_value('_username', rcube_utils::INPUT_POST);
        $domain = rcube_utils::get_input_value('_domain', rcube_utils::INPUT_POST);
        $name = rcube_utils::get_input_value('_name', rcube_utils::INPUT_POST);
        $email = rcube_utils::get_input_value('_email', rcube_utils::INPUT_POST);
        $password = rcube_utils::get_input_value('_password', rcube_utils::INPUT_POST);
        $password_confirm = rcube_utils::get_input_value('_password_confirm', rcube_utils::INPUT_POST);
        $terms = rcube_utils::get_input_value('_terms', rcube_utils::INPUT_POST);
        $captcha = rcube_utils::get_input_value('_captcha', rcube_utils::INPUT_POST);
        
        // Validate form data
        $errors = array();
        
        // Check username
        if (empty($username)) {
            $errors[] = $this->gettext('username_required');
        } elseif (!preg_match('/^[a-zA-Z0-9._%+-]+$/', $username)) {
            $errors[] = $this->gettext('username_invalid');
        } elseif (in_array(strtolower($username), $this->config['forbidden_usernames'])) {
            $errors[] = $this->gettext('username_forbidden');
        }
        
        // Check domain
        if (!in_array($domain, $this->config['allowed_domains'])) {
            $errors[] = $this->gettext('domain_not_allowed');
        }
        
        // Check name
        if (empty($name)) {
            $errors[] = $this->gettext('name_required');
        }
        
        // Check email
        if (empty($email)) {
            $errors[] = $this->gettext('email_required');
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = $this->gettext('email_invalid');
        }
        
        // Check password
        if (empty($password)) {
            $errors[] = $this->gettext('password_required');
        } elseif (strlen($password) < $this->config['min_password_length']) {
            $errors[] = sprintf($this->gettext('password_too_short'), $this->config['min_password_length']);
        } elseif ($password != $password_confirm) {
            $errors[] = $this->gettext('passwords_not_match');
        }
        
        // Check terms
        if (empty($terms)) {
            $errors[] = $this->gettext('terms_required');
        }
        
        // Check CAPTCHA
        if ($this->config['use_captcha']) {
            $captcha_sum = $this->rc->session->get('captcha_sum');
            if (empty($captcha) || intval($captcha) != $captcha_sum) {
                $errors[] = $this->gettext('captcha_invalid');
            }
        }
        
        // Check if account already exists
        $email_address = $username . '@' . $domain;
        if ($this->account_exists($email_address)) {
            $errors[] = $this->gettext('account_exists');
        }
        
        // Check IP rate limiting
        $ip = $_SERVER['REMOTE_ADDR'];
        if ($this->get_accounts_count_by_ip($ip) >= $this->config['max_accounts_per_ip']) {
            $errors[] = sprintf($this->gettext('max_accounts_reached'), $this->config['max_accounts_per_ip']);
        }
        
        // If there are errors, show them and redirect back to the form
        if (!empty($errors)) {
            foreach ($errors as $error) {
                $this->rc->output->show_message($error, 'error');
            }
            $this->rc->output->redirect(array('_task' => 'login', '_action' => 'plugin.account_registration'));
            return;
        }
        
        // Generate verification token if required
        $verification_token = '';
        if ($this->config['require_verification']) {
            $verification_token = md5(uniqid(rand(), true));
        }
        
        // Create the account
        $success = $this->create_account($username, $domain, $password, $name, $email, $verification_token);
        
        if ($success) {
            // Send verification email if required
            if ($this->config['require_verification']) {
                $this->send_verification_email($email_address, $email, $name, $verification_token);
                $this->rc->output->show_message($this->gettext('registration_success_verify'), 'confirmation');
            } else {
                $this->rc->output->show_message($this->gettext('registration_success'), 'confirmation');
            }
            
            // Forward email to admin if configured
            if ($this->config['forward_to_admin']) {
                $this->forward_to_admin($email_address, $name, $email);
            }
            
            // Redirect to login page
            $this->rc->output->redirect(array('_task' => 'login'));
        } else {
            $this->rc->output->show_message($this->gettext('registration_failed'), 'error');
            $this->rc->output->redirect(array('_task' => 'login', '_action' => 'plugin.account_registration'));
        }
    }

    /**
     * Verify account with token
     */
    function verify_account()
    {
        $this->register_localization();
        
        $token = rcube_utils::get_input_value('_token', rcube_utils::INPUT_GET);
        $email = rcube_utils::get_input_value('_email', rcube_utils::INPUT_GET);
        
        if (empty($token) || empty($email)) {
            $this->rc->output->show_message($this->gettext('invalid_verification'), 'error');
            $this->rc->output->redirect(array('_task' => 'login'));
            return;
        }
        
        // Verify the token
        $success = $this->verify_account_token($email, $token);
        
        if ($success) {
            $this->rc->output->show_message($this->gettext('verification_success'), 'confirmation');
        } else {
            $this->rc->output->show_message($this->gettext('verification_failed'), 'error');
        }
        
        $this->rc->output->redirect(array('_task' => 'login'));
    }

    /**
     * Add admin settings section
     */
    function settings_actions($actions)
    {
        // Only show to admin users
        if ($this->is_admin_user()) {
            $actions['account_registration'] = array(
                'type' => 'link',
                'label' => 'account_registration.account_management',
                'href' => $this->rc->url(array('_action' => 'plugin.account_registration.admin')),
            );
        }
        
        return $actions;
    }

    /**
     * Display admin page
     */
    function admin_page()
    {
        $this->register_localization();
        
        // Check if user is admin
        if (!$this->is_admin_user()) {
            $this->rc->output->show_message($this->gettext('access_denied'), 'error');
            $this->rc->output->redirect(array('_task' => 'settings'));
            return;
        }
        
        // Add CSS and JS
        $this->include_script('account_registration_admin.js');
        
        // Set page title
        $this->rc->output->set_pagetitle($this->gettext('account_management'));
        
        // Add content handler
        $this->rc->output->add_handler('admin_form', array($this, 'admin_form'));
        
        // Display the template
        $this->rc->output->send('account_registration.admin');
    }

    /**
     * Generate admin form
     */
    function admin_form()
    {
        // Get all accounts
        $accounts = $this->get_all_accounts();
        
        // Build the accounts table
        $table = html::tag('table', array('class' => 'accounts-table'),
            html::tag('thead',
                html::tag('tr',
                    html::tag('th', null, $this->gettext('email')) .
                    html::tag('th', null, $this->gettext('name')) .
                    html::tag('th', null, $this->gettext('recovery_email')) .
                    html::tag('th', null, $this->gettext('created')) .
                    html::tag('th', null, $this->gettext('status')) .
                    html::tag('th', null, $this->gettext('actions'))
                )
            ) .
            html::tag('tbody', null,
                $this->build_accounts_rows($accounts)
            )
        );
        
        // Build the form for adding new accounts
        $add_form = html::div(array('class' => 'add-account-form'),
            html::tag('h3', null, $this->gettext('add_new_account')) .
            html::div(array('class' => 'form-section'),
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'new-username'), $this->gettext('username')) .
                    html::tag('input', array(
                        'type' => 'text',
                        'name' => '_username',
                        'id' => 'new-username',
                        'size' => 30,
                        'required' => true
                    )) .
                    html::span(array('class' => 'domain-name'), '@' . $this->config['domain'])
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'new-name'), $this->gettext('name')) .
                    html::tag('input', array(
                        'type' => 'text',
                        'name' => '_name',
                        'id' => 'new-name',
                        'size' => 30,
                        'required' => true
                    ))
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'new-email'), $this->gettext('recovery_email')) .
                    html::tag('input', array(
                        'type' => 'email',
                        'name' => '_email',
                        'id' => 'new-email',
                        'size' => 30,
                        'required' => true
                    ))
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'new-password'), $this->gettext('password')) .
                    html::tag('input', array(
                        'type' => 'password',
                        'name' => '_password',
                        'id' => 'new-password',
                        'size' => 30,
                        'required' => true
                    ))
                ) .
                html::div(array('class' => 'row'),
                    html::label(array('for' => 'new-status'), $this->gettext('status')) .
                    html::tag('select', array(
                        'name' => '_status',
                        'id' => 'new-status'
                    ),
                        html::tag('option', array('value' => 'active'), $this->gettext('active')) .
                        html::tag('option', array('value' => 'inactive'), $this->gettext('inactive'))
                    )
                ) .
                html::div(array('class' => 'formbuttons'),
                    html::tag('button', array(
                        'type' => 'submit',
                        'class' => 'button mainaction',
                        'id' => 'add-account-button'
                    ), $this->gettext('add_account'))
                )
            )
        );
        
        $add_form = html::tag('form', array(
            'action' => $this->rc->url(array('_action' => 'plugin.account_registration.admin_action', '_act' => 'add')),
            'method' => 'post',
            'id' => 'add-account-form'
        ), $add_form);
        
        // Build the complete admin interface
        $output = html::div(array('class' => 'account-management'),
            html::div(array('class' => 'accounts-list'),
                html::tag('h2', null, $this->gettext('registered_accounts')) .
                $table
            ) .
            html::div(array('class' => 'account-actions'),
                $add_form
            )
        );
        
        return $output;
    }

    /**
     * Build table rows for accounts
     */
    private function build_accounts_rows($accounts)
    {
        $rows = '';
        
        if (empty($accounts)) {
            return html::tag('tr', array('class' => 'nodata'),
                html::tag('td', array('colspan' => 6), $this->gettext('no_accounts'))
            );
        }
        
        foreach ($accounts as $account) {
            $status_class = $account['status'] == 'active' ? 'active' : 'inactive';
            
            $actions = html::a(array(
                'href' => $this->rc->url(array(
                    '_action' => 'plugin.account_registration.admin_action',
                    '_act' => 'edit',
                    '_email' => $account['email']
                )),
                'class' => 'button edit',
                'title' => $this->gettext('edit')
            ), $this->gettext('edit')) . ' ' .
            html::a(array(
                'href' => $this->rc->url(array(
                    '_action' => 'plugin.account_registration.admin_action',
                    '_act' => 'delete',
                    '_email' => $account['email']
                )),
                'class' => 'button delete',
                'title' => $this->gettext('delete'),
                'onclick' => 'return confirm("' . $this->gettext('confirm_delete') . '")'
            ), $this->gettext('delete'));
            
            $rows .= html::tag('tr',
                html::tag('td', null, $account['email']) .
                html::tag('td', null, $account['name']) .
                html::tag('td', null, $account['recovery_email']) .
                html::tag('td', null, $account['created']) .
                html::tag('td', array('class' => 'status ' . $status_class), $this->gettext($account['status'])) .
                html::tag('td', array('class' => 'actions'), $actions)
            );
        }
        
        return $rows;
    }

    /**
     * Process admin actions
     */
    function admin_action()
    {
        $this->register_localization();
        
        // Check if user is admin
        if (!$this->is_admin_user()) {
            $this->rc->output->show_message($this->gettext('access_denied'), 'error');
            $this->rc->output->redirect(array('_task' => 'settings'));
            return;
        }
        
        $action = rcube_utils::get_input_value('_act', rcube_utils::INPUT_GET);
        
        switch ($action) {
            case 'add':
                $this->admin_add_account();
                break;
                
            case 'edit':
                $this->admin_edit_account();
                break;
                
            case 'delete':
                $this->admin_delete_account();
                break;
                
            default:
                $this->rc->output->redirect(array('_action' => 'plugin.account_registration.admin'));
                break;
        }
    }

    /**
     * Add a new account from admin interface
     */
    private function admin_add_account()
    {
        // Get form data
        $username = rcube_utils::get_input_value('_username', rcube_utils::INPUT_POST);
        $name = rcube_utils::get_input_value('_name', rcube_utils::INPUT_POST);
        $email = rcube_utils::get_input_value('_email', rcube_utils::INPUT_POST);
        $password = rcube_utils::get_input_value('_password', rcube_utils::INPUT_POST);
        $status = rcube_utils::get_input_value('_status', rcube_utils::INPUT_POST);
        
        // Validate form data
        $errors = array();
        
        // Check username
        if (empty($username)) {
            $errors[] = $this->gettext('username_required');
        } elseif (!preg_match('/^[a-zA-Z0-9._%+-]+$/', $username)) {
            $errors[] = $this->gettext('username_invalid');
        }
        
        // Check name
        if (empty($name)) {
            $errors[] = $this->gettext('name_required');
        }
        
        // Check email
        if (empty($email)) {
            $errors[] = $this->gettext('email_required');
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = $this->gettext('email_invalid');
        }
        
        // Check password
        if (empty($password)) {
            $errors[] = $this->gettext('password_required');
        } elseif (strlen($password) < $this->config['min_password_length']) {
            $errors[] = sprintf($this->gettext('password_too_short'), $this->config['min_password_length']);
        }
        
        // Check if account already exists
        $email_address = $username . '@' . $this->config['domain'];
        if ($this->account_exists($email_address)) {
            $errors[] = $this->gettext('account_exists');
        }
        
        // If there are errors, show them and redirect back to the form
        if (!empty($errors)) {
            foreach ($errors as $error) {
                $this->rc->output->show_message($error, 'error');
            }
            $this->rc->output->redirect(array('_action' => 'plugin.account_registration.admin'));
            return;
        }
        
        // Create the account
        $success = $this->create_account($username, $this->config['domain'], $password, $name, $email, '', $status);
        
        if ($success) {
            $this->rc->output->show_message($this->gettext('account_created'), 'confirmation');
        } else {
            $this->rc->output->show_message($this->gettext('account_create_failed'), 'error');
        }
        
        $this->rc->output->redirect(array('_action' => 'plugin.account_registration.admin'));
    }

    /**
     * Edit an existing account from admin interface
     */
    private function admin_edit_account()
    {
        // TODO: Implement account editing
        $this->rc->output->redirect(array('_action' => 'plugin.account_registration.admin'));
    }

    /**
     * Delete an account from admin interface
     */
    private function admin_delete_account()
    {
        $email = rcube_utils::get_input_value('_email', rcube_utils::INPUT_GET);
        
        if (empty($email)) {
            $this->rc->output->show_message($this->gettext('invalid_request'), 'error');
            $this->rc->output->redirect(array('_action' => 'plugin.account_registration.admin'));
            return;
        }
        
        $success = $this->delete_account($email);
        
        if ($success) {
            $this->rc->output->show_message($this->gettext('account_deleted'), 'confirmation');
        } else {
            $this->rc->output->show_message($this->gettext('account_delete_failed'), 'error');
        }
        
        $this->rc->output->redirect(array('_action' => 'plugin.account_registration.admin'));
    }

    /**
     * Check if an account exists
     */
    private function account_exists($email)
    {
        // Implementation depends on mail server setup
        // For native installation, we can check the database
        
        // Extract username and domain
        list($username, $domain) = explode('@', $email);
        
        // Check if we're using the native mail server
        if (file_exists('/workspace/Email/mail-server-native/manage-users.sh')) {
            // Execute the script to check if user exists
            $output = shell_exec('cd /workspace/Email/mail-server-native && ./manage-users.sh exists ' . escapeshellarg($email) . ' 2>&1');
            return strpos($output, 'exists') !== false;
        }
        
        // For Docker installation, we need to use the Docker API
        if (file_exists('/workspace/Email/mail-server/docker-mail-management.sh')) {
            $output = shell_exec('cd /workspace/Email/mail-server && ./docker-mail-management.sh check-user ' . escapeshellarg($email) . ' 2>&1');
            return strpos($output, 'exists') !== false;
        }
        
        // Fallback to database check
        $db = $this->get_db_connection();
        if ($db) {
            $query = "SELECT COUNT(*) FROM virtual_users WHERE email = ?";
            $stmt = $db->prepare($query);
            $stmt->execute(array($email));
            $count = $stmt->fetchColumn();
            return $count > 0;
        }
        
        // If we can't determine, assume it exists to be safe
        return true;
    }

    /**
     * Create a new email account
     */
    private function create_account($username, $domain, $password, $name, $recovery_email, $verification_token = '', $status = 'inactive')
    {
        $email = $username . '@' . $domain;
        
        // Store account in database
        $db = $this->get_db_connection();
        if (!$db) {
            return false;
        }
        
        // Begin transaction
        $db->beginTransaction();
        
        try {
            // Insert into registration database
            $query = "INSERT INTO account_registrations (email, name, recovery_email, verification_token, status, created, ip) 
                      VALUES (?, ?, ?, ?, ?, NOW(), ?)";
            $stmt = $db->prepare($query);
            $stmt->execute(array(
                $email,
                $name,
                $recovery_email,
                $verification_token,
                empty($verification_token) ? 'active' : 'pending',
                $_SERVER['REMOTE_ADDR']
            ));
            
            // Create the actual email account
            $success = false;
            
            // Check if we're using the native mail server
            if (file_exists('/workspace/Email/mail-server-native/manage-users.sh')) {
                // Execute the script to add user
                $output = shell_exec('cd /workspace/Email/mail-server-native && ./manage-users.sh add ' . 
                                    escapeshellarg($email) . ' ' . 
                                    escapeshellarg($password) . ' 2>&1');
                $success = strpos($output, 'successfully') !== false;
            }
            
            // For Docker installation, we need to use the Docker API
            elseif (file_exists('/workspace/Email/mail-server/docker-mail-management.sh')) {
                $output = shell_exec('cd /workspace/Email/mail-server && ./docker-mail-management.sh add-user ' . 
                                    escapeshellarg($email) . ' ' . 
                                    escapeshellarg($password) . ' 2>&1');
                $success = strpos($output, 'successfully') !== false;
            }
            
            // If account creation failed, rollback and return false
            if (!$success) {
                $db->rollBack();
                return false;
            }
            
            // Commit transaction
            $db->commit();
            return true;
        } 
        catch (Exception $e) {
            $db->rollBack();
            rcube::write_log('errors', 'Account registration plugin: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Delete an email account
     */
    private function delete_account($email)
    {
        // Delete from database
        $db = $this->get_db_connection();
        if (!$db) {
            return false;
        }
        
        // Begin transaction
        $db->beginTransaction();
        
        try {
            // Delete from registration database
            $query = "DELETE FROM account_registrations WHERE email = ?";
            $stmt = $db->prepare($query);
            $stmt->execute(array($email));
            
            // Delete the actual email account
            $success = false;
            
            // Check if we're using the native mail server
            if (file_exists('/workspace/Email/mail-server-native/manage-users.sh')) {
                // Execute the script to delete user
                $output = shell_exec('cd /workspace/Email/mail-server-native && ./manage-users.sh delete ' . 
                                    escapeshellarg($email) . ' 2>&1');
                $success = strpos($output, 'successfully') !== false;
            }
            
            // For Docker installation, we need to use the Docker API
            elseif (file_exists('/workspace/Email/mail-server/docker-mail-management.sh')) {
                $output = shell_exec('cd /workspace/Email/mail-server && ./docker-mail-management.sh delete-user ' . 
                                    escapeshellarg($email) . ' 2>&1');
                $success = strpos($output, 'successfully') !== false;
            }
            
            // If account deletion failed, rollback and return false
            if (!$success) {
                $db->rollBack();
                return false;
            }
            
            // Commit transaction
            $db->commit();
            return true;
        } 
        catch (Exception $e) {
            $db->rollBack();
            rcube::write_log('errors', 'Account registration plugin: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Verify account with token
     */
    private function verify_account_token($email, $token)
    {
        $db = $this->get_db_connection();
        if (!$db) {
            return false;
        }
        
        // Check if token is valid
        $query = "SELECT * FROM account_registrations WHERE email = ? AND verification_token = ?";
        $stmt = $db->prepare($query);
        $stmt->execute(array($email, $token));
        $account = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$account) {
            return false;
        }
        
        // Update account status
        $query = "UPDATE account_registrations SET status = 'active', verification_token = '', verified = NOW() WHERE email = ?";
        $stmt = $db->prepare($query);
        $stmt->execute(array($email));
        
        return true;
    }

    /**
     * Get number of accounts created from an IP
     */
    private function get_accounts_count_by_ip($ip)
    {
        $db = $this->get_db_connection();
        if (!$db) {
            return 0;
        }
        
        $query = "SELECT COUNT(*) FROM account_registrations WHERE ip = ? AND created > DATE_SUB(NOW(), INTERVAL 24 HOUR)";
        $stmt = $db->prepare($query);
        $stmt->execute(array($ip));
        
        return $stmt->fetchColumn();
    }

    /**
     * Get all registered accounts
     */
    private function get_all_accounts()
    {
        $db = $this->get_db_connection();
        if (!$db) {
            return array();
        }
        
        $query = "SELECT * FROM account_registrations ORDER BY created DESC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Send verification email
     */
    private function send_verification_email($email, $recovery_email, $name, $token)
    {
        $subject = $this->gettext('verify_account_subject');
        
        $verify_url = $this->rc->url(array(
            '_action' => 'plugin.account_registration.verify',
            '_token' => $token,
            '_email' => $email
        ), true, true);
        
        $body = $this->gettext('verify_account_body') . "\n\n";
        $body .= $verify_url . "\n\n";
        $body .= $this->gettext('verify_account_footer');
        
        $headers = array(
            'From' => $this->config['admin_email'],
            'To' => $recovery_email,
            'Subject' => $subject,
        );
        
        $mail = new Mail_mime("\r\n");
        $mail->setTXTBody($body);
        
        $message = $mail->getMessage();
        $headers = $mail->headers($headers);
        
        $smtp = new rcube_smtp();
        return $smtp->send_mail($recovery_email, $this->config['admin_email'], $headers, $message);
    }

    /**
     * Forward registration to admin
     */
    private function forward_to_admin($email, $name, $recovery_email)
    {
        $subject = sprintf($this->gettext('new_registration_subject'), $email);
        
        $body = sprintf($this->gettext('new_registration_body'), $email, $name, $recovery_email, $_SERVER['REMOTE_ADDR']);
        
        $headers = array(
            'From' => $this->config['admin_email'],
            'To' => $this->config['admin_email'],
            'Subject' => $subject,
        );
        
        $mail = new Mail_mime("\r\n");
        $mail->setTXTBody($body);
        
        $message = $mail->getMessage();
        $headers = $mail->headers($headers);
        
        $smtp = new rcube_smtp();
        return $smtp->send_mail($this->config['admin_email'], $this->config['admin_email'], $headers, $message);
    }

    /**
     * Check if current user is admin
     */
    private function is_admin_user()
    {
        $username = $this->rc->user->get_username();
        return $username == 'admin@' . $this->config['domain'] || $username == $this->config['admin_email'];
    }

    /**
     * Get database connection
     */
    private function get_db_connection()
    {
        static $db;
        
        if ($db) {
            return $db;
        }
        
        // Use Roundcube's database connection
        $db = $this->rc->get_dbh();
        
        // Check if our table exists, if not create it
        $this->create_database_tables();
        
        return $db;
    }

    /**
     * Create necessary database tables
     */
    private function create_database_tables()
    {
        $db = $this->rc->get_dbh();
        
        // Check if table exists
        $table_exists = false;
        $tables = $db->list_tables();
        
        foreach ($tables as $table) {
            if ($table == 'account_registrations') {
                $table_exists = true;
                break;
            }
        }
        
        if (!$table_exists) {
            // Create the table
            $db->exec("CREATE TABLE account_registrations (
                id INT NOT NULL AUTO_INCREMENT,
                email VARCHAR(255) NOT NULL,
                name VARCHAR(255) NOT NULL,
                recovery_email VARCHAR(255) NOT NULL,
                verification_token VARCHAR(255) DEFAULT '',
                status ENUM('pending', 'active', 'inactive') DEFAULT 'pending',
                created DATETIME NOT NULL,
                verified DATETIME DEFAULT NULL,
                ip VARCHAR(45) NOT NULL,
                PRIMARY KEY (id),
                UNIQUE KEY (email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
        }
    }

    /**
     * Register localization strings
     */
    private function register_localization()
    {
        $this->add_texts('localization/', false);
    }
}
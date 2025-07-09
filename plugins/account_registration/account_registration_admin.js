/**
 * Account Registration Plugin Admin JavaScript
 */

$(document).ready(function() {
    // Password generation
    $('#generate-password').on('click', function(e) {
        e.preventDefault();
        
        // Generate a random password
        var length = 12;
        var charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+';
        var password = '';
        
        for (var i = 0; i < length; i++) {
            var randomChar = charset.charAt(Math.floor(Math.random() * charset.length));
            password += randomChar;
        }
        
        // Set the password field
        $('#new-password').val(password);
    });
    
    // Username validation
    $('#new-username').on('keyup', function() {
        var username = $(this).val();
        
        // Only allow letters, numbers, dots, underscores, hyphens, and plus signs
        if (username !== '' && !username.match(/^[a-zA-Z0-9._%+-]+$/)) {
            if ($('#username-error').length === 0) {
                $(this).after('<div id="username-error" class="input-error">' + 
                              rcmail.gettext('username_invalid', 'account_registration') + 
                              '</div>');
            }
            $(this).addClass('error');
        } else {
            $('#username-error').remove();
            $(this).removeClass('error');
        }
    });
    
    // Form validation before submission
    $('#add-account-form').on('submit', function(e) {
        var username = $('#new-username').val();
        var name = $('#new-name').val();
        var email = $('#new-email').val();
        var password = $('#new-password').val();
        
        var errors = [];
        
        // Check username
        if (username === '' || !username.match(/^[a-zA-Z0-9._%+-]+$/)) {
            errors.push(rcmail.gettext('username_invalid', 'account_registration'));
            $('#new-username').addClass('error');
        }
        
        // Check name
        if (name === '') {
            errors.push(rcmail.gettext('name_required', 'account_registration'));
            $('#new-name').addClass('error');
        }
        
        // Check email
        if (email === '' || !email.match(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)) {
            errors.push(rcmail.gettext('email_invalid', 'account_registration'));
            $('#new-email').addClass('error');
        }
        
        // Check password
        if (password === '') {
            errors.push(rcmail.gettext('password_required', 'account_registration'));
            $('#new-password').addClass('error');
        }
        
        // If there are errors, prevent form submission
        if (errors.length > 0) {
            e.preventDefault();
            
            // Display errors
            errors.forEach(function(error) {
                rcmail.display_message(error, 'error');
            });
            
            return false;
        }
    });
});
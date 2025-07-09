/**
 * Account Registration Plugin JavaScript
 */

$(document).ready(function() {
    // Password strength validation
    $('#reg-password').on('keyup', function() {
        var password = $(this).val();
        var strength = 0;
        
        // Check length
        if (password.length >= 8) {
            strength += 1;
        }
        
        // Check for lowercase letters
        if (password.match(/[a-z]/)) {
            strength += 1;
        }
        
        // Check for uppercase letters
        if (password.match(/[A-Z]/)) {
            strength += 1;
        }
        
        // Check for numbers
        if (password.match(/[0-9]/)) {
            strength += 1;
        }
        
        // Check for special characters
        if (password.match(/[^a-zA-Z0-9]/)) {
            strength += 1;
        }
        
        // Update strength indicator
        var strengthClass = '';
        var strengthText = '';
        
        switch (strength) {
            case 0:
            case 1:
                strengthClass = 'weak';
                strengthText = rcmail.gettext('password_weak', 'account_registration');
                break;
            case 2:
            case 3:
                strengthClass = 'medium';
                strengthText = rcmail.gettext('password_medium', 'account_registration');
                break;
            case 4:
            case 5:
                strengthClass = 'strong';
                strengthText = rcmail.gettext('password_strong', 'account_registration');
                break;
        }
        
        // Add strength indicator if it doesn't exist
        if ($('#password-strength').length === 0) {
            $(this).after('<div id="password-strength" class="password-strength"></div>');
        }
        
        // Update strength indicator
        $('#password-strength')
            .attr('class', 'password-strength ' + strengthClass)
            .text(strengthText);
    });
    
    // Password confirmation validation
    $('#reg-password-confirm').on('keyup', function() {
        var password = $('#reg-password').val();
        var confirm = $(this).val();
        
        if (confirm === '') {
            $(this).removeClass('match nomatch');
            return;
        }
        
        if (password === confirm) {
            $(this).removeClass('nomatch').addClass('match');
        } else {
            $(this).removeClass('match').addClass('nomatch');
        }
    });
    
    // Username validation
    $('#reg-username').on('keyup', function() {
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
    $('#registration-form').on('submit', function(e) {
        var password = $('#reg-password').val();
        var confirm = $('#reg-password-confirm').val();
        var username = $('#reg-username').val();
        
        var errors = [];
        
        // Check username
        if (username === '' || !username.match(/^[a-zA-Z0-9._%+-]+$/)) {
            errors.push(rcmail.gettext('username_invalid', 'account_registration'));
            $('#reg-username').addClass('error');
        }
        
        // Check password
        if (password === '') {
            errors.push(rcmail.gettext('password_required', 'account_registration'));
            $('#reg-password').addClass('error');
        }
        
        // Check password confirmation
        if (password !== confirm) {
            errors.push(rcmail.gettext('passwords_not_match', 'account_registration'));
            $('#reg-password-confirm').addClass('error');
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
require 'bcrypt'
require_relative 'database-model.rb'
require_relative '../user-authentication.rb'

def getErrorMessage params

    error_msg = ""

    email = params[:email]
    email_conf = params[:email_validation]
    if ! isValidEmail email
        error_msg += "Please enter valid email <br>"
    elsif email != email_conf
        error_msg+= "Emails don't match <br>"
    end

    password = params[:password]
    password_conf = params[:password_validation]
    if ! isValidPassword password
        error_msg += "Please enter valid password <br>"
    elsif password != password_conf
         error_msg += "Passwords don't match<br>"
    end

    return error_msg

end

def isValidEmail email
    return !email.nil? && (email.index URI::MailTo::EMAIL_REGEXP)
end

def isValidPassword password
    return (!password.nil?) && (password.length>=8) && (password.index /\d/ ) && (password.index /[#?!@$%^&*-_]/) && (!password.index /\s/)
end

def newUser displayName, email, password
    return true
end
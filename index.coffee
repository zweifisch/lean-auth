{setup} = require "./schema"
{compare, hash, merge, gentoken} = require "./utils"
errors = require "./errors"
{getClient} = require "./ldap"

exports.init = (url, ldap)->
    db = setup url
    User = db.model 'user'
    Role = db.model 'role'
    PasswordResetRequest = db.model 'password_reset_request'
    EmailVerification = db.model 'email_verification'

    ldap = getClient ldap if ldap?.url

    User: User
    Role: Role
    PasswordResetRequest: PasswordResetRequest
    errors: errors

    createUser: ({name, email, password, more})->
        hash(password).then (hashed)->
            User.create
                name: name
                email: email
                password: hashed

    # err | user
    login: (criteria, password)->
        User.findOne(where: criteria).then (user)->
            throw new errors.UserNotFoundError "login failed" unless user
            throw new errors.UserDisabledError "login failed" unless user.enabled
            compare(password, user.password).then (matched)->
                throw new errors.PasswordMismatchError "login failed" unless matched
                user

    updatePassword: updatePassword = (user, password)->
        hash(password).then (hashed)->
            user.set "password", hashed
            user.save()

    getPasswordResetToken: (email)->
        User.findOne(where: email: email).then (user)->
            if user
                gentoken(32).then (token)->
                    PasswordResetRequest.create
                        userId: user.id
                        token: token
                    .then ->
                        user: user
                        token: token
            else
                throw new errors.UserNotExitError "user not found"

    # err | user
    resetPasswordWithToken: (token, newpasswd)->
        PasswordResetRequest.findOne(where: token: token).then (request)->
            throw new errors.InvalidTokenError "token invalid" unless request
            User.findById(request.userId).then (user)->
                throw new errors.UserNotExitError "user not found" unless user
                updatePassword user, newpasswd

    resetPassword: (user, oldpasswd, newpasswd)->
        compare(oldpasswd, user.password).then (matched)->
            throw new errors.PasswordMismatchError "passwd mismatch" unless matched
            updatePassword user, newpasswd

    # err | {token}
    getEmailVerificationToken: (user)->
        gentoken(32).then (token)->
            EmailVerification.create
                userId: user.id
                token: token

    # err | user
    verifyEmailWithToken: (token)->
        EmailVerification.findOne(where: token: token).then (request)->
            throw new errors.InvalidTokenError "token invalid" unless request
            User.findById(request.userId).then (user)->
                throw new errors.UserNotExitError "user not found" unless user
                user.set "verified", yes
                user.save()

    disableUser: (user)->
        user.set "enabled", no
        user.save()

    enableUser: (user)->
        user.set "enabled", yes
        user.save()

    grant: (user, role)->
        user.addRole role

    revoke: (user, role)->
        user.removeRole role

    createRole: ({name, description})->
        Role.create
            name: name
            description: description

    findUser: (criteria)->
        User.findOne where: criteria

    deleteUser: (criteria)->
        User.destroy where: criteria, limit: 1

    sync: db.sync.bind db

    ldapLogin: (username, passwd)->
        throw Error "ldap url not provided" unless ldap
        ldap(username, passwd).then (user)->
            User.upsert(user).then -> user

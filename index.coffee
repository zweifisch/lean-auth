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
    Resource = db.model 'resource'
    Action = db.model 'action'

    ldap = getClient ldap if ldap?.url

    id2model = (model)-> (maybeId)->
        if "object" is typeof maybeId then Promise.resolve maybeId else model.findById maybeId

    id2user = id2model User
    id2role = id2model Role
    id2resource = id2model Resource

    destroyById = (model)-> (id)->
        model.destroy
            where:
                id: id
            limit: 1

    User: User
    Role: Role
    Resource: Resource
    Action: Action

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
            throw new errors.UserNotFoundError "login failed, user not found" unless user
            throw new errors.UserDisabledError "login failed, user disabled" unless user.enabled
            compare(password, user.password).then (matched)->
                throw new errors.PasswordMismatchError "login failed, password mismatch" unless matched
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
        id2user(user).then (user)->
            user.set "enabled", no
            user.save()

    enableUser: (user)->
        id2user(user).then (user)->
            user.set "enabled", yes
            user.save()

    grant: (user, role)->
        Promise.all([
            id2user(user)
            id2role(role)
        ]).then ([user, role])->
            user.addRole role

    revoke: (user, role)->
        Promise.all([
            id2user(user)
            id2role(role)
        ]).then ([user, role])->
            user.removeRole role

    setRoles: (user, roles)->
        id2user(user).then (user)->
            user.setRoles roles

    listRole: (criteria)->
        Role.findAll criteria

    createRole: ({name, description})->
        Role.create
            name: name
            description: description

    findUser: (criteria)->
        User.findOne where: criteria

    listUser: (criteria)->
        User.findAll criteria

    getUser: (id)->
        User.findById id, include: Role

    countUser: (criteria)->
        User.count where: criteria

    updateUser: (id, data)->
        User.update data,
            where:
                id: id
            # fields: ["extra", "email"]
            limit: 1

    updateRole: (id, data)->
        Role.update data,
            where:
                id: id
            fields: ["description", "name"]
            limit: 1

    sync: db.sync.bind db

    ldapLogin: (username, passwd)->
        throw Error "ldap url not provided" unless ldap
        ldap(username, passwd).then (user)->
            User.upsert(user).then -> user

    getPolicy: ->
        Resource.findAll
            include: [
                model: Action
                include: Role
            ]
        .then (resources)->
            ret = {}
            for res in resources
                actions = {}
                for action in res.actions
                    actions[action.name] = action.roles.map (x)-> x.name
                ret[res.name] = actions
            ret

    getResource: (id)->
        Resource.findById id, include: [model: Action, include: Role]

    createAction: (resource, {name, description})->
        id2resource(resource).then (resource)->
            resource.createAction
                name: name
                description: description

    deleteRole: destroyById Role
    deleteUser: destroyById User
    deleteResource: destroyById Resource

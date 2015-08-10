{setup} = require "./db"
{compare, hash, merge, gentoken} = require "./utils"
errors = require "./errors"
{getClient} = require "./ldap"
_ = require "underscore"


id2model = (model)-> (maybeId)->
    if "object" is typeof maybeId then Promise.resolve maybeId else model.findById maybeId

destroyById = (model)-> (id)->
    model.destroy
        where:
            id: id
        limit: 1


class Auth

    constructor: ({database, prefix, ldap})->
        @db = setup database, prefix or "auth"

        @User = @db.model 'user'
        @Role = @db.model 'role'
        @PasswordResetRequest = @db.model 'passwordResetRequest'
        @EmailVerification = @db.model 'emailVerification'
        @Resource = @db.model 'resource'
        @Action = @db.model 'action'

        @ldap = getClient ldap if ldap?.url

        @id2user = id2model @User
        @id2role = id2model @Role
        @id2resource = id2model @Resource
        @id2action = id2model @Action

        @deleteRole = destroyById @Role
        @deleteUser = destroyById @User
        @deleteResource = destroyById @Resource

    createUser: ({name, email, password, more})->
        hash(password).then (hashed)=>
            @User.create
                name: name
                email: email
                password: hashed

    # err | user
    login: (criteria, password)->
        @User.findOne({where: criteria, include: @Role}).then (user)->
            throw new errors.UserNotFoundError "login failed, user not found" unless user
            throw new errors.UserDisabledError "login failed, user disabled" unless user.enabled
            compare(password, user.password).then (matched)->
                throw new errors.PasswordMismatchError "login failed, password mismatch" unless matched
                user

    updatePassword: (user, password)->
        hash(password).then (hashed)->
            user.set "password", hashed
            user.save()

    getPasswordResetToken: (email)->
        @User.findOne(where: email: email).then (user)->
            if user
                gentoken(32).then (token)->
                    user.createPasswordResetRequest token: token
            else
                throw new errors.UserNotExistError "user not found"

    # err | user
    resetPasswordWithToken: (token, newpasswd)->
        @PasswordResetRequest.findOne(where: token: token).then (request)=>
            throw new errors.InvalidTokenError "token invalid" unless request
            request.getUser().then (user)=>
                throw new errors.UserNotExistError "user not found" unless user
                @updatePassword user, newpasswd

    resetPassword: (user, oldpasswd, newpasswd)->
        compare(oldpasswd, user.password).then (matched)=>
            throw new errors.PasswordMismatchError "passwd mismatch" unless matched
            @updatePassword user, newpasswd

    # err | {token}
    getEmailVerificationToken: (user)->
        gentoken(32).then (token)->
            user.createEmailVerification token: token

    # err | user
    verifyEmailWithToken: (token)->
        @EmailVerification.findOne(where: token: token).then (request)->
            throw new errors.InvalidTokenError "token invalid" unless request
            request.getUser().then (user)->
                throw new errors.UserNotExistError "user not found" unless user
                user.set "verified", yes
                user.save()

    disableUser: (user)->
        @id2user(user).then (user)->
            user.set "enabled", no
            user.save()

    enableUser: (user)->
        @id2user(user).then (user)->
            user.set "enabled", yes
            user.save()

    grant: (user, role)->
        Promise.all([
            @id2user(user)
            @id2role(role)
        ]).then ([user, role])->
            user.addRole role

    revoke: (user, role)->
        Promise.all([
            @id2user(user)
            @id2role(role)
        ]).then ([user, role])->
            user.removeRole role

    setRoles: (user, roles)->
        @id2user(user).then (user)->
            user.setRoles roles

    listRole: (criteria)->
        @Role.findAll criteria

    getRole: (id)->
        @Role.findById id

    createRole: ({name, description})->
        @Role.create
            name: name
            description: description

    ensureRole: (name)->
        @Role.upsert(name: name).then =>
            @Role.findOne where: name: name

    findUser: (criteria)->
        @User.findOne where: criteria

    listUser: (criteria)->
        @User.findAll criteria

    getUser: (id)->
        @User.findById id, include: @Role

    countUser: (criteria)->
        @User.count where: criteria

    updateUser: (id, data)->
        @User.update data,
            where:
                id: id
            # fields: ["extra", "email"]
            limit: 1

    updateRole: (id, data)->
        @Role.update data,
            where:
                id: id
            fields: ["description", "name"]
            limit: 1

    ldapLogin: (username, passwd)->
        throw Error "ldap url not provided" unless @ldap
        @ldap(username, passwd).then (user)->
            User.upsert(user).then -> user

    getPolicy: ->
        @Resource.findAll
            include: [
                model: @Action
                include: @Role
            ]
        .then (resources)->
            ret = {}
            for res in resources
                actions = {}
                for action in res.actions
                    actions[action.name] = action.roles.map (x)-> x.name
                ret[res.name] = actions
            ret

    getAction: (resource, action)->
        @Action.findOne
            where:
                name: action
            include:
                model: @Resource
                where:
                    name: resource

    # err | bool
    addRule: (role, action, resource)->
        Promise.all([
            @getAction resource, action
            @Role.findOne where: name: role
        ]).then ([action_, role])->
            if action_ and role
                action_.addRole(role).then (count)-> count is 1
            else
                throw new Error "action #{resource}:#{action} not found"

    # err | bool
    removeRule: (role, action, resource)->
        Promise.all([
            @getAction resource, action
            @Role.findOne where: name: role
        ]).then ([action_, role])->
            if action_ and role
                action_.removeRole(role).then (count)-> count is 1
            else
                throw new Error "action #{resource}:#{action} not found"

    getResource: (id)->
        @Resource.findById id, include: [model: @Action, include: @Role]

    createAction: (resource, {name, description})->
        id = resource?.id or resource
        @Action.upsert
            resource_id: id
            name: name
            description: description

    updateAction: (action, {name, description, roles})->
        @id2action(action).then (action)->
            action.set "name", name
            action.set "description", description
            action.save()
        .then (action)->
            if roles
                action.setRoles roles

    importPolicy: (policy)->
        rolesP = Promise.all (_.unique _.flatten _.values(policy).map _.values).map (role)=>
            @Role.upsert name: role

        actionsP = Promise.all _.pairs(policy).map ([res, actions])=>
            @Resource.upsert(name: res).then =>
                @Resource.findOne where: name: res
            .then (resource)=>
                Promise.all Object.keys(actions).map (action)=>
                    @createAction resource, name: action

        flatten = (list)-> _.flatten list, yes

        rules = flatten _.pairs(policy).map ([res, actions])->
            flatten _.pairs(actions).map ([action, roles])->
                roles.map (role)-> [role, action, res]

        Promise.all([rolesP, actionsP]).then =>
            Promise.all rules.map (rule)=> @addRule rule...

    sync: (args...)-> @db.sync args...


module.exports = 
    errors: errors
    Auth: Auth

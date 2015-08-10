chai = require 'chai'
promised = require "chai-as-promised"
{Auth, errors} = require "./src"

chai.use promised
chai.should()

auth = new Auth database: process.env.DATABASE_URL or "sqlite://:memory:"

describe "user", ->

    describe "user", ->

        it "should sync schema", ->
            auth.sync(force: yes).should.be.fulfilled

        it "should hash password", ->
            auth.createUser
                name: "test"
                email: "test@test.com"
                password: "pass"
            .then ->
                auth.login(name:"test", "pass").then (user)->
                    user.name
                .should.eventually.equal "test"

        it "should change password", ->
            auth.createUser
                name: "test2"
                email: "test@test2.com"
                password: "pass"
            .then (user)->
                auth.updatePassword(user, "pass2").then ->
                    Promise.all([
                        auth.login(name:"test2", "pass2").then(-> yes)
                        auth.login(name:"test2", "pass").catch(-> no)
                    ]).should.eventually.deep.equal [yes, no]

        it "should not login when user not exists", ->
            auth.login(name:"test0", "pass0").should.be.rejected

        it "should not login when user is disabled", ->
            auth.createUser
                name: "test6"
                email: "test@test6.com"
                password: "pass6"
            .then (user)->
                auth.disableUser(user).then ->
                    auth.login(name:"test6", "pass6").should.be.rejected

        it "should delete user", ->
            auth.createUser
                name: "test3"
                email: "test@test3.com"
                password: "pass"
            .then (user)->
                auth.deleteUser(user.id).then ->
                    auth.findUser(name:"test3").then (user)->
                        auth.findUser(name:"test3").should.eventually.equal null

        it "should create token for password reset", ->
            auth.createUser
                name: "test4"
                email: "test@test4.com"
                password: "pass4"
            .then (user)->
                auth.getPasswordResetToken("test@test4.com").then ({token})->
                    user.getPasswordResetRequests
                        where: token: token
                    .then (requests)->
                        requests.length
                    .should.eventually.equal 1

        it "should reset password with valid token", ->
            auth.createUser
                name: "test7"
                email: "test@test7.com"
                password: "pass7"
            .then (user)->
                auth.getPasswordResetToken("test@test7.com").then (token)->
                    Promise.all([
                        auth.resetPasswordWithToken(token.token, "test77").then(->
                            auth.login(name: "test7", "test77").then -> true
                        ),
                        auth.resetPasswordWithToken("invalid token", "test78").catch (err)->
                            err instanceof errors.InvalidTokenError
                    ]).should.eventually.deep.equal [yes, yes]

        it "should compare old password when reset a password", ->
            auth.createUser
                name: "test5"
                email: "test@test5.com"
                password: "pass5"
            .then (user)->
                Promise.all([
                    auth.resetPassword(user, "pass5", "pass55").then((user)-> yes),
                    auth.resetPassword(user, "passs", "pass55").catch (err)->
                        err instanceof errors.PasswordMismatchError
                ]).should.eventually.deep.equal [yes, yes]

        it "should verify email with token", ->
            auth.createUser
                name: "test8"
                email: "test@test8.com"
                password: "pass8"
            .then (user)->
                auth.getEmailVerificationToken(user).then (token)->
                    Promise.all([
                        auth.verifyEmailWithToken(token.token).then (user)-> user.verified
                        auth.resetPasswordWithToken("invalid token").catch (err)->
                            err instanceof errors.InvalidTokenError
                    ])
                    .should.eventually.deep.equal [yes, yes]

        it "should grant role", ->
            Promise.all([
                auth.createUser
                    name: "test9"
                    email: "test@test9.com"
                    password: "pass9"
                auth.createRole
                    name: "admin"
            ]).then ([user, role])->
                auth.grant(user, role).then ->
                    user.reload().then (user)->
                        user.getRoles()
                    .then (roles)->
                        roles.map ({name})-> name
                    .should.eventually.deep.equal ["admin"]

        it "should get role", ->
            Promise.all([
                auth.createUser
                    name: "test10"
                    email: "test@test10.com"
                    password: "pass10"
                auth.createRole
                    name: "operator"
            ]).then ([user, role])->
                auth.grant(user, role).then ->
                    auth.getUser(user.id).then (user)->
                        user.roles.map (x)-> x.name
                    .should.eventually.deep.equal ["operator"]

        it "should ensure role", ->
            auth.ensureRole("root").then (role)->
                role.name
            .should.eventually.equal "root"

    describe "policy", ->

        it "should fetch policy", ->

            resource = auth.Resource.create
                name: "article"

            editor = auth.Role.create
                name: "editor"

            subscriber = auth.Role.create
                name: "subscriber"

            Promise.all([resource, editor, subscriber]).then ([resource, editor, subscriber])->
                actions = ["create", "read", "update", "delete"].map (action)->
                    resource.createAction name: action

                Promise.all(actions).then ([c,r,u,d])->
                    Promise.all [
                        c.addRole(editor, allowed: yes)
                        r.addRoles([editor, subscriber], allowed: yes)
                        u.addRole(editor, allowed: yes)
                    ]
                .then ->
                    auth.getPolicy().should.eventually.deep.equal
                        article:
                            create: ["editor"]
                            read: ["editor", "subscriber"]
                            update: ["editor"]
                            delete: []

        it "should add rule", ->

            Promise.all([
                auth.Resource.create name: "thing"
                auth.Role.create name: "creator"
            ]).then ([thing])->
                thing.createAction name: "create"
            .then ->
                auth.addRule("creator", "create", "thing")
            .then ->
                auth.getPolicy().should.eventually.deep.equal
                    article:
                        create: ["editor"]
                        read: ["editor", "subscriber"]
                        update: ["editor"]
                        delete: []
                    thing:
                        create: ["creator"]

        it "should remove rule", ->

            auth.removeRule("editor", "read", "article").then ->

                auth.getPolicy().should.eventually.deep.equal
                    article:
                        create: ["editor"]
                        read: ["subscriber"]
                        update: ["editor"]
                        delete: []
                    thing:
                        create: ["creator"]

        it "should import policy", ->

            policy =
                article:
                    create: ["editor", "subscriber"]
                user:
                    manage: ["hr"]
                more:
                    action: ["role"]

            auth.importPolicy(policy).then ->
                auth.getPolicy().should.eventually.deep.equal
                    article:
                        create: ["editor", "subscriber"]
                        read: ["subscriber"]
                        update: ["editor"]
                        delete: []
                    thing:
                        create: ["creator"]
                    user:
                        manage: ["hr"]
                    more:
                        action: ["role"]

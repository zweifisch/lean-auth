chai = require 'chai'
promised = require "chai-as-promised"
{init} = require "./index"

chai.use promised
chai.should()

auth = {sync, createUser, login, User, errors} = init process.env.DATABASE
setup = sync force: yes

describe "user", ->

    describe "user", ->

        it "should hash password", ->
            create = ->
                createUser
                    name: "test"
                    email: "test@test.com"
                    password: "pass"
            setup.then(create).then ->
                login(name:"test", "pass").should.eventually.equal yes
                
        it "should change password", ->
            create = ->
                createUser
                    name: "test2"
                    email: "test@test2.com"
                    password: "pass"
            setup.then(create).then (user)->
                auth.updatePassword(user, "pass2").then ->
                    Promise.all([
                        login(name:"test2", "pass2"),
                        login(name:"test2", "pass")
                    ]).should.eventually.deep.equal [yes, no]

        it "should not login when user not exists", ->
            setup.then ->
                login(name:"test0", "pass0").should.eventually.equal no

        it "should not login when user is disabled", ->
            create = ->
                createUser
                    name: "test6"
                    email: "test@test6.com"
                    password: "pass6"
            setup.then(create).then (user)->
                auth.disableUser(user).then ->
                    login(name:"test6", "pass6").should.eventually.equal no

        it "should delete user", ->
            create = ->
                createUser
                    name: "test3"
                    email: "test@test3.com"
                    password: "pass"
            setup.then(create).then ->
                auth.deleteUser(name: "test3").then ->
                    auth.findUser(name:"test3").then (user)->
                        auth.findUser(name:"test3").should.eventually.equal null

        it "should create token for password reset", ->
            create = ->
                createUser
                    name: "test4"
                    email: "test@test4.com"
                    password: "pass4"
            setup.then(create).then (user)->
                auth.getPasswordResetToken("test@test4.com").then ({token})->
                    auth.PasswordResetRequest.findOne
                        where: userId: user.id
                    .then (request)-> request.token
                    .should.eventually.equal token

        it "should reset password with valid token", ->
            create = ->
                createUser
                    name: "test7"
                    email: "test@test7.com"
                    password: "pass7"
            setup.then(create).then (user)->
                auth.getPasswordResetToken("test@test7.com").then ({token})->
                    auth.PasswordResetRequest.findOne
                        where: userId: user.id
                    .then ({token})->
                        Promise.all([
                            auth.resetPasswordWithToken(token, "test77").then(->
                                login name: "test7", "test77"
                            ),
                            auth.resetPasswordWithToken("invalid token", "test78").catch (err)->
                                err instanceof errors.InvalidTokenError
                        ])
                    .should.eventually.deep.equal [yes, yes]

        it "should compare old password when reset a password", ->
            create = ->
                createUser
                    name: "test5"
                    email: "test@test5.com"
                    password: "pass5"
            setup.then(create).then (user)->
                Promise.all([
                    auth.resetPassword(user, "pass5", "pass55").then((user)-> yes),
                    auth.resetPassword(user, "passs", "pass55").catch (err)->
                        err instanceof errors.PasswordMismatchError
                ]).should.eventually.deep.equal [yes, yes]

        it "should verify email with token", ->
            create = ->
                createUser
                    name: "test8"
                    email: "test@test8.com"
                    password: "pass8"
            setup.then(create).then (user)->
                auth.getEmailVerificationToken(user).then ({token})->
                    Promise.all([
                        auth.verifyEmailWithToken(token).then (user)-> user.verified
                        auth.resetPasswordWithToken("invalid token").catch (err)->
                            err instanceof errors.InvalidTokenError
                    ])
                    .should.eventually.deep.equal [yes, yes]

        it "should grant role", ->
            create = -> Promise.all([
                createUser
                    name: "test9"
                    email: "test@test9.com"
                    password: "pass9"
                auth.createRole
                    name: "admin"
            ])
            setup.then(create).then ([user, role])->
                auth.grant(user, role).then ->
                    user.reload().then (user)->
                        user.getRoles()
                    .then (roles)->
                        roles.map ({name})-> name
                    .should.eventually.deep.equal ["admin"]

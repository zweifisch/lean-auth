chai = require 'chai'
promised = require "chai-as-promised"
{init} = require "./index"

chai.use promised
chai.should()

{sync, createUser, loginUser, User} = init process.env.DATABASE
setup = sync force: yes

describe "user", ->
    describe "create", ->

        create = ->
            createUser
                name: "test"
                email: "test@test.com"
                password: "pass"
        
        it "should hash password", ->
            setup.then(create).then ->
                loginUser(name:"test", "pass").should.eventually.equal yes
                

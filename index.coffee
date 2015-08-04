{setup} = require "./schema"
{compare, hash} = require "./utils"

# url = 'mysql://root:simple-passwd@127.0.0.1:3306/db9'

exports.init = (url)->
    db = setup url
    User = db.model 'user'
    Role = db.model 'role'

    User: User
    Role: Role

    createUser: ({name, email, password, more})->
        hash(password).then (hashed)->
            User.create
                name: name
                email: email
                password: hashed

    loginUser: (criteria, password)->
        User.findOne(criteria).then (user)->
            compare password, user.password

    sync: db.sync.bind db

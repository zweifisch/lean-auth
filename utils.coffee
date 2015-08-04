bcrypt = require 'bcrypt'

promisify = (f)-> 
    (args...)->
        new Promise (resolve, reject)->
            f args..., (err, result)->
                if err then reject err else resolve result

hash = promisify bcrypt.hash

exports.hash = (password)-> hash password, 10

exports.compare = promisify bcrypt.compare

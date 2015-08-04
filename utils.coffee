bcrypt = require 'bcrypt'
crypto = require 'crypto'

promisify = (f)-> 
    (args...)->
        new Promise (resolve, reject)->
            f args..., (err, result)->
                if err then reject err else resolve result

hash = promisify bcrypt.hash

exports.hash = (password)-> hash password, 10

exports.compare = promisify bcrypt.compare

exports.merge = (base, extra)->
    ret = {}
    for own key, val of base
        ret[key] = val
    for own key, val of extra
        ret[key] = val
    ret

randomBytes = promisify crypto.randomBytes

exports.gentoken = (bytes)->
    randomBytes(bytes).then (buf)-> buf.toString 'hex'

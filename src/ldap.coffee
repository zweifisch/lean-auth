ldap = require 'ldapjs'
{promisify} = require "./utils"

exports.getClient = ({url, uid, base})->
    client = ldap.createClient url: url
    uid or= "uid"

    bind = promisify client.bind.bind client

    search = promisify client.search.bind client

    (user, passwd)->

        bind("#{uid}=#{user},#{base}", passwd).then ->
            search base,
                filter: "(#{uid}=#{user})"
                scope: "sub"
                attributes: ["mail", "#{uid}"]
            .then (res)->
                new Promise (resolve, reject)->
                    result = null
                    res.on 'searchEntry', ({object})->
                        result =
                            email: object.mail
                            name: object[uid]
                    res.on 'end', -> resolve result
                    res.on 'error', reject

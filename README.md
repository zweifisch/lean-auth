# lean-auth

## features

- username/password login
- ldap login
- email verification
- password recovery
- role/permission management

## api

```
{Auth} = require("lean-auth");
var auth = new Auth({database: "mysql://user:passwd@localhost/db"});

auth.sync().then(function(){
    auth.createUser({
        name: name,
        email: email,
        password: password
    });
});

auth.login({name: name}, password);
```

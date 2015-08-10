# lean-auth

[![NPM Version][npm-image]][npm-url]
[![Build Status][travis-image]][travis-url]

## features

- username/password login
- ldap login
- email verification
- password recovery
- role/permission management

## api

```js
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

[npm-image]: https://img.shields.io/npm/v/lean-auth.svg?style=flat
[npm-url]: https://npmjs.org/package/lean-auth
[travis-image]: https://img.shields.io/travis/zweifisch/lean-auth.svg?style=flat
[travis-url]: https://travis-ci.org/zweifisch/lean-auth

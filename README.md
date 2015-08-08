
## features

- username/password login
- ldap login
- email verification
- password lost and fund
- role/permission management

## api

```
createUser({
    name: name,
    email: email,
    password: password
});
```

```
disable(user);
enable(user);
```

```
login({name: name}, password);
```

```
getEmailverificationToken(email);

verifyEmailWithToken(user);
```

```
updatePassword(user, newpassword);

resetPassword(user, oldpasswd, newpasswd);

getPasswordResetToken(token);

resetPasswordWithToken(email);
```

```
findUser({name: name});
```

```
grant(user, role);
revoke(user, role);
```

## ldap


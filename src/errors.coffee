
class PasswordMismatchError
    constructor:(@message)->

class UserNotExistError
    constructor:(@message)->

class InvalidTokenError
    constructor:(@message)->

class UserDisabledError
    constructor:(@message)->

class UserNotFoundError
    constructor:(@message)->

module.exports =
    PasswordMismatchError: PasswordMismatchError
    UserNotExistError: UserNotExistError
    InvalidTokenError: InvalidTokenError
    UserDisabledError: UserDisabledError
    UserNotFoundError: UserNotFoundError

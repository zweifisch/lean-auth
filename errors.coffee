
class PasswordMismatchError
    constructor:(@message)->

class UserNotExistError
    constructor:(@message)->

class InvalidTokenError
    constructor:(@message)->

module.exports =
    PasswordMismatchError: PasswordMismatchError
    UserNotExistError: UserNotExistError
    InvalidTokenError: InvalidTokenError

Sequelize = require "sequelize"

exports.setup = (url)->
    
    {STRING, INTEGER, CHAR, TEXT, BOOLEAN} = Sequelize
    sequelize = new Sequelize url

    define = (name, {schema, options})-> 
        sequelize.define name, schema, options

    tbl = (name)-> "auth_#{name}"

    User = define "user",
        schema:
            name:
                type: STRING
                unique: yes
                allowNull: no
                validate:
                    is: /^[a-z0-9_.-]+$/i
                    len: [3,32]
            email:
                type: STRING
                unique: yes
                allowNull: no
                validate:
                    isEmail: yes
            password:
                type: CHAR(60)
                allowNull: yes
            enabled:
                type: BOOLEAN
                allowNull: no
                defaultValue: yes
            verified:
                type: BOOLEAN
                allowNull: no
                defaultValue: no
            extra:
                type: TEXT
        options:
            timestamps: yes
            underscored: yes
            paranoid: yes
            tableName: tbl "users"

    Role = define "role",
        schema:
            name:
                type: STRING
                unique: yes
                allowNull: no
            description:
                type: STRING
                allowNull: yes
        options:
            timestamps: yes
            underscored: yes
            paranoid: yes
            tableName: tbl "roles"

    RoleAssignment = define "roleAssignment",
        schema: {}
        options:
            paranoid: no
            underscored: yes
            timestamps: yes
            tableName: tbl "role_assignments"

    PasswordResetRequest = define "passwordResetRequest",
        schema:
            token:
                type: CHAR(64)
                allowNull: no
        options:
            paranoid: no
            underscored: yes
            timestamps: yes
            tableName: tbl "password_reset_requests"

    EmailVerification = define "emailVerification",
        schema:
            token:
                type: CHAR(64)
                allowNull: no
        options:
            paranoid: no
            underscored: yes
            timestamps: yes
            tableName: tbl "email_verifications"

    Resource = define "resource",
        schema:
            name:
                type: STRING
                unique: yes
                allowNull: no
                validate:
                    is: /^[a-z0-9_.-]+$/i
                    len: [1,32]
            description:
                type: STRING
                allowNull: yes
        options:
            timestamps: yes
            underscored: yes
            paranoid: yes
            tableName: tbl "resources"

    Action = define "action",
        schema:
            name:
                type: STRING
                unique: yes
                allowNull: no
                validate:
                    is: /^[a-z0-9_.-]+$/i
                    len: [1,32]
            description:
                type: STRING
                allowNull: yes
        options:
            timestamps: yes
            underscored: yes
            paranoid: yes
            tableName: tbl "actions"

    Rule = define "rule",
        schema:
            allowed:
                type: BOOLEAN
                allowNull: no
                defaultValue: yes
        options:
            underscored: yes
            timestamps: yes
            tableName: tbl "rules"

    User.belongsToMany Role, through: RoleAssignment

    Resource.hasMany Action

    Action.belongsToMany Role, through: Rule

    User.hasMany PasswordResetRequest
    User.hasMany EmailVerification

    PasswordResetRequest.belongsTo User
    EmailVerification.belongsTo User

    sequelize

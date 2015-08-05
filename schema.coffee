Sequelize = require "sequelize"

exports.setup = (url)->
    
    {STRING, INTEGER, CHAR, TEXT, BOOLEAN} = Sequelize
    sequelize = new Sequelize url

    define = (name, {schema, options})-> 
        sequelize.define name, schema, options

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

    Role = define "role",
        schema:
            name:
                type: STRING
                allowNull: no
            description:
                type: STRING
                allowNull: yes
        options:
            timestamps: yes
            underscored: yes
            paranoid: yes

    RoleAssignment = define "role_assignment",
        schema: {}
        options:
            underscored: yes
            timestamps: yes

    User.belongsToMany(Role, { through: RoleAssignment});

    PasswordResetRequest = define "password_reset_request",
        schema:
            userId:
                type: INTEGER
                model: User
                key: "id"
                field: "user_id"
            token:
                type: CHAR(64)
                allowNull: no
        options:
            underscored: yes
            timestamps: yes

    EmailVerification = define "email_verification",
        schema:
            userId:
                type: INTEGER
                model: User
                key: "id"
                field: "user_id"
            token:
                type: CHAR(64)
                allowNull: no
        options:
            underscored: yes
            timestamps: yes

    sequelize

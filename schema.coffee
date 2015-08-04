Sequelize = require "sequelize"

exports.setup = (url)->
    
    {STRING, INTEGER, CHAR, TEXT} = Sequelize
    sequelize = new Sequelize url

    options =
        timestamps: yes
        paranoid: yes
        underscored: yes

    User = sequelize.define "user",
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
            allowNull: no
        extra:
            type: TEXT
    , options

    Role = sequelize.define "role",
        name:
            type: STRING
            allowNull: no
        description:
            type: STRING
            allowNull: yes
    , options

    RoleAssignment = sequelize.define "role_assignment",
        userId: 
            type: INTEGER
            model: User
            key: "id"
            field: "user_id"
        roleId:
            type: INTEGER
            model: Role
            key: "id"
            field: "role_id"
    , options

    sequelize

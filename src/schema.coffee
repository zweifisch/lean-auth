{STRING, INTEGER, CHAR, TEXT, BOOLEAN} = require "sequelize"

module.exports =

    user:
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

    role:
        name:
            type: STRING
            unique: yes
            allowNull: no
        description:
            type: STRING
            allowNull: yes

    token:
        token:
            type: CHAR(64)
            allowNull: no

    uniqueName:
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

    name:
        name:
            type: STRING
            unique: no
            allowNull: no
            validate:
                is: /^[a-z0-9_.-]+$/i
                len: [1,32]
        description:
            type: STRING
            allowNull: yes

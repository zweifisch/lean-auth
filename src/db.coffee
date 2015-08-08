Sequelize = require "sequelize"
schema = require "./schema"

exports.setup = (url, prefix)->
    
    sequelize = new Sequelize url

    tbl = (name)-> "#{prefix}_#{name}"

    User = sequelize.define "user", schema.user,
        timestamps: yes
        underscored: yes
        paranoid: yes
        tableName: tbl "users"

    Role = sequelize.define "role", schema.role,
        timestamps: yes
        underscored: yes
        paranoid: yes
        tableName: tbl "roles"

    RoleAssignment = sequelize.define "roleAssignment", {},
        paranoid: no
        underscored: yes
        timestamps: yes
        tableName: tbl "role_assignments"

    PasswordResetRequest = sequelize.define "passwordResetRequest", schema.token,
        paranoid: no
        underscored: yes
        timestamps: yes
        tableName: tbl "password_reset_requests"

    EmailVerification = sequelize.define "emailVerification", schema.token,
        paranoid: no
        underscored: yes
        timestamps: yes
        tableName: tbl "email_verifications"

    Resource = sequelize.define "resource", schema.uniqueName,
        timestamps: yes
        underscored: yes
        paranoid: yes
        tableName: tbl "resources"

    Action = sequelize.define "action", schema.name,
        timestamps: yes
        underscored: yes
        paranoid: yes
        tableName: tbl "actions"

    Rule = sequelize.define "rule", {},
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



module.exports = (sequelize, DataTypes) ->

  person = sequelize.define 'person',
    birth_year: DataTypes.INTEGER
    town: DataTypes.STRING
    age: DataTypes.INTEGER
  ,
    timestamps: false

  attr = sequelize.define 'translats',
    entity_id:
      type: DataTypes.INTEGER
      primaryKey: true
    ###
    id of translated attribute, e.g.
    person.name = 3, enum.value = 0
    ###
    entity_type:
      type: DataTypes.INTEGER
      primaryKey: true
    lang:
      type: DataTypes.STRING
      primaryKey: true
    value:
      type: DataTypes.STRING
      allowNull: false
  ,
    timestamps: false

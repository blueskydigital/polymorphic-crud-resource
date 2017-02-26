

module.exports = (sequelize, Sequelize) ->

  person = sequelize.define 'person',
    birth_year: Sequelize.INTEGER
    town: Sequelize.STRING
    age: Sequelize.INTEGER
    parent_id: Sequelize.INTEGER
  ,
    timestamps: false

  attr = sequelize.define 'translats',
    id:
      type: Sequelize.INTEGER
      autoIncrement: true
      primaryKey: true
    updated:
      type: Sequelize.DATE
      defaultValue: Sequelize.NOW
    entity_id:
      type: Sequelize.INTEGER
      unique: 'compositeIndex'
    ###
    id of translated attribute, e.g.
    person.name = 3, enum.value = 0
    ###
    entity_type:
      type: Sequelize.INTEGER
      unique: 'compositeIndex'
    lang:
      type: Sequelize.STRING
      allowNull: false
      unique: 'compositeIndex'
    value:
      type: Sequelize.STRING
      allowNull: false
  ,
    timestamps: false

async = require('async')
_ = require('lodash')
Sequelize = require('sequelize')

exports.save = (body, saved, assotiations, pkname, transaction) ->
  promises = []
  for ass in assotiations
    if body[ass.name]
      promise = _saveSingleAssoc(ass, body, saved, pkname, transaction)
      promises.push promise
  return Sequelize.Promise.all(promises)

_saveSingleAssoc = (a, body, saved, pkname, transaction) ->
  cond = _.extend({}, a.defaults)
  cond[a.fk] = saved[pkname]
  newI = (_.extend({}, cond, i) for i in body[a.name])
  return a.model.bulkCreate(newI, {transaction: transaction}).then (created)->
    saved.dataValues[a.name] = created

exports.update = (body, saved, assotiations, pkname, transaction) ->
  promises = []
  for ass in assotiations
    if body[ass.name]
      promise = _updateSingleAssoc(ass, body[ass.name], saved, pkname, transaction)
      promises.push promise
  return Sequelize.Promise.all(promises)

_updateSingleAssoc = (a, data, saved, pkname, transaction) ->
  cond = _.extend({}, a.defaults)
  cond[a.fk] = saved[pkname]
  saved.dataValues[a.name] = []
  # find all assotiations
  return a.model.findAll(where: cond).then (found)->
    promises = []
    # and save notexisting (new) assocs first
    promises.push(_saveNewAssocs(a, data, cond, transaction).then (savedrows)->
      saved.dataValues[a.name] = saved.dataValues[a.name].concat(savedrows)
    )
    # then continue with changed rows
    changed = _.filter(data, (i)-> i.id != undefined)
    for ch in changed
      row = _.find(found, (i)-> i.id == ch.id)
      if row == undefined
        throw new Exception('row not found in existin, incomming data wrong')
      if ! ch.updated   # wrong data doesnot contain updated, but should => force update
        ch.updated = new Date()
      # update only if timestamps differ or DB row not set updated
      if !row.updated || row.updated.toISOString() != ch.updated
        for k, v of ch  # update values
          row.setDataValue(k, v)
        promises.push(row.save({transaction: transaction}).then (savedrow)->
          saved.dataValues[a.name].push(savedrow)
        )
    # and destroy those existing rows that are not in data
    for row in found
      inData = _.find(data, (i)-> i.id == row.id)
      if inData == undefined
        promises.push(row.destroy({transaction: transaction}))
    # return promise waiting 4 all operations
    return Sequelize.Promise.all(promises)

_saveNewAssocs = (a, data, ids, transaction)->
  newRows = _.filter(data, (i)-> i.id == undefined) # those without autogen id
  newI = (_.extend({}, ids, i) for i in newRows)
  return a.model.bulkCreate(newI, {transaction: transaction})


exports.load = (items, assotiations, pkname) ->
  promises = []
  for ass in assotiations
    promises.push(_loadSingleAssoc(ass, items, pkname))
  return Sequelize.Promise.all(promises)

_loadSingleAssoc = (a, items, pkname) ->
  _idx = {}
  for i in items
    _idx[i[pkname]] = i
  cond = _.extend({}, a.defaults)
  cond[a.fk] = {$in: _.pluck(items, pkname)}
  # if present: remove default attrs (we don't want to add join params)
  if a.defaults
    attrs = _.remove Object.keys(a.model.attributes), (i)->
      return i not in Object.keys(a.defaults)
  return a.model.findAll(where: cond, attributes: attrs).then (found)->
    for i in items
      i.dataValues[a.name] = [] if not i.dataValues[a.name]
    for f in found
      item = _idx[f[a.fk]]
      item.dataValues[a.name].push(_.omit(f.dataValues, [a.fk]))

exports.delete = (item, assotiations, pkname, transaction) ->
  promises = []
  for ass in assotiations
    promise = _deleteSingleAssoc(ass, item, pkname, transaction)
    promises.push(promise)
  return Sequelize.Promise.all(promises)

_deleteSingleAssoc = (a, item, pkname, transaction) ->
  cond = _.extend({}, a.defaults)
  cond[a.fk] = item[pkname]
  opts = if transaction then {transaction: transaction} else {}
  return a.model.destroy(Object.assign({where: cond}, opts))

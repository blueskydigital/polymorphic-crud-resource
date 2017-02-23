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
  return a.model.bulkCreate(newI, {transaction: transaction}).then ->
    saved.dataValues[a.name] = body[a.name]

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
  # find all assotiations
  return a.model.findAll(where: cond).then (found)->
    promises = []
    solved = []
    for row in found # solve each row separately (save? update? delete?)
      promises.push(_updateOneRow(row, cond, a.uniques, data, solved, transaction))
    # and save notexisting (new) assocs
    promises.push(_saveNewAssocs(a, data, cond, solved, transaction))
    return Sequelize.Promise.all(promises)

_shouldUpdate = (inDB, inReq)->   # just compare attrs' toString
  for k, v of inReq
    return true if inDB[k].toString() != inReq[k].toString()
  return false

_updateOneRow = (row, cond, uniques, data, solved, transaction) ->
  # look if it is in body
  searchCond = {}
  for u in uniques
    searchCond[u] = row[u]
  inBody = _.find(data, searchCond)
  if inBody == undefined
    return row.destroy({transaction: transaction})  # not in body -> delete
  else
    solved.push(inBody)
    if _shouldUpdate(row, inBody)
      for k, v of inBody  # update values
        row[k] = v
      return row.save({transaction: transaction})

_saveNewAssocs = (a, data, ids, solved, transaction)->
  newRows = _.filter(data, (i)-> i not in solved)
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
    for f in found
      item = _idx[f[a.fk]]
      item.dataValues[a.name] = [] if not item.dataValues[a.name]
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
  return a.model.destroy({where: cond, transaction: transaction})

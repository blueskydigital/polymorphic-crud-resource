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
  return a.model.destroy(where: cond, {transaction: transaction})
  .then ->
    newI = (_.extend({}, cond, i) for i in body[a.name])
    return a.model.bulkCreate newI, {transaction: transaction}
  .then ->
    saved.dataValues[a.name] = body[a.name]

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
  return a.model.destroy(where: cond, {transaction: transaction})

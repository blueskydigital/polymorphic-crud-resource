async = require('async')
_ = require('lodash')

exports.save = (body, saved, assotiations, pkname, cb) ->
  async.map assotiations, (ass, callback)->
    if body[ass.name]
      _saveSingleAssoc(ass, body, saved, pkname, callback)
    else
      callback(null)
  , (err, results) ->
    cb(err, saved)

_saveSingleAssoc = (a, body, saved, pkname, cb) ->
  cond = _.extend({}, a.defaults)
  cond[a.fk] = saved[pkname]
  a.model.destroy(where: cond)
  .then ->
    newI = (_.extend({}, cond, i) for i in body[a.name])
    a.model.bulkCreate newI
  .then ->
    saved.dataValues[a.name] = body[a.name]
    cb(null)
  .catch (err)->
    cb(err)

exports.load = (items, assotiations, pkname, cb) ->
  async.map assotiations, (ass, callback)->
    _loadSingleAssoc(ass, items, pkname, callback)
  , (err, results) ->
    cb(err, items)

_loadSingleAssoc = (a, items, pkname, cb) ->
  _idx = {}
  for i in items
    _idx[i[pkname]] = i
  cond = _.extend({}, a.defaults)
  cond[a.fk] = {$in: _.pluck(items, pkname)}
  # if present: remove default attrs (we don't want to add join params)
  if a.defaults
    attrs = _.remove Object.keys(a.model.attributes), (i)->
      return i not in Object.keys(a.defaults)
  a.model.findAll(where: cond, attributes: attrs)
  .then (found)->
    for f in found
      item = _idx[f[a.fk]]
      item.dataValues[a.name] = [] if not item.dataValues[a.name]
      item.dataValues[a.name].push(_.omit(f.dataValues, [a.fk]))
    cb(null)
  .catch (err)->
    cb(err)

exports.delete = (item, assotiations, pkname, cb) ->
  async.map assotiations, (ass, callback)->
    _deleteSingleAssoc(ass, item, pkname, callback)
  , (err, results) ->
    cb(err, item)

_deleteSingleAssoc = (a, item, pkname, cb) ->
  cond = _.extend({}, a.defaults)
  cond[a.fk] = item[pkname]
  a.model.destroy(where: cond)
  .then (found)->
    cb(null)
  .catch (err)->
    cb(err)

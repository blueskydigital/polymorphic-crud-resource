async = require('async')
_ = require('lodash')

exports.save = (body, saved, assotiations, cb) ->
  async.map assotiations, (ass, callback)->
    _saveSingleAssoc(ass, body, saved, callback)
  , (err, results) ->
    cb(err, saved)

_saveSingleAssoc = (a, body, saved, cb) ->
  if body[a.name]
    cond = _.extend({}, a.defaults)
    cond[a.fk] = saved.id
    a.model.destroy(where: cond)
    .then ->
      newI = (_.extend({}, cond, i) for i in body[a.name])
      a.model.bulkCreate newI
    .then ->
      saved.dataValues[a.name] = body[a.name]
      cb(null)
    .catch (err)->
      cb(err)

exports.load = (item, assotiations, cb) ->
  async.map assotiations, (ass, callback)->
    _loadSingleAssoc(ass, item, callback)
  , (err, results) ->
    cb(err, item)

_loadSingleAssoc = (a, item, cb) ->
  cond = a.defaults
  cond[a.fk] = item.id
  # remove default attrs (we don't want to add join params)
  attrs = _.remove Object.keys(a.model.attributes), (i)->
    return i not in Object.keys(cond)
  a.model.findAll(where: cond, attributes: attrs)
  .then (found)->
    item.dataValues[a.name] = found
    cb(null)
  .catch (err)->
    cb(err)

exports.delete = (item, assotiations, cb) ->
  async.map assotiations, (ass, callback)->
    _deleteSingleAssoc(ass, item, callback)
  , (err, results) ->
    cb(err, item)

_deleteSingleAssoc = (a, item, cb) ->
  cond = a.defaults
  cond[a.fk] = item.id
  a.model.destroy(where: cond)
  .then (found)->
    cb(null)
  .catch (err)->
    cb(err)

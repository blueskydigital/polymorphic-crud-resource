_ = require('lodash')
assots = require('./assotiations')
utils = require('./utils')

module.exports = (Model, assotiations=[], opts={}) ->

  pkname = opts.identifier || 'id'

  _load = (req, res, next) ->
    options =
      where: {}
    options.where[pkname] = req.params.id
    Model.find(options).then (found) ->
      return res.status(404).send('not found') if not found
      req.found = found
      next()
    .catch (err)->
      return res.status(400).send(err)

  # ------------------------------------ SEARCH -------------------------------
  _prepare_search = (req, res, next) ->
    try
      req.searchOpts = utils.createSearchOptions(req)
      req.ass4load = utils.filterAssocs(req.searchOpts.include, assotiations)
      # we want id (generaly primary ids) as well
      if req.ass4load.length > 0 and req.searchOpts.attributes
        req.searchOpts.attributes.push(pkname)
      next()
    catch err
      return next(err)

  _list = (req, res, next) ->
    rows = null
    Model.findAndCountAll(req.searchOpts).then (result) ->
      res.set('x-total-count', result.count)
      rows = result.rows
      return assots.load(rows, req.ass4load, pkname)
    .then ()->
      res.status(200).json rows
    .catch(next)

  # ------------------------------------ CREATE -------------------------------
  _create = (req, res, next) ->
    _do_create req.body, req.transaction, (err, newinstance)->
      return next(err) if err
      req.transaction.commit() if req.transaction
      res.status(201).json(newinstance)

  _do_create = (body, transaction, cb)->
    item = Model.build(body)
    item.save(if transaction then {transaction: transaction} else {})
    .then (saved)->
      return assots.save(body, saved, assotiations, pkname, transaction)
    .then (allsaved)->
      cb(null, item.toJSON())
    .catch (err)->
      cb(err)

  # ------------------------------------ RETRIEVE ------------------------------

  _do_retrieve = (item) ->
    return assots.load([item], assotiations, pkname)

  _retrieve = (req, res, next) ->
    _do_retrieve(req.found).then ()->
      res.json req.found
    .catch(next)

  # ------------------------------------ UPDATE -------------------------------
  _do_update = (item, body, transaction, cb) ->
    assots.load([item], assotiations, pkname).then ()->
      # asses2update = _.filter assotiations, (i) -> i.name of body
      for k, v of body  # update values
        item[k] = v
      item.save(if transaction then {transaction: transaction} else {})
      .then (updated)->
        return assots.save(body, updated, assotiations, pkname, transaction)
      .then (allsaved)->
        cb(null, item.toJSON())
      .catch (err)->
        cb(err)

  _update = (req, res, next) ->
    _do_update req.found, req.body, req.transaction, (err, updated) ->
      return next(err) if err
      req.transaction.commit() if req.transaction
      res.json updated

  # ------------------------------------ DELETE -------------------------------
  _do_delete = (item, transaction, cb) ->
    assots.load([item], assotiations, pkname) # load data to send back
    .then ()->
      assots.delete(item, assotiations, pkname, transaction)
    .then ()->
      item.destroy(if transaction then {transaction: transaction} else {})
    .then (allsaved)->
      cb(null, item.toJSON())
    .catch (err)->
      cb(err)

  _delete = (req, res, next) ->
    _do_delete req.found, req.transaction, (err, removed)->
      return next(err) if err
      req.transaction.commit() if req.transaction
      res.json removed

  # ------------------------------------ APP -------------------------------
  initApp: (app, middlewares={})->
    app.get('', middlewares['list'] or [], _prepare_search, _list)
    app.post('', middlewares['create'] or [], _create)
    app.get('/:id', middlewares['get'] or [], _load, _retrieve)
    app.put('/:id', middlewares['update'] or [], _load, _update)
    app['delete']('/:id', middlewares['delete'] or [], _load, _delete)

  create: _do_create
  retrieve: _do_retrieve
  update: _do_update
  delete: _do_delete
  load: _load
  createMW: _create
  retrieveMW: _retrieve
  updateMW: _update
  deleteMW: _delete
  listMW: _list
  prepareSearchMW: _prepare_search

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
      return next(status: 404, message: 'not found') if not found
      req.found = found
      next()
    .catch(next)

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
      next()
    .catch(next)

  # ------------------------------------ CREATE -------------------------------
  _create = (req, res, next) ->
    _do_create req.body, req.transaction
    .then (newinstance)->
      req.transaction.commit() if req.transaction
      res.status(201).json(newinstance)
      req.params.id = newinstance.id  # save id for further process
      next()
    .catch(next)

  _do_create = (body, transaction)->
    item = Model.build(body)
    return item.save(if transaction then {transaction: transaction} else {})
    .then (saved)->
      return assots.save(body, saved, assotiations, pkname, transaction)
    .then (allsaved)->
      return item.toJSON()

  # ------------------------------------ RETRIEVE ------------------------------

  _do_retrieve = (item) ->
    return assots.load([item], assotiations, pkname)

  _retrieve = (req, res, next) ->
    _do_retrieve(req.found).then ()->
      res.json req.found
      next()
    .catch(next)

  # ------------------------------------ UPDATE -------------------------------
  _do_update = (item, body, transaction) ->
    for k, v of body  # update values
      item[k] = v
    return item.save(if transaction then {transaction: transaction} else {})
    .then (updated)->
      return assots.update(body, updated, assotiations, pkname, transaction)
    .then (allsaved)->
      return item.toJSON()

  _update = (req, res, next) ->
    _do_update req.found, req.body, req.transaction
    .then (updated) ->
      req.transaction.commit() if req.transaction
      res.json updated
      next()
    .catch(next)

  # ------------------------------------ DELETE -------------------------------
  _do_delete = (item, transaction, cb) ->
    assots.load([item], assotiations, pkname) # load data to send back
    .then ()->
      return assots.delete(item, assotiations, pkname, transaction)
    .then ()->
      return item.destroy(if transaction then {transaction: transaction} else {})
    .then (allsaved)->
      return item.toJSON()

  _delete = (req, res, next) ->
    _do_delete req.found, req.transaction
    .then (removed) ->
      req.transaction.commit() if req.transaction
      res.json removed
      next()
    .catch(next)

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

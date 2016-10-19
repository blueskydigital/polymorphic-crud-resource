_ = require('lodash')
assots = require('./assotiations')
utils = require('./utils')

module.exports = (Model, assotiations=[]) ->

  _load = (req, res, next) ->
    options =
      where: {id: req.params.id}
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
        req.searchOpts.attributes.push('id')
      next()
    catch err
      return res.status(400).send(err)

  _list = (req, res) ->
    Model.findAndCountAll(req.searchOpts).then (result) ->
      res.set('x-total-count', result.count)
      if req.ass4load.length > 0
        return assots.load result.rows, req.ass4load, (err, loadedresults)->
          return res.status(400).send(err) if err
          res.status(200).json loadedresults
      res.status(200).json result.rows
    .catch (err)->
      return res.status(400).send(err)

  # ------------------------------------ CREATE -------------------------------
  _create = (req, res, next) ->
    _do_create req.body, (err, newinstance)->
      return res.status(400).send(err) if err
      res.status(201).json(newinstance)

  _do_create = (body, cb)->
    n = Model.build(body)
    n.save().then (saved) ->
      if assotiations.length > 0
        assots.save body, saved, assotiations, (err, saved)->
          return cb(err) if err
          cb(null, saved)
      else
        cb(null, saved)
    .catch (err)->
      return cb(err)

  # ------------------------------------ RETRIEVE -------------------------------
  _do_retrieve = (item, cb) ->
    assots.load [item], assotiations, (err, saved)->
      return cb(err) if err
      cb(null, item)

  _retrieve = (req, res) ->
    _do_retrieve req.found, (err, found)->
      return res.status(400).send(err) if err
      return res.status(404).send('not found') if not found
      res.json found

  # ------------------------------------ UPDATE -------------------------------
  _do_update = (item, body, cb) ->
    assots.load [item], assotiations, (err, saved)->
      return cb(err) if err
      asses2update = _.filter assotiations, (i) -> i.name of body
      for k, v of body
        item[k] = v
      item.save().then (updated)->
        if asses2update
          return assots.save body, updated, asses2update, (err, saved)->
            return cb(err) if err
            cb(null, saved)
        cb(null, updated)
      .catch (err)->
        return cb(err)

  _update = (req, res) ->
    _do_update req.found, req.body, (err, updated) ->
      return res.status(400).send(err) if err
      res.json updated

  # ------------------------------------ DELETE -------------------------------
  _do_delete = (item, cb) ->
    assots.load [item], assotiations, (err, saved)->
      return cb(err) if err
      assots.delete item, assotiations, (err, removed) ->
        return cb(err) if err
        item.destroy().then ->
          cb(null, removed)
        .catch (err)->
          return cb(err)

  _delete = (req, res) ->
    _do_delete req.found, (err, removed)->
      return res.status(400).send(err) if err
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

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
      return res.status(400).send(err)

  _list = (req, res) ->
    rows = null
    Model.findAndCountAll(req.searchOpts).then (result) ->
      res.set('x-total-count', result.count)
      rows = result.rows
      return assots.load(rows, req.ass4load, pkname)
    .then ()->
      res.status(200).json rows
    .catch (err)->
      return res.status(400).send(err)

  # ------------------------------------ CREATE -------------------------------
  _create = (req, res, next) ->
    _do_create req.body, (err, newinstance)->
      return res.status(400).send(err) if err
      res.status(201).json(newinstance)

  _do_create = (body, cb)->
    item = Model.build(body)
    Model.sequelize.transaction().then (t)->
      item.save({transaction: t})
      .then (saved)->
        return assots.save(body, saved, assotiations, pkname, t)
      .then (allsaved)->
        t.commit()
        cb(null, item.toJSON())
      .catch (err)->
        t.rollback()
        cb(err)

  # ------------------------------------ RETRIEVE ------------------------------

  _do_retrieve = (item) ->
    return assots.load([item], assotiations, pkname)

  _retrieve = (req, res) ->
    _do_retrieve(req.found).then ()->
      res.json req.found
    .catch (err)->
      res.status(400).send(err)

  # ------------------------------------ UPDATE -------------------------------
  _do_update = (item, body, cb) ->
    assots.load([item], assotiations, pkname).then ()->
      # asses2update = _.filter assotiations, (i) -> i.name of body
      for k, v of body  # update values
        item[k] = v
      Model.sequelize.transaction().then (t)->
        item.save({transaction: t})
        .then (updated)->
          return assots.save(body, updated, assotiations, pkname, t)
        .then (allsaved)->
          t.commit()
          cb(null, item.toJSON())
        .catch (err)->
          t.rollback()
          cb(err)
    .catch (err)->
      cb(err)

  _update = (req, res) ->
    _do_update req.found, req.body, (err, updated) ->
      return res.status(400).send(err) if err
      res.json updated

  # ------------------------------------ DELETE -------------------------------
  _do_delete = (item, cb) ->
    Model.sequelize.transaction().then (t)->
      assots.load([item], assotiations, pkname) # load data to send back
      .then ()->
        assots.delete(item, assotiations, pkname, t)
      .then ()->
        item.destroy()
      .then (allsaved)->
        t.commit()
        cb(null, item.toJSON())
      .catch (err)->
        t.rollback()
        cb(err)

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

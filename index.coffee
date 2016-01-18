_ = require('lodash')
assots = require('./assotiations')
utils = require('./utils')

module.exports = (Model, assotiations=[]) ->

  _load = (id, cb, options={}) ->
    options.where = {id: id}
    Model.find(options).then (found) ->
      cb(null, found)
    .catch (err)->
      cb(err)

  _list = (req, res) ->
    try
      searchOpts = utils.createSearchOptions(req)
      ass4load = utils.filterAssocs(searchOpts.include, assotiations)
      # we want id (generaly primary ids) as well
      if ass4load.length > 0 and searchOpts.attributes
        searchOpts.attributes.push('id')
    catch err
      return res.status(400).send(err)
    Model.findAll(searchOpts).then (results) ->
      if ass4load.length > 0
        return assots.load results, ass4load, (err, loadedresults)->
          return res.status(400).send(err) if err
          res.status(200).json loadedresults
      res.status(200).json results
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
  _do_retrieve = (id, cb) ->
    _load id, (err, found)->
      return cb(err) if err
      assots.load [found], assotiations, (err, saved)->
        return cb(err) if err
        cb(null, found)

  _retrieve = (req, res) ->
    _do_retrieve req.params.id, (err, found)->
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
    _load req.params.id, (err, found)->
      return res.status(400).send(err) if err
      return res.status(404).send('not found') if not found
      _do_update found, req.body, (err, updated) ->
        return res.status(400).send(err) if err
        res.json updated

  # ------------------------------------ DELETE -------------------------------
  _do_delete = (item, cb) ->
    assots.load [item], assotiations, (err, saved)->
      return cb(err) if err
      item.destroy().then ->
        assots.delete item, assotiations, (err, removed)->
          cb(null, removed)
      .catch (err)->
        return cb(err)

  _delete = (req, res) ->
    _load req.params.id, (err, found)->
      return res.status(400).send(err) if err
      return res.status(404).send('not found') if not found
      _do_delete found, (err, removed)->
        return res.status(400).send(err) if err
        res.json removed

  # ------------------------------------ APP -------------------------------
  initApp: (app, middlewares={})->
    app.get('', middlewares['list'] or [], _list)
    app.post('', middlewares['create'] or [], _create)
    app.get('/:id', middlewares['get'] or [], _retrieve)
    app.put('/:id', middlewares['update'] or [], _update)
    app['delete']('/:id', middlewares['delete'] or [], _delete)

  create: _do_create
  retrieve: _do_retrieve
  update: _do_update
  delete: _do_delete

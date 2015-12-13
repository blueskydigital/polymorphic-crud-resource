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

  _retrieve = (req, res) ->
    _load req.params.id, (err, found)->
      return res.status(400).send(err) if err
      return res.status(404).send('not found') if not found
      assots.load [found], assotiations, (err, saved)->
        return res.status(400).send(err) if err
        res.json found

  _update = (req, res) ->
    _load req.params.id, (err, found)->
      return res.status(400).send(err) if err
      return res.status(404).send('not found') if not found
      assots.load [found], assotiations, (err, saved)->
        return res.status(400).send(err) if err
        asses2update = _.filter assotiations, (i) -> i.name of req.body
        for k, v of req.body
          found[k] = v
        found.save().then (updated)->
          if asses2update
            return assots.save req.body, updated, asses2update, (err, saved)->
              return res.status(400).send(err) if err
              res.json(saved)
          res.json updated
        .catch (err)->
          return res.status(400).send(err)

  _delete = (req, res) ->
    _load req.params.id, (err, found)->
      return res.status(400).send(err) if err
      return res.status(404).send('not found') if not found
      assots.load [found], assotiations, (err, saved)->
        return res.status(400).send(err) if err
        found.destroy().then ->
          assots.delete found, assotiations, (err, removed)->
            res.json found
        .catch (err)->
          return res.status(400).send(err)

  initApp: (app, middlewares=[])->
    app.get('', _list)
    app.post('', middlewares, _create)
    app.get('/:id', _retrieve)
    app.put('/:id', middlewares, _update)
    app['delete']('/:id', middlewares, _delete)

  create: _do_create

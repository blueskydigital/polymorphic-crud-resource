// const _ = require('lodash')
const assots = require('./assotiations')
const utils = require('./utils')

module.exports = function (Model, assotiations, opts) {
  //
  if (assotiations == null) {
    assotiations = []
  }
  if (opts == null) {
    opts = {}
  }

  const pkname = opts.identifier || 'id'

  function _load (req, res, next) {
    const options = {
      where: {}
    }
    options.where[pkname] = req.params.id
    return Model.findOne(options).then((found) => {
      if (!found) {
        return next({
          status: 404,
          message: 'not found'
        })
      }
      req.found = found
      if (req.method === 'PUT' || req.method === 'DELETE') {
        return _doRetrieve(found).then(() => {
          req.loaded = JSON.parse(JSON.stringify(req.found))
          next()
        })
      }
      next()
    })
    .catch(next)
  }

  function _prepareSearch (req, res, next) {
    try {
      req.searchOpts = utils.createSearchOptions(req)
      req.ass4load = utils.filterAssocs(req.searchOpts.include, assotiations)
      if (req.ass4load.length > 0 && req.searchOpts.attributes) {
        req.searchOpts.attributes.push(pkname)
      }
      return next()
    } catch (err) {
      return next(err)
    }
  }

  function _list (req, res, next) {
    var rows
    rows = null
    return Model.findAndCountAll(req.searchOpts)
    .then(function (result) {
      res.set('x-total-count', result.count)
      rows = result.rows
      return assots.load(rows, req.ass4load, pkname)
    })
    .then(function () {
      res.status(200).json(rows)
      return next()
    })
    .catch(next)
  }

  function _create (req, res, next) {
    return _doCreate(req.body, req.transaction)
    .then(function (newinstance) {
      if (req.transaction) {
        req.transaction.commit()
      }
      res.status(201).json(newinstance)
      req.created = newinstance
      return next()
    })
    .catch(next)
  }

  function _doCreate (body, transaction) {
    const item = Model.build(body)
    return item.save(transaction ? {transaction: transaction} : {})
    .then(function (saved) {
      return assots.save(body, saved, assotiations, pkname, transaction)
    })
    .then(function (allsaved) {
      return item.toJSON()
    })
  }

  function _doRetrieve (item) {
    return assots.load([item], assotiations, pkname)
  }

  function _retrieve (req, res, next) {
    return _doRetrieve(req.found).then(function () {
      res.json(req.found)
      return next()
    }).catch(next)
  }

  function _doUpdate (item, body, transaction) {
    return item.update(body, transaction ? {
      transaction: transaction
    } : {})
    .then(function (updated) {
      return assots.update(body, updated, assotiations, pkname, transaction)
    })
    .then(function (allsaved) {
      return item.toJSON()
    })
  }

  function _update (req, res, next) {
    return _doUpdate(req.found, req.body, req.transaction)
    .then(function (updated) {
      if (req.transaction) {
        req.transaction.commit()
      }
      res.json(updated)
      req.updated = updated
      return next()
    })
    .catch(next)
  }

  function _doDelete (item, transaction, cb) {
    return assots.load([item], assotiations, pkname)
    .then(function () {
      return assots.delete(item, assotiations, pkname, transaction)
    })
    .then(function () {
      return item.destroy(transaction ? {transaction: transaction} : {})
    })
    .then(function (allsaved) {
      return item.toJSON()
    })
  }

  function _delete (req, res, next) {
    return _doDelete(req.found, req.transaction)
    .then(function (removed) {
      if (req.transaction) {
        req.transaction.commit()
      }
      res.json(removed)
      return next()
    })
    .catch(next)
  }

  return {
    initApp: function (app, middlewares) {
      if (middlewares == null) {
        middlewares = {}
      }
      app.get('', middlewares['list'] || [], _prepareSearch, _list)
      app.post('', middlewares['create'] || [], _create)
      app.get('/:id', middlewares['get'] || [], _load, _retrieve)
      app.put('/:id', middlewares['update'] || [], _load, _update)
      return app['delete']('/:id', middlewares['delete'] || [], _load, _delete)
    },
    create: _doCreate,
    retrieve: _doRetrieve,
    update: _doUpdate,
    delete: _doDelete,
    load: _load,
    createMW: _create,
    retrieveMW: _retrieve,
    updateMW: _update,
    deleteMW: _delete,
    listMW: _list,
    prepareSearchMW: _prepareSearch
  }
}

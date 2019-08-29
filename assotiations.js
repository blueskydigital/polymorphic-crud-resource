const _ = require('lodash')
const Sequelize = require('sequelize')

exports.save = function (body, saved, assotiations, pkname, transaction) {
  const promises = assotiations.map((ass, idx) => {
    if (body[ass.name]) {
      return _saveSingleAssoc(ass, body, saved, pkname, transaction)
    }
  })
  return Sequelize.Promise.all(promises)
}

function _saveSingleAssoc (a, body, saved, pkname, transaction) {
  const cond = _.extend({}, a.defaults)
  cond[a.fk] = saved[pkname]
  const newI = body[a.name].map((i) => {
    return _.extend({}, cond, i)
  })
  return a.model.bulkCreate(newI, {
    transaction: transaction
  }).then((created) => {
    saved.dataValues[a.name] = created.map(i => _removePKs(a, i))
  })
}

function _removePKs (a, saved) {
  const pks = [a.fk].concat(_.keys(a.defaults))
  return _.omit(saved.toJSON(), pks)
}

exports.update = function (body, saved, assotiations, pkname, transaction) {
  const promises = assotiations.map((ass) => {
    return _updateSingleAssoc(ass, body[ass.name], saved, pkname, transaction)
  })
  return Sequelize.Promise.all(promises)
}

function _updateSingleAssoc (a, data, saved, pkname, transaction) {
  const cond = _.extend({}, a.defaults)
  cond[a.fk] = saved[pkname]
  saved.dataValues[a.name] = []
  // find all assotiations
  return a.model.findAll({where: cond})
  .then((found) => {
    const promises = []
    const changed = _.filter(data, (i) => i.id !== undefined)
    // then continue with changed rows
    changed.map((ch) => {
      const row = _.find(found, (i) => i.id === ch.id)
      // throw new Error('row not found in existin, incomming data wrong: ' + JSON.stringify(ch))
      if (row !== undefined) { // wrong data doesnot contain updated, but should => force update
        if (!ch.updated) {
          ch.updated = new Date()
        }
        // update only if timestamps differ or DB row not set updated
        if (!row.updated || row.updated.toISOString() !== ch.updated) {
          const p = row.update(ch, {transaction: transaction}).then((savedrow) => {
            return saved.dataValues[a.name].push(_removePKs(a, savedrow))
          })
          promises.push(p)
        } else {
          saved.dataValues[a.name].push(_removePKs(a, row))
        }
      }
    })
    // and destroy those existing rows that are not in data
    found.map((row) => {
      const inData = _.find(data, (i) => i.id === row.id)
      if (inData === undefined) {
        promises.push(row.destroy({transaction: transaction}))
      }
    })
    return Sequelize.Promise.all(promises)
  }).then(() => {
    return _saveNewAssocs(a, data, cond, transaction)
  }).then((savedrows) => {
    saved.dataValues[a.name] = saved.dataValues[a.name].concat(savedrows)
    saved.dataValues[a.name] = saved.dataValues[a.name].map(i => {
      return i.toJSON ? _removePKs(a, i) : i
    })
  })
}

function _saveNewAssocs (a, data, ids, transaction) {
  const newI = _.filter(data, (i) => {
    return i.id === undefined
  }).map((i) => {
    return _.extend({}, ids, i)
  })
  return a.model.bulkCreate(newI, {transaction: transaction})
}

exports.load = function (items, assotiations, pkname) {
  const promises = assotiations.map((ass) => {
    return _loadSingleAssoc(ass, items, pkname)
  })
  return Sequelize.Promise.all(promises)
}

function _loadSingleAssoc (a, items, pkname) {
  let attrs
  const _idx = {}
  items.map((i) => {
    _idx[i[pkname]] = i
  })
  const cond = _.extend({}, a.defaults)
  cond[a.fk] = {
    [Op.in]: _.pluck(items, pkname)
  }
  if (a.defaults) {
    attrs = _.remove(Object.keys(a.model.attributes || a.model.rawAttributes), (i) => {
      return Object.keys(a.defaults).indexOf(i) < 0
    })
  }
  return a.model.findAll({where: cond, attributes: attrs})
  .then((found) => {
    items.map((i) => {
      if (!i.dataValues[a.name]) {
        i.dataValues[a.name] = []
      }
    })
    found.map((f) => {
      const item = _idx[f[a.fk]]
      item.dataValues[a.name].push(_.omit(f.dataValues, [a.fk]))
    })
  })
}

exports.delete = function (item, assotiations, pkname, transaction) {
  const promises = assotiations.map((ass) => {
    return _deleteSingleAssoc(ass, item, pkname, transaction)
  })
  return Sequelize.Promise.all(promises)
}

function _deleteSingleAssoc (a, item, pkname, transaction) {
  const cond = _.extend({}, a.defaults)
  cond[a.fk] = item[pkname]
  const opts = transaction ? {
    transaction: transaction
  } : {}
  return a.model.destroy(Object.assign({
    where: cond
  }, opts))
}

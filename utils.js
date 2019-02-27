const _ = require('lodash')

exports.createSearchOptions = function (req) {
  const opts = {}

  if (req.query.filter) {
    const filter = JSON.parse(req.query.filter)

    _.map(filter, function (v, k) {
      const likeMatch = k.match(/(.+)_like$/)
      if (likeMatch && (likeMatch.length > 0)) {
        delete filter[k]
        filter[likeMatch[1]] = { $like: `%${v}%` }
      }

      const inMatch = k.match(/(.+)_in$/)
      if (inMatch && (inMatch.length > 0)) {
        delete filter[k]
        filter[inMatch[1]] = { $in: v.split(',') }
      }

      const betweenMatch = k.match(/(.+)__between$/)
      if (betweenMatch && (betweenMatch.length > 0)) {
        delete filter[k]
        const f = filter[betweenMatch[1]] || v
        filter[betweenMatch[1]] = { $between: [f, v] }
      }

      const customMatch1 = k.match(/(.+)__custom1$/)
      if (customMatch1 && (customMatch1.length > 0)) {
        // filter[k]: VALUE,KEY1,KEY2
        const value = filter[k].split(',')
        delete filter[k]
        filter['$and'] = filter['$and'] || []
        filter['$and'].push({ '$and': [
          {
            [value[1]]: {
              $lte: value[0]
            }
          },
          {
            [value[2]]: {
              $gte: value[0]
            }
          }
        ] })
      }

      const customMatch2 = k.match(/(.+)__custom2$/)
      if (customMatch2 && (customMatch2.length > 0)) {
        // filter[k]: VALUE,KEY
        const value = filter[k].split(',')
        delete filter[k]
        filter['$and'] = filter['$and'] || []
        filter['$and'].push({ '$or': [
          {
            '$and': [
              { [value[1]]: { $like: `%${value[0]}%` } },
              { [value[1]]: { $notLike: `-%` } }
            ]
          },
          {
            '$and': [
              { [value[1]]: { $like: `-%` } },
              { [value[1]]: { $notLike: `%${value[0]}%` } }
            ]
          }
        ] })
      }
    })
    opts.where = filter
  }

  if (req.query.sort) {
    opts.order = JSON.parse(req.query.sort)
  }

  if (req.query.offset) {
    opts.offset = parseInt(req.query.offset)
  }

  if (req.query.limit) {
    opts.limit = parseInt(req.query.limit)
  }

  if (req.query.attrs) {
    opts.attributes = JSON.parse(req.query.attrs)
  }

  if (req.query.embed) {
    opts.include = JSON.parse(req.query.embed)
  }

  return opts
}

exports.filterAssocs = function (include, assocs) {
  const ass4load = []
  const iterable = include || []
  for (let idx = 0; idx < iterable.length; idx++) {
    var i = iterable[idx]
    const a = _.find(assocs, item => item.name === i)
    if (a) {
      ass4load.push(a)
    }
  }
  include && include.splice(0, include.length)
  return ass4load
}

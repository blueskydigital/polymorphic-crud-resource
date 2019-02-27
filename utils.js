const _ = require('lodash')

exports.createSearchOptions = function (req) {
  const opts = {}

  if (req.query.filter) {
    const filter = JSON.parse(req.query.filter)

    //  console.log(1000, req);

    _.map(filter, function (v, k) {
      const likematch = k.match(/(.+)_like$/)
      if (likematch && (likematch.length > 0)) {
        delete filter[k]
        filter[likematch[1]] = { $like: `%${v}%` }
      }

      const inmatch = k.match(/(.+)_in$/)
      if (inmatch && (inmatch.length > 0)) {
        delete filter[k]
        filter[inmatch[1]] = { $in: v.split(',') }
      }

      const betweenmatch = k.match(/(.+)__between$/)
      if (betweenmatch && (betweenmatch.length > 0)) {
        delete filter[k]
        const f = filter[betweenmatch[1]] || v
        filter[betweenmatch[1]] = { $between: [f, v] }
      }

      const andmatch = k.match(/(.+)__and$/)
      if (andmatch && (andmatch.length > 0)) {
        const value = filter[k].split(',')
        delete filter[k]
        filter['$and'] = [
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
        ]
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

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

      const fromMatch = k.match(/(.+)__from$/)
      if (fromMatch && (fromMatch.length > 0)) {
        const from = fromMatch[1]
        const to = fromMatch[0] + '__to'
        if (!filter[from] && filter[to]) {
          filter[from] = { $between: [v, filter[to]] }
        } else if (!filter[from]) {
          filter[from] = { $gte: v }
        }
        delete filter[k]
        delete filter[to]
      }

      const toMatch = k.match(/(.+)__from__to$/)
      if (toMatch && (toMatch.length > 0)) {
        const from = toMatch[1] + '__from'
        const to = toMatch[1]
        if (!filter[to] && filter[from]) {
          filter[to] = { $between: [filter[from], v] }
        } else if (!filter[to]) {
          filter[to] = { $lte: v }
        }
        delete filter[k]
        delete filter[from]
      }

      const customMatch1 = k.match(/(.+)__custom1$/)
      if (customMatch1 && (customMatch1.length > 0)) {
        // filter[k]: VALUE,KEY1,KEY2
        const value = filter[k].split(',')
        delete filter[k]
        filter['$and'] = filter['$and'] || []
        filter['$and'].push({
          '$and': [
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
        })
      }

      const customMatch2 = k.match(/(.+)__custom2$/)
      if (customMatch2 && (customMatch2.length > 0)) {
        // filter[k]: VALUE,KEY
        const value = filter[k].split(',')
        delete filter[k]
        filter['$and'] = filter['$and'] || []
        filter['$and'].push({
          '$or': [
            {
              '$and': [
                {
                  '$or': [
                    { [value[1]]: { $like: `%${value[0]}%` } },
                    { [value[1]]: 'WW' }
                  ]
                },
                { [value[1]]: { $notLike: `-%` } }
              ]
            },
            {
              '$and': [
                { [value[1]]: { $like: `-%` } },
                { [value[1]]: { $notLike: `%${value[0]}%` } }
              ]
            }
          ]
        })
      }

      const customMatch3 = k.match(/(.+)__custom3$/) // history filter
      if(customMatch3 && (customMatch3.length > 0)) {
        const value = filter[k].split(',')
        delete filter[k]

        filter['$and'] = filter['$and'] || []
        filter['$and'].push({ 
          '$or': [
            { [value[1]]: null }, // is null
            { [value[1]]: { $gte : new Date() }} // only greater than now
          ]
          
        })

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

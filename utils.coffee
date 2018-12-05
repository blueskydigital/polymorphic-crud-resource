_ = require('lodash')

exports.createSearchOptions = (req)->

  opts = {}

  if req.query.filter
    filter = JSON.parse(req.query.filter)
    _.map filter, (v, k) ->
      likematch = k.match(/(.+)_like$/)
      if likematch and likematch.length > 0
        delete filter[k]
        filter[likematch[1]] = {$like: "%#{v}%"}
      inmatch = k.match(/(.+)_in$/)
      if inmatch and inmatch.length > 0
        delete filter[k]
        filter[inmatch[1]] = {$in: v.split(',')}
      betweenmatch = k.match(/(.+)__between$/)
      if betweenmatch and betweenmatch.length > 0
        delete filter[k]
        f = filter[betweenmatch[1]] || v
        filter[betweenmatch[1]] = {$between: [f, v]}
    opts.where = filter

  if req.query.sort
    opts.order = JSON.parse(req.query.sort)

  if req.query.offset
    opts.offset = parseInt(req.query.offset)

  if req.query.limit
    opts.limit = parseInt(req.query.limit)

  if req.query.attrs
    opts.attributes = JSON.parse(req.query.attrs)

  if req.query.embed
    opts.include = JSON.parse(req.query.embed)

  return opts

exports.filterAssocs = (include, assocs) ->
  ass4load = []
  for i, idx in include || []
    a = _.find(assocs, (item)->item.name == i)
    if a
      ass4load.push(a)
  include && include.splice(0, include.length)
  return ass4load

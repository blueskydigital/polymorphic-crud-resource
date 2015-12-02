_ = require('lodash')

exports.createSearchOptions = (req)->

  opts = {}

  if req.query.filter
    filter = JSON.parse(req.query.filter)
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
      include.splice(idx, 1)
  return ass4load
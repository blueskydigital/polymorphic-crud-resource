
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

  return opts

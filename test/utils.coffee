should = require 'should'

deepCompare = (one, two, entitypath='')->
  # try
  if one instanceof Array
    two.length.should.be.eql one.length
    for i, idx in one
      deepCompare(i, two[idx], entitypath)
  else if one instanceof Object
    two.should.be.type('object')
    for k, v of one
      continue if k == 'id'
      deepCompare(one[k], two[k], "#{entitypath}.#{k}")
  else if one == undefined or two == undefined
    console.log "WAAAAAAAAARRRRNNN: #{entitypath}: #{one} is missing in two"
  else if one == null
    should(two).be.exactly null
  else
    one.toString().should.be.eql two.toString()
  # catch e
  #   console.log "ONE: #{JSON.stringify(one, null, '  ')}"
  #   console.log "TWO: #{JSON.stringify(two, null, '  ')}"
  #   console.log "ERROR: #{e}"
  #   throw e

exports.deepCompare = deepCompare

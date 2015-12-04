
should = require 'should'
request = require 'request'
tester = require '../tester'

module.exports = (g, addr) ->

  change =
    name: [{lang: 'cz', value: 'ChangedCZTrolol'}]
    birth_year: 1999

  tester(g, addr, g.data[0], change)

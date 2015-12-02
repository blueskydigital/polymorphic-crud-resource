
should = require 'should'
request = require 'request'
async = require 'async'

module.exports = (g, addr) ->

  it "shall prepare data", (done) ->
    async.map g.data, (item, cback)->
      request
        url: addr
        body: item
        json: true,
        method: 'post'
      , (err, res, body) ->
        return done(err) if err
        res.statusCode.should.eql 201
        should.exist body.id
        cback(null)
    , (err, results)->
      return done(err) if err
      done()

  it "shall list items", (done) ->
    request
      url: addr
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      body.length.should.eql 3
      done()

  it "shall list items in range 1-3", (done) ->
    request
      url: "#{addr}&range=[1-3]"
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      body.length.should.eql 2
      done()

  it "shall list items sorted according age", (done) ->
    request
      url: "#{addr}&sort=['age','desc']"
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      body.length.should.eql 2
      done()

  it "shall list items that has parent_id=1 and sorted acording birth_year", (done) ->
    request
      url: "#{addr}filter={parent_id:1}&sort=['birth_year', 'asc']"
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      body.length.should.eql 2
      done()

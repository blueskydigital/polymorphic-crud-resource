
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
      res.headers['x-total-count'].should.eql '3'
      done()

  it "shall list items in range 1-3", (done) ->
    request
      url: "#{addr}/?offset=1&limit=20"
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      console.log JSON.stringify(body, null, 2)
      body.length.should.eql 2
      body[0].id.should.eql 2
      body[1].id.should.eql 3
      res.headers['x-total-count'].should.eql '3'
      done()

  it "shall list items sorted according age", (done) ->
    request
      url: addr + '/?sort=[["age","desc"]]'
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      console.log JSON.stringify(body, null, 2)
      body.length.should.eql 3
      body[0].age.should.eql 32
      body[1].age.should.eql 26
      body[2].age.should.eql 22
      done()

  it "shall list items that has parent_id=1 and sorted acording birth_year", (done) ->
    request
      url: addr + '/?filter={"parent_id":"1"}&sort=[["birth_year", "desc"]]'
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      console.log JSON.stringify(body, null, 2)
      body.length.should.eql 2
      body[0].birth_year.should.eql 1988
      body[1].birth_year.should.eql 1983
      done()

  it "shall list subset of attrs of items that has parent_id=1", (done) ->
    request
      url: addr + '/?filter={"parent_id":"1"}&sort=[["birth_year", "asc"]]&attrs=["birth_year", "town"]'
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      console.log JSON.stringify(body, null, 2)
      body.length.should.eql 2
      for i in body
        Object.keys(i).length.should.eql 2
      res.headers['x-total-count'].should.eql '2'
      done()

  it "shall list subset with PAGING of attrs of items that has parent_id=1", (done) ->
    request
      url: addr + '/?offset=1&limit=1&filter={"parent_id":"1"}&sort=[["birth_year", "asc"]]&attrs=["birth_year", "town"]'
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      console.log JSON.stringify(body, null, 2)
      body.length.should.eql 1
      for i in body
        Object.keys(i).length.should.eql 2
      res.headers['x-total-count'].should.eql '2'
      done()

  it "shall list subset of attrs (with name embeded)", (done) ->
    request
      url: addr + '/?attrs=["birth_year", "town"]&embed=["name"]'
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      console.log JSON.stringify(body, null, 2)
      body.length.should.eql 3
      for i in body
        Object.keys(i).length.should.eql 4 # with id
      done()

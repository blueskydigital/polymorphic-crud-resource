
should = require 'should'
request = require 'request'

module.exports = (entityFactory, change, addr) ->

  troll = entityFactory()

  it "shall create new item", (done) ->
    request
      url: addr
      body: troll
      json: true,
      method: 'post'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 201
      should.exist body.id
      troll.id = body.id
      done()

  it "shall list items", (done) ->
    request
      url: addr
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 200
      body.length.should.eql 1
      should.exist body[0].id
      done()

  it "shall return full info about item", (done) ->
    request
      url: "#{addr}/#{troll.id}"
      body: change
      json: true
      method: 'get'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      should.deepEqual(body, troll)
      done()

  changedTroll = null

  it "shall update the item with: #{JSON.stringify(change)}", (done) ->
    request
      url: "#{addr}/#{troll.id}"
      body: change
      json: true,
      method: 'put'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      changedTroll = JSON.parse(JSON.stringify(troll))
      for k, v of change
        changedTroll[k] = change[k]
      should.deepEqual(body, changedTroll)
      done()

  it "shall delete item", (done) ->
    request
      url: "#{addr}/#{troll.id}"
      json: true,
      method: 'delete'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      should.deepEqual(body, changedTroll)
      done()

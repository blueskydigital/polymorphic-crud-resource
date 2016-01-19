
should = require 'should'
request = require 'request'
utils = require './utils'

module.exports = (g, addr, data, change) ->

  troll = data

  it "shall create new item", (done) ->
    request
      url: addr
      body: troll
      json: true,
      method: 'post'
    , (err, res, body) ->
      return done(err) if err
      console.log JSON.stringify(addr: body, null, '  ')
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
      console.log JSON.stringify({addr: addr, body: body}, null, '  ')
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
      console.log JSON.stringify({addr: "#{addr}/#{troll.id}", body: body}, null, '  ')
      utils.deepCompare(body, troll)
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
      console.log JSON.stringify({addr: "#{addr}/#{troll.id}", body: body}, null, '  ')
      changedTroll = JSON.parse(JSON.stringify(troll))
      for k, v of change
        changedTroll[k] = change[k]
      utils.deepCompare(body, changedTroll)
      done()

  it "shall delete item", (done) ->
    request
      url: "#{addr}/#{troll.id}"
      json: true,
      method: 'delete'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      console.log JSON.stringify({addr: "#{addr}/#{troll.id}", body: body}, null, '  ')
      utils.deepCompare(body, changedTroll)
      done()

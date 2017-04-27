
should = require 'should'
request = require 'request'
utils = require '../utils'

module.exports = (g, addr) ->

  change =
    name: [{lang: 'cz', value: 'ChangedCZTrolol'}]
    birth_year: 1999

  troll = g.data[0]

  it "shall create new item", (done) ->
    request
      url: addr
      body: troll
      json: true,
      method: 'post'
    , (err, res, body) ->
      return done(err) if err
      console.log JSON.stringify(created: body, null, '  ')
      res.statusCode.should.eql 201
      should.exist body.id
      should.exist body.name
      should.exist body.descr
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
      should.exist body.name
      should.exist body.descr
      console.log JSON.stringify({addr: "#{addr}/#{troll.id}", body: body}, null, '  ')
      utils.deepCompare(body, troll)
      troll = body
      done()

  it "shall update the item", (done) ->
    # update attr of troll and some assotiations
    updatedTrol = JSON.parse(JSON.stringify(troll))
    updatedTrol.town = 'ZellAmSee'
    updatedTrol.name.splice(0, 1) # delete first item from name array
    updatedTrol.name[0].lang = 'es' # update the remaining item
    updatedTrol.name[0].updated = new Date()
    updatedTrol.name.push({lang: 'us', value: 'anglickej trololol'})
    request
      url: "#{addr}/#{troll.id}"
      body: updatedTrol
      json: true
      method: 'put'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      console.log JSON.stringify({addr: "#{addr}/#{troll.id}", body: body}, null, '  ')
      res.body.town.should.eql 'ZellAmSee'
      body.name.length.should.eql 2
      body.name[0].value.should.eql 'anglickej trololol'
      body.name[0].lang.should.eql 'us'
      body.name[1].lang.should.eql 'es'
      done()

  it "shall delete item", (done) ->
    request
      url: "#{addr}/#{troll.id}"
      json: true
      method: 'delete'
    , (err, res, body) ->
      return done(err) if err

      res.statusCode.should.eql 200
      console.log JSON.stringify({addr: "#{addr}/#{troll.id}", body: body}, null, '  ')
      done()

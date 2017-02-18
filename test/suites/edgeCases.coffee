should = require 'should'
request = require 'request'
tester = require '../tester'

module.exports = (g, addr) ->

  it "shall create new item without assotiations", (done) ->
    withoutAssocs =
      birth_year: 1945
      town: 'Tabor'
      age: 32
      parent_id: 1

    request
      url: addr
      body: withoutAssocs
      json: true,
      method: 'post'
    , (err, res, body) ->
      return done(err) if err
      console.log JSON.stringify(addr: body, null, '  ')
      res.statusCode.should.eql 201
      should.exist body.id
      done()

  it "mustnot create new item if assotiations incorrect", (done) ->
    troll =
      birth_year: 1945
      town: 'Tabor'
      age: 32
      parent_id: 1
      name: [
        {lang: 'cz', value: "ceskej troll"}
        {lang: 'cz', value: "zase ceskej troll - duplicity"}
      ]
    # try to create it, but SHOULD fail with 400
    request
      url: addr
      body: troll
      json: true
      method: 'post'
    , (err, res, body) ->
      return done(err) if err
      console.log body
      res.statusCode.should.eql 400
      should.not.exist body.id
      done()


  it "mustnot change existing assotiated data on fail", (done) ->
    origNames = [
      {lang: 'cz', value: "ceskej troll"}
      {lang: 'en', value: "anglickej troll"}
    ]
    troll =
      birth_year: 1945
      town: 'Tabor'
      age: 32
      parent_id: 1
      name: origNames

    # create troll
    request
      url: addr
      body: troll
      json: true
      method: 'post'
    , (err, res, body) ->
      return done(err) if err
      res.statusCode.should.eql 201
      should.exist body.id
      troll.id = body.id

      # try to update troll with duplicate names
      troll.name = [
        {lang: 'cz', value: "ceskej troll"}
        {lang: 'cz', value: "duplicitni ceskej troll"}
      ]
      request
        url: "#{addr}/#{troll.id}"
        body: troll
        json: true
        method: 'put'
      , (err, res, body) ->
        return done(err) if err
        console.log JSON.stringify(addr: body, null, '  ')
        res.statusCode.should.eql 400

        # and see if data changed
        request
          url: "#{addr}/#{troll.id}"
          json: true
          method: 'get'
        , (err, res, body) ->
          return done(err) if err
          console.log JSON.stringify(addr: body, null, '  ')
          should.exist body.name
          body.name.should.eql origNames
          done()

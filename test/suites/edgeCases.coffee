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

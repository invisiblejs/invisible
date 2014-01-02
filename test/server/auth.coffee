assert = require('assert')
Invisible = require('../../')
request = require('supertest')
mongo = require('mongodb')
express = require('express')
config = require('../../lib/config')

config.db_uri = 'mongodb://127.0.0.1:27017/invisible-test'

app = express()
app.use express.bodyParser()
app.use(require('../../lib/auth'))
require('../../lib/routes')(app)


describe 'Auth routes', () ->

    person = undefined
    db = undefined

    before (done) ->
        config.authenticate = (user, pasword, cb) ->
            if user == "Facundo" and password == "pass"
                return cb(null, username:user, password:password)
            return cb("failed!")
        config.authExpiration = 10

        class User
            constructor: (@user, @pass) ->

        Invisible.createModel("User", User)
        person = new Invisible.User("Facundo", "pass")
        
    
        mongo.connect config.db_uri, (err, database) ->
            db = database
            db.dropDatabase ()->
                person.save ()->
                    done()
    
    it 'Should send a 401 when authentication is configured', (done)->
        request(app)
        .get('/invisible/User/')
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should send send a 200 when including a valid token', (done)->
        expires = new Date()
        expires.setSeconds(expires.getSeconds() + 10)
        token = 
            token: "access"
            refresh: "refresh"
            expires: expires
            user: person._id

        col = db.collection("AuthToken")
        col.save token, (err, token)->
            request(app)
            .get('/invisible/User/')
            .set('Authorization', 'Bearer access')
            .end (err, res) ->
                assert.equal(res.statusCode, 200)
                assert not err
                done()

    it 'Should send send a 401 when including an invalid token', (done)->
        request(app)
        .get('/invisible/User/')
        .set('Authorization', 'Bearer invalid')
        .end (err, res) ->
            assert.equal(res.statusCode, 401)
            done()

    it 'Should send send a 401 when the token has expired', ()->
        fail()

    it 'Should generate a new token when authenticated', ()->
        fail()

    it 'Should not generate a token when not authenticated', ()->
        fail()

    it 'Should not generate a token when the credentials are invalid', ()->
        fail()

    it 'Should refresh the token when given a valid refresh token', ()->
        fail()

    it 'Should not refresh the token when not given a refresh token', ()->
        fail()

    it 'Should not refresh the token when given an invalid refresh token', ()->
        fail()


